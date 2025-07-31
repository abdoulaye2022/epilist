<?php
// public/cron.php - SYSTÈME DE NOTIFICATIONS PROGRAMMÉES EPILIST - VERSION NETTOYÉE

require __DIR__ . '/../vendor/autoload.php';

use App\Services\NotificationService;
use App\Models\User;
use App\Models\Budget;
use App\Models\UserDevice;
use Carbon\Carbon;
use Dotenv\Dotenv;

// Charger les variables d'environnement
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
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

$notificationService = new NotificationService();

echo "=== EpiList Notification Cron Started at " . Carbon::now()->toDateTimeString() . " ===\n";

try {
    // 1. ✅ RÉSUMÉ QUOTIDIEN (9h00 du matin)
    if (Carbon::now()->hour === 9 && Carbon::now()->minute < 30) {
        echo "Sending daily budget summaries...\n";
        sendDailySummaries($notificationService);
    }

    // 2. ✅ ALERTES BUDGETS DÉPASSÉS (toutes les heures 9h-21h)
    $currentHour = Carbon::now()->hour;
    // if ($currentHour >= 9 && $currentHour <= 21) {
        echo "Checking for budget alerts...\n";
        checkBudgetAlerts($notificationService);
    // }

    // 3. ✅ BUDGETS EXPIRANT BIENTÔT (une fois par jour à 18h)
    if (Carbon::now()->hour === 18 && Carbon::now()->minute < 30) {
        echo "Checking for expiring budgets...\n";
        checkExpiringBudgets($notificationService);
    }

    // 4. ✅ NETTOYAGE DES APPAREILS INACTIFS (une fois par semaine le dimanche à 2h)
    if (Carbon::now()->dayOfWeek === Carbon::SUNDAY && Carbon::now()->hour === 2) {
        echo "Cleaning up inactive devices...\n";
        cleanupInactiveDevices();
    }

    echo "=== Cron completed successfully ===\n";

} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    error_log("EpiList Cron Error: " . $e->getMessage());
}

/**
 * ✅ ENVOI DES RÉSUMÉS QUOTIDIENS
 */
function sendDailySummaries(NotificationService $service): void
{
    echo "Starting daily summaries...\n";
    
    $activeUsers = User::active()
        ->whereHas('devices', function($q) {
            $q->active()->canReceiveNotifications();
        })
        ->get();

    echo "Found {$activeUsers->count()} active users with devices\n";
    $sentCount = 0;
    
    foreach ($activeUsers as $user) {
        // Récupérer les budgets actifs de l'utilisateur
        $budgets = Budget::forUser($user->id)
            ->active()
            ->current()
            ->get();

        $alertBudgets = $budgets->filter(fn($b) => $b->shouldShowAlert());
        
        if ($alertBudgets->isNotEmpty()) {
            foreach ($alertBudgets as $budget) {
                $success = $service->sendBudgetAlert($user, $budget, 'daily_summary');
                
                if ($success) {
                    $sentCount++;
                }
            }
        }
    }
    
    echo "Daily summaries sent: {$sentCount}\n";
}

/**
 * ✅ VÉRIFICATION DES ALERTES BUDGET
 */
function checkBudgetAlerts(NotificationService $service): void
{
    echo "Starting budget alerts check...\n";
    
    $exceededBudgets = Budget::active()
        ->current()
        ->with(['user'])
        ->get()
        ->filter(function($budget) {
            return $budget->shouldShowAlert() && 
                   $budget->user->canReceiveNotifications();
        });

    echo "Found {$exceededBudgets->count()} budgets needing alerts\n";
    $alertsSent = 0;
    
    foreach ($exceededBudgets as $budget) {
        $user = $budget->user;
        $alertType = $budget->isExceeded() ? 'exceeded' : 'warning';
        
        // Éviter les spams - vérifier la dernière alerte envoyée
        $lastAlert = getLastAlertTime($budget->id, $alertType);
        $now = Carbon::now();
        
        // Alertes "exceeded": max 1 par heure
        // Alertes "warning": max 1 par 4 heures
        $cooldownHours = $alertType === 'exceeded' ? 1 : 4;
        
        $shouldSendAlert = false;
        
        if (!$lastAlert) {
            $shouldSendAlert = true;
        } else {
            $hoursSinceLastAlert = $lastAlert->diffInHours($now);
            
            if ($hoursSinceLastAlert >= $cooldownHours) {
                $shouldSendAlert = true;
            }
        }
        
        if ($shouldSendAlert) {
            $success = $service->sendBudgetAlert($user, $budget, $alertType);
            
            if ($success) {
                $alertsSent++;
                saveLastAlertTime($budget->id, $alertType, $now);
            }
        }
    }
    
    echo "Budget alerts sent: {$alertsSent}\n";
}

/**
 * ✅ BUDGETS EXPIRANT BIENTÔT
 */
function checkExpiringBudgets(NotificationService $service): void
{
    echo "Checking for expiring budgets...\n";
    
    $threeDaysFromNow = Carbon::now()->addDays(3)->toDateString();
    
    $expiringBudgets = Budget::active()
        ->current()
        ->whereDate('end_date', $threeDaysFromNow)
        ->with(['user'])
        ->get()
        ->filter(function($budget) {
            return $budget->user->canReceiveNotifications();
        });

    echo "Found {$expiringBudgets->count()} expiring budgets\n";
    $sentCount = 0;
    
    foreach ($expiringBudgets as $budget) {
        $user = $budget->user;
        $daysLeft = $budget->getDaysRemaining();
        $spentPercentage = round($budget->getSpentPercentage(), 1);
        
        $result = $service->sendToUser(
            $user->id,
            'budget_expiring',
            '⏰ Budget se termine bientôt',
            "Le budget \"{$budget->name}\" se termine dans {$daysLeft} jour(s). Vous avez utilisé {$spentPercentage}%",
            [
                'budget_id' => (string) $budget->id,
                'budget_name' => $budget->name,
                'days_remaining' => $daysLeft,
                'spent_percentage' => $spentPercentage,
                'action' => 'renew_budget'
            ]
        );
        
        if ($result['success']) {
            $sentCount++;
        }
    }
    
    echo "Expiration notifications sent: {$sentCount}\n";
}

/**
 * ✅ NETTOYAGE DES APPAREILS INACTIFS
 */
function cleanupInactiveDevices(): void
{
    echo "Cleaning up inactive devices...\n";
    
    try {
        $cleaned = UserDevice::cleanupInactiveDevices();
        echo "Inactive devices cleaned: {$cleaned}\n";
    } catch (\Exception $e) {
        echo "Error cleaning devices: " . $e->getMessage() . "\n";
    }
}

/**
 * ✅ HELPERS POUR ÉVITER LES SPAMS DE NOTIFICATIONS
 */
function getLastAlertTime(int $budgetId, string $alertType): ?Carbon
{
    $cacheFile = __DIR__ . "/../storage/alerts_{$budgetId}_{$alertType}.txt";
    
    if (!file_exists($cacheFile)) {
        return null;
    }
    
    try {
        $timestamp = file_get_contents($cacheFile);
        
        if (!$timestamp || !is_numeric($timestamp)) {
            unlink($cacheFile);
            return null;
        }
        
        $alertTime = Carbon::createFromTimestamp($timestamp, 'UTC');
        
        // Vérification de sécurité: Pas plus de 30 jours dans le passé
        if ($alertTime->diffInDays(Carbon::now()) > 30) {
            unlink($cacheFile);
            return null;
        }
        
        return $alertTime;
        
    } catch (\Exception $e) {
        if (file_exists($cacheFile)) {
            unlink($cacheFile);
        }
        return null;
    }
}

function saveLastAlertTime(int $budgetId, string $alertType, Carbon $time): void
{
    $cacheFile = __DIR__ . "/../storage/alerts_{$budgetId}_{$alertType}.txt";
    $storageDir = dirname($cacheFile);
    
    try {
        if (!is_dir($storageDir)) {
            mkdir($storageDir, 0755, true);
        }
        
        file_put_contents($cacheFile, $time->getTimestamp());
        
    } catch (\Exception $e) {
        error_log("Error saving alert timestamp: " . $e->getMessage());
    }
}