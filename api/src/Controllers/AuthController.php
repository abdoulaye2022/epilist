<?php
// src/Controllers/AuthController.php - VERSION COMPLÈTE AVEC SUPPORT DEVISE

namespace App\Controllers;

use App\Models\User;
use App\Models\Currency;
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
     * ✅ MÉTHODE UTILITAIRE POUR FORMATER LES DONNÉES UTILISATEUR AVEC DEVISE
     */
    private function formatUserData(User $user): array
    {
        // S'assurer que la devise est chargée
        if (!$user->relationLoaded('currency')) {
            $user->load('currency');
        }

        $currency = $user->getPreferredCurrency();

        return [
            'id' => $user->id,
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'full_name' => trim($user->first_name . ' ' . $user->last_name),
            'email' => $user->email,
            'email_verified' => $user->email_verified,
            'email_verified_at' => $user->email_verified_at?->toISOString(),
            'currency' => [
                'id' => $currency->id,
                'code' => $currency->code,
                'name' => $currency->name,
                'symbol' => $currency->symbol,
                'display_name' => $currency->name . ' (' . $currency->code . ')'
            ],
            'is_active' => $user->is_active,
            'created_at' => $user->created_at->toISOString(),
            'updated_at' => $user->updated_at->toISOString()
        ];
    }

    /**
     * Crée une réponse d'erreur JSON.
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

            // Récupérer l'utilisateur avec sa devise
            $user = User::with('currency')->find($decoded['data']->auth_id);

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
                    'message' => 'Token refreshed successfully',
                    'access_token' => $accessToken,
                    'refresh_token' => $newRefreshToken,
                    'data' => $this->formatUserData($user)
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
                'code' => 'VALIDATION_ERROR',
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            // Find user by email with currency
            $user = User::with('currency')->where('email', $data['email'])->first();
            
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

            // Success response with currency support
            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Login successful',
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'data' => $this->formatUserData($user)
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

        // ✅ NOUVELLE VALIDATION POUR LA DEVISE (OPTIONNELLE)
        if (isset($data['currency_id'])) {
            $validator->rule('integer', 'currency_id')
                ->message('Currency ID must be an integer');
            $validator->rule('min', 'currency_id', 1)
                ->message('Currency ID must be at least 1');
        }

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

            // ✅ GÉRER LA DEVISE SÉLECTIONNÉE
            $currencyId = 1; // CAD par défaut
            if (isset($data['currency_id'])) {
                $currency = Currency::active()->find($data['currency_id']);
                if ($currency) {
                    $currencyId = $currency->id;
                }
            }

            // Generate verification code
            $verificationCode = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiration = Carbon::now()->addHours(2);

            // Create user with currency
            $user = User::create([
                'first_name' => trim($data['first_name']),
                'last_name' => trim($data['last_name']),
                'email' => filter_var($data['email'], FILTER_SANITIZE_EMAIL),
                'password_hash' => password_hash($data['password'], PASSWORD_DEFAULT),
                'terms_accepted' => true,
                'currency_id' => $currencyId, // ✅ ASSIGNATION DE LA DEVISE
                'email_verification_code' => $verificationCode,
                'email_verification_code_expires_at' => $expiration,
                'created_at' => new \DateTime(),
                'updated_at' => new \DateTime()
            ]);

            // Charger la devise pour la réponse
            $user->load('currency');

            // In dev environment, override email for testing
            if(Config::get('APP_ENV') == 'dev') {
                $user->email = 'm2atodev@gmail.com';
            }

            // Send verification email
            $mailSender = new MailSender();
            $mailSender->sendVerificationEmail($user->email, $user->first_name, $verificationCode);

            // Success response with currency support
            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Account created successfully. Please check your email for verification code.',
                'data' => $this->formatUserData($user) + [
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
                'code' => 'VALIDATION_ERROR',
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            $user = User::with('currency')->where('email', $data['email'])->first();
            
            if (!$user) {
                return $this->createErrorResponse(
                    'User not found', 
                    404,
                    'USER_NOT_FOUND'
                );
            }

            // Vérifier si l'email est déjà vérifié
            if ($user->isEmailVerified()) {
                return $this->createErrorResponse(
                    'Email already verified', 
                    400,
                    'EMAIL_ALREADY_VERIFIED'
                );
            }

            // Vérifier le code et son expiration
            if ($user->email_verification_code !== $data['code']) {
                return $this->createErrorResponse(
                    'Invalid verification code', 
                    400,
                    'INVALID_VERIFICATION_CODE'
                );
            }

            if (Carbon::now()->gt($user->email_verification_code_expires_at)) {
                return $this->createErrorResponse(
                    'Verification code has expired', 
                    400,
                    'VERIFICATION_CODE_EXPIRED'
                );
            }

            // Marquer l'email comme vérifié
            $user->markEmailAsVerified();
            $user->save();

            if(Config::get('APP_ENV') == 'dev') {
                $user->email = 'm2atodev@gmail.com';
            }

            // Envoyer l'email de bienvenue
            $mailSender = new MailSender();
            $mailSender->sendWelcomeEmail($user->email, $user->first_name);

            // Generate tokens (comme dans login)
            $accessToken = $this->jwtService->generateToken([
                'auth_id' => $user->id
            ]);

            $refreshToken = $this->jwtService->generateRefreshToken([
                'auth_id' => $user->id
            ]);

            // Success response with currency support
            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Email verified successfully. You are now logged in.',
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'data' => $this->formatUserData($user)
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);

        } catch (\Exception $e) {
            // Error handling
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'SERVER_ERROR',
                'message' => 'Error verifying email: ' . $e->getMessage()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
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
                'code' => 'VALIDATION_ERROR',
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
                return $this->createErrorResponse(
                    'User not found',
                    404,
                    'USER_NOT_FOUND'
                );
            }

            // Vérifier le code et son expiration
            if ($user->password_change_code !== $data['code']) {
                return $this->createErrorResponse(
                    'Invalid verification code',
                    400,
                    'INVALID_CODE'
                );
            }

            if (Carbon::now()->gt($user->password_change_code_expires_at)) {
                return $this->createErrorResponse(
                    'Verification code has expired',
                    400,
                    'CODE_EXPIRED'
                );
            }

            // Vérifier si l'utilisateur existe toujours et est actif
            if (!$user->is_active) {
                return $this->createErrorResponse(
                    'User account is not active',
                    400,
                    'USER_INACTIVE'
                );
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
            return $this->createErrorResponse(
                'Server error occurred while changing password',
                500,
                'SERVER_ERROR'
            );
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
            $user = User::with('currency')->find($authId);
            
            if (!$user) {
                return $this->createErrorResponse('Utilisateur non trouvé', 404);
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'data' => $this->formatUserData($user)
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

        // ✅ NOUVELLE VALIDATION POUR LA DEVISE (OPTIONNELLE)
        if (isset($data['currency_id'])) {
            $validator->rule('integer', 'currency_id')
                ->message('Currency ID must be an integer');
            $validator->rule('min', 'currency_id', 1)
                ->message('Currency ID must be at least 1');
        }

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
            $user = User::with('currency')->find($authId);
            
            if (!$user) {
                return $this->createErrorResponse('User not found', 404);
            }

            // Mise à jour des champs de base
            $updateData = [
                'first_name' => $data['first_name'],
                'last_name' => $data['last_name'],
                'updated_at' => new \DateTime()
            ];

            // ✅ MISE À JOUR DE LA DEVISE SI FOURNIE
            if (isset($data['currency_id'])) {
                $currency = Currency::active()->find($data['currency_id']);
                if ($currency) {
                    $updateData['currency_id'] = $currency->id;
                } else {
                    return $this->createErrorResponse('Invalid currency selected', 400, 'INVALID_CURRENCY');
                }
            }

            $user->update($updateData);
            
            // Recharger avec la devise mise à jour
            $user->refresh();
            $user->load('currency');

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Profile updated successfully',
                    'data' => $this->formatUserData($user)
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Update error: ' . $e->getMessage(), 500);
        }
    }

    private function genererResetToken(): string {
        do {
            $resetToken = bin2hex(random_bytes(32));
            $ad = User::where('reset_token', $resetToken)->first();
        } while ($ad);
        return $resetToken;
    }

    private function genererNumeroReference(): string {
        do {
            $numero = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $user = User::where('number', $numero)->first();
        } while ($user);
        return $numero;
    }

    /**
     * Demander la suppression de compte (envoie un code par email)
     */
    public function requestAccountDeletion(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('lengthMax', 'reason', 500)
            ->message('La raison ne peut pas dépasser 500 caractères');

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
            
            if (!$user || !$user->isActive()) {
                return $this->createErrorResponse('Utilisateur non trouvé ou inactif', 404);
            }

            // Générer le code de suppression
            $deletionCode = $user->generateDeletionCode();

            // Préparer l'email de vérification
            if(Config::get('APP_ENV') == 'dev') {
                $emailToSend = 'm2atodev@gmail.com';
            } else {
                $emailToSend = $user->email;
            }

            // Envoyer l'email avec le code
            $mailSender = new MailSender();
            $mailSent = $mailSender->sendAccountDeletionCode(
                $emailToSend, 
                $user->first_name, 
                $deletionCode
            );

            if (!$mailSent) {
                return $this->createErrorResponse(
                    'Erreur lors de l\'envoi de l\'email de vérification', 
                    500
                );
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Code de suppression envoyé par email. Vérifiez votre boîte de réception.',
                    'data' => [
                        'code_expires_in_minutes' => 120,
                        'email_sent_to' => $user->email
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse(
                'Erreur lors de la demande de suppression: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Confirmer la suppression de compte avec le code
     */
    public function confirmAccountDeletion(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('required', ['deletion_code'])
            ->message('Code de suppression requis');
        $validator->rule('regex', 'deletion_code', '/^\d{6}$/')
            ->message('Le code doit contenir exactement 6 chiffres');

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
                return $this->createErrorResponse('Utilisateur non trouvé', 404);
            }

            // Vérifier le code de suppression
            if (!$user->isAccountDeletionCodeValid($data['deletion_code'])) {
                return $this->createErrorResponse(
                    'Code de suppression invalide ou expiré', 
                    400,
                    'INVALID_DELETION_CODE'
                );
            }

            // Marquer le compte pour suppression
            $reason = $data['reason'] ?? 'Demande utilisateur';
            $user->requestDeletion($reason);

            // Envoyer email de confirmation
            if(Config::get('APP_ENV') == 'dev') {
                $emailToSend = 'm2atodev@gmail.com';
            } else {
                $emailToSend = $user->email;
            }

            $mailSender = new MailSender();
            $mailSender->sendAccountDeletionConfirmation(
                $emailToSend, 
                $user->first_name
            );

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Votre compte a été marqué pour suppression. Vous avez 30 jours pour annuler cette action.',
                    'data' => [
                        'deletion_effective_date' => Carbon::now()->addDays(30)->toISOString(),
                        'can_cancel_until' => Carbon::now()->addDays(30)->toISOString()
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse(
                'Erreur lors de la confirmation de suppression: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Annuler la demande de suppression de compte
     */
    public function cancelAccountDeletion(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        try {
            $user = User::find($authId);
            
            if (!$user) {
                return $this->createErrorResponse('Utilisateur non trouvé', 404);
            }

            if (!$user->isDeletionRequested()) {
                return $this->createErrorResponse(
                    'Aucune demande de suppression en cours', 
                    400
                );
            }

            // Vérifier si dans les 30 jours
            if ($user->deletion_requested_at && 
                $user->deletion_requested_at->addDays(30)->isPast()) {
                return $this->createErrorResponse(
                    'La période d\'annulation de 30 jours est écoulée', 
                    400
                );
            }

            // Annuler la demande de suppression
            $user->cancelDeletionRequest();

            // Envoyer email de confirmation d'annulation
            if(Config::get('APP_ENV') == 'dev') {
                $emailToSend = 'm2atodev@gmail.com';
            } else {
                $emailToSend = $user->email;
            }

            $mailSender = new MailSender();
            $mailSender->sendAccountDeletionCancellation(
                $emailToSend, 
                $user->first_name
            );

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Demande de suppression annulée avec succès. Votre compte est de nouveau actif.',
                    'data' => [
                        'account_status' => 'active',
                        'reactivated_at' => Carbon::now()->toISOString()
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse(
                'Erreur lors de l\'annulation: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Obtenir le statut de suppression du compte
     */
    public function getAccountDeletionStatus(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        try {
            $user = User::find($authId);
            
            if (!$user) {
                return $this->createErrorResponse('Utilisateur non trouvé', 404);
            }

            $status = [
                'is_active' => $user->isActive(),
                'is_deletion_requested' => $user->isDeletionRequested(),
                'deletion_requested_at' => $user->deletion_requested_at?->toISOString(),
                'deletion_reason' => $user->deletion_reason,
                'can_cancel_deletion' => false,
                'deletion_effective_date' => null
            ];

            if ($user->isDeletionRequested() && $user->deletion_requested_at) {
                $deletionDate = $user->deletion_requested_at->addDays(30);
                $canCancel = $deletionDate->isFuture();
                
                $status['can_cancel_deletion'] = $canCancel;
                $status['deletion_effective_date'] = $deletionDate->toISOString();
                $status['days_remaining'] = max(0, $deletionDate->diffInDays(Carbon::now()));
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'data' => $status
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse(
                'Erreur lors de la récupération du statut: ' . $e->getMessage(), 
                500
            );
        }
    }

    public function debugAuth(Request $request, Response $response)
    {
        $serverParams = $request->getServerParams();
        
        $debug = [
            'method' => $request->getMethod(),
            'uri' => (string) $request->getUri(),
            'timestamp' => date('c'),
            
            // Test de récupération Authorization
            'auth_tests' => [
                'getHeaderLine' => $request->getHeaderLine('Authorization') ?: 'EMPTY',
                'getHeader' => $request->getHeader('Authorization') ?: 'EMPTY',
                'server_HTTP_AUTHORIZATION' => $serverParams['HTTP_AUTHORIZATION'] ?? 'NOT_SET',
                'server_REDIRECT_HTTP_AUTHORIZATION' => $serverParams['REDIRECT_HTTP_AUTHORIZATION'] ?? 'NOT_SET',
                'global_SERVER_HTTP_AUTHORIZATION' => $_SERVER['HTTP_AUTHORIZATION'] ?? 'NOT_SET',
            ],
            
            // Toutes les headers reçues
            'all_headers' => $request->getHeaders(),
            
            // Variables serveur liées à l'auth
            'server_auth_vars' => array_filter($serverParams, function($key) {
                return stripos($key, 'auth') !== false || stripos($key, 'http_') === 0;
            }, ARRAY_FILTER_USE_KEY)
        ];

        // Apache headers si disponible
        if (function_exists('apache_request_headers')) {
            $debug['apache_headers'] = apache_request_headers();
        }

        $response->getBody()->write(json_encode($debug, JSON_PRETTY_PRINT));
        return $response->withHeader('Content-Type', 'application/json');
    }
}