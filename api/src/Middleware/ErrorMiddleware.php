<?php

namespace App\Middleware;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;
use Psr\Http\Message\ResponseFactoryInterface;
use Slim\Exception\HttpMethodNotAllowedException;
use Slim\Exception\HttpNotFoundException; // Import manquant

class ErrorMiddleware
{
    private ResponseFactoryInterface $responseFactory;

    public function __construct(ResponseFactoryInterface $responseFactory)
    {
        $this->responseFactory = $responseFactory;
    }

    public function __invoke(Request $request, RequestHandler $handler): Response
    {
        error_log("ErrorMiddleware: Processing request: " . $request->getMethod() . " " . $request->getUri()->getPath());

        try {
            // Passe la requête au prochain middleware ou au gestionnaire de route
            $response = $handler->handle($request);
            error_log("ErrorMiddleware: Request completed successfully");

            // Un contrôleur qui rattrape lui-même son exception et répond
            // « 500 » de sa propre main n'arrivait jamais dans le journal :
            // l'écran Monitoring restait calme pendant que l'application
            // multipliait les erreurs. On journalise donc d'après le STATUT
            // de la réponse, d'où qu'elle vienne.
            if ($response->getStatusCode() >= 500) {
                $this->logServerError($request, $response->getStatusCode(), $this->peekBody($response));
            }

            return $response;
        } catch (HttpNotFoundException $e) {
            // Gestion spécifique de l'erreur "Not Found"
            return $this->createErrorResponse('Route non trouvée.', 404);
        } catch (HttpMethodNotAllowedException $e) {
            // Gestion spécifique de l'erreur "Method Not Allowed"
            return $this->createErrorResponse('Méthode HTTP non autorisée pour cette route.', 405);
        } catch (\App\Services\SpaceAccessException $e) {
            // Accès espace refusé (Phase 2) : réponse propre, jamais un 500.
            return $this->createErrorResponse($e->getMessage(), $e->getStatus());
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            // Un identifiant qui ne désigne rien est une erreur de l'appelant,
            // pas une panne du serveur : 404, et pas de ligne dans le journal
            // des erreurs (sinon il se remplit de faux positifs).
            return $this->createErrorResponse('Ressource introuvable.', 404);
        } catch (\Throwable $e) {
            // \Throwable et non \Exception : les erreurs du moteur PHP
            // (TypeError, appel sur null, ArgumentCountError…) n'héritent PAS
            // de \Exception. Elles passaient donc à côté d'ici, repartaient en
            // page d'erreur Slim — du HTML, là où l'application attend du
            // JSON — et n'étaient jamais journalisées.
            error_log("ErrorMiddleware: EXCEPTION CAUGHT!");
            error_log('ErrorMiddleware Exception: ' . $e->getMessage());
            error_log('ErrorMiddleware Exception File: ' . $e->getFile());
            error_log('ErrorMiddleware Exception Line: ' . $e->getLine());
            error_log('ErrorMiddleware Stack trace: ' . $e->getTraceAsString());

            $this->logServerError(
                $request,
                500,
                $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine()
            );

            $message = 'Une erreur interne est survenue.';

            // En mode dev, afficher le message d'erreur détaillé
            if (($_ENV['APP_ENV'] ?? '') === 'dev') {
                $message .= ' Détails: ' . $e->getMessage();
            }

            return $this->createErrorResponse($message, 500);
        }
    }

    /**
     * Journal pour l'écran Monitoring de l'espace admin. Protégé : si la base
     * est elle-même en cause, on ne boucle pas.
     */
    private function logServerError(Request $request, int $status, string $message): void
    {
        try {
            \Illuminate\Database\Capsule\Manager::table('api_error_logs')->insert([
                'method' => $request->getMethod(),
                'path' => substr($request->getUri()->getPath(), 0, 255),
                'status' => $status,
                'message' => substr($message, 0, 2000),
                'user_id' => $request->getAttribute('auth_id'),
                'created_at' => date('Y-m-d H:i:s'),
            ]);
        } catch (\Throwable $logError) {
            // silencieux
        }
    }

    /** Lit le corps d'une réponse sans le consommer (pour le journal). */
    private function peekBody(Response $response): string
    {
        try {
            $body = $response->getBody();
            if (!$body->isSeekable()) {
                return '';
            }
            $position = $body->tell();
            $body->rewind();
            $contents = $body->read(2000);
            $body->seek($position);
            return $contents;
        } catch (\Throwable $e) {
            return '';
        }
    }

    private function createErrorResponse(string $message, int $statusCode): Response
    {
        $response = $this->responseFactory->createResponse($statusCode);
        $response->getBody()->write(json_encode(['success' => false, 'message' => $message]));
        return $response->withHeader('Content-Type', 'application/json');
    }
}
