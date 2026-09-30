<?php
// public/index.php - VERSION AVEC IMPORT CONTACTCONTROLLER

//  SUPPRESSION DES WARNINGS DEPRECATED POUR BREVO
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
    AnalyticsController,
    ListReceiptsController,
    DeviceController,
    BudgetController,
    CampaignController,
    ContactController,  //  AJOUT DE L'IMPORT MANQUANT
    CategoryController,
    StoreController,
    PriceController,
    IntelligenceController,
    AdminController,
    AppVersionController,
    RecurringListController,
    MealPlanController,
    ImageController,
    MessageController,
    SuggestionController,
    SpaceController,
    SupplierController,
    PurchaseRequestController,
    EmailPreferenceController  // 📧 Nouveau controller pour les préférences d'email
};
use App\Middleware\ErrorMiddleware;
use App\Middleware\JwtMiddleware;
use App\Middleware\AdminMiddleware;
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

//  ROUTES D'AUTHENTIFICATION (sans authentification)
$app->post('/auth/login', [AuthController::class, 'login']);
$app->post('/auth/refresh', [AuthController::class, 'refresh_token']);
// 2FA espace admin (web) : code par email puis jetons
$app->post('/auth/admin/otp', [AuthController::class, 'adminOtpRequest']);
$app->post('/auth/admin/verify-otp', [AuthController::class, 'adminOtpVerify']);
$app->post('/auth/register', [AuthController::class, 'register']);
$app->post('/auth/reset-link', [AuthController::class, 'resetLink']);
$app->post('/auth/validate-reset-token', [AuthController::class, 'validateResetToken']);
$app->post('/auth/reset-password', [AuthController::class, 'resetPassword']);
$app->post('/auth/confirm-email', [AuthController::class, 'confirmEmail']);
$app->post('/auth/resend-verification', [AuthController::class, 'resendVerificationEmail']);
$app->post('/auth/logout', [AuthController::class, 'logout']);
$app->post('/auth/request-password-change', [AuthController::class, 'requestPasswordChange']);
$app->post('/auth/verify-password-change-code', [AuthController::class, 'verifyPasswordChangeCode']);

//  ROUTES DE DEVISES PUBLIQUES (ORDRE IMPORTANT: routes spécifiques AVANT les routes avec paramètres)
$app->get('/currencies', [CurrencyController::class, 'index']);
$app->get('/currencies/popular', [CurrencyController::class, 'getPopular']);
$app->get('/currencies/{id}', [CurrencyController::class, 'show']);

//  ROUTES DE PARTAGE PUBLIQUES
$app->get('/share/{token}', [SharedListController::class, 'showSharePage']);

//  ROUTES DE TEST
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

// Route /test-auth-header supprimée : elle renvoyait tous les headers recus
// (dont Authorization) a n'importe qui, sans authentification.

//  ROUTE PUBLIQUE POUR PRÉVISUALISER L'EMAIL (avant le groupe protégé)
$app->get('/campaign/preview', [CampaignController::class, 'previewCampaignEmail']);
$app->get('/unsubscribe/{token}', [CampaignController::class, 'handleUnsubscribe']); 

//  ROUTES DE CONTACT PUBLIQUES (IMPORTANT: AVANT LE GROUPE PROTÉGÉ)
$app->get('/contact/feedback-types', [ContactController::class, 'getFeedbackTypes']);
$app->post('/contact/feedback-anonymous', [ContactController::class, 'sendFeedback']);

// 📲 Contrôle de version de l'app — PUBLIC et AVANT l'authentification :
// une app bloquée par une version périmée doit pouvoir l'apprendre même
// si la connexion ne passe plus.
$app->get('/app/version-check', [AppVersionController::class, 'check']);
$app->post('/app/version-stat', [AppVersionController::class, 'stat']);

//  ROUTES SSO PUBLIQUES (sans authentification)
$app->post('/auth/sso/google/login', [AuthController::class, 'googleLogin']);
$app->post('/auth/sso/google/register', [AuthController::class, 'googleRegister']);
$app->post('/auth/sso/apple/login', [AuthController::class, 'appleLogin']);
$app->post('/auth/sso/apple/register', [AuthController::class, 'appleRegister']);

//  GROUPE DE ROUTES PROTÉGÉES (avec authentification)
$app->group('', function ($group) {
    //  ROUTES D'AUTHENTIFICATION PROTÉGÉES
    $group->post('/check-auth', [AuthController::class, 'checkAuth']);
    $group->get('/auth/me', [AuthController::class, 'getCurrentUser']);
    $group->put('/auth/me', [AuthController::class, 'updateProfile']);

    // 🏠 ESPACES (Phase 1 — fondation, voir docs/audit-espaces-epilist.md)
    $group->get('/spaces', [SpaceController::class, 'index']);
    $group->post('/spaces', [SpaceController::class, 'create']);
    $group->get('/spaces/{id:[0-9]+}', [SpaceController::class, 'show']);
    $group->put('/spaces/{id:[0-9]+}', [SpaceController::class, 'update']);
    $group->delete('/spaces/{id:[0-9]+}', [SpaceController::class, 'destroy']);
    $group->get('/spaces/{id:[0-9]+}/members', [SpaceController::class, 'members']);
    $group->put('/spaces/{id:[0-9]+}/members/{userId:[0-9]+}', [SpaceController::class, 'updateMember']);
    $group->delete('/spaces/{id:[0-9]+}/members/{userId:[0-9]+}', [SpaceController::class, 'removeMember']);
    $group->post('/spaces/{id:[0-9]+}/leave', [SpaceController::class, 'leave']);
    $group->post('/spaces/{id:[0-9]+}/invitations', [SpaceController::class, 'invite']);
    $group->get('/spaces/{id:[0-9]+}/invitations', [SpaceController::class, 'invitations']);
    $group->delete('/spaces/{id:[0-9]+}/invitations/{invId:[0-9]+}', [SpaceController::class, 'revokeInvitation']);
    $group->get('/spaces/{id:[0-9]+}/activity', [SpaceController::class, 'activity']);

    // 🍽️ RESTAURANT (Phase 3) : fournisseurs + demandes d'achat
    $group->get('/suppliers', [SupplierController::class, 'index']);
    $group->post('/suppliers', [SupplierController::class, 'store']);
    $group->put('/suppliers/{id:[0-9]+}', [SupplierController::class, 'update']);
    $group->delete('/suppliers/{id:[0-9]+}', [SupplierController::class, 'destroy']);
    $group->get('/purchase-requests', [PurchaseRequestController::class, 'index']);
    $group->post('/purchase-requests', [PurchaseRequestController::class, 'store']);
    $group->get('/purchase-requests/{id:[0-9]+}', [PurchaseRequestController::class, 'show']);
    $group->post('/purchase-requests/{id:[0-9]+}/submit', [PurchaseRequestController::class, 'submit']);
    $group->post('/purchase-requests/{id:[0-9]+}/approve', [PurchaseRequestController::class, 'approve']);
    $group->post('/purchase-requests/{id:[0-9]+}/reject', [PurchaseRequestController::class, 'reject']);
    $group->post('/purchase-requests/{id:[0-9]+}/purchased', [PurchaseRequestController::class, 'purchased']);
    $group->post('/purchase-requests/{id:[0-9]+}/cancel', [PurchaseRequestController::class, 'cancel']);
    $group->get('/space-invitations', [SpaceController::class, 'myInvitations']);
    $group->post('/space-invitations/{token}/accept', [SpaceController::class, 'acceptInvitation']);
    $group->post('/space-invitations/{token}/decline', [SpaceController::class, 'declineInvitation']);

    //  ROUTES DE DEVISES PROTÉGÉES
    $group->get('/user/currency', [CurrencyController::class, 'getUserCurrency']);
    $group->put('/user/currency', [CurrencyController::class, 'updateUserCurrency']);
    $group->post('/currency/format', [CurrencyController::class, 'formatUserAmount']);

    //  ROUTES POUR LA SUPPRESSION DE COMPTE
    $group->post('/auth/request-account-deletion', [AuthController::class, 'requestAccountDeletion']);
    $group->post('/auth/confirm-account-deletion', [AuthController::class, 'confirmAccountDeletion']);
    $group->post('/auth/cancel-account-deletion', [AuthController::class, 'cancelAccountDeletion']);
    $group->get('/auth/account-deletion-status', [AuthController::class, 'getAccountDeletionStatus']);
    $group->put('/auth/fcm-token', [AuthController::class, 'updateFCMToken']);

    //  ROUTES POUR LES SUGGESTIONS DE PRODUITS
    $group->get('/product-suggestions/search', [ProductSuggestionController::class, 'search']);
    $group->get('/product-suggestions/popular', [ProductSuggestionController::class, 'getPopular']);
    $group->get('/product-suggestions/stats', [ProductSuggestionController::class, 'getStats']);
    $group->put('/product-suggestions/{id}', [ProductSuggestionController::class, 'update']);
    $group->delete('/product-suggestions/{id}', [ProductSuggestionController::class, 'delete']);
    $group->delete('/product-suggestions', [ProductSuggestionController::class, 'clear']);

    //  ROUTES POUR LES LISTES DE COURSES
    $group->get('/shopping-lists', [ShoppingListController::class, 'index']);
    $group->post('/shopping-lists', [ShoppingListController::class, 'store']);
    $group->get('/shopping-lists/{id}', [ShoppingListController::class, 'show']);
    $group->put('/shopping-lists/{id}', [ShoppingListController::class, 'update']);
    $group->delete('/shopping-lists/{id}', [ShoppingListController::class, 'destroy']);
    $group->post('/shopping-lists/{id}/restore', [ShoppingListController::class, 'restore']);
    $group->post('/shopping-lists/{id}/duplicate', [ShoppingListController::class, 'duplicate']);

    //  ROUTES POUR LE PARTAGE DE LISTES
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

    //  ROUTES POUR LES ARTICLES DE LISTE (ORDRE IMPORTANT: routes spécifiques AVANT paramètres)
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

    //  NOUVELLES ROUTES POUR LES FACTURES DE LISTES
    $group->get('/shopping-lists/{listId}/receipts', [ListReceiptsController::class, 'index']);
    $group->post('/shopping-lists/{listId}/receipts', [ListReceiptsController::class, 'store']);
    $group->get('/shopping-lists/{listId}/receipts/by-store', [ListReceiptsController::class, 'byStore']);
    $group->get('/shopping-lists/{listId}/receipts/stats', [ListReceiptsController::class, 'stats']);
    $group->get('/shopping-lists/{listId}/receipts/export/pdf', [ListReceiptsController::class, 'exportPDF']);
    $group->get('/shopping-lists/{listId}/receipts/export/csv', [ListReceiptsController::class, 'exportCSV']);
    // 💰 Intelligence prix : import structuré de reçu (OCR/manuel),
    // résolution de libellés, historique, comparateur, optimiseur
    $group->post('/shopping-lists/{listId}/receipts/import', [PriceController::class, 'importReceipt']);
    $group->post('/receipts/resolve-labels', [PriceController::class, 'resolveLabels']);
    $group->get('/price-history', [PriceController::class, 'priceHistory']);
    $group->get('/shopping-lists/{id}/store-comparison', [PriceController::class, 'storeComparison']);
    $group->get('/shopping-lists/{id}/optimization', [PriceController::class, 'optimization']);

    $group->get('/shopping-lists/{listId}/receipts/{receiptId}', [ListReceiptsController::class, 'show']);
    $group->put('/shopping-lists/{listId}/receipts/{receiptId}', [ListReceiptsController::class, 'update']);
    $group->delete('/shopping-lists/{listId}/receipts/{receiptId}', [ListReceiptsController::class, 'destroy']);

    //  ROUTES D'ANALYTICS MISES À JOUR
    $group->get('/analytics/dashboard', [AnalyticsController::class, 'dashboard']);
    $group->get('/analytics/spending/monthly', [AnalyticsController::class, 'monthlySpendingHistory']);
    $group->get('/analytics/spending/trends', [AnalyticsController::class, 'spendingTrends']);
    $group->get('/analytics/spending/comparison', [AnalyticsController::class, 'periodComparison']);
    $group->get('/analytics/spending/categories', [AnalyticsController::class, 'spendingByCategory']);
    $group->get('/analytics/spending/stores', [AnalyticsController::class, 'spendingByStore']);
    $group->get('/analytics/products/top', [AnalyticsController::class, 'topProducts']);
    $group->get('/analytics/spending/daily', [AnalyticsController::class, 'dailySpendingHistory']);
    $group->get('/analytics/spending/weekly', [AnalyticsController::class, 'weeklySpendingHistory']);
    $group->get('/analytics/spending/yearly', [AnalyticsController::class, 'yearlySpendingHistory']);
    $group->get('/analytics/data-quality', [AnalyticsController::class, 'dataQualityReport']);

    //  ROUTES POUR LES BUDGETS (dans le groupe protégé)
    $group->get('/budgets', [BudgetController::class, 'index']);
    $group->post('/budgets', [BudgetController::class, 'store']);
    $group->get('/budgets/dashboard', [BudgetController::class, 'dashboard']);
    $group->get('/budgets/alerts', [BudgetController::class, 'getAlerts']);
    $group->post('/budgets/quick', [BudgetController::class, 'createQuickBudget']);
    $group->get('/budgets/forecast', [IntelligenceController::class, 'budgetForecast']);
    $group->get('/budgets/{id}', [BudgetController::class, 'show']);
    $group->put('/budgets/{id}', [BudgetController::class, 'update']);
    $group->delete('/budgets/{id}', [BudgetController::class, 'destroy']);

    //  ROUTES DEVICES COMPLÈTES ET CORRIGÉES
    $group->post('/devices/register', [DeviceController::class, 'register']);
    $group->put('/devices/push-token', [DeviceController::class, 'updatePushToken']);
    $group->get('/devices', [DeviceController::class, 'index']);
    $group->put('/devices/notifications', [DeviceController::class, 'updateNotificationPreferences']);
    $group->post('/devices/deactivate', [DeviceController::class, 'deactivate']);

    // Routes retirées (handlers inexistants dans DeviceController -> 500) :
    // /devices/real-token, /devices/analyze, /devices/test-advanced, /devices/debug

    //  ROUTES DE TEST DE NOTIFICATIONS
    $group->post('/devices/test-notification', [DeviceController::class, 'testNotification']);
    $group->post('/devices/test-user-notifications', [DeviceController::class, 'testNotificationToUser']);

    //  ROUTES POUR LES CAMPAGNES MARKETING — réservées aux admins
    //  (users.role = 'admin', voir migrations/add_role_to_users.sql)
    // 🛠️ Espace administrateur (web) : dashboard, utilisateurs, stats,
    // monitoring, versions de l'app. JWT + rôle admin obligatoires.
    $group->get('/admin/overview', [AdminController::class, 'overview'])->add(new AdminMiddleware());
    $group->get('/admin/users', [AdminController::class, 'users'])->add(new AdminMiddleware());
    $group->put('/admin/users/{id}', [AdminController::class, 'updateUser'])->add(new AdminMiddleware());
    $group->get('/admin/stats', [AdminController::class, 'stats'])->add(new AdminMiddleware());
    $group->get('/admin/errors', [AdminController::class, 'errors'])->add(new AdminMiddleware());
    $group->delete('/admin/errors', [AdminController::class, 'purgeErrors'])->add(new AdminMiddleware());
    $group->delete('/admin/errors/{id}', [AdminController::class, 'deleteError'])->add(new AdminMiddleware());
    $group->get('/admin/app-versions', [AppVersionController::class, 'index'])->add(new AdminMiddleware());
    $group->put('/admin/app-versions/{platform}', [AppVersionController::class, 'update'])->add(new AdminMiddleware());
    $group->post('/admin/app-versions/{platform}/reset-stats', [AppVersionController::class, 'resetStats'])->add(new AdminMiddleware());

    $group->post('/campaigns/new-version', [CampaignController::class, 'sendNewVersionCampaign'])->add(new AdminMiddleware());
    $group->get('/campaigns/stats', [CampaignController::class, 'getCampaignStats'])->add(new AdminMiddleware());
    $group->post('/campaigns/test-email', [CampaignController::class, 'sendTestEmail'])->add(new AdminMiddleware());

    // 📧 ROUTES DE PRÉFÉRENCES D'EMAIL
    $group->get('/user/email-preferences', [EmailPreferenceController::class, 'getPreferences']);
    $group->put('/user/email-preferences', [EmailPreferenceController::class, 'updatePreferences']);
    $group->post('/user/email-preferences/reset', [EmailPreferenceController::class, 'resetPreferences']);
    $group->post('/user/email-preferences/unsubscribe-marketing', [EmailPreferenceController::class, 'unsubscribeMarketing']);

    //  ROUTES DE CONTACT PROTÉGÉES
    $group->post('/contact/feedback', [ContactController::class, 'sendFeedback']);

    //  ROUTES POUR LES CATÉGORIES
    $group->get('/categories', function($request, $response) {
        error_log("Route: GET /categories called");
        $controller = new CategoryController();
        return $controller->index($request, $response);
    });

    $group->post('/categories', function($request, $response) {
        error_log("Route: POST /categories called");
        $controller = new CategoryController();
        return $controller->store($request, $response);
    });

    $group->post('/categories/initialize-defaults', function($request, $response) {
        error_log("=== Route: POST /categories/initialize-defaults CALLED ===");
        try {
            $controller = new CategoryController();
            error_log("Controller instantiated successfully");
            return $controller->initializeDefaults($request, $response);
        } catch (\Exception $e) {
            error_log("ERROR in route handler: " . $e->getMessage());
            error_log("Stack trace: " . $e->getTraceAsString());
            throw $e;
        }
    });

    $group->put('/categories/reorder', [CategoryController::class, 'reorder']);

    // 🏪 MAGASINS ET ORDRE DES RAYONS (tri par rayon)
    // 🧠 Intelligence du foyer : prédictions, inventaire, projection budget
    $group->get('/predictions', [IntelligenceController::class, 'getPredictions']);
    $group->post('/predictions/feedback', [IntelligenceController::class, 'predictionFeedback']);
    $group->get('/inventory', [IntelligenceController::class, 'getInventory']);
    $group->post('/inventory/status', [IntelligenceController::class, 'setInventoryStatus']);
    $group->delete('/inventory/{id}', [IntelligenceController::class, 'deleteInventoryItem']);
    // (budgets/forecast est déclaré plus haut, avant /budgets/{id})

    // 🔁 Listes récurrentes intelligentes
    $group->get('/recurring-lists', [RecurringListController::class, 'index']);
    $group->post('/recurring-lists', [RecurringListController::class, 'store']);
    $group->put('/recurring-lists/{id}', [RecurringListController::class, 'update']);
    $group->delete('/recurring-lists/{id}', [RecurringListController::class, 'destroy']);
    $group->get('/recurring-lists/{id}/preview', [RecurringListController::class, 'preview']);
    $group->post('/recurring-lists/{id}/generate', [RecurringListController::class, 'generate']);

    // 🍽️ Planificateur de repas
    $group->get('/recipes', [MealPlanController::class, 'recipes']);
    $group->post('/meal-plans/preview', [MealPlanController::class, 'preview']);
    $group->post('/meal-plans', [MealPlanController::class, 'store']);

    $group->get('/stores', [StoreController::class, 'index']);
    $group->post('/stores', [StoreController::class, 'store']);
    $group->put('/stores/{id}', [StoreController::class, 'update']);
    $group->delete('/stores/{id}', [StoreController::class, 'destroy']);
    $group->post('/stores/{id}/merge', [StoreController::class, 'merge']);
    $group->get('/stores/{id}/category-order', [StoreController::class, 'getCategoryOrder']);
    $group->put('/stores/{id}/category-order', [StoreController::class, 'setCategoryOrder']);

    // 📷 IMAGES (avatars et photos de produits)
    $group->post('/user/avatar', [ImageController::class, 'uploadAvatar']);
    $group->delete('/user/avatar', [ImageController::class, 'deleteAvatar']);
    $group->post('/shopping-lists/{listId}/items/{itemId}/image', [ImageController::class, 'uploadItemImage']);
    $group->delete('/shopping-lists/{listId}/items/{itemId}/image', [ImageController::class, 'deleteItemImage']);


    $group->get('/categories/{id}', [CategoryController::class, 'show']);
    $group->put('/categories/{id}', [CategoryController::class, 'update']);
    $group->delete('/categories/{id}', [CategoryController::class, 'destroy']);

    // ROUTES POUR LES MESSAGES DE CHAT
    // Get messages for a list
    $group->get('/lists/{listId}/messages', [MessageController::class, 'getMessages']);
    // Send a message
    $group->post('/lists/{listId}/messages', [MessageController::class, 'sendMessage']);
    // Get unread count
    $group->get('/lists/{listId}/messages/unread-count', [MessageController::class, 'getUnreadCount']);
    // Mark message as read
    $group->post('/messages/{messageId}/read', [MessageController::class, 'markAsRead']);
    // Delete a message
    $group->delete('/messages/{messageId}', [MessageController::class, 'deleteMessage']);

    // ROUTES POUR LES SUGGESTIONS INTELLIGENTES
    // Get personalized suggestions
    $group->get('/suggestions', [SuggestionController::class, 'getSuggestions']);
    // Get suggestion for specific product (quantity/price)
    $group->get('/suggestions/product', [SuggestionController::class, 'getProductSuggestion']);
    // Record feedback on suggestion
    $group->post('/suggestions/feedback', [SuggestionController::class, 'recordFeedback']);
    // Recalculate patterns
    $group->post('/suggestions/recalculate', [SuggestionController::class, 'recalculatePatterns']);
    // Get statistics
    $group->get('/suggestions/stats', [SuggestionController::class, 'getStatistics']);
    // Get trending products
    $group->get('/suggestions/trending', [SuggestionController::class, 'getTrending']);
})->add($jwtMiddleware);

$app->run();