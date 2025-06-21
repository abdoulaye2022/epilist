<?php
// public/index.php

// ini_set('display_errors', 1);
// ini_set('display_startup_errors', 1);
// error_reporting(E_ALL);

require __DIR__ . '/../vendor/autoload.php';

use Slim\Factory\AppFactory;
use App\Controllers\{
    AuthController,
    ShoppingListController,
    ListItemController
};
use App\Middleware\ErrorMiddleware;
use App\Middleware\JwtMiddleware;
use App\Middleware\CorsMiddleware;
use App\Config\Database;
use App\Services\JwtService;
use Dotenv\Dotenv;
use Psr\Http\Message\ResponseFactoryInterface;
use App\Services\MailSender;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Carbon\Carbon;

// Charger les variables d'environnement
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// Utiliser les variables d'environnement
$dbConnection = $_ENV['DB_CONNECTION'];
$dbHost = $_ENV['DB_HOST'];
$dbPort = $_ENV['DB_PORT'];
$dbDatabase = $_ENV['DB_DATABASE'];
$dbUsername = $_ENV['DB_USERNAME'];
$dbPassword = $_ENV['DB_PASSWORD'];

$jwtSecret = $_ENV['JWT_SECRET'];
$jwtAlgorithm = $_ENV['JWT_ALGORITHM'];
$jwtExpiration = $_ENV['JWT_EXPIRATION'];

$jwtRefreshSecret = $_ENV['JWT_REFRESH_SECRET'];
$jwtRefreshAlgorithm = $_ENV['JWT_REFRESH_ALGORITHM'];
$jwtRefreshExpiration = $_ENV['JWT_REFRESH_EXPIRATION'];

// Initialiser la connexion à la base de données
Database::connect(
    $_ENV['DB_CONNECTION'],
    $_ENV['DB_HOST'],
    $_ENV['DB_PORT'],
    $_ENV['DB_DATABASE'],
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD']
);

// Créer une instance de l'application Slim
$app = AppFactory::create();

date_default_timezone_set('UTC');
Carbon::setLocale('fr');

$app->add(new CorsMiddleware());


if( $_ENV['APP_ENV'] != 'dev') {
    $app->setBasePath('/api.epilist/public');
}

// Récupérer la ResponseFactoryInterface depuis le conteneur de Slim
$responseFactory = $app->getResponseFactory();

// Instancier JwtMiddleware manuellement
$jwtMiddleware = new JwtMiddleware($responseFactory);
$errorMiddleware = new ErrorMiddleware($responseFactory);

$app->add($errorMiddleware);

// Ajouter le middleware pour parser le JSON
$app->addBodyParsingMiddleware();

// Activer le middleware d'erreurs
$app->addErrorMiddleware(true, true, true);

$app->post('/auth/login', [AuthController::class, 'login']);
$app->post('/auth/refresh-token', [AuthController::class, 'refresh_token']);
$app->post('/auth/register', [AuthController::class, 'register']);
$app->post('/auth/reset-link', [AuthController::class, 'resetLink']);
$app->post('/auth/validate-reset-token', [AuthController::class, 'validateResetToken']);
$app->post('/auth/reset-password', [AuthController::class, 'resetPassword']);
$app->post('/auth/confirm-email', [AuthController::class, 'confirmedmail']);
$app->post('/auth/resend-confirm-email', [AuthController::class, 'resendconfirmedmail']);

$app->group('', function ($group) {
    // Authentification
    $group->post('/check-auth', [AuthController::class, 'checkAuth']);

    // Shopping Lists Routes
    $group->get('/shopping-lists', [ShoppingListController::class, 'index']);
    $group->post('/shopping-lists', [ShoppingListController::class, 'store']);
    $group->get('/shopping-lists/{id}', [ShoppingListController::class, 'show']);
    $group->put('/shopping-lists/{id}', [ShoppingListController::class, 'update']);
    $group->delete('/shopping-lists/{id}', [ShoppingListController::class, 'destroy']);
    $group->post('/shopping-lists/{id}/restore', [ShoppingListController::class, 'restore']);

    // List Items Routes
    $group->get('/shopping-lists/{listId}/items', [ListItemController::class, 'index']);
    $group->post('/shopping-lists/{listId}/items', [ListItemController::class, 'store']);
    $group->put('/shopping-lists/{listId}/items/{itemId}', [ListItemController::class, 'update']);
    $group->patch('/shopping-lists/{listId}/items/{itemId}/toggle', [ListItemController::class, 'togglePurchased']);
    $group->delete('/shopping-lists/{listId}/items/{itemId}', [ListItemController::class, 'destroy']);
    $group->post('/shopping-lists/{listId}/items/{itemId}/restore', [ListItemController::class, 'restore']);

})->add($jwtMiddleware);

$app->run();