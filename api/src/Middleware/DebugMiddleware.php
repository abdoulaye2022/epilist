<?php
// src/Middleware/DebugMiddleware.php - MIDDLEWARE DE DÉBOGAGE TEMPORAIRE

namespace App\Middleware;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;

class DebugMiddleware
{
    public function __invoke(Request $request, RequestHandler $handler): Response
    {
        $uri = $request->getUri()->getPath();
        
        // Déboguer seulement les routes SSO Apple
        if (strpos($uri, '/auth/sso/apple') !== false) {
            error_log(" [DebugMiddleware] === DÉBUT REQUÊTE APPLE ===");
            error_log(" [DebugMiddleware] URI: " . $uri);
            error_log(" [DebugMiddleware] Méthode: " . $request->getMethod());
            error_log(" [DebugMiddleware] Headers: " . json_encode($request->getHeaders()));
            
            $body = $request->getBody()->getContents();
            error_log(" [DebugMiddleware] Body brut: " . $body);
            
            // Remettre le body à sa place
            $request->getBody()->rewind();
            
            try {
                $parsedBody = $request->getParsedBody();
                error_log(" [DebugMiddleware] Body parsé: " . json_encode($parsedBody));
            } catch (\Exception $e) {
                error_log(" [DebugMiddleware] Erreur parsing body: " . $e->getMessage());
            }
        }

        // Traiter la requête
        $response = $handler->handle($request);

        // Déboguer la réponse Apple
        if (strpos($uri, '/auth/sso/apple') !== false) {
            $responseBody = $response->getBody()->getContents();
            error_log(" [DebugMiddleware] Réponse status: " . $response->getStatusCode());
            error_log(" [DebugMiddleware] Réponse headers: " . json_encode($response->getHeaders()));
            error_log(" [DebugMiddleware] Réponse body: " . $responseBody);
            error_log(" [DebugMiddleware] === FIN REQUÊTE APPLE ===");
            
            // Remettre le body à sa place
            $response->getBody()->rewind();
        }

        return $response;
    }
}