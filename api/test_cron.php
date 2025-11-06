<?php
// test_cron.php - TEST DES FONCTIONS CRON
require __DIR__ . '/vendor/autoload.php';

use App\Services\NotificationService;
use App\Services\ListCompletionNotificationService;
use App\Models\User;
use App\Models\Budget;
use App\Models\UserDevice;
use Carbon\Carbon;
use Dotenv\Dotenv;

// Charger les variables d'environnement
$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

// Configuration UTC globale
date_default_timezone_set('UTC');
Carbon::setLocale('fr');

// Initialiser la base de données
App\Config\Database::connect(
    $_ENV['DB_CONNECTION'],
    $_ENV['DB_HOST'],
    $_ENV['DB_PORT'],
    $_ENV['DB_DATABASE'],
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD']
);

echo "=== TEST DES CRON EPILIST ===\n\n";

try {
    // Test 1: Vérifier que NotificationService existe et fonctionne
    echo "1. Test NotificationService...\n";
    $notificationService = new NotificationService();
    echo "   ✅ NotificationService instancié\n\n";

    // Test 2: Vérifier les utilisateurs actifs
    echo "2. Test utilisateurs actifs avec devices...\n";
    $activeUsers = User::where('is_active', true)
        ->whereHas('devices', function($q) {
            $q->where('is_active', true)->whereNotNull('push_token');
        })
        ->get();
    echo "   ✅ Utilisateurs actifs: {$activeUsers->count()}\n\n";

    // Test 3: Vérifier les budgets
    echo "3. Test budgets actifs...\n";
    if (class_exists('App\Models\Budget')) {
        $budgets = Budget::where('is_active', true)->get();
        echo "   ✅ Budgets actifs: {$budgets->count()}\n\n";
    } else {
        echo "   ⚠️  Budget model not found\n\n";
    }

    // Test 4: Vérifier ListCompletionNotificationService
    echo "4. Test ListCompletionNotificationService...\n";
    if (class_exists('App\Services\ListCompletionNotificationService')) {
        $completionService = new ListCompletionNotificationService();
        echo "   ✅ ListCompletionNotificationService instancié\n\n";
    } else {
        echo "   ⚠️  ListCompletionNotificationService not found\n\n";
    }

    // Test 5: Vérifier le dossier storage
    echo "5. Test dossier storage...\n";
    $storageDir = __DIR__ . "/storage";
    if (!is_dir($storageDir)) {
        mkdir($storageDir, 0755, true);
        echo "   ✅ Dossier storage créé\n";
    } else {
        echo "   ✅ Dossier storage existe\n";
    }
    if (is_writable($storageDir)) {
        echo "   ✅ Dossier storage accessible en écriture\n\n";
    } else {
        echo "   ❌ Dossier storage NON accessible en écriture\n\n";
    }

    // Test 6: Test des méthodes NotificationService
    echo "6. Test méthodes NotificationService...\n";
    $methods = ['sendBudgetAlert', 'sendInactivityReminder', 'sendWeeklyListReminder', 'sendToUser'];
    foreach ($methods as $method) {
        if (method_exists($notificationService, $method)) {
            echo "   ✅ Méthode $method existe\n";
        } else {
            echo "   ❌ Méthode $method MANQUANTE\n";
        }
    }
    echo "\n";

    // Test 7: Test Budget methods
    if (class_exists('App\Models\Budget') && $budgets->count() > 0) {
        echo "7. Test méthodes Budget...\n";
        $testBudget = $budgets->first();
        $budgetMethods = ['shouldShowAlert', 'isExceeded', 'getDaysRemaining', 'getSpentPercentage'];
        foreach ($budgetMethods as $method) {
            if (method_exists($testBudget, $method)) {
                echo "   ✅ Méthode Budget::$method existe\n";
            } else {
                echo "   ⚠️  Méthode Budget::$method manquante\n";
            }
        }
        echo "\n";
    }

    // Test 8: Test UserDevice methods
    echo "8. Test méthodes UserDevice...\n";
    if (method_exists('App\Models\UserDevice', 'cleanupInactiveDevices')) {
        echo "   ✅ Méthode UserDevice::cleanupInactiveDevices existe\n";
    } else {
        echo "   ⚠️  Méthode UserDevice::cleanupInactiveDevices manquante (fallback disponible)\n";
    }
    echo "\n";

    echo "=== TOUS LES TESTS TERMINÉS ===\n";
    echo "Le système cron est prêt à fonctionner!\n";

} catch (\Exception $e) {
    echo "❌ ERREUR: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}
