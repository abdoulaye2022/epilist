<?php
// src/Middleware/AdminMiddleware.php
// Réservé aux comptes avec users.role = 'admin'. À placer APRÈS JwtMiddleware
// (il lit l'attribut auth_id posé par celui-ci).

namespace App\Middleware;

use App\Models\User;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;
use Slim\Psr7\Factory\ResponseFactory;

class AdminMiddleware implements MiddlewareInterface
{
    public function process(Request $request, RequestHandler $handler): Response
    {
        $userId = $request->getAttribute('auth_id');

        $user = $userId ? User::find($userId) : null;
        if (!$user || ($user->role ?? null) !== 'admin') {
            $response = (new ResponseFactory())->createResponse(403);
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'FORBIDDEN',
                'message' => 'Admin privileges required'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        }

        return $handler->handle($request);
    }
}
