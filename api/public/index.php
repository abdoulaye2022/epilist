<?php
// public/index.php

declare(strict_types=1);

// Gestion des erreurs pour le développement
if ($_ENV['APP_ENV'] ?? 'production' === 'local') {
    ini_set('display_errors', '1');
    ini_set('display_startup_errors', '1');
    error_reporting(E_ALL);
}

require __DIR__ . '/../vendor/autoload.php';

use Slim\Factory\AppFactory;
use App\Controllers\{
    AuthController,
};
use App\Middleware\ErrorMiddleware;
use App\Middleware\JwtMiddleware;
use App\Middleware\CorsMiddleware;
use App\Config\Database;
use Dotenv\Dotenv;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Carbon\Carbon;

// Charger les variables d'environnement
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// Initialiser la connexion à la base de données
Database::connect(
    $_ENV['DB_CONNECTION'],
    $_ENV['DB_HOST'],
    $_ENV['DB_PORT'],
    $_ENV['DB_DATABASE'],
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD']
);

// Configuration globale
date_default_timezone_set('UTC');
Carbon::setLocale('fr');

// Créer une instance de l'application Slim
$app = AppFactory::create();

// Configuration du base path pour la production
if (($_ENV['APP_ENV'] ?? 'production') !== 'local') {
    $app->setBasePath('/api.kiloshare/public');
}

// Middlewares globaux
$app->add(new CorsMiddleware());

// Récupérer la ResponseFactoryInterface depuis le conteneur de Slim
$responseFactory = $app->getResponseFactory();

// Instancier les middlewares
$jwtMiddleware = new JwtMiddleware($responseFactory);
$errorMiddleware = new ErrorMiddleware($responseFactory);

$app->add($errorMiddleware);

// Middleware de parsing JSON
$app->addBodyParsingMiddleware();

// Middleware d'erreurs
$app->addErrorMiddleware(
    displayErrorDetails: ($_ENV['APP_ENV'] ?? 'production') === 'local',
    logErrors: true,
    logErrorDetails: true
);

// ===== HEALTH CHECK =====
$app->get('/health', function (Request $request, Response $response) {
    $health = [
        'status' => 'ok',
        'timestamp' => date('c'),
        'version' => $_ENV['APP_VERSION'] ?? '1.0.0'
    ];
    
    $response->getBody()->write(json_encode($health));
    return $response->withHeader('Content-Type', 'application/json');
});

// ===== ROUTES PUBLIQUES =====

// Routes d'authentification
$app->group('/auth', function ($group) {
    // Authentification de base
    $group->post('/login', [AuthController::class, 'login']);
    $group->post('/register', [AuthController::class, 'register']);
    $group->post('/refresh-token', [AuthController::class, 'refresh_token']);
    
    // Récupération de mot de passe
    $group->post('/reset-link', [AuthController::class, 'resetLink']);
    $group->post('/validate-reset-token', [AuthController::class, 'validateResetToken']);
    $group->post('/reset-password', [AuthController::class, 'resetPassword']);
    
    // Confirmation email
    $group->post('/confirm-email', [AuthController::class, 'confirmedmail']);
    $group->post('/resend-confirm-email', [AuthController::class, 'resendconfirmedmail']);
    
    // SSO Google
    $group->post('/sso-google', [AuthController::class, 'ssoGoogle']);
    $group->post('/sso-google-create', [AuthController::class, 'ssoGoogleCreate']);
});

// ===== ROUTES PROTÉGÉES PAR JWT =====
$app->group('/api', function ($group) {
    
    // Vérification d'authentification
    $group->post('/check-auth', [AuthController::class, 'checkAuth']);

    // Routes utilisateur
    // $group->group('/users', function ($userGroup) {
    //     $userGroup->get('', [UserController::class, 'index']);
    //     $userGroup->get('/me', [UserController::class, 'me']);
    //     $userGroup->post('', [UserController::class, 'store']);
    //     $userGroup->post('/update-avatar', [UserController::class, 'updateAvatar']);
    //     $userGroup->get('/{id:[0-9]+}', [UserController::class, 'show']);
    //     $userGroup->put('', [UserController::class, 'update']);
    //     $userGroup->delete('/{id:[0-9]+}', [UserController::class, 'destroy']);
    //     $userGroup->put('/{id:[0-9]+}/toggle-active', [UserController::class, 'toggleActive']);
    //     $userGroup->put('/change-password', [UserController::class, 'changePassword']);
    //     $userGroup->get('/profile/{id:[0-9]+}', [UserController::class, 'profil']);
    // });

})->add($jwtMiddleware);

// Route 404 personnalisée
$app->map(['GET', 'POST', 'PUT', 'DELETE', 'PATCH'], '/{routes:.+}', function (Request $request, Response $response) {
    $errorData = [
        'error' => 'Route not found',
        'message' => 'The requested endpoint does not exist',
        'status' => 404
    ];
    
    $response->getBody()->write(json_encode($errorData));
    return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
});

// Lancement de l'application
$app->run();