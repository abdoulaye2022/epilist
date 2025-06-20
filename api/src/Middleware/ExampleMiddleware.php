<?php
// src/Middleware/ExampleMiddleware.php

namespace App\Middleware;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;

class ExampleMiddleware
{
    public function __invoke(Request $request, RequestHandler $handler): Response
    {
        // Exemple de traitement avant la requête
        $response = $handler->handle($request);

        // Exemple de traitement après la requête
        return $response->withHeader('X-Custom-Header', 'Middleware');
    }
}