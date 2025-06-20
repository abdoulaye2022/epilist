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
        try {
            // Passe la requête au prochain middleware ou au gestionnaire de route
            return $handler->handle($request);
        } catch (HttpNotFoundException $e) {
            // Gestion spécifique de l'erreur "Not Found"
            return $this->createErrorResponse('Route non trouvée.', 404);
        } catch (HttpMethodNotAllowedException $e) {
            // Gestion spécifique de l'erreur "Method Not Allowed"
            return $this->createErrorResponse('Méthode HTTP non autorisée pour cette route.', 405);
        } catch (\Exception $e) {
            // Gestion des autres erreurs
            var_dump($e->getMessage()); die;
            return $this->createErrorResponse('Une erreur interne est survenue.', 500);
        }
    }

    private function createErrorResponse(string $message, int $statusCode): Response
    {
        $response = $this->responseFactory->createResponse($statusCode);
        $response->getBody()->write(json_encode(['success' => false, 'message' => $message]));
        return $response->withHeader('Content-Type', 'application/json');
    }
}