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
    private function createErrorResponse(string $message, int $statusCode, string $code = ''): JsonResponse
    {
        return new JsonResponse(
            $statusCode,
            new Headers(['Content-Type' => 'application/json']),
            (new StreamFactory())->createStream(json_encode([
                'success' => false,
                'code' => $code,
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
            $user = User::find($decoded['data']->auth_id);

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
                'message' => 'Login successful',
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'data' => [
                    'id' => $user->id,
                    'first_name' => $user->first_name,
                    'last_name' => $user->last_name,
                    'email' => $user->email,
                    'email_verified' => $user->email_verified,
                    'email_verified_at' => $user->email_verified_at
                ]]))
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
                'code' => 'VALIDATION_ERROR',
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
                return $this->createErrorResponse(
                    'Invalid credentials. Please try again.', 
                    401,
                    'USER_NOT_FOUND'
                );
            }

            // Verify password
            if (!password_verify($data['password'], $user->password_hash)) {
                return $this->createErrorResponse(
                    'Invalid credentials. Please try again.', 
                    401,
                    'INVALID_PASSWORD'
                );
            }

            // Vérifier si l'email est confirmé
            if (!$user->isEmailVerified()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'code' => 'EMAIL_NOT_VERIFIED',
                    'message' => 'Please verify your email address before logging in.',
                    'data' => [
                        'email' => $user->email,
                        'verification_required' => true,
                        'can_resend_code' => true
                    ]
                ]));
                return $response
                    ->withHeader('Content-Type', 'application/json')
                    ->withStatus(403);
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
                    'email' => $user->email,
                    'email_verified' => $user->email_verified,
                    'email_verified_at' => $user->email_verified_at
                ]
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);

        } catch (\Exception $e) {
            // Error handling
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'SERVER_ERROR',
                'message' => 'Login failed: ' . $e->getMessage()
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
            ->message('Invalid email address');
        
        $validator->rule('lengthMax', 'email', 255)
            ->message('Email is too long (max 255 characters)');
        
        $validator->rule('lengthMax', ['first_name', 'last_name'], 100)
            ->message('{field} is too long (max 100 characters)');

        $validator->rule(function($field, $value, $params, $fields) {
            return User::where('email', $value)->count() === 0;
        }, 'email')->message('This email is already registered');

        // Validate
        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'VALIDATION_ERROR',
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            // Check if email already exists
            if (User::findByEmail($data['email'])) {
                return $this->createErrorResponse(
                    'This email is already registered', 
                    400,
                    'EMAIL_ALREADY_EXISTS'
                );
            }

            // Generate verification code
            $verificationCode = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiration = Carbon::now()->addHours(2);

            // Create user
            $user = User::create([
                'first_name' => trim($data['first_name']),
                'last_name' => trim($data['last_name']),
                'email' => filter_var($data['email'], FILTER_SANITIZE_EMAIL),
                'password_hash' => password_hash($data['password'], PASSWORD_DEFAULT),
                'terms_accepted' => true,
                'email_verification_code' => $verificationCode,
                'email_verification_code_expires_at' => $expiration,
                'created_at' => new \DateTime(),
                'updated_at' => new \DateTime()
            ]);

            // In dev environment, override email for testing
            if(Config::get('APP_ENV') == 'dev') {
                $user->email = 'm2atodev@gmail.com';
            }

            // Send verification email
            $mailSender = new MailSender();
            $mailSender->sendVerificationEmail($user->email, $user->first_name, $verificationCode);

            // Success response
            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Account created successfully. Please check your email for verification code.',
                'data' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'first_name' => $user->first_name,
                    'last_name' => $user->last_name,
                    'email_verified' => $user->email_verified,
                    'verification_required' => true
                ]
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(201);

        } catch (\Exception $e) {
            // Error handling
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'SERVER_ERROR',
                'message' => 'Registration failed: ' . $e->getMessage()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }

    public function confirmEmail(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('required', ['email', 'code'])
            ->message('{field} is required');
        $validator->rule('email', 'email')
            ->message('Invalid email address');

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
            $user = User::findByEmail($data['email']);
            
            if (!$user) {
                return $this->createErrorResponse('User not found', 404);
            }

            // Vérifier si l'email est déjà vérifié
            if ($user->isEmailVerified()) {
                return $this->createErrorResponse('Email already verified', 400);
            }

            // Vérifier le code et son expiration
            if ($user->email_verification_code !== $data['code']) {
                return $this->createErrorResponse('Invalid verification code', 400);
            }

            if (Carbon::now()->gt($user->email_verification_code_expires_at)) {
                return $this->createErrorResponse('Verification code has expired', 400);
            }

            // Marquer l'email comme vérifié
            $user->email_verified_at = Carbon::now();
            $user->email_verification_code = null;
            $user->email_verification_code_expires_at = null;
            $user->email_verified = 1;
            $user->save();

            if(Config::get('APP_ENV')=='dev') {
                $user->email = 'm2atodev@gmail.com';
            }

            // Envoyer l'email de bienvenue
            $mailSender = new MailSender();
            $mailSender->sendWelcomeEmail($user->email, $user->first_name);

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Email verified successfully',
                    'data' => [
                        'email_verified' => true,
                        'email_verified_at' => $user->email_verified_at->format('Y-m-d H:i:s')
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Error verifying email: ' . $e->getMessage(), 500);
        }
    }

    public function resendVerificationEmail(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('required', ['email'])
            ->message('{field} is required');
        $validator->rule('email', 'email')
            ->message('Invalid email address');

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
            $user = User::findByEmail($data['email']);
            
            if (!$user) {
                return $this->createErrorResponse('User not found', 404);
            }

            // Vérifier si l'email est déjà vérifié
            if ($user->isEmailVerified()) {
                return $this->createErrorResponse('Email already verified', 400);
            }

            // Générer un nouveau code de vérification
            $verificationCode = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiration = Carbon::now()->addHours(2);

            // Mettre à jour le code
            $user->email_verification_code = $verificationCode;
            $user->email_verification_code_expires_at = $expiration;
            $user->save();

            if(Config::get('APP_ENV')=='dev') {
                $user->email = 'm2atodev@gmail.com';
            }

            // Envoyer le nouveau code par email
            $mailSender = new MailSender();
            $mailSender->sendVerificationEmail($user->email, $user->first_name, $verificationCode);

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Verification email resent successfully'
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Error resending verification email: ' . $e->getMessage(), 500);
        }
    }

    public function requestPasswordChange(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('required', ['email'])
            ->message('{field} is required');
        $validator->rule('email', 'email')
            ->message('Invalid email address');

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
            $user = User::findByEmail($data['email']);
            
            if (!$user) {
                return $this->createErrorResponse('If this email exists, a password change code has been sent.', 200);
            }

            // Générer un code de 6 chiffres
            $code = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiration = Carbon::now()->addHours(2); // Code valide pendant 2 heures

            // Sauvegarder le code et sa date d'expiration
            $user->password_change_code = $code;
            $user->password_change_code_expires_at = $expiration;
            $user->save();


            if(Config::get('APP_ENV')=='dev') {
                $user->email = 'm2atodev@gmail.com';
            }

            // Envoyer le code par email
            $mailSender = new MailSender();
            $mailSender->sendPasswordChangeCode($user->email, $code);

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'If this email exists, a password change code has been sent.'
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Error sending password change code: ' . $e->getMessage(), 500);
        }
    }

    public function verifyPasswordChangeCode(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('required', ['email', 'code', 'new_password'])
            ->message('{field} is required');
        $validator->rule('email', 'email')
            ->message('Invalid email address');
        $validator->rule('lengthMin', 'new_password', 6)
            ->message('Password must be at least 6 characters');

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
            $user = User::findByEmail($data['email']);
            
            if (!$user) {
                return $this->createErrorResponse('Invalid request', 400);
            }

            // Vérifier le code et son expiration
            if ($user->password_change_code !== $data['code']) {
                return $this->createErrorResponse('Invalid code', 400);
            }

            if (Carbon::now()->gt($user->password_change_code_expires_at)) {
                return $this->createErrorResponse('Code has expired', 400);
            }

            // Mettre à jour le mot de passe
            $user->password_hash = password_hash($data['new_password'], PASSWORD_DEFAULT);
            $user->password_change_code = null;
            $user->password_change_code_expires_at = null;
            $user->save();

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Password changed successfully'
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Error changing password: ' . $e->getMessage(), 500);
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
                        'email_verified' => $user->email_verified,
                        'email_verified_at' => $user->email_verified_at
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
                        'email_verified' => $user->email_verified,
                        'email_verified_at' => $user->email_verified_at
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