<?php
// src/Middleware/JwtMiddleware.php - VERSION CORRIGÉE

namespace App\Middleware;

use App\Services\JwtService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;
use Psr\Http\Message\ResponseFactoryInterface;
use Slim\Psr7\Factory\StreamFactory;

class JwtMiddleware
{
    private JwtService $jwtService;
    private ResponseFactoryInterface $responseFactory;

    public function __construct(ResponseFactoryInterface $responseFactory)
    {
        $this->jwtService = new JwtService();
        $this->responseFactory = $responseFactory;
    }

    public function __invoke(Request $request, RequestHandler $handler): Response
    {
        // ✅ SOLUTION: Utiliser la méthode robuste pour récupérer le header
        $authHeader = $this->getAuthorizationHeader($request);

        if (empty($authHeader)) {
            return $this->createErrorResponse('Authorization header missing', 401);
        }

        // Check Bearer format
        if (!preg_match('/^Bearer\s+(.+)$/', $authHeader, $matches)) {
            return $this->createErrorResponse('Invalid authorization header format', 401);
        }

        $token = trim($matches[1]);

        if (empty($token)) {
            return $this->createErrorResponse('Access token missing', 401);
        }

        // Validate token
        $payload = $this->jwtService->validateToken($token);
        if (!$payload) {
            return $this->createErrorResponse('Invalid or expired access token', 401);
        }

        // Extract user ID
        $userId = $this->jwtService->getUserIdFromPayload($payload);
        if (!$userId) {
            return $this->createErrorResponse('Invalid token payload', 401);
        }

        // Add user ID to request attributes
        $request = $request->withAttribute('auth_id', $userId);
        $request = $request->withAttribute('jwt_payload', $payload);

        return $handler->handle($request);
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Récupère le header Authorization de façon robuste
     */
    private function getAuthorizationHeader(Request $request): ?string
    {
        // Méthode 1: getHeaderLine (méthode standard PSR-7)
        $authHeader = $request->getHeaderLine('Authorization');
        if (!empty($authHeader)) {
            return $authHeader;
        }

        // Méthode 2: getHeader (retourne un array)
        $headers = $request->getHeader('Authorization');
        if (!empty($headers)) {
            return $headers[0];
        }

        // Méthode 3: Variables serveur
        $serverParams = $request->getServerParams();
        
        // Essayer les différentes variables serveur possibles
        $possibleKeys = [
            'HTTP_AUTHORIZATION',
            'REDIRECT_HTTP_AUTHORIZATION', 
            'HTTP_X_AUTHORIZATION',
            'AUTHORIZATION'
        ];

        foreach ($possibleKeys as $key) {
            if (isset($serverParams[$key]) && !empty($serverParams[$key])) {
                return $serverParams[$key];
            }
        }

        // Méthode 4: apache_request_headers() si disponible
        if (function_exists('apache_request_headers')) {
            $apacheHeaders = apache_request_headers();
            
            // Essayer différentes variations de casse
            $authKeys = ['Authorization', 'authorization', 'AUTHORIZATION'];
            foreach ($authKeys as $key) {
                if (isset($apacheHeaders[$key]) && !empty($apacheHeaders[$key])) {
                    return $apacheHeaders[$key];
                }
            }
        }

        // Méthode 5: $_SERVER global en dernier recours
        if (isset($_SERVER['HTTP_AUTHORIZATION']) && !empty($_SERVER['HTTP_AUTHORIZATION'])) {
            return $_SERVER['HTTP_AUTHORIZATION'];
        }

        return null;
    }

    private function createErrorResponse(string $message, int $statusCode): Response
    {
        $errorData = [
            'success' => false,
            'error' => $message,
            'timestamp' => date('c')
        ];

        $response = $this->responseFactory->createResponse($statusCode);
        $response->getBody()->write(json_encode($errorData));
        
        return $response->withHeader('Content-Type', 'application/json');
    }
}