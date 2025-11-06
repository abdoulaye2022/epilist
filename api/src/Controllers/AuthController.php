<?php
// src/Controllers/AuthController.php - PARTIE 1: SSO ET MÉTHODES PRINCIPALES

namespace App\Controllers;

use App\Models\User;
use App\Models\UserDevice;
use App\Models\Currency;
use App\Services\JwtService;
use App\Services\SSOService;
use App\Services\RateLimiter;
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
    private $ssoService;
    private $rateLimiter;

    public function __construct()
    {
        $this->jwtService = new JwtService();
        $this->ssoService = new SSOService();
        $this->rateLimiter = new RateLimiter();
    }

    // ===================== MÉTHODES SSO =====================

        /**
     *  CORRIGÉ: Connexion avec Google - inclut les tokens JWT
     */
    public function googleLogin(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('required', ['id_token', 'user_info'])
            ->message('Google token et informations utilisateur requis');

        if (!$validator->validate()) {
            return $this->createErrorResponse('Données Google invalides', 400, 'VALIDATION_ERROR', $validator->errors());
        }

        try {
            $idToken = $data['id_token'];
            $userInfo = $data['user_info'];

            error_log(" [AuthController] === DÉBUT CONNEXION GOOGLE ANDROID ===");
            error_log(" [AuthController] ID Token: " . substr($idToken, 0, 50) . '...');
            error_log(" [AuthController] User Info: " . json_encode($userInfo));

            // 1. Vérifier le token Google
            $googleUserData = $this->ssoService->verifyGoogleToken($idToken);
            if (!$googleUserData) {
                error_log(" [AuthController] Token Google invalide");
                return $this->createErrorResponse(
                    'Token Google invalide ou expiré',
                    401,
                    'INVALID_SSO_TOKEN'
                );
            }

            error_log(" [AuthController] Token Google validé:");
            error_log("   Email: " . $googleUserData['email']);
            error_log("   Méthode: " . $googleUserData['validation_method']);

            // 2. Chercher l'utilisateur par email
            $email = $googleUserData['email'];
            $user = User::with('currency')->where('email', $email)->first();

            if ($user) {
                //  UTILISATEUR EXISTANT - CONNEXION
                error_log(" [AuthController] Utilisateur existant trouvé: {$user->email}");

                if (!$user->isActive()) {
                    return $this->createErrorResponse(
                        'Ce compte utilisateur n\'est pas actif',
                        403,
                        'USER_INACTIVE'
                    );
                }

                // Marquer l'email comme vérifié s'il ne l'est pas encore
                if (!$user->isEmailVerified()) {
                    $user->markEmailAsVerified();
                    $user->save();
                    error_log(" [AuthController] Email marqué comme vérifié");
                }

                // Sauvegarder/mettre à jour les informations Google
                $this->ssoService->saveSSOAccountLink($user->id, 'google', $googleUserData['sub'], $userInfo);

            } else {
                //  ANDROID: NOUVEL UTILISATEUR - CRÉATION AUTOMATIQUE
                error_log(" [AuthController] Nouvel utilisateur Google Android - création automatique");

                $firstName = $userInfo['first_name'] ?? $googleUserData['given_name'] ?? '';
                $lastName = $userInfo['last_name'] ?? $googleUserData['family_name'] ?? '';

                // Fallback intelligent pour le nom
                if (empty($firstName) && !empty($googleUserData['name'])) {
                    $nameParts = explode(' ', $googleUserData['name'], 2);
                    $firstName = $nameParts[0];
                    $lastName = $nameParts[1] ?? '';
                }

                // Valeurs par défaut si nom manquant
                if (empty($firstName)) $firstName = 'Utilisateur';
                if (empty($lastName)) $lastName = 'Google';

                try {
                    $user = User::create([
                        'first_name' => $firstName,
                        'last_name' => $lastName,
                        'email' => $email,
                        'password_hash' => null, // Pas de mot de passe pour SSO
                        'terms_accepted' => true,
                        'currency_id' => 1, // CAD par défaut
                        'email_verified' => true, // Google vérifie déjà l'email
                        'email_verified_at' => Carbon::now(),
                        'created_at' => new \DateTime(),
                        'updated_at' => new \DateTime()
                    ]);

                    $user->load('currency');
                    error_log(" [AuthController] Nouvel utilisateur créé: {$user->email} (ID: {$user->id})");

                    // Sauvegarder les informations Google
                    $this->ssoService->saveSSOAccountLink($user->id, 'google', $googleUserData['sub'], $userInfo);

                    //  ANDROID: Envoyer email de bienvenue
                    $this->sendWelcomeEmailSafely($user);

                } catch (\Exception $createError) {
                    error_log(" [AuthController] Erreur création utilisateur: " . $createError->getMessage());
                    
                    //  ANDROID: Vérifier si l'utilisateur a été créé entre temps (race condition)
                    $existingUser = User::with('currency')->where('email', $email)->first();
                    if ($existingUser) {
                        error_log(" [AuthController] Utilisateur créé par processus concurrent - utilisation");
                        $user = $existingUser;
                    } else {
                        return $this->createErrorResponse(
                            'Erreur lors de la création du compte: ' . $createError->getMessage(),
                            500,
                            'USER_CREATION_FAILED'
                        );
                    }
                }
            }

            // 3. Gérer le token FCM si fourni
            if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
                error_log(" [AuthController] Mise à jour FCM pour utilisateur: {$user->id}");
                $this->updateUserFCMToken($user->id, $data['fcm_data']);
            }

            // 4.  Générer les tokens JWT
            $accessToken = $this->jwtService->generateToken([
                'auth_id' => $user->id
            ]);

            $refreshToken = $this->jwtService->generateRefreshToken([
                'auth_id' => $user->id
            ]);

            error_log(" [AuthController] === CONNEXION GOOGLE ANDROID RÉUSSIE ===");
            error_log(" [AuthController] Utilisateur: {$user->email}");
            error_log(" [AuthController] Access token généré: " . substr($accessToken, 0, 30) . '...');

            // 5.  Réponse cohérente
            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Connexion Google réussie',
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'data' => $this->formatUserData($user),
                'auth_method' => 'google',
                'is_new_user' => !isset($data['is_existing_user']) // Indiquer si c'est un nouvel utilisateur
            ]));
            
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);

        } catch (\Exception $e) {
            error_log(" [AuthController] Erreur générale Google Android: " . $e->getMessage());
            error_log(" [AuthController] Stack trace: " . $e->getTraceAsString());

            return $this->createErrorResponse(
                'Erreur lors de la connexion Google: ' . $e->getMessage(),
                500,
                'GOOGLE_LOGIN_ERROR'
            );
        }
    }

    /**
     *  CORRIGÉ: Inscription avec Google - inclut les tokens JWT
     */
    public function googleRegister(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('required', ['id_token', 'user_info'])
            ->message('Google token et informations utilisateur requis');

        if (!$validator->validate()) {
            return $this->createErrorResponse('Données Google invalides', 400, 'VALIDATION_ERROR', $validator->errors());
        }

        try {
            $idToken = $data['id_token'];
            $userInfo = $data['user_info'];

            error_log(" [AuthController] === DÉBUT INSCRIPTION GOOGLE ANDROID ===");

            // 1. Vérifier le token Google
            $googleUserData = $this->ssoService->verifyGoogleToken($idToken);
            if (!$googleUserData) {
                error_log(" [AuthController] Token Google invalide pour inscription");
                return $this->createErrorResponse(
                    'Token Google invalide',
                    401,
                    'INVALID_SSO_TOKEN'
                );
            }

            $email = $googleUserData['email'];

            // 2.  ANDROID: Vérifier que l'utilisateur n'existe pas déjà
            $existingUser = User::where('email', $email)->first();
            if ($existingUser) {
                error_log(" [AuthController] Utilisateur Google existe déjà: {$email}");
                
                //  ANDROID: Rediriger vers login au lieu d'erreur
                return $this->createErrorResponse(
                    'Un compte existe déjà avec cet email. Redirection vers la connexion.',
                    409, // 409 Conflict pour indiquer que l'utilisateur doit se connecter
                    'EMAIL_ALREADY_EXISTS_REDIRECT_LOGIN',
                    ['existing_email' => $email]
                );
            }

            // 3. Créer le nouvel utilisateur
            $firstName = $userInfo['first_name'] ?? $googleUserData['given_name'] ?? '';
            $lastName = $userInfo['last_name'] ?? $googleUserData['family_name'] ?? '';

            if (empty($firstName) && !empty($googleUserData['name'])) {
                $nameParts = explode(' ', $googleUserData['name'], 2);
                $firstName = $nameParts[0];
                $lastName = $nameParts[1] ?? '';
            }

            // Valeurs par défaut
            if (empty($firstName)) $firstName = 'Utilisateur';
            if (empty($lastName)) $lastName = 'Google';

            // Déterminer la devise (si fournie)
            $currencyId = 1; // CAD par défaut
            if (isset($data['currency_id'])) {
                $currency = Currency::active()->find($data['currency_id']);
                if ($currency) {
                    $currencyId = $currency->id;
                }
            }

            $user = User::create([
                'first_name' => $firstName,
                'last_name' => $lastName,
                'email' => $email,
                'password_hash' => null,
                'terms_accepted' => true,
                'currency_id' => $currencyId,
                'email_verified' => true,
                'email_verified_at' => Carbon::now(),
                'created_at' => new \DateTime(),
                'updated_at' => new \DateTime()
            ]);

            $user->load('currency');

            // 4. Sauvegarder les informations Google
            $this->ssoService->saveSSOAccountLink($user->id, 'google', $googleUserData['sub'], $userInfo);

            // 5. Gérer le token FCM si fourni
            if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
                error_log(" [AuthController] Enregistrement FCM inscription Google: {$user->id}");
                $this->updateUserFCMToken($user->id, $data['fcm_data']);
            }

            // 6.  Générer les tokens JWT pour inscription
            $accessToken = $this->jwtService->generateToken([
                'auth_id' => $user->id
            ]);

            $refreshToken = $this->jwtService->generateRefreshToken([
                'auth_id' => $user->id
            ]);

            error_log(" [AuthController] Inscription Google Android réussie: {$user->email}");

            // 7. Envoyer email de bienvenue
            $this->sendWelcomeEmailSafely($user);

            // 8.  Réponse cohérente
            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Inscription Google réussie',
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'data' => $this->formatUserData($user),
                'auth_method' => 'google',
                'is_new_user' => true
            ]));
            
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(201);

        } catch (\Exception $e) {
            error_log(" [AuthController] Erreur inscription Google Android: " . $e->getMessage());

            return $this->createErrorResponse(
                'Erreur lors de l\'inscription Google: ' . $e->getMessage(),
                500,
                'GOOGLE_REGISTER_ERROR'
            );
        }
    }

    private function sendWelcomeEmailSafely(User $user): void
    {
        try {
            $emailToSend = $user->email;
            
            //  ANDROID: En développement, rediriger vers l'email de test
            if (Config::get('APP_ENV') == 'dev') {
                $emailToSend = 'm2atodev@gmail.com';
                error_log(" [AuthController] Email de bienvenue redirigé vers: " . $emailToSend);
            }

            $mailSender = new MailSender();
            $mailSender->sendWelcomeEmail($emailToSend, $user->first_name);
            error_log(" [AuthController] Email de bienvenue envoyé");
            
        } catch (\Exception $emailError) {
            error_log(" [AuthController] Erreur email de bienvenue: " . $emailError->getMessage());
            // Ne pas faire échouer la connexion pour un problème d'email
        }
    }

    /**
     *  CORRIGÉ: Connexion avec Apple - inclut les tokens JWT
     */
    public function appleLogin(Request $request, Response $response)
    {
        error_log(" [AuthController] Début appleLogin");
        
        try {
            $data = $request->getParsedBody();
            error_log(" [AuthController] Données reçues: " . json_encode($data));

            //  VALIDATION AMÉLIORÉE
            $validator = new Validator($data);
            $validator->rule('required', ['id_token', 'user_info'])
                ->message('Apple token et informations utilisateur requis');

            if (!$validator->validate()) {
                error_log(" [AuthController] Validation échouée: " . json_encode($validator->errors()));
                return $this->createErrorResponse('Données Apple invalides', 400, 'VALIDATION_ERROR', $validator->errors());
            }

            $idToken = $data['id_token'];
            $userInfo = $data['user_info'];

            error_log(" [AuthController] ID Token reçu: " . substr($idToken, 0, 50) . '...');
            error_log(" [AuthController] User Info: " . json_encode($userInfo));

            // 1.  VÉRIFICATION DU TOKEN APPLE AVEC GESTION D'ERREUR
            try {
                $appleUserData = $this->ssoService->verifyAppleToken($idToken);
                if (!$appleUserData) {
                    error_log(" [AuthController] Token Apple invalide");
                    return $this->createErrorResponse(
                        'Token Apple invalide',
                        401,
                        'INVALID_SSO_TOKEN'
                    );
                }
                error_log(" [AuthController] Token Apple vérifié: " . json_encode($appleUserData));
            } catch (\Exception $tokenError) {
                error_log(" [AuthController] Erreur vérification token Apple: " . $tokenError->getMessage());
                return $this->createErrorResponse(
                    'Erreur lors de la vérification du token Apple: ' . $tokenError->getMessage(),
                    401,
                    'APPLE_TOKEN_VERIFICATION_FAILED'
                );
            }

            // 2.  RÉCUPÉRATION EMAIL ET APPLE ID SÉCURISÉE
            $email = $appleUserData['email'] ?? $userInfo['email'] ?? null;
            $appleId = $appleUserData['sub'] ?? null;

            if (empty($appleId)) {
                error_log(" [AuthController] Apple ID manquant");
                return $this->createErrorResponse(
                    'Apple ID manquant dans le token',
                    400,
                    'MISSING_APPLE_ID'
                );
            }

            error_log(" [AuthController] Apple ID: " . $appleId);
            error_log(" [AuthController] Email: " . ($email ?: 'privé'));

            $user = null;
            
            // 3.  RECHERCHE UTILISATEUR AMÉLIORÉE
            if ($email && !empty($email)) {
                $user = User::with('currency')->where('email', $email)->first();
                if ($user) {
                    error_log(" [AuthController] Utilisateur trouvé par email: " . $user->email);
                }
            }
            
            // Si pas trouvé par email, chercher par Apple ID dans les liens SSO
            if (!$user) {
                $ssoLink = $this->ssoService->findSSOAccountLink('apple', $appleId);
                if ($ssoLink) {
                    $user = User::with('currency')->find($ssoLink['user_id']);
                    if ($user) {
                        error_log(" [AuthController] Utilisateur trouvé par Apple ID: " . $user->email);
                    }
                }
            }

            if ($user) {
                //  UTILISATEUR EXISTANT - CONNEXION
                error_log(" [AuthController] Connexion utilisateur existant: {$user->email}");

                if (!$user->isActive()) {
                    error_log(" [AuthController] Utilisateur inactif: {$user->email}");
                    return $this->createErrorResponse(
                        'Ce compte utilisateur n\'est pas actif',
                        403,
                        'USER_INACTIVE'
                    );
                }

                // Marquer l'email comme vérifié si ce n'est pas déjà fait
                if (!$user->isEmailVerified()) {
                    $user->markEmailAsVerified();
                    $user->save();
                    error_log(" [AuthController] Email marqué comme vérifié");
                }

                // Sauvegarder/mettre à jour les informations Apple
                $this->ssoService->saveSSOAccountLink($user->id, 'apple', $appleId, $userInfo);

            } else {
                //  NOUVEL UTILISATEUR - CRÉATION
                error_log(" [AuthController] Création nouvel utilisateur Apple");
                
                // Générer un email si pas fourni
                if (empty($email)) {
                    $email = $this->ssoService->generateAppleEmail($appleId);
                    error_log(" [AuthController] Email généré: " . $email);
                }

                $firstName = $userInfo['first_name'] ?? '';
                $lastName = $userInfo['last_name'] ?? '';

                // Valeurs par défaut si nom manquant
                if (empty($firstName) && empty($lastName)) {
                    $firstName = 'Utilisateur';
                    $lastName = 'Apple';
                }

                try {
                    $user = User::create([
                        'first_name' => $firstName,
                        'last_name' => $lastName,
                        'email' => $email,
                        'password_hash' => null, // Pas de mot de passe pour SSO
                        'terms_accepted' => true,
                        'currency_id' => 1, // CAD par défaut
                        'email_verified' => true, // Apple vérifie déjà l'email
                        'email_verified_at' => Carbon::now(),
                        'created_at' => new \DateTime(),
                        'updated_at' => new \DateTime()
                    ]);

                    $user->load('currency');
                    error_log(" [AuthController] Utilisateur créé: {$user->email} (ID: {$user->id})");

                    // Sauvegarder les informations Apple
                    $this->ssoService->saveSSOAccountLink($user->id, 'apple', $appleId, $userInfo);

                    // Envoyer email de bienvenue (seulement si email réel)
                    if (!$this->ssoService->isApplePrivateEmail($email)) {
                        if(Config::get('APP_ENV') == 'dev') {
                            $user->email = 'm2atodev@gmail.com';
                        }

                        try {
                            $mailSender = new MailSender();
                            $mailSender->sendWelcomeEmail($user->email, $user->first_name);
                            error_log(" [AuthController] Email de bienvenue envoyé");
                        } catch (\Exception $emailError) {
                            error_log(" [AuthController] Erreur email de bienvenue: " . $emailError->getMessage());
                        }
                    } else {
                        error_log(" [AuthController] Email de bienvenue non envoyé (email Apple privé)");
                    }

                } catch (\Exception $createError) {
                    error_log(" [AuthController] Erreur création utilisateur: " . $createError->getMessage());
                    return $this->createErrorResponse(
                        'Erreur lors de la création du compte: ' . $createError->getMessage(),
                        500,
                        'USER_CREATION_FAILED'
                    );
                }
            }

            // 4.  GESTION FCM TOKEN
            if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
                error_log(" [AuthController] Mise à jour FCM pour utilisateur: {$user->id}");
                try {
                    $this->updateUserFCMToken($user->id, $data['fcm_data']);
                } catch (\Exception $fcmError) {
                    error_log(" [AuthController] Erreur FCM: " . $fcmError->getMessage());
                    // Continuer même si FCM échoue
                }
            }

            // 5.  GÉNÉRATION DES TOKENS JWT
            try {
                $accessToken = $this->jwtService->generateToken([
                    'auth_id' => $user->id
                ]);

                $refreshToken = $this->jwtService->generateRefreshToken([
                    'auth_id' => $user->id
                ]);

                error_log(" [AuthController] Tokens JWT générés pour utilisateur: {$user->id}");
                error_log(" [AuthController] Access token: " . substr($accessToken, 0, 30) . '...');

            } catch (\Exception $tokenError) {
                error_log(" [AuthController] Erreur génération tokens: " . $tokenError->getMessage());
                return $this->createErrorResponse(
                    'Erreur lors de la génération des tokens',
                    500,
                    'TOKEN_GENERATION_FAILED'
                );
            }

            // 6.  RÉPONSE DE SUCCÈS
            $responseData = [
                'success' => true,
                'message' => 'Connexion Apple réussie',
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'data' => $this->formatUserData($user),
                'auth_method' => 'apple'
            ];

            error_log(" [AuthController] Connexion Apple terminée avec succès pour: {$user->email}");
            error_log(" [AuthController] Réponse: " . json_encode(['success' => true, 'user_id' => $user->id]));

            $response->getBody()->write(json_encode($responseData));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);

        } catch (\Exception $e) {
            error_log(" [AuthController] Erreur générale Apple Login: " . $e->getMessage());
            error_log(" [AuthController] Stack trace: " . $e->getTraceAsString());

            return $this->createErrorResponse(
                'Erreur lors de la connexion Apple: ' . $e->getMessage(),
                500,
                'APPLE_LOGIN_ERROR'
            );
        }
    }

    /**
     *  CORRECTION MAJEURE: Inscription avec Apple
     */
    public function appleRegister(Request $request, Response $response)
    {
        error_log(" [AuthController] Début appleRegister");
        
        try {
            $data = $request->getParsedBody();
            error_log(" [AuthController] Données inscription reçues: " . json_encode($data));

            // Validation
            $validator = new Validator($data);
            $validator->rule('required', ['id_token', 'user_info'])
                ->message('Apple token et informations utilisateur requis');

            if (!$validator->validate()) {
                error_log(" [AuthController] Validation inscription échouée: " . json_encode($validator->errors()));
                return $this->createErrorResponse('Données Apple invalides', 400, 'VALIDATION_ERROR', $validator->errors());
            }

            $idToken = $data['id_token'];
            $userInfo = $data['user_info'];

            error_log(" [AuthController] Inscription - ID Token: " . substr($idToken, 0, 50) . '...');

            // 1. Vérifier le token Apple
            try {
                $appleUserData = $this->ssoService->verifyAppleToken($idToken);
                if (!$appleUserData) {
                    error_log(" [AuthController] Token Apple invalide pour inscription");
                    return $this->createErrorResponse(
                        'Token Apple invalide',
                        401,
                        'INVALID_SSO_TOKEN'
                    );
                }
                error_log(" [AuthController] Token Apple vérifié pour inscription");
            } catch (\Exception $tokenError) {
                error_log(" [AuthController] Erreur vérification token inscription: " . $tokenError->getMessage());
                return $this->createErrorResponse(
                    'Erreur lors de la vérification du token Apple',
                    401,
                    'APPLE_TOKEN_VERIFICATION_FAILED'
                );
            }

            $email = $appleUserData['email'] ?? $userInfo['email'] ?? null;
            $appleId = $appleUserData['sub'] ?? null;

            if (empty($appleId)) {
                return $this->createErrorResponse(
                    'Apple ID manquant',
                    400,
                    'MISSING_APPLE_ID'
                );
            }

            // Générer un email si pas fourni par Apple
            if (empty($email)) {
                $email = $this->ssoService->generateAppleEmail($appleId);
                error_log(" [AuthController] Email généré pour inscription: " . $email);
            }

            // 2. Vérifier que l'utilisateur n'existe pas déjà par email
            $existingUserByEmail = User::where('email', $email)->first();
            if ($existingUserByEmail) {
                error_log(" [AuthController] Email déjà existant: " . $email);
                return $this->createErrorResponse(
                    'Un compte existe déjà avec cet email',
                    400,
                    'EMAIL_ALREADY_EXISTS'
                );
            }

            // 3. Vérifier que l'Apple ID n'est pas déjà lié
            $existingSSOLink = $this->ssoService->findSSOAccountLink('apple', $appleId);
            if ($existingSSOLink) {
                error_log(" [AuthController] Apple ID déjà lié: " . $appleId);
                return $this->createErrorResponse(
                    'Ce compte Apple est déjà lié à un autre utilisateur',
                    400,
                    'APPLE_ACCOUNT_ALREADY_LINKED'
                );
            }

            // 4. Créer le nouvel utilisateur
            $firstName = $userInfo['first_name'] ?? '';
            $lastName = $userInfo['last_name'] ?? '';

            if (empty($firstName) && empty($lastName)) {
                $firstName = 'Utilisateur';
                $lastName = 'Apple';
            }

            // Déterminer la devise (si fournie)
            $currencyId = 1; // CAD par défaut
            if (isset($data['currency_id'])) {
                $currency = Currency::active()->find($data['currency_id']);
                if ($currency) {
                    $currencyId = $currency->id;
                }
            }

            try {
                $user = User::create([
                    'first_name' => $firstName,
                    'last_name' => $lastName,
                    'email' => $email,
                    'password_hash' => null,
                    'terms_accepted' => true,
                    'currency_id' => $currencyId,
                    'email_verified' => true,
                    'email_verified_at' => Carbon::now(),
                    'created_at' => new \DateTime(),
                    'updated_at' => new \DateTime()
                ]);

                $user->load('currency');
                error_log(" [AuthController] Utilisateur Apple créé: {$user->email} (ID: {$user->id})");

                // 5. Sauvegarder les informations Apple
                $this->ssoService->saveSSOAccountLink($user->id, 'apple', $appleId, $userInfo);

                // 6. Gérer le token FCM si fourni
                if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
                    error_log(" [AuthController] Enregistrement FCM inscription Apple pour utilisateur: {$user->id}");
                    try {
                        $this->updateUserFCMToken($user->id, $data['fcm_data']);
                    } catch (\Exception $fcmError) {
                        error_log(" [AuthController] Erreur FCM inscription: " . $fcmError->getMessage());
                    }
                }

                // 7. Générer les tokens JWT
                $accessToken = $this->jwtService->generateToken([
                    'auth_id' => $user->id
                ]);

                $refreshToken = $this->jwtService->generateRefreshToken([
                    'auth_id' => $user->id
                ]);

                error_log(" [AuthController] Inscription Apple réussie pour: {$user->email}");

                // 8. Envoyer email de bienvenue (seulement si email réel)
                if (!$this->ssoService->isApplePrivateEmail($email)) {
                    if(Config::get('APP_ENV') == 'dev') {
                        $user->email = 'm2atodev@gmail.com';
                    }

                    try {
                        $mailSender = new MailSender();
                        $mailSender->sendWelcomeEmail($user->email, $user->first_name);
                        error_log(" [AuthController] Email de bienvenue envoyé pour inscription Apple");
                    } catch (\Exception $emailError) {
                        error_log(" [AuthController] Erreur email bienvenue inscription: " . $emailError->getMessage());
                    }
                } else {
                    error_log(" [AuthController] Email bienvenue non envoyé (email Apple privé)");
                }

                // 9. Réponse de succès
                $responseData = [
                    'success' => true,
                    'message' => 'Inscription Apple réussie',
                    'access_token' => $accessToken,
                    'refresh_token' => $refreshToken,
                    'data' => $this->formatUserData($user),
                    'auth_method' => 'apple',
                    'is_private_email' => $this->ssoService->isApplePrivateEmail($email)
                ];

                $response->getBody()->write(json_encode($responseData));
                return $response
                    ->withHeader('Content-Type', 'application/json')
                    ->withStatus(201);

            } catch (\Exception $createError) {
                error_log(" [AuthController] Erreur création utilisateur inscription: " . $createError->getMessage());
                return $this->createErrorResponse(
                    'Erreur lors de la création du compte: ' . $createError->getMessage(),
                    500,
                    'USER_CREATION_FAILED'
                );
            }

        } catch (\Exception $e) {
            error_log(" [AuthController] Erreur générale Apple Register: " . $e->getMessage());
            error_log(" [AuthController] Stack trace: " . $e->getTraceAsString());

            return $this->createErrorResponse(
                'Erreur lors de l\'inscription Apple: ' . $e->getMessage(),
                500,
                'APPLE_REGISTER_ERROR'
            );
        }
    }

    // ===================== GESTION DES LIENS SSO =====================

    /**
     *  NOUVELLE ROUTE: Lier un compte SSO
     */
    public function linkSSOAccount(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        $provider = $request->getAttribute('provider'); // 'google' ou 'apple'
        $data = $request->getParsedBody();

        // Validation
        $validator = new Validator($data);
        $validator->rule('required', ['id_token', 'user_info'])
            ->message('Token et informations utilisateur requis');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'VALIDATION_ERROR',
                'message' => 'Données invalides',
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

            $idToken = $data['id_token'];
            $userInfo = $data['user_info'];

            // Vérifier le token selon le provider
            if ($provider === 'google') {
                $ssoUserData = $this->ssoService->verifyGoogleToken($idToken);
                $ssoId = $ssoUserData['sub'];
            } elseif ($provider === 'apple') {
                $ssoUserData = $this->ssoService->verifyAppleToken($idToken);
                $ssoId = $ssoUserData['sub'];
            } else {
                return $this->createErrorResponse('Provider non supporté', 400);
            }

            if (!$ssoUserData) {
                return $this->createErrorResponse(
                    'Token ' . ucfirst($provider) . ' invalide',
                    401,
                    'INVALID_SSO_TOKEN'
                );
            }

            // Vérifier si le compte SSO est déjà lié à un autre utilisateur
            $existingLink = $this->ssoService->findSSOAccountLink($provider, $ssoId);
            if ($existingLink && $existingLink['user_id'] !== $user->id) {
                return $this->createErrorResponse(
                    'Ce compte ' . ucfirst($provider) . ' est déjà lié à un autre utilisateur',
                    400,
                    'SSO_ACCOUNT_ALREADY_LINKED'
                );
            }

            // Sauvegarder la liaison
            $this->ssoService->saveSSOAccountLink($user->id, $provider, $ssoId, $userInfo);

            error_log(" Compte {$provider} lié avec succès pour utilisateur: {$user->id}");

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Compte ' . ucfirst($provider) . ' lié avec succès',
                    'data' => [
                        'provider' => $provider,
                        'linked_at' => Carbon::now()->toISOString()
                    ]
                ]))
            );

        } catch (\Exception $e) {
            error_log(" Erreur lors de la liaison {$provider}: " . $e->getMessage());

            return $this->createErrorResponse(
                'Erreur lors de la liaison du compte ' . ucfirst($provider),
                500
            );
        }
    }

    /**
     *  NOUVELLE ROUTE: Délier un compte SSO
     */
    public function unlinkSSOAccount(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        $provider = $request->getAttribute('provider'); // 'google' ou 'apple'

        try {
            $user = User::find($authId);
            
            if (!$user || !$user->isActive()) {
                return $this->createErrorResponse('Utilisateur non trouvé ou inactif', 404);
            }

            // Vérifier si l'utilisateur a un mot de passe avant de délier SSO
            if (!$user->password_hash) {
                // Vérifier s'il a d'autres méthodes de connexion
                $otherSSOLinks = $this->ssoService->getUserSSOLinks($user->id);
                $otherProviders = array_filter($otherSSOLinks, function($link) use ($provider) {
                    return $link['provider'] !== $provider;
                });

                if (empty($otherProviders)) {
                    return $this->createErrorResponse(
                        'Impossible de délier le seul moyen de connexion. Ajoutez un mot de passe ou liez un autre compte d\'abord.',
                        400,
                        'CANNOT_UNLINK_ONLY_AUTH_METHOD'
                    );
                }
            }

            // Supprimer la liaison
            $success = $this->ssoService->removeSSOAccountLink($user->id, $provider);

            if ($success) {
                error_log(" Compte {$provider} délié avec succès pour utilisateur: {$user->id}");

                return new JsonResponse(
                    200,
                    new Headers(['Content-Type' => 'application/json']),
                    (new StreamFactory())->createStream(json_encode([
                        'success' => true,
                        'message' => 'Compte ' . ucfirst($provider) . ' délié avec succès',
                        'data' => [
                            'provider' => $provider,
                            'unlinked_at' => Carbon::now()->toISOString()
                        ]
                    ]))
                );
            } else {
                return $this->createErrorResponse(
                    'Aucune liaison trouvée pour ce provider',
                    404
                );
            }

        } catch (\Exception $e) {
            error_log(" Erreur lors de la déliaison {$provider}: " . $e->getMessage());

            return $this->createErrorResponse(
                'Erreur lors de la déliaison du compte ' . ucfirst($provider),
                500
            );
        }
    }

    /**
     *  NOUVELLE ROUTE: Obtenir les comptes SSO liés
     */
    public function getSSOLinks(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        try {
            $user = User::find($authId);
            
            if (!$user || !$user->isActive()) {
                return $this->createErrorResponse('Utilisateur non trouvé ou inactif', 404);
            }

            $ssoLinks = $this->ssoService->getUserSSOLinks($user->id);
            
            $formattedLinks = [];
            foreach ($ssoLinks as $link) {
                $formattedLinks[] = [
                    'provider' => $link['provider'],
                    'linked_at' => Carbon::parse($link['created_at'])->toISOString(),
                    'last_login_at' => $link['last_login_at'] ? 
                        Carbon::parse($link['last_login_at'])->toISOString() : null
                ];
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'data' => [
                        'linked_accounts' => $formattedLinks,
                        'has_password' => !is_null($user->password_hash),
                        'can_unlink' => count($formattedLinks) > 1 || !is_null($user->password_hash)
                    ]
                ]))
            );

        } catch (\Exception $e) {
            error_log(" Erreur lors de la récupération des liens SSO: " . $e->getMessage());

            return $this->createErrorResponse(
                'Erreur lors de la récupération des comptes liés',
                500
            );
        }
    }

    // ===================== MÉTHODES UTILITAIRES =====================
    
    private function updateUserFCMToken(int $userId, array $fcmData): bool
    {
        try {
            error_log(" [AuthController] Mise à jour FCM pour utilisateur: {$userId}");
            
            if (empty($fcmData['device_id']) || empty($fcmData['push_token'])) {
                error_log(" [AuthController] Données FCM incomplètes - ignoré");
                return false;
            }

            $platform = $fcmData['platform'] ?? 'unknown';
            if (!in_array($platform, ['android', 'ios'])) {
                error_log(" [AuthController] Plateforme invalide: {$platform} - ignoré");
                return false;
            }

            error_log("   Device ID: " . substr($fcmData['device_id'], 0, 20) . '...');
            error_log("   Platform: {$platform}");
            error_log("   Push Token: " . substr($fcmData['push_token'], 0, 20) . '...');

            $existingDevice = UserDevice::forUser($userId)
                ->where('device_id', $fcmData['device_id'])
                ->first();

            if ($existingDevice) {
                $oldToken = $existingDevice->push_token;
                $newToken = $fcmData['push_token'];
                
                if ($oldToken !== $newToken) {
                    error_log(" [AuthController] Token FCM différent détecté - mise à jour");
                    
                    $existingDevice->update([
                        'push_token' => $newToken,
                        'platform' => $platform,
                        'app_version' => $fcmData['app_version'] ?? $existingDevice->app_version,
                        'os_version' => $fcmData['os_version'] ?? $existingDevice->os_version,
                        'device_model' => $fcmData['device_model'] ?? $existingDevice->device_model,
                        'is_active' => true,
                        'last_active_at' => Carbon::now()
                    ]);
                    
                    error_log(" [AuthController] Token FCM mis à jour avec succès");
                    return true;
                } else {
                    error_log(" [AuthController] Token FCM identique - activité mise à jour");
                    $existingDevice->markAsActive();
                    return true;
                }
            } else {
                error_log(" [AuthController] Nouvel appareil détecté - enregistrement");
                
                $device = UserDevice::registerDevice(array_merge($fcmData, [
                    'user_id' => $userId
                ]));
                
                error_log(" [AuthController] Nouvel appareil enregistré avec ID: {$device->id}");
                return true;
            }

        } catch (\Exception $e) {
            error_log(" [AuthController] Erreur lors de la mise à jour FCM: " . $e->getMessage());
            return false;
        }
    }

    /**
     *  MÉTHODE MISE À JOUR: Formater les données utilisateur avec devise et SSO
     */
    private function formatUserData(User $user): array
    {
        if (!$user->relationLoaded('currency')) {
            $user->load('currency');
        }

        $currency = $user->getPreferredCurrency();

        // Récupérer les comptes SSO liés
        $ssoLinks = $this->ssoService->getUserSSOLinks($user->id);
        $linkedProviders = array_column($ssoLinks, 'provider');

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
            'linked_accounts' => [
                'google' => in_array('google', $linkedProviders),
                'apple' => in_array('apple', $linkedProviders),
            ],
            'has_password' => !is_null($user->password_hash),
            'created_at' => $user->created_at->toISOString(),
            'updated_at' => $user->updated_at->toISOString()
        ];
    }

    /**
     * Crée une réponse d'erreur JSON.
     */
    private function createErrorResponse(string $message, int $statusCode, string $code = '', array $errors = []): JsonResponse
    {
        $responseData = [
            'success' => false,
            'message' => $message,
        ];

        if (!empty($code)) {
            $responseData['code'] = $code;
        }

        if (!empty($errors)) {
            $responseData['errors'] = $errors;
        }

        return new JsonResponse(
            $statusCode,
            new Headers(['Content-Type' => 'application/json']),
            (new StreamFactory())->createStream(json_encode($responseData))
        );
    }

    /**
     * 🔒 Obtenir l'adresse IP du client (avec support proxy/load balancer)
     */
    private function getClientIP(Request $request): string
    {
        // Vérifier les headers de proxy
        $headers = $request->getHeaders();

        // X-Forwarded-For (le plus commun)
        if (!empty($headers['X-Forwarded-For'])) {
            $ips = is_array($headers['X-Forwarded-For'])
                ? $headers['X-Forwarded-For'][0]
                : $headers['X-Forwarded-For'];
            $ipList = explode(',', $ips);
            return trim($ipList[0]); // Premier IP = client original
        }

        // X-Real-IP
        if (!empty($headers['X-Real-IP'])) {
            return is_array($headers['X-Real-IP'])
                ? $headers['X-Real-IP'][0]
                : $headers['X-Real-IP'];
        }

        // CF-Connecting-IP (Cloudflare)
        if (!empty($headers['CF-Connecting-IP'])) {
            return is_array($headers['CF-Connecting-IP'])
                ? $headers['CF-Connecting-IP'][0]
                : $headers['CF-Connecting-IP'];
        }

        // Fallback sur REMOTE_ADDR
        $serverParams = $request->getServerParams();
        return $serverParams['REMOTE_ADDR'] ?? '0.0.0.0';
    }

    // ===================== AUTHENTIFICATION CLASSIQUE =====================

    public function login(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        $validator = new Validator($data);
        
        $validator->rule('required', ['email', 'password'])
            ->message('{field} is required');
        
        $validator->rule('email', 'email')
            ->message('Invalid email address');
        
        $validator->rule('lengthMax', 'email', 255)
            ->message('Email is too long (max 255 characters)');

        if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
            $fcmData = $data['fcm_data'];
            
            if (isset($fcmData['device_id'])) {
                $validator->rule('lengthMax', 'fcm_data.device_id', 255)
                    ->message('Device ID too long');
            }
            
            if (isset($fcmData['push_token'])) {
                $validator->rule('lengthMax', 'fcm_data.push_token', 512)
                    ->message('Push token too long');
            }
            
            if (isset($fcmData['platform'])) {
                $validator->rule('in', 'fcm_data.platform', ['android', 'ios'])
                    ->message('Platform must be android or ios');
            }
        }

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
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'code' => 'INVALID_CREDENTIALS',
                    'message' => 'Invalid credentials. Please try again.'
                ]));
                return $response
                    ->withHeader('Content-Type', 'application/json')
                    ->withStatus(401);
            }

            if (!password_verify($data['password'], $user->password_hash)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'code' => 'INVALID_CREDENTIALS',
                    'message' => 'Invalid credentials. Please try again.'
                ]));
                return $response
                    ->withHeader('Content-Type', 'application/json')
                    ->withStatus(401);
            }

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

            if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
                error_log(" Mise à jour FCM lors du login pour utilisateur: {$user->id}");
                $fcmUpdateSuccess = $this->updateUserFCMToken($user->id, $data['fcm_data']);
                
                if ($fcmUpdateSuccess) {
                    error_log(" Token FCM mis à jour avec succès lors du login");
                } else {
                    error_log(" Échec de la mise à jour FCM (connexion continue)");
                }
            }

            $accessToken = $this->jwtService->generateToken([
                'auth_id' => $user->id
            ]);

            $refreshToken = $this->jwtService->generateRefreshToken([
                'auth_id' => $user->id
            ]);

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

    /**
     *  NOUVELLE ROUTE: Mettre à jour le mot de passe
     */
    public function updatePassword(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        $data = $request->getParsedBody();

        $validator = new Validator($data);
        $validator->rule('required', ['new_password'])
            ->message('Le nouveau mot de passe est requis');
        $validator->rule('lengthMin', 'new_password', 6)
            ->message('Le mot de passe doit faire au moins 6 caractères');

        // Si l'utilisateur a déjà un mot de passe, exiger l'ancien
        $user = User::find($authId);
        if ($user && $user->password_hash) {
            $validator->rule('required', ['current_password'])
                ->message('Le mot de passe actuel est requis');
        }

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'VALIDATION_ERROR',
                'message' => 'Validation échouée',
                'errors' => $validator->errors()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            if (!$user || !$user->isActive()) {
                return $this->createErrorResponse('Utilisateur non trouvé ou inactif', 404);
            }

            // Vérifier l'ancien mot de passe si nécessaire
            if ($user->password_hash && isset($data['current_password'])) {
                if (!password_verify($data['current_password'], $user->password_hash)) {
                    return $this->createErrorResponse(
                        'Mot de passe actuel incorrect',
                        400,
                        'INVALID_CURRENT_PASSWORD'
                    );
                }
            }

            // Mettre à jour le mot de passe
            $user->password_hash = password_hash($data['new_password'], PASSWORD_DEFAULT);
            $user->updated_at = new \DateTime();
            $user->save();

            error_log(" Mot de passe mis à jour pour utilisateur: {$user->id}");

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Mot de passe mis à jour avec succès'
                ]))
            );

        } catch (\Exception $e) {
            error_log(" Erreur lors de la mise à jour du mot de passe: " . $e->getMessage());

            return $this->createErrorResponse(
                'Erreur lors de la mise à jour du mot de passe',
                500
            );
        }
    }

    /**
     *  NOUVELLE ROUTE: Obtenir les préférences email
     */
    public function getEmailPreferences(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        try {
            $user = User::find($authId);
            
            if (!$user || !$user->isActive()) {
                return $this->createErrorResponse('Utilisateur non trouvé ou inactif', 404);
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'data' => [
                        'marketing_emails' => $user->marketing_emails_enabled ?? true,
                        'notification_emails' => $user->notification_emails_enabled ?? true,
                        'security_emails' => true // Toujours activé
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    /**
     *  NOUVELLE ROUTE: Mettre à jour les préférences email
     */
    public function updateEmailPreferences(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        $data = $request->getParsedBody();

        try {
            $user = User::find($authId);
            
            if (!$user || !$user->isActive()) {
                return $this->createErrorResponse('Utilisateur non trouvé ou inactif', 404);
            }

            $updateData = [];
            
            if (isset($data['marketing_emails'])) {
                $updateData['marketing_emails_enabled'] = (bool) $data['marketing_emails'];
            }
            
            if (isset($data['notification_emails'])) {
                $updateData['notification_emails_enabled'] = (bool) $data['notification_emails'];
            }

            if (!empty($updateData)) {
                $updateData['updated_at'] = new \DateTime();
                $user->update($updateData);
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Préférences email mises à jour',
                    'data' => [
                        'marketing_emails' => $user->marketing_emails_enabled ?? true,
                        'notification_emails' => $user->notification_emails_enabled ?? true,
                        'security_emails' => true
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    /**
     *  NOUVELLE ROUTE: Se réabonner au marketing
     */
    public function resubscribeToMarketing(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        try {
            $user = User::find($authId);
            
            if (!$user || !$user->isActive()) {
                return $this->createErrorResponse('Utilisateur non trouvé ou inactif', 404);
            }

            $user->update([
                'marketing_emails_enabled' => true,
                'updated_at' => new \DateTime()
            ]);

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Réabonné aux emails marketing avec succès'
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    /**
     *  NOUVELLE ROUTE: Demander la suppression du compte
     */
    public function requestAccountDeletion(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        $data = $request->getParsedBody();
        $reason = $data['reason'] ?? 'Non spécifié';

        try {
            $user = User::find($authId);
            
            if (!$user || !$user->isActive()) {
                return $this->createErrorResponse('Utilisateur non trouvé ou inactif', 404);
            }

            // Générer un code de confirmation
            $confirmationCode = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiration = Carbon::now()->addHours(24);

            $user->update([
                'deletion_confirmation_code' => $confirmationCode,
                'deletion_confirmation_code_expires_at' => $expiration,
                'deletion_reason' => $reason,
                'deletion_requested_at' => Carbon::now(),
                'updated_at' => new \DateTime()
            ]);

            // Envoyer email de confirmation
            if(Config::get('APP_ENV') == 'dev') {
                $user->email = 'm2atodev@gmail.com';
            }

            try {
                $mailSender = new MailSender();
                $mailSender->sendAccountDeletionConfirmation($user->email, $user->first_name, $confirmationCode);
            } catch (\Exception $emailError) {
                error_log(" Erreur lors de l'envoi de l'email de suppression: " . $emailError->getMessage());
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Demande de suppression initiée. Vérifiez votre email pour confirmer.',
                    'data' => [
                        'expires_at' => $expiration->toISOString()
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    /**
     *  NOUVELLE ROUTE: Confirmer la suppression du compte
     */
    public function confirmAccountDeletion(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        $validator = new Validator($data);
        $validator->rule('required', ['email', 'confirmation_code'])
            ->message('{field} est requis');
        $validator->rule('email', 'email')
            ->message('Email invalide');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'VALIDATION_ERROR',
                'message' => 'Validation échouée',
                'errors' => $validator->errors()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            $user = User::where('email', $data['email'])->first();
            
            if (!$user) {
                return $this->createErrorResponse('Utilisateur non trouvé', 404);
            }

            if ($user->deletion_confirmation_code !== $data['confirmation_code']) {
                return $this->createErrorResponse(
                    'Code de confirmation invalide',
                    400,
                    'INVALID_CONFIRMATION_CODE'
                );
            }

            if (Carbon::now()->gt($user->deletion_confirmation_code_expires_at)) {
                return $this->createErrorResponse(
                    'Code de confirmation expiré',
                    400,
                    'CONFIRMATION_CODE_EXPIRED'
                );
            }

            // Marquer le compte pour suppression (soft delete)
            $user->update([
                'is_active' => false,
                'deleted_at' => Carbon::now(),
                'deletion_confirmed_at' => Carbon::now(),
                'updated_at' => new \DateTime()
            ]);

            error_log(" Compte marqué pour suppression: {$user->email}");

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Compte supprimé avec succès'
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    /**
     *  NOUVELLE ROUTE: Annuler la suppression du compte
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

            $user->update([
                'deletion_confirmation_code' => null,
                'deletion_confirmation_code_expires_at' => null,
                'deletion_reason' => null,
                'deletion_requested_at' => null,
                'updated_at' => new \DateTime()
            ]);

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Demande de suppression annulée'
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    /**
     *  NOUVELLE ROUTE: Statut de suppression du compte
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

            $hasPendingDeletion = !is_null($user->deletion_requested_at) && 
                                 is_null($user->deletion_confirmed_at);

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'data' => [
                        'has_pending_deletion' => $hasPendingDeletion,
                        'deletion_requested_at' => $user->deletion_requested_at ? 
                            Carbon::parse($user->deletion_requested_at)->toISOString() : null,
                        'expires_at' => $user->deletion_confirmation_code_expires_at ? 
                            Carbon::parse($user->deletion_confirmation_code_expires_at)->toISOString() : null
                    ]
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    /**
     *  NOUVELLE ROUTE: Mettre à jour le token FCM
     */
    public function updateFCMToken(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        $data = $request->getParsedBody();

        $validator = new Validator($data);
        $validator->rule('required', ['device_id', 'push_token', 'platform'])
            ->message('{field} est requis');
        $validator->rule('in', 'platform', ['android', 'ios'])
            ->message('Plateforme doit être android ou ios');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'VALIDATION_ERROR',
                'message' => 'Validation échouée',
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

            $fcmUpdateSuccess = $this->updateUserFCMToken($authId, $data);

            if ($fcmUpdateSuccess) {
                return new JsonResponse(
                    200,
                    new Headers(['Content-Type' => 'application/json']),
                    (new StreamFactory())->createStream(json_encode([
                        'success' => true,
                        'message' => 'Token FCM mis à jour avec succès'
                    ]))
                );
            } else {
                return $this->createErrorResponse(
                    'Échec de la mise à jour du token FCM',
                    500
                );
            }

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    /**
     *  NOUVELLE ROUTE: Déconnexion (logout)
     */
    public function logout(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        try {
            // Si un device_id est fourni, désactiver l'appareil
            if (isset($data['device_id']) && !empty($data['device_id'])) {
                $authId = $request->getAttribute('auth_id');
                
                if ($authId) {
                    $device = UserDevice::forUser($authId)
                        ->where('device_id', $data['device_id'])
                        ->first();
                        
                    if ($device) {
                        $device->markAsInactive();
                        error_log(" Appareil désactivé lors de la déconnexion: {$data['device_id']}");
                    }
                }
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Déconnexion réussie'
                ]))
            );

        } catch (\Exception $e) {
            error_log(" Erreur lors de la déconnexion: " . $e->getMessage());
            
            // Même en cas d'erreur, on retourne un succès car la déconnexion côté client doit fonctionner
            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Déconnexion réussie'
                ]))
            );
        }
    }

    // ===================== TOKEN REFRESH =====================

    public function refresh_token(Request $request, Response $response)
    {
        $data = json_decode($request->getBody(), true);
        $refreshToken = $data['refresh_token'] ?? '';

        if (empty($refreshToken)) {
            return $this->createErrorResponse('Refresh token manquant', 400);
        }

        try {
            $decoded = $this->jwtService->validateRefreshToken($refreshToken);
            if (!$decoded) {
                return $this->createErrorResponse('Token invalide ou expiré', 401);
            }

            if (isset($decoded->exp) && $decoded->exp < time()) {
                return $this->createErrorResponse('Refresh token expiré', 401);
            }

            $user = User::with('currency')->find($decoded['data']->auth_id);

            if (!$user) {
                return $this->createErrorResponse('Utilisateur non trouvé', 404);
            }

            if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
                error_log(" Mise à jour FCM lors du refresh token pour utilisateur: {$user->id}");
                $this->updateUserFCMToken($user->id, $data['fcm_data']);
            }

            $accessToken = $this->jwtService->generateToken([
                'auth_id' => $user->id
            ]);

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
            return $this->createErrorResponse('Refresh token invalide: ' . $e->getMessage(), 401);
        }
    }

    /**
     *  MÉTHODE MISE À JOUR: Vérification d'authentification avec mise à jour FCM
     */
    public function checkAuth(Request $request, Response $response)
    {
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Non autorisé', 401);
        }

        try {
            $user = User::with('currency')->find($authId);
            
            if (!$user || !$user->isActive()) {
                return $this->createErrorResponse('Utilisateur non trouvé ou inactif', 404);
            }

            $data = $request->getParsedBody() ?? [];
            if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
                error_log(" Mise à jour FCM lors de checkAuth pour utilisateur: {$user->id}");
                $fcmUpdateSuccess = $this->updateUserFCMToken($user->id, $data['fcm_data']);
                
                if ($fcmUpdateSuccess) {
                    error_log(" Token FCM mis à jour avec succès lors de checkAuth");
                }
            }

            return new JsonResponse(
                200,
                new Headers(['Content-Type' => 'application/json']),
                (new StreamFactory())->createStream(json_encode([
                    'success' => true,
                    'message' => 'Authentification valide',
                    'data' => $this->formatUserData($user)
                ]))
            );

        } catch (\Exception $e) {
            return $this->createErrorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    /**
     *  ROUTE DE DEBUG: Débugger l'authentification
     */
    public function debugAuth(Request $request, Response $response)
    {
        $headers = $request->getHeaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;
        
        $debugInfo = [
            'method' => $request->getMethod(),
            'uri' => (string) $request->getUri(),
            'headers' => $headers,
            'auth_header' => $authHeader,
            'parsed_body' => $request->getParsedBody(),
            'query_params' => $request->getQueryParams(),
            'timestamp' => Carbon::now()->toISOString()
        ];

        return new JsonResponse(
            200,
            new Headers(['Content-Type' => 'application/json']),
            (new StreamFactory())->createStream(json_encode([
                'success' => true,
                'debug_info' => $debugInfo
            ], JSON_PRETTY_PRINT))
        );
    }

    public function register(Request $request, Response $response)
    {
        $data = $request->getParsedBody();

        // 🔒 PROTECTION BOT: Obtenir l'IP du client
        $ipAddress = $this->getClientIP($request);

        // 🔒 PROTECTION BOT: Vérifier si l'IP est bloquée
        if ($this->rateLimiter->isIPBlocked($ipAddress)) {
            error_log("🚫 [AuthController] Tentative d'inscription depuis IP bloquée: {$ipAddress}");
            return $this->createErrorResponse(
                'Trop de tentatives. Votre IP a été temporairement bloquée.',
                429,
                'IP_BLOCKED'
            );
        }

        // 🔒 PROTECTION BOT: Vérifier si l'IP est suspecte
        if ($this->rateLimiter->isSuspiciousIP($ipAddress)) {
            error_log("⚠️  [AuthController] IP suspecte détectée lors de l'inscription: {$ipAddress}");
            $this->rateLimiter->blockIP($ipAddress, 60); // Bloquer 1 heure
            return $this->createErrorResponse(
                'Activité suspecte détectée. Veuillez réessayer plus tard.',
                429,
                'SUSPICIOUS_ACTIVITY'
            );
        }

        // 🔒 PROTECTION BOT: Vérifier limite globale (anti-spam massif)
        if (!$this->rateLimiter->checkGlobalRegistrationLimit()) {
            error_log("🚫 [AuthController] Limite globale d'inscriptions atteinte");
            return $this->createErrorResponse(
                'Trop d\'inscriptions en cours. Veuillez réessayer dans quelques minutes.',
                429,
                'GLOBAL_LIMIT_REACHED'
            );
        }

        $validator = new Validator($data);

        $validator->rule('required', ['first_name', 'last_name', 'email', 'password'])
            ->message('{field} is required');

        $validator->rule('email', 'email')
            ->message('Invalid email address');

        $validator->rule('lengthMax', 'email', 255)
            ->message('Email is too long (max 255 characters)');

        $validator->rule('lengthMax', ['first_name', 'last_name'], 100)
            ->message('{field} is too long (max 100 characters)');

        $validator->rule('lengthMin', 'password', 6)
            ->message('Password must be at least 6 characters');

        if (isset($data['currency_id'])) {
            $validator->rule('integer', 'currency_id')
                ->message('Currency ID must be an integer');
            $validator->rule('min', 'currency_id', 1)
                ->message('Currency ID must be at least 1');
        }

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

        // 🔒 PROTECTION BOT: Vérifier limite par IP
        if (!$this->rateLimiter->checkIPLimit('registration', $ipAddress)) {
            $retryAfter = $this->rateLimiter->getRetryAfter('registration', $ipAddress);
            error_log("🚫 [AuthController] Limite d'inscriptions atteinte pour IP: {$ipAddress}");

            return $this->createErrorResponse(
                'Trop de tentatives d\'inscription. Veuillez réessayer dans ' . ceil($retryAfter / 60) . ' minutes.',
                429,
                'RATE_LIMIT_EXCEEDED',
                ['retry_after' => $retryAfter]
            );
        }

        // 🔒 PROTECTION BOT: Vérifier limite par email
        if (!$this->rateLimiter->checkEmailLimit('registration_email', $data['email'])) {
            error_log("🚫 [AuthController] Trop de tentatives pour email: {$data['email']}");
            return $this->createErrorResponse(
                'Cet email a été utilisé trop de fois. Veuillez réessayer plus tard.',
                429,
                'EMAIL_RATE_LIMIT'
            );
        }

        try {
            // Vérifier si l'email existe déjà
            if (User::findByEmail($data['email'])) {
                // 🔒 Enregistrer la tentative même en cas d'échec
                $this->rateLimiter->recordAttempt('registration', $ipAddress);

                return $this->createErrorResponse(
                    'This email is already registered',
                    400,
                    'EMAIL_ALREADY_EXISTS'
                );
            }

            // Déterminer la devise
            $currencyId = 1; // CAD par défaut
            if (isset($data['currency_id'])) {
                $currency = Currency::active()->find($data['currency_id']);
                if ($currency) {
                    $currencyId = $currency->id;
                }
            }

            // Générer le code de vérification
            $verificationCode = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiration = Carbon::now()->addHours(2);

            // Créer l'utilisateur
            $user = User::create([
                'first_name' => trim($data['first_name']),
                'last_name' => trim($data['last_name']),
                'email' => filter_var($data['email'], FILTER_SANITIZE_EMAIL),
                'password_hash' => password_hash($data['password'], PASSWORD_DEFAULT),
                'terms_accepted' => true,
                'currency_id' => $currencyId,
                'email_verification_code' => $verificationCode,
                'email_verification_code_expires_at' => $expiration,
                'created_at' => new \DateTime(),
                'updated_at' => new \DateTime()
            ]);

            $user->load('currency');

            // 🔒 PROTECTION BOT: Enregistrer la tentative réussie
            $this->rateLimiter->recordAttempt('registration', $ipAddress);
            $this->rateLimiter->recordAttempt('registration_email', md5(strtolower($data['email'])));
            $this->rateLimiter->recordGlobalAttempt('registration');

            // Envoyer l'email de vérification
            if(Config::get('APP_ENV') == 'dev') {
                $user->email = 'm2atodev@gmail.com';
            }

            $mailSender = new MailSender();
            $mailSender->sendVerificationEmail($user->email, $user->first_name, $verificationCode);

            error_log("✅ [AuthController] Inscription réussie depuis IP: {$ipAddress}");

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
            // 🔒 Enregistrer la tentative même en cas d'erreur
            $this->rateLimiter->recordAttempt('registration', $ipAddress);

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

        // 🔒 PROTECTION BOT: Obtenir l'IP du client
        $ipAddress = $this->getClientIP($request);

        // 🔒 PROTECTION BOT: Vérifier si l'IP est bloquée
        if ($this->rateLimiter->isIPBlocked($ipAddress)) {
            error_log("🚫 [AuthController] Tentative de vérification email depuis IP bloquée: {$ipAddress}");
            return $this->createErrorResponse(
                'Trop de tentatives. Votre IP a été temporairement bloquée.',
                429,
                'IP_BLOCKED'
            );
        }

        $validator = new Validator($data);
        $validator->rule('required', ['email', 'code'])
            ->message('{field} is required');
        $validator->rule('email', 'email')
            ->message('Invalid email address');

        if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
            $fcmData = $data['fcm_data'];

            if (isset($fcmData['device_id'])) {
                $validator->rule('lengthMax', 'fcm_data.device_id', 255)
                    ->message('Device ID too long');
            }

            if (isset($fcmData['push_token'])) {
                $validator->rule('lengthMax', 'fcm_data.push_token', 512)
                    ->message('Push token too long');
            }

            if (isset($fcmData['platform'])) {
                $validator->rule('in', 'fcm_data.platform', ['android', 'ios'])
                    ->message('Platform must be android or ios');
            }
        }

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

        // 🔒 PROTECTION BOT: Vérifier limite par IP pour les codes de vérification
        if (!$this->rateLimiter->checkIPLimit('verification_code', $ipAddress)) {
            $retryAfter = $this->rateLimiter->getRetryAfter('verification_code', $ipAddress);
            error_log("🚫 [AuthController] Trop de tentatives de vérification depuis IP: {$ipAddress}");

            return $this->createErrorResponse(
                'Trop de tentatives de vérification. Veuillez réessayer dans ' . ceil($retryAfter / 60) . ' minutes.',
                429,
                'RATE_LIMIT_EXCEEDED',
                ['retry_after' => $retryAfter]
            );
        }

        try {
            $user = User::with('currency')->where('email', $data['email'])->first();

            if (!$user) {
                // 🔒 Enregistrer tentative échouée
                $this->rateLimiter->recordAttempt('verification_code', $ipAddress);

                return $this->createErrorResponse(
                    'User not found',
                    404,
                    'USER_NOT_FOUND'
                );
            }

            if ($user->isEmailVerified()) {
                return $this->createErrorResponse(
                    'Email already verified',
                    400,
                    'EMAIL_ALREADY_VERIFIED'
                );
            }

            if ($user->email_verification_code !== $data['code']) {
                // 🔒 Enregistrer tentative échouée
                $this->rateLimiter->recordAttempt('verification_code', $ipAddress);

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

            $user->markEmailAsVerified();
            $user->save();

            // 🔒 PROTECTION BOT: Réinitialiser les tentatives après succès
            $this->rateLimiter->resetAttempts('verification_code', $ipAddress);

            if (isset($data['fcm_data']) && is_array($data['fcm_data'])) {
                error_log(" Mise à jour FCM lors de la confirmation d'email pour utilisateur: {$user->id}");
                $fcmUpdateSuccess = $this->updateUserFCMToken($user->id, $data['fcm_data']);

                if ($fcmUpdateSuccess) {
                    error_log(" Token FCM mis à jour avec succès lors de la confirmation");
                } else {
                    error_log(" Échec de la mise à jour FCM (confirmation continue)");
                }
            }

            if(Config::get('APP_ENV') == 'dev') {
                $user->email = 'm2atodev@gmail.com';
            }

            $mailSender = new MailSender();
            $mailSender->sendWelcomeEmail($user->email, $user->first_name);

            $accessToken = $this->jwtService->generateToken([
                'auth_id' => $user->id
            ]);

            $refreshToken = $this->jwtService->generateRefreshToken([
                'auth_id' => $user->id
            ]);

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

            if ($user->isEmailVerified()) {
                return $this->createErrorResponse('Email already verified', 400);
            }

            $verificationCode = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiration = Carbon::now()->addHours(2);

            $user->email_verification_code = $verificationCode;
            $user->email_verification_code_expires_at = $expiration;
            $user->save();

            if(Config::get('APP_ENV')=='dev') {
                $user->email = 'm2atodev@gmail.com';
            }

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

        // 🔒 PROTECTION BOT: Obtenir l'IP du client
        $ipAddress = $this->getClientIP($request);

        // 🔒 PROTECTION BOT: Vérifier si l'IP est bloquée
        if ($this->rateLimiter->isIPBlocked($ipAddress)) {
            error_log("🚫 [AuthController] Tentative de reset mot de passe depuis IP bloquée: {$ipAddress}");
            return $this->createErrorResponse(
                'Trop de tentatives. Votre IP a été temporairement bloquée.',
                429,
                'IP_BLOCKED'
            );
        }

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

        // 🔒 PROTECTION BOT: Vérifier limite par IP
        if (!$this->rateLimiter->checkIPLimit('password_reset', $ipAddress)) {
            $retryAfter = $this->rateLimiter->getRetryAfter('password_reset', $ipAddress);
            error_log("🚫 [AuthController] Limite de reset mot de passe atteinte pour IP: {$ipAddress}");

            return $this->createErrorResponse(
                'Trop de tentatives. Veuillez réessayer dans ' . ceil($retryAfter / 60) . ' minutes.',
                429,
                'RATE_LIMIT_EXCEEDED',
                ['retry_after' => $retryAfter]
            );
        }

        try {
            // 🔒 Enregistrer la tentative
            $this->rateLimiter->recordAttempt('password_reset', $ipAddress);

            $user = User::findByEmail($data['email']);

            if (!$user) {
                // Toujours retourner succès pour ne pas révéler si l'email existe
                return $this->createErrorResponse('If this email exists, a password change code has been sent.', 200);
            }

            $code = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiration = Carbon::now()->addHours(2);

            $user->password_change_code = $code;
            $user->password_change_code_expires_at = $expiration;
            $user->save();

            if(Config::get('APP_ENV')=='dev') {
                $user->email = 'm2atodev@gmail.com';
            }

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

            if (!$user->is_active) {
                return $this->createErrorResponse(
                    'User account is not active',
                    400,
                    'USER_INACTIVE'
                );
            }

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

    // ===================== ROUTES PROTÉGÉES =====================

    public function getCurrentUser(Request $request, Response $response)
    {
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
        $authId = $request->getAttribute('auth_id');
        
        if (!$authId) {
            return $this->createErrorResponse('Unauthorized', 401);
        }

        $data = $request->getParsedBody();

        $validator = new Validator($data);
        $validator->rule('required', ['first_name', 'last_name'])
            ->message('{field} is required');
        $validator->rule('lengthMax', ['first_name', 'last_name'], 100)
            ->message('{field} is too long (max 100 characters)');

        if (isset($data['currency_id'])) {
            $validator->rule('integer', 'currency_id')
                ->message('Currency ID must be an integer');
            $validator->rule('min', 'currency_id', 1)
                ->message('Currency ID must be at least 1');
        }

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
            $user = User::with('currency')->find($authId);
            
            if (!$user) {
                return $this->createErrorResponse('User not found', 404);
            }

            $updateData = [
                'first_name' => trim($data['first_name']),
                'last_name' => trim($data['last_name']),
                'updated_at' => new \DateTime()
            ];

            if (isset($data['currency_id'])) {
                $currency = Currency::active()->find($data['currency_id']);
                if ($currency) {
                    $updateData['currency_id'] = $currency->id;
                }
            }

            $user->update($updateData);
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
            return $this->createErrorResponse('Profile update failed: ' . $e->getMessage(), 500);
        }
    }
}