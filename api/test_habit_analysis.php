<?php
// test_habit_analysis.php - SCRIPT DE TEST POUR LE SYSTÈME D'ANALYSE DES HABITUDES

require __DIR__ . '/vendor/autoload.php';

use App\Services\UserHabitAnalysisService;
use App\Models\User;
use Dotenv\Dotenv;
use Carbon\Carbon;

// Charger les variables d'environnement
$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

// Configuration UTC
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

echo "=== EpiList Habit Analysis Test ===\n\n";

// Créer le service
$habitService = new UserHabitAnalysisService();

// Options du script
$userId = $argv[1] ?? null;
$action = $argv[2] ?? 'analyze';

if (!$userId) {
    echo "Usage: php test_habit_analysis.php <user_id> [action]\n";
    echo "Actions:\n";
    echo "  analyze  - Analyser les habitudes de l'utilisateur (défaut)\n";
    echo "  notify   - Analyser ET envoyer notification si nécessaire\n";
    echo "  stored   - Afficher l'analyse sauvegardée\n";
    echo "  all      - Analyser tous les utilisateurs\n\n";
    echo "Exemples:\n";
    echo "  php test_habit_analysis.php 123 analyze\n";
    echo "  php test_habit_analysis.php 123 notify\n";
    echo "  php test_habit_analysis.php all all\n";
    exit(1);
}

try {
    if ($userId === 'all') {
        // Analyser tous les utilisateurs
        echo "🚀 Analyzing ALL active users...\n\n";
        $results = $habitService->analyzeAndNotifyAllUsers();

        echo "\n=== RESULTS ===\n";
        echo "Users analyzed: {$results['analyzed']}\n";
        echo "Notifications sent: {$results['notifications_sent']}\n";

        if (!empty($results['errors'])) {
            echo "\nErrors:\n";
            foreach ($results['errors'] as $error) {
                echo "  - {$error}\n";
            }
        }

    } else {
        // Analyser un utilisateur spécifique
        $user = User::find($userId);

        if (!$user) {
            echo "❌ User {$userId} not found\n";
            exit(1);
        }

        echo "👤 User: {$user->name} ({$user->email})\n";
        echo "Currency: {$user->getPreferredCurrency()->code} ({$user->getPreferredCurrency()->symbol})\n\n";

        if ($action === 'stored') {
            // Afficher l'analyse sauvegardée
            echo "📖 Reading stored analysis...\n\n";
            $analysis = $habitService->getStoredHabitAnalysis($userId);

            if ($analysis) {
                echo "=== STORED ANALYSIS ===\n";
                echo json_encode($analysis, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
                echo "\n";
            } else {
                echo "❌ No stored analysis found for user {$userId}\n";
            }

        } else {
            // Analyser les habitudes
            echo "📊 Analyzing user habits...\n\n";
            $analysis = $habitService->analyzeUserHabits($user);

            echo "=== ANALYSIS RESULT ===\n";
            echo "Frequency: {$analysis['frequency']}\n";
            echo "Pattern: {$analysis['pattern']}\n";
            echo "Confidence: {$analysis['confidence']}%\n";

            if (isset($analysis['preferred_day'])) {
                $dayName = match($analysis['preferred_day']) {
                    1 => 'Lundi',
                    2 => 'Mardi',
                    3 => 'Mercredi',
                    4 => 'Jeudi',
                    5 => 'Vendredi',
                    6 => 'Samedi',
                    0 => 'Dimanche',
                    default => 'Unknown'
                };
                echo "Preferred day: {$dayName}\n";
            }

            if (isset($analysis['average_interval_days'])) {
                echo "Average interval: {$analysis['average_interval_days']} days\n";
            }

            if (isset($analysis['last_list_date'])) {
                echo "Last list: {$analysis['last_list_date']}\n";
            }

            if (isset($analysis['days_since_last_list'])) {
                echo "Days since last list: {$analysis['days_since_last_list']}\n";
            }

            if (isset($analysis['next_expected_date'])) {
                echo "Next expected: {$analysis['next_expected_date']}\n";
            }

            echo "Should notify: " . ($analysis['should_notify'] ? '✅ YES' : '❌ NO') . "\n";

            if (isset($analysis['total_lists_90d'])) {
                echo "Total lists (90d): {$analysis['total_lists_90d']}\n";
            }

            // Si action = notify, envoyer la notification
            if ($action === 'notify' && $analysis['should_notify']) {
                echo "\n📬 Sending notification...\n";
                $sent = $habitService->sendHabitBasedReminder($user, $analysis);

                if ($sent) {
                    echo "✅ Notification sent successfully!\n";
                } else {
                    echo "❌ Failed to send notification\n";
                }
            } elseif ($action === 'notify' && !$analysis['should_notify']) {
                echo "\n⏭️  Notification not needed based on analysis\n";
            }

            echo "\n=== FULL ANALYSIS JSON ===\n";
            echo json_encode($analysis, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
            echo "\n";
        }
    }

    echo "\n✅ Test completed successfully\n";

} catch (\Exception $e) {
    echo "\n❌ ERROR: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}
