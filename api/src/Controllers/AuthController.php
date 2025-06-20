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
use Valitron\Validator;

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

        // Initialize validator
        $validator = new Validator($data);
        
        // Validation rules
        $validator->rule('required', ['email', 'password'])
            ->message('{field} is required');
        
        $validator->rule('email', 'email')
            ->message('Invalid email address');
        
        $validator->rule('lengthMax', 'email', 255)
            ->message('Email is too long (max 255 characters)');

        // Validate
        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            // Find user by email
            $user = User::findByEmail($data['email']);
            
            if (!$user) {
                return $this->createErrorResponse('Invalid credentials. Please try again.', 401);
            }

            // Verify password
            if (!password_verify($data['password'], $user->password_hash)) {
                return $this->createErrorResponse('Invalid credentials. Please try again.', 401);
            }

            // Generate tokens
            $accessToken = $this->jwtService->generateToken([
                'auth_id' => $user->id
            ]);

            $refreshToken = $this->jwtService->generateRefreshToken([
                'auth_id' => $user->id
            ]);

            // Success response
            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Login successful',
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'data' => [
                    'id' => $user->id,
                    'first_name' => $user->first_name,
                    'last_name' => $user->last_name,
                    'email' => $user->email
                ]
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);

        } catch (\Exception $e) {
            // Error handling
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Login failed',
                'error' => $e->getMessage()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }

    public function register(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        // Initialize validator
        $validator = new Validator($data);
        
        // Validation rules
        $validator->rule('required', ['first_name', 'last_name', 'email', 'password'])
            ->message('{field} is required');
        
        $validator->rule('email', 'email')
            ->message('Email is not valid');
        
        $validator->rule('lengthMax', 'email', 255)
            ->message('Email is too long (max 255 characters)');
        
        $validator->rule('lengthMax', ['first_name', 'last_name'], 100)
            ->message('{field} is too long (max 100 characters)');
    
        
        $validator->rule(function($field, $value, $params, $fields) {
            return User::where('email', $value)->count() === 0;
        }, 'email')->message('This email is already registered');

        // Validation
        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            // Data sanitization
            $cleanData = [
                'first_name' => trim($data['first_name']),
                'last_name' => trim($data['last_name']),
                'email' => filter_var($data['email'], FILTER_SANITIZE_EMAIL),
                'password_hash' => password_hash($data['password'], PASSWORD_DEFAULT),
                'terms_accepted' => 1, // Always set to 1 as required
                'created_at' => new \DateTime(),
                'updated_at' => new \DateTime()
            ];

            // Create user
            $user = User::create($cleanData);

            // Success response
            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Account created successfully',
                'data' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'first_name' => $user->first_name,
                    'last_name' => $user->last_name
                ]
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(201);

        } catch (\Exception $e) {
            // Error handling
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Error creating account',
                'error' => $e->getMessage()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }

    public function getCurrentUser(Request $request, Response $response)
    {
        // Récupérer l'ID de l'utilisateur depuis le token JWT
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        try {
            $user = User::find($authId);
            
            if (!$user) {
                return $this->createErrorResponse('Utilisateur non trouvé', 404);
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'data' => [
                        'id' => $user->id,
                        'first_name' => $user->first_name,
                        'last_name' => $user->last_name,
                        'email' => $user->email,
                        'phone' => $user->phone ?? null,
                        'avatar' => $user->avatar ?? null,
                        'email_verified' => (bool)$user->email_verified,
                        'created_at' => $user->created_at->format('Y-m-d H:i:s'),
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    public function updateProfile(Request $request, Response $response)
    {
        // Get user ID from JWT token
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Unauthorized', 401);
        }

        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('required', ['first_name', 'last_name'])
            ->message('{field} is required');
        $validator->rule('lengthMax', ['first_name', 'last_name'], 100)
            ->message('{field} is too long (max 100 characters)');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            $user = User::find($authId);
            
            if (!$user) {
                return $this->createErrorResponse('User not found', 404);
            }

            // Update ONLY first name and last name fields
            $user->first_name = $data['first_name'];
            $user->last_name = $data['last_name'];
            $user->updated_at = new \DateTime();
            $user->save();

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Profile updated successfully',
                    'data' => [
                        'id' => $user->id,
                        'first_name' => $user->first_name,
                        'last_name' => $user->last_name,
                        'email' => $user->email,
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Update error: ' . $e->getMessage(), 500);
        }
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