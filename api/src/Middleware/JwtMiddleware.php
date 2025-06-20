<?php
// src/Middleware/JwtMiddleware.php

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
        // Extract token from Authorization header
        $authHeader = $request->getHeaderLine('Authorization');

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