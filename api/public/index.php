<?php
// public/index.php - VERSION AVEC ROUTES CORRIGÉES

// ✅ SUPPRESSION DES WARNINGS DEPRECATED POUR BREVO
error_reporting(E_ALL & ~E_DEPRECATED);

require __DIR__ . '/../vendor/autoload.php';

use Slim\Factory\AppFactory;
use App\Controllers\{
    AuthController,
    ShoppingListController,
    ListItemController,
    SharedListController,
    ProductSuggestionController,
    CurrencyController,
    AnalyticsController
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

// Configuration d'erreurs selon l'environnement
if ($_ENV['APP_ENV'] === 'dev') {
    ini_set('display_errors', '1');
    ini_set('display_startup_errors', '1');
} else {
    ini_set('display_errors', '0');
    ini_set('log_errors', '1');
}

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

// ✅ ROUTES D'AUTHENTIFICATION (sans authentification)
$app->post('/auth/login', [AuthController::class, 'login']);
$app->post('/auth/refresh', [AuthController::class, 'refresh_token']);
$app->post('/auth/register', [AuthController::class, 'register']);
$app->post('/auth/reset-link', [AuthController::class, 'resetLink']);
$app->post('/auth/validate-reset-token', [AuthController::class, 'validateResetToken']);
$app->post('/auth/reset-password', [AuthController::class, 'resetPassword']);
$app->post('/auth/confirm-email', [AuthController::class, 'confirmEmail']);
$app->post('/auth/resend-verification', [AuthController::class, 'resendVerificationEmail']);
$app->post('/auth/logout', [AuthController::class, 'logout']);
$app->post('/auth/request-password-change', [AuthController::class, 'requestPasswordChange']);
$app->post('/auth/verify-password-change-code', [AuthController::class, 'verifyPasswordChangeCode']);

// ✅ ROUTES DE DEVISES PUBLIQUES (ORDRE IMPORTANT: routes spécifiques AVANT les routes avec paramètres)
$app->get('/currencies', [CurrencyController::class, 'index']);
$app->get('/currencies/popular', [CurrencyController::class, 'getPopular']);
$app->get('/currencies/{id}', [CurrencyController::class, 'show']);

// ✅ ROUTES DE PARTAGE PUBLIQUES
$app->get('/share/{token}', [SharedListController::class, 'showSharePage']);

// ✅ ROUTES DE TEST
$app->get('/', function ($request, $response) {
    $response->getBody()->write('EpiList API');
    return $response;
});

$app->get('/test', function ($request, $response) {
    $response->getBody()->write('Test route works!');
    return $response->withHeader('Content-Type', 'text/plain');
});

$app->get('/test-json', function ($request, $response) {
    $data = [
        'success' => true,
        'message' => 'API fonctionne correctement',
        'timestamp' => time(),
        'php_version' => PHP_VERSION,
        'currencies_available' => true
    ];
    
    $response->getBody()->write(json_encode($data));
    return $response->withHeader('Content-Type', 'application/json');
});

$app->get('/test-auth-header', [AuthController::class, 'debugAuth']);

// ✅ GROUPE DE ROUTES PROTÉGÉES (avec authentification)
$app->group('', function ($group) {
    // ✅ ROUTES D'AUTHENTIFICATION PROTÉGÉES
    $group->post('/check-auth', [AuthController::class, 'checkAuth']);
    $group->get('/auth/me', [AuthController::class, 'getCurrentUser']);
    $group->put('/auth/me', [AuthController::class, 'updateProfile']);

    // ✅ ROUTES DE DEVISES PROTÉGÉES
    $group->get('/user/currency', [CurrencyController::class, 'getUserCurrency']);
    $group->put('/user/currency', [CurrencyController::class, 'updateUserCurrency']);
    $group->post('/currency/format', [CurrencyController::class, 'formatUserAmount']);

    // ✅ ROUTES POUR LA SUPPRESSION DE COMPTE
    $group->post('/auth/request-account-deletion', [AuthController::class, 'requestAccountDeletion']);
    $group->post('/auth/confirm-account-deletion', [AuthController::class, 'confirmAccountDeletion']);
    $group->post('/auth/cancel-account-deletion', [AuthController::class, 'cancelAccountDeletion']);
    $group->get('/auth/account-deletion-status', [AuthController::class, 'getAccountDeletionStatus']);

    // ✅ ROUTES POUR LES SUGGESTIONS DE PRODUITS
    $group->get('/product-suggestions/search', [ProductSuggestionController::class, 'search']);
    $group->get('/product-suggestions/popular', [ProductSuggestionController::class, 'getPopular']);
    $group->get('/product-suggestions/stats', [ProductSuggestionController::class, 'getStats']);
    $group->put('/product-suggestions/{id}', [ProductSuggestionController::class, 'update']);
    $group->delete('/product-suggestions/{id}', [ProductSuggestionController::class, 'delete']);
    $group->delete('/product-suggestions', [ProductSuggestionController::class, 'clear']);

    // ✅ ROUTES POUR LES LISTES DE COURSES
    $group->get('/shopping-lists', [ShoppingListController::class, 'index']);
    $group->post('/shopping-lists', [ShoppingListController::class, 'store']);
    $group->get('/shopping-lists/{id}', [ShoppingListController::class, 'show']);
    $group->put('/shopping-lists/{id}', [ShoppingListController::class, 'update']);
    $group->delete('/shopping-lists/{id}', [ShoppingListController::class, 'destroy']);
    $group->post('/shopping-lists/{id}/restore', [ShoppingListController::class, 'restore']);
    $group->post('/shopping-lists/{id}/duplicate', [ShoppingListController::class, 'duplicate']);

    // ✅ ROUTES POUR LE PARTAGE DE LISTES
    $group->post('/shopping-lists/{id}/share', [SharedListController::class, 'createShareLink']);
    $group->get('/share/invitation/{token}', [SharedListController::class, 'getShareInvitation']);
    $group->post('/share/accept/{token}', [SharedListController::class, 'acceptShareInvitation']);
    $group->post('/share/decline/{token}', [SharedListController::class, 'declineShareInvitation']);
    $group->get('/shared-lists', [SharedListController::class, 'getSharedLists']);
    $group->get('/shopping-lists/{id}/shares', [SharedListController::class, 'getListShares']);
    $group->put('/shared-lists/{id}', [SharedListController::class, 'updateSharePermission']);
    $group->delete('/shared-lists/{id}', [SharedListController::class, 'revokeShare']);
    $group->post('/shopping-lists/{id}/leave', [SharedListController::class, 'leaveSharedList']);
    $group->delete('/shopping-lists/{id}/share-links', [SharedListController::class, 'revokeAllShareLinks']);
    $group->get('/shopping-lists/{id}/share-stats', [SharedListController::class, 'getShareStats']);

    // ✅ ROUTES POUR LES ARTICLES DE LISTE (ORDRE IMPORTANT: routes spécifiques AVANT paramètres)
    $group->get('/shopping-lists/{listId}/items', [ListItemController::class, 'index']);
    $group->post('/shopping-lists/{listId}/items', [ListItemController::class, 'store']);
    
    // Routes spécifiques AVANT les routes avec {itemId}
    $group->post('/shopping-lists/{listId}/items/force', [ListItemController::class, 'forceStore']);
    $group->get('/shopping-lists/{listId}/items/suggestions', [ListItemController::class, 'getSimilarItems']);
    $group->patch('/shopping-lists/{listId}/items/mark-all', [ListItemController::class, 'markAllPurchased']);
    $group->delete('/shopping-lists/{listId}/items/clear-purchased', [ListItemController::class, 'clearPurchased']);
    $group->get('/shopping-lists/{listId}/stats', [ListItemController::class, 'getListStats']);
    
    // Routes avec {itemId} APRÈS les routes spécifiques
    $group->put('/shopping-lists/{listId}/items/{itemId}', [ListItemController::class, 'update']);
    $group->patch('/shopping-lists/{listId}/items/{itemId}/toggle', [ListItemController::class, 'togglePurchased']);
    $group->delete('/shopping-lists/{listId}/items/{itemId}', [ListItemController::class, 'destroy']);
    $group->post('/shopping-lists/{listId}/items/{itemId}/restore', [ListItemController::class, 'restore']);
    $group->put('/shopping-lists/{listId}/items/{itemId}/merge', [ListItemController::class, 'mergeWithExisting']);

    // ✅ ROUTES D'ANALYTICS ET STATISTIQUES
    $group->get('/analytics/dashboard', [AnalyticsController::class, 'dashboard']);
    $group->get('/analytics/spending/monthly', [AnalyticsController::class, 'monthlySpendingHistory']);
    $group->get('/analytics/spending/trends', [AnalyticsController::class, 'spendingTrends']);
    $group->get('/analytics/spending/comparison', [AnalyticsController::class, 'periodComparison']);
    $group->get('/analytics/spending/categories', [AnalyticsController::class, 'spendingByCategory']);
    $group->get('/analytics/products/top', [AnalyticsController::class, 'topProducts']);
    $group->get('/analytics/spending/daily', [AnalyticsController::class, 'dailySpendingHistory']);
$group->get('/analytics/spending/weekly', [AnalyticsController::class, 'weeklySpendingHistory']);
$group->get('/analytics/spending/yearly', [AnalyticsController::class, 'yearlySpendingHistory']);

})->add($jwtMiddleware);

$app->run();