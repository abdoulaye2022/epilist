<?php
// src/Controllers/AuthController.php

namespace App\Controllers;

use App\Models\User;
use App\Services\JwtService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Psr7\Response as SlimResponse;
use Slim\Psr7\Factory\ResponseFactory;
use Slim\Psr7\Factory\StreamFactory;
use Slim\Psr7\Headers;
use Slim\Psr7\Response as JsonResponse;
use App\Services\MailSender;
use App\Config\Config;
use Carbon\Carbon;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\ClientException;
use GuzzleHttp\Exception\RequestException;

class AuthController
{
    private $jwtService;

    public function __construct()
    {
        $this->jwtService = new JwtService();
    }

    /**
     * Crée une réponse d'erreur JSON.
     *
     * @param string $message
     * @param int $statusCode
     * @return JsonResponse
     */
    private function createErrorResponse(string $message, int $statusCode): JsonResponse
    {
        return new JsonResponse(
            $statusCode,
            new Headers(['Content-Type' => 'application/json']),
            (new StreamFactory())->createStream(json_encode([
                'success' => false,
                'message' => $message,
            ]))
        );
    }

    public function refresh_token(Request $request, Response $response)
    {
        // Récupérer les données de la requête
        $data = json_decode($request->getBody(), true);
        $refreshToken = $data['refresh_token'] ?? '';

        // Vérifier si le refresh_token est fourni
        if (empty($refreshToken)) {
            return $this->createErrorResponse('Refresh token manquant', 400);
        }

        try {
            // Décoder et valider le refresh_token
            $decoded = $this->jwtService->validateRefreshToken($refreshToken);
            if (!$decoded) {
                return $this->createErrorResponse('Token invalide ou expiré', 401);
            }

            // Vérifier si le refresh_token est expiré
            if (isset($decoded->exp) && $decoded->exp < time()) {
                return $this->createErrorResponse('Refresh token expiré', 401);
            }

            // Récupérer l'employé associé au refresh_token
            $user = User::find($decoded['sub']->auth_id);

            if (!$user) {
                return $this->createErrorResponse('Utilisateur non trouvé', 404);
            }

            // Générer un nouveau access_token
            $accessToken = $this->jwtService->generateToken([
                'auth_id' => $user->id
            ]);

            // Générer un nouveau refresh_token
            $newRefreshToken = $this->jwtService->generateRefreshToken([
                'auth_id' => $user->id
            ]);

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Tokens rafraîchis avec succès',
                    'access_token' => $accessToken,
                    'refresh_token' => $newRefreshToken,
                    'data' => [
                        'id' => $user->id,
                        'number' => $user->number,
                        'first_name' => $user->first_name,
                        'last_name' => $user->last_name,
                        'email' => $user->email,
                        'phone' => $user->phone,
                        'email_verified' => $user->email_verified,
                        'is_stripe_active' => $user->is_stripe_active, 
                        'role' => $user->role,
                        'avatar' => $user->avatar
                    ],
                    'iva' => $user->role == 'admin' ? 1 : 0 
                ]))
            );

        } catch (\Exception $e) {
            // En cas d'erreur (token invalide, etc.)
            return $this->createErrorResponse('Refresh token invalide: ' . $e->getMessage(), 401);
        }
    }

    public function login(Request $request, Response $response)
    {
        $data = $request->getParsedBody();
    
        // error_log(print_r($data, true));
    
        if (empty($data)) {
            return $this->createErrorResponse('Missing or invalid request data', 400);
        }
    
        $email = $data['email'] ?? '';
        $password = $data['password'] ?? '';
    
        // Validation de l'email
        if (empty($email)) {
            return $this->createErrorResponse('Email is required', 400);
        }
    
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $this->createErrorResponse('Invalid email address', 400);
        }
    
        // Validation du mot de passe
        if (empty($password)) {
            return $this->createErrorResponse('Password is required', 400);
        }
    
        $user = User::findByEmail($email);
    
        if (!$user) {
            return $this->createErrorResponse('Identifiants incorrects. Veuillez réessayer.', 400);
        }
    
        if (!password_verify($password, $user->password_hash)) {
            return $this->createErrorResponse('Identifiants incorrects. Veuillez réessayer.', 400);
        }
    
        $accessToken = $this->jwtService->generateToken([
            'auth_id' => $user->id
        ]);
    
        $refreshToken = $this->jwtService->generateRefreshToken([
            'auth_id' => $user->id
        ]);
    
        return new JsonResponse(
            200,
            new Headers(['Content-Type' => 'application/json']),
            (new StreamFactory())->createStream(json_encode([
                'success' => true,
                'message' => 'Login successful.',
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'data' => [
                    'id' => $user->id,
                    'first_name' => $user->first_name,
                    'last_name' => $user->last_name,
                    'email' => $user->email
                ]
            ]))
        );
    }

    public function register(Request $request, Response $response)
    {
        $data = $request->getParsedBody();
    
        $errors = [];
    
        // Validation des champs
        if (empty($data['first_name'])) {
            $errors['first_name'] = 'Le prénom est obligatoire.';
        }
    
        if (empty($data['last_name'])) {
            $errors['last_name'] = 'Le nom est obligatoire.';
        }
    
        if (empty($data['email'])) {
            $errors['email'] = 'L\'email est obligatoire.';
        } elseif (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            $errors['email'] = 'L\'email n\'est pas valide.';
        } else {
            $data['email'] = filter_var($data['email'], FILTER_SANITIZE_EMAIL);
        }
    
        if (empty($data['password'])) {
            $errors['password'] = 'Le mot de passe est obligatoire.';
        }
    
        // Si des erreurs sont détectées, retournez une réponse JSON avec les erreurs
        if (!empty($errors)) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $errors,
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }
    
        // Vérifier si l'utilisateur existe déjà
        $existingUser = User::where('email', $data['email'])->first();
    
        if ($existingUser) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Ce courriel est déjà associé à un compte.',
                'errors' => ['email' => 'This email is already registered.'],
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }
    
        // Hacher le mot de passe
        $data['password_hash'] = password_hash($data['password'], PASSWORD_BCRYPT);
    
        // Créer l'utilisateur
        $user = User::create($data);
    
        // Retourner une réponse JSON de succès
        $response->getBody()->write(json_encode([
            'success' => true,
            'message' => 'Compte créé avec succès. Veuillez vérifier votre e-mail pour confirmedr votre compte.',
        ]));
        return $response
            ->withHeader('Content-Type', 'application/json')
            ->withStatus(200);
    }

    private function genererResetToken(): string {
        do {
            // Génère un nombre aléatoire de 6 chiffres
            $resetToken = bin2hex(random_bytes(32));
    
            // Vérifie si le numéro existe déjà dans la base de données
            $ad = User::where('reset_token', $resetToken)->first();
        } while ($ad); // Répète si le numéro existe déjà
    
        return $resetToken;
    }

    private function genererNumeroReference(): string {
        do {
            // Génère un nombre aléatoire de 6 chiffres
            $numero = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
    
            // Vérifie si le numéro existe déjà dans la base de données
            $user = User::where('number', $numero)->first();
        } while ($user); // Répète si le numéro existe déjà
    
        return $numero;
    }
}