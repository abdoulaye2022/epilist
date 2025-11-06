<?php
// public/cron.php - SYSTÈME DE NOTIFICATIONS PROGRAMMÉES EPILIST - VERSION COMPLÈTE CORRIGÉE

require __DIR__ . '/../vendor/autoload.php';

use App\Services\NotificationService;
use App\Services\ListCompletionNotificationService;
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
    // 1. RESUME QUOTIDIEN (9h58 du matin) - CORRIGE
    if (Carbon::now()->hour === 9) {
        echo "Sending daily budget summaries...\n";
        sendDailySummaries($notificationService);
    }

    // 2. ALERTES BUDGETS DEPASSES (toutes les heures 9h-21h) - DEJA OK
    $currentHour = Carbon::now()->hour;
    if ($currentHour >= 9 && $currentHour <= 21) {
        echo "Checking for budget alerts...\n";
        checkBudgetAlerts($notificationService);
    }

    // 3. BUDGETS EXPIRANT BIENTOT (18h58) - CORRIGE
    if (Carbon::now()->hour === 18) {
        echo "Checking for expiring budgets...\n";
        checkExpiringBudgets($notificationService);
    }

    // 4. RAPPEL UTILISATEURS INACTIFS (mardi a 10h58) - CORRIGE
    if (Carbon::now()->dayOfWeek === Carbon::TUESDAY && Carbon::now()->hour === 10) {
        echo "Checking for inactive users (no lists in 2 weeks)...\n";
        checkInactiveUsers($notificationService);
    }

    // 5. LISTES COMPLETEES SANS FACTURE (heures paires, 8h-22h) - CORRIGE
    if ($currentHour >= 8 && $currentHour <= 22 && $currentHour % 2 === 0) {
        echo "Checking for completed lists without receipts...\n";
        checkCompletedLists();
    }

    // 6. NETTOYAGE DES APPAREILS INACTIFS (dimanche a 2h58) - DEJA OK
    if (Carbon::now()->dayOfWeek === Carbon::SUNDAY && Carbon::now()->hour === 2) {
        echo "Cleaning up inactive devices...\n";
        cleanupInactiveDevices();
        
        echo "Cleaning up old notification cache files...\n";
        cleanupNotificationCacheFiles();
    }

    // 7. UTILISATEURS SANS LISTE CETTE SEMAINE (vendredi a 19h58) - CORRIGE
    if (Carbon::now()->dayOfWeek === Carbon::FRIDAY && Carbon::now()->hour === 19) {
        echo "Checking for users with no lists this week...\n";
        checkUsersWithoutWeeklyLists($notificationService);
    }

    echo "=== Cron completed successfully ===\n";

} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    error_log("EpiList Cron Error: " . $e->getMessage());
}

/**
 * ENVOI DES RESUMES QUOTIDIENS - VERSION CORRIGEE
 */
function sendDailySummaries(NotificationService $service): void
{
    echo "Starting daily summaries...\n";

    //  NOUVEAU VERROU: Une seule fois par jour
    $lockFile = __DIR__ . "/../storage/daily_summary_" . Carbon::now()->format('Y-m-d') . ".lock";
    
    if (file_exists($lockFile)) {
        echo "Daily summaries already sent today, skipping...\n";
        return;
    }
    
    try {
        // CORRECTION: Utiliser query directe au lieu de scopes potentiellement inexistants
        $activeUsers = User::where('is_active', true)
            ->whereHas('devices', function($q) {
                $q->where('is_active', true)->whereNotNull('push_token');
            })
            ->get();

        echo "Found {$activeUsers->count()} active users with devices\n";
        $sentCount = 0;
        
        foreach ($activeUsers as $user) {
            try {
                //  CORRECTION: Vérifier l'existence de la classe Budget
                if (!class_exists('App\Models\Budget')) {
                    echo "Budget model not found, skipping budget summaries\n";
                    break;
                }

                // Récupérer les budgets actifs de l'utilisateur
                $budgets = Budget::where('user_id', $user->id)
                    ->where('is_active', true)
                    ->get();

                $alertBudgets = $budgets->filter(function($budget) {
                    return method_exists($budget, 'shouldShowAlert') && $budget->shouldShowAlert();
                });
                
                if ($alertBudgets->isNotEmpty()) {
                    foreach ($alertBudgets as $budget) {
                        $success = $service->sendBudgetAlert($user, $budget, 'daily_summary');
                        
                        if ($success) {
                            $sentCount++;
                        }
                    }
                }
            } catch (\Exception $e) {
                error_log("Error processing daily summary for user {$user->id}: " . $e->getMessage());
            }
        }
        
        echo "Daily summaries sent: {$sentCount}\n";

        //  Créer le verrou à la fin si succès
        touch($lockFile);
        echo "Daily summaries sent: {$sentCount}\n";
        
    } catch (\Exception $e) {
        echo "Error in sendDailySummaries: " . $e->getMessage() . "\n";
        error_log("Daily summaries error: " . $e->getMessage());
    }
}

/**
 *  VÉRIFICATION DES ALERTES BUDGET - VERSION CORRIGÉE
 */
function checkBudgetAlerts(NotificationService $service): void
{
    echo "Starting budget alerts check...\n";
    
    try {
        //  CORRECTION: Vérifier l'existence de la classe Budget
        if (!class_exists('App\Models\Budget')) {
            echo "Budget model not found, skipping budget alerts\n";
            return;
        }
        
        $exceededBudgets = Budget::where('is_active', true)
            ->with(['user'])
            ->get()
            ->filter(function($budget) {
                if (!$budget->user) {
                    return false;
                }
                
                // Vérifier que l'utilisateur a des appareils actifs
                $hasActiveDevices = $budget->user->devices()
                    ->where('is_active', true)
                    ->whereNotNull('push_token')
                    ->exists();
                
                return $hasActiveDevices && 
                       method_exists($budget, 'shouldShowAlert') && 
                       $budget->shouldShowAlert();
            });

        echo "Found {$exceededBudgets->count()} budgets needing alerts\n";
        $alertsSent = 0;
        
        foreach ($exceededBudgets as $budget) {
            try {
                $user = $budget->user;
                $alertType = (method_exists($budget, 'isExceeded') && $budget->isExceeded()) ? 'exceeded' : 'warning';
                
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
                
            } catch (\Exception $e) {
                error_log("Error processing budget alert for budget {$budget->id}: " . $e->getMessage());
            }
        }
        
        echo "Budget alerts sent: {$alertsSent}\n";
        
    } catch (\Exception $e) {
        echo "Error in checkBudgetAlerts: " . $e->getMessage() . "\n";
        error_log("Budget alerts error: " . $e->getMessage());
    }
}

/**
 *  BUDGETS EXPIRANT BIENTÔT - VERSION CORRIGÉE
 */
function checkExpiringBudgets(NotificationService $service): void
{
    echo "Checking for expiring budgets...\n";

    //  NOUVEAU VERROU: Une seule fois par jour
    $lockFile = __DIR__ . "/../storage/expiring_budgets_" . Carbon::now()->format('Y-m-d') . ".lock";
    
    if (file_exists($lockFile)) {
        echo "Expiring budgets already checked today, skipping...\n";
        return;
    }
    
    try {
        //  CORRECTION: Vérifier l'existence de la classe Budget
        if (!class_exists('App\Models\Budget')) {
            echo "Budget model not found, skipping expiring budgets check\n";
            return;
        }
        
        $threeDaysFromNow = Carbon::now()->addDays(3)->toDateString();
        
        $expiringBudgets = Budget::where('is_active', true)
            ->whereDate('end_date', $threeDaysFromNow)
            ->with(['user'])
            ->get()
            ->filter(function($budget) {
                if (!$budget->user) {
                    return false;
                }
                
                // Vérifier que l'utilisateur a des appareils actifs
                return $budget->user->devices()
                    ->where('is_active', true)
                    ->whereNotNull('push_token')
                    ->exists();
            });

        echo "Found {$expiringBudgets->count()} expiring budgets\n";
        $sentCount = 0;
        
        foreach ($expiringBudgets as $budget) {
            try {
                $user = $budget->user;
                $daysLeft = method_exists($budget, 'getDaysRemaining') ? $budget->getDaysRemaining() : 3;
                $spentPercentage = method_exists($budget, 'getSpentPercentage') ? 
                    round($budget->getSpentPercentage(), 1) : 0;
                
                $result = $service->sendToUser(
                    $user->id,
                    'budget_expiring',
                    'Budget se termine bientot',
                    "Le budget \"{$budget->name}\" se termine dans {$daysLeft} jour(s). Vous avez utilisé {$spentPercentage}%",
                    [
                        'budget_id' => (string) $budget->id,
                        'budget_name' => (string) $budget->name,
                        'days_remaining' => (string) $daysLeft,
                        'spent_percentage' => (string) $spentPercentage,
                        'action' => 'renew_budget'
                    ]
                );
                
                if ($result['success']) {
                    $sentCount++;
                }
                
            } catch (\Exception $e) {
                error_log("Error processing expiring budget for budget {$budget->id}: " . $e->getMessage());
            }
        }
        
        echo "Expiration notifications sent: {$sentCount}\n";

        //  Créer le verrou à la fin
        touch($lockFile);
        echo "Expiration notifications sent: {$sentCount}\n";
        
    } catch (\Exception $e) {
        echo "Error in checkExpiringBudgets: " . $e->getMessage() . "\n";
        error_log("Expiring budgets error: " . $e->getMessage());
    }
}

/**
 *  VÉRIFICATION DES UTILISATEURS INACTIFS - VERSION CORRIGÉE
 */
function checkInactiveUsers(NotificationService $service): void
{
    echo "Starting inactive users check...\n";

    //  NOUVEAU VERROU: Une seule fois par semaine
    $weekNumber = Carbon::now()->format('Y-W'); // 2025-33 par exemple
    $lockFile = __DIR__ . "/../storage/inactive_users_week_{$weekNumber}.lock";
    
    if (file_exists($lockFile)) {
        echo "Inactive users already checked this week, skipping...\n";
        return;
    }
    
    try {
        $twoWeeksAgo = Carbon::now()->subWeeks(2);
        
        //  CORRECTION: Query plus robuste
        $inactiveUsers = User::where('is_active', true)
            ->whereHas('devices', function($q) {
                $q->where('is_active', true)->whereNotNull('push_token');
            })
            ->whereHas('shoppingLists') // Ont déjà créé des listes
            ->whereDoesntHave('shoppingLists', function($q) use ($twoWeeksAgo) {
                $q->where('created_at', '>=', $twoWeeksAgo);
            })
            ->with(['shoppingLists' => function($q) {
                $q->orderBy('created_at', 'desc')->limit(1);
            }])
            ->get();

        echo "Found {$inactiveUsers->count()} inactive users\n";
        
        $sentCount = 0;
        $errors = [];
        
        foreach ($inactiveUsers as $user) {
            try {
                // Vérifier qu'on n'a pas déjà envoyé ce type de notification récemment
                $lastInactivityAlert = getLastInactivityAlert($user->id);
                $now = Carbon::now();
                
                // Ne pas spammer: une seule notification d'inactivité par mois
                if ($lastInactivityAlert && $lastInactivityAlert->diffInDays($now) < 30) {
                    continue;
                }
                
                // Calculer depuis quand l'utilisateur n'a pas créé de liste
                $lastList = $user->shoppingLists->first();
                $daysSinceLastList = $lastList ? 
                    $lastList->created_at->diffInDays($now) : 
                    $user->created_at->diffInDays($now);
                
                //  CORRECTION: Utiliser la méthode du service
                $success = $service->sendInactivityReminder($user, $daysSinceLastList);
                
                if ($success) {
                    $sentCount++;
                    saveLastInactivityAlert($user->id, $now);
                    echo "Sent inactivity reminder to user {$user->id} ({$daysSinceLastList} days)\n";
                } else {
                    $errors[] = "Failed to send to user {$user->id}";
                }
                
            } catch (\Exception $e) {
                $errors[] = "Error processing user {$user->id}: " . $e->getMessage();
                error_log("Inactive user notification error for user {$user->id}: " . $e->getMessage());
            }
        }
        
        echo "Inactivity reminders sent: {$sentCount}\n";
        
        if (!empty($errors)) {
            echo "Errors encountered:\n";
            foreach ($errors as $error) {
                echo "- {$error}\n";
            }
        }

        //  Créer le verrou à la fin
        touch($lockFile);
        echo "Inactivity reminders sent: {$sentCount}\n";
        
    } catch (\Exception $e) {
        echo "Error in checkInactiveUsers: " . $e->getMessage() . "\n";
        error_log("Inactive users check error: " . $e->getMessage());
    }
}

/**
 *  CORRECTION MAJEURE: VÉRIFICATION DES LISTES COMPLÉTÉES SANS FACTURE
 */
function checkCompletedLists(): void
{
    echo "Starting completed lists check...\n";
    
    try {
        //  CORRECTION: Vérifier que la classe existe
        if (!class_exists('App\Services\ListCompletionNotificationService')) {
            echo "ListCompletionNotificationService not found, skipping completed lists check\n";
            return;
        }
        
        $completionService = new ListCompletionNotificationService();
        $results = $completionService->checkRecentlyCompletedLists();
        
        echo "Completed lists check results:\n";
        echo "- Lists checked: {$results['checked']}\n";
        echo "- Notifications sent: {$results['notifications_sent']}\n";
        
        if (!empty($results['errors'])) {
            echo "- Errors encountered:\n";
            foreach ($results['errors'] as $error) {
                echo "  * {$error}\n";
            }
        }
        
    } catch (\Exception $e) {
        echo "Error in completed lists check: " . $e->getMessage() . "\n";
        error_log("Completed lists check error: " . $e->getMessage());
    }
    
    echo "Completed lists check finished.\n\n";
}

/**
 *  NETTOYAGE DES APPAREILS INACTIFS - VERSION CORRIGÉE
 */
function cleanupInactiveDevices(): void
{
    echo "Cleaning up inactive devices...\n";
    
    try {
        //  CORRECTION: Vérifier que la méthode existe
        if (method_exists('App\Models\UserDevice', 'cleanupInactiveDevices')) {
            $cleaned = UserDevice::cleanupInactiveDevices();
            echo "Inactive devices cleaned: {$cleaned}\n";
        } else {
            // Fallback: nettoyer manuellement
            $thirtyDaysAgo = Carbon::now()->subDays(30);
            $cleaned = UserDevice::where('last_active_at', '<', $thirtyDaysAgo)
                ->orWhereNull('last_active_at')
                ->where('created_at', '<', $thirtyDaysAgo)
                ->delete();
            echo "Inactive devices cleaned (manual): {$cleaned}\n";
        }
    } catch (\Exception $e) {
        echo "Error cleaning devices: " . $e->getMessage() . "\n";
        error_log("Device cleanup error: " . $e->getMessage());
    }
}

/**
 *  NETTOYAGE DES FICHIERS CACHE DE NOTIFICATIONS - VERSION CORRIGÉE
 */
function cleanupNotificationCacheFiles(): void
{
    echo "Starting notification cache cleanup...\n";
    
    try {
        //  CORRECTION: Nettoyer les fichiers de completion si le service existe
        if (class_exists('App\Services\ListCompletionNotificationService')) {
            $completionService = new ListCompletionNotificationService();
            $cleaned = $completionService->cleanupOldNotificationFiles();
            echo "Completion notification cache files cleaned: {$cleaned}\n";
        }
        
        // Nettoyer aussi les fichiers d'inactivité
        $inactivityCleaned = cleanupInactivityCacheFiles();
        echo "Inactivity notification cache files cleaned: {$inactivityCleaned}\n";
        
        //  ANCIEN: Nettoyer aussi les fichiers d'alertes budget
        $budgetAlertsCleaned = cleanupBudgetAlertsCacheFiles();
        echo "Budget alerts cache files cleaned: {$budgetAlertsCleaned}\n";
        
        //  NOUVEAU: Nettoyer les fichiers de rappels hebdomadaires
        $weeklyReminderCleaned = cleanupWeeklyReminderCacheFiles();
        echo "Weekly reminder cache files cleaned: {$weeklyReminderCleaned}\n";
        
    } catch (\Exception $e) {
        echo "Error cleaning notification cache files: " . $e->getMessage() . "\n";
        error_log("Notification cache cleanup error: " . $e->getMessage());
    }
    
    echo "Notification cache cleanup finished.\n";
}

/**
 *  HELPERS POUR ÉVITER LES SPAMS DE NOTIFICATIONS
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

/**
 *  HELPER: Récupérer la dernière alerte d'inactivité
 */
function getLastInactivityAlert(int $userId): ?Carbon
{
    $cacheFile = __DIR__ . "/../storage/inactivity_alert_{$userId}.txt";
    
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
        
        // Vérification de sécurité: Pas plus de 6 mois dans le passé
        if ($alertTime->diffInMonths(Carbon::now()) > 6) {
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

/**
 *  HELPER: Sauvegarder la dernière alerte d'inactivité
 */
function saveLastInactivityAlert(int $userId, Carbon $time): void
{
    $cacheFile = __DIR__ . "/../storage/inactivity_alert_{$userId}.txt";
    $storageDir = dirname($cacheFile);
    
    try {
        if (!is_dir($storageDir)) {
            mkdir($storageDir, 0755, true);
        }
        
        file_put_contents($cacheFile, $time->getTimestamp());
        
    } catch (\Exception $e) {
        error_log("Error saving inactivity alert timestamp: " . $e->getMessage());
    }
}

/**
 *  HELPER: Nettoyer les anciens fichiers cache d'inactivité
 */
function cleanupInactivityCacheFiles(): int
{
    $cleaned = 0;
    $storageDir = __DIR__ . "/../storage";
    
    if (!is_dir($storageDir)) {
        return 0;
    }
    
    try {
        $files = glob($storageDir . "/inactivity_alert_*.txt");
        $now = time();
        
        foreach ($files as $file) {
            $lastModified = filemtime($file);
            
            // Supprimer les fichiers plus anciens que 6 mois
            if (($now - $lastModified) > (6 * 30 * 24 * 60 * 60)) {
                unlink($file);
                $cleaned++;
            }
        }
        
    } catch (\Exception $e) {
        error_log("Error cleaning inactivity cache files: " . $e->getMessage());
    }
    
    return $cleaned;
}

/**
 *  NOUVEAU: HELPER pour nettoyer les fichiers cache d'alertes budget
 */
function cleanupBudgetAlertsCacheFiles(): int
{
    $cleaned = 0;
    $storageDir = __DIR__ . "/../storage";
    
    if (!is_dir($storageDir)) {
        return 0;
    }
    
    try {
        $files = glob($storageDir . "/alerts_*.txt");
        $now = time();
        
        foreach ($files as $file) {
            $lastModified = filemtime($file);
            
            // Supprimer les fichiers plus anciens que 30 jours
            if (($now - $lastModified) > (30 * 24 * 60 * 60)) {
                unlink($file);
                $cleaned++;
            }
        }
        
    } catch (\Exception $e) {
        error_log("Error cleaning budget alerts cache files: " . $e->getMessage());
    }
    
    return $cleaned;
}

/**
 *  NOUVELLE FONCTION: Vérifier les utilisateurs sans liste cette semaine
 */
function checkUsersWithoutWeeklyLists(NotificationService $service): void
{
    echo "Starting weekly lists check...\n";

    //  NOUVEAU VERROU: Une seule fois par semaine
    $weekNumber = Carbon::now()->format('Y-W');
    $lockFile = __DIR__ . "/../storage/weekly_lists_check_week_{$weekNumber}.lock";
    
    if (file_exists($lockFile)) {
        echo "Weekly lists check already done this week, skipping...\n";
        return;
    }
    
    try {
        $startOfWeek = Carbon::now()->startOfWeek(); // Lundi de cette semaine
        $endOfWeek = Carbon::now()->endOfWeek();     // Dimanche de cette semaine
        
        echo "Checking for lists created between {$startOfWeek->toDateString()} and {$endOfWeek->toDateString()}\n";
        
        //  Trouver les utilisateurs actifs qui n'ont PAS créé de liste cette semaine
        $usersWithoutWeeklyLists = User::where('is_active', true)
            ->whereHas('devices', function($q) {
                $q->where('is_active', true)->whereNotNull('push_token');
            })
            ->whereHas('shoppingLists') // Ont déjà créé des listes dans le passé
            ->whereDoesntHave('shoppingLists', function($q) use ($startOfWeek, $endOfWeek) {
                $q->whereBetween('created_at', [$startOfWeek, $endOfWeek]);
            })
            ->with(['shoppingLists' => function($q) {
                $q->orderBy('created_at', 'desc')->limit(1);
            }])
            ->get();

        echo "Found {$usersWithoutWeeklyLists->count()} users without lists this week\n";
        
        $sentCount = 0;
        $errors = [];
        
        foreach ($usersWithoutWeeklyLists as $user) {
            try {
                // Vérifier qu'on n'a pas déjà envoyé cette notification cette semaine
                $lastWeeklyReminder = getLastWeeklyReminder($user->id);
                $now = Carbon::now();
                
                // Ne pas spammer: une seule notification par semaine
                if ($lastWeeklyReminder && $lastWeeklyReminder->isCurrentWeek()) {
                    continue;
                }
                
                // Calculer depuis quand l'utilisateur n'a pas créé de liste
                $lastList = $user->shoppingLists->first();
                $daysSinceLastList = $lastList ? 
                    $lastList->created_at->diffInDays($now) : 
                    $user->created_at->diffInDays($now);
                
                // Envoyer la notification avec un message adapté
                $success = $service->sendWeeklyListReminder($user, $daysSinceLastList);
                
                if ($success) {
                    $sentCount++;
                    saveLastWeeklyReminder($user->id, $now);
                    echo "Sent weekly reminder to user {$user->id} ({$daysSinceLastList} days since last list)\n";
                } else {
                    $errors[] = "Failed to send to user {$user->id}";
                }
                
            } catch (\Exception $e) {
                $errors[] = "Error processing user {$user->id}: " . $e->getMessage();
                error_log("Weekly reminder error for user {$user->id}: " . $e->getMessage());
            }
        }
        
        echo "Weekly reminders sent: {$sentCount}\n";
        
        if (!empty($errors)) {
            echo "Errors encountered:\n";
            foreach ($errors as $error) {
                echo "- {$error}\n";
            }
        }

        //  NOUVEAU: Nettoyer les fichiers de verrous
        $locksCleaned = cleanupLockFiles();
        echo "Lock files cleaned: {$locksCleaned}\n";

        //  Créer le verrou à la fin
        touch($lockFile);
        echo "Weekly reminders sent: {$sentCount}\n";
        
    } catch (\Exception $e) {
        echo "Error in checkUsersWithoutWeeklyLists: " . $e->getMessage() . "\n";
        error_log("Weekly lists check error: " . $e->getMessage());
    }
}

//  6. NOUVELLE FONCTION: Nettoyer les verrous anciens
function cleanupLockFiles(): int
{
    $cleaned = 0;
    $storageDir = __DIR__ . "/../storage";
    
    if (!is_dir($storageDir)) {
        return 0;
    }
    
    try {
        $files = glob($storageDir . "/*.lock");
        $now = time();
        
        foreach ($files as $file) {
            $lastModified = filemtime($file);
            
            // Supprimer les verrous plus anciens que 7 jours
            if (($now - $lastModified) > (7 * 24 * 60 * 60)) {
                unlink($file);
                $cleaned++;
            }
        }
        
    } catch (\Exception $e) {
        error_log("Error cleaning lock files: " . $e->getMessage());
    }
    
    return $cleaned;
}

/**
 *  HELPER: Récupérer le dernier rappel hebdomadaire
 */
function getLastWeeklyReminder(int $userId): ?Carbon
{
    $cacheFile = __DIR__ . "/../storage/weekly_reminder_{$userId}.txt";
    
    if (!file_exists($cacheFile)) {
        return null;
    }
    
    try {
        $timestamp = file_get_contents($cacheFile);
        
        if (!$timestamp || !is_numeric($timestamp)) {
            unlink($cacheFile);
            return null;
        }
        
        $reminderTime = Carbon::createFromTimestamp($timestamp, 'UTC');
        
        // Vérification de sécurité: Pas plus de 2 mois dans le passé
        if ($reminderTime->diffInMonths(Carbon::now()) > 2) {
            unlink($cacheFile);
            return null;
        }
        
        return $reminderTime;
        
    } catch (\Exception $e) {
        if (file_exists($cacheFile)) {
            unlink($cacheFile);
        }
        return null;
    }
}

/**
 *  HELPER: Sauvegarder le dernier rappel hebdomadaire
 */
function saveLastWeeklyReminder(int $userId, Carbon $time): void
{
    $cacheFile = __DIR__ . "/../storage/weekly_reminder_{$userId}.txt";
    $storageDir = dirname($cacheFile);
    
    try {
        if (!is_dir($storageDir)) {
            mkdir($storageDir, 0755, true);
        }
        
        file_put_contents($cacheFile, $time->getTimestamp());
        
    } catch (\Exception $e) {
        error_log("Error saving weekly reminder timestamp: " . $e->getMessage());
    }
}

/**
 *  HELPER: Nettoyer les anciens fichiers cache de rappels hebdomadaires (à ajouter dans cleanupNotificationCacheFiles)
 */
function cleanupWeeklyReminderCacheFiles(): int
{
    $cleaned = 0;
    $storageDir = __DIR__ . "/../storage";
    
    if (!is_dir($storageDir)) {
        return 0;
    }
    
    try {
        $files = glob($storageDir . "/weekly_reminder_*.txt");
        $now = time();
        
        foreach ($files as $file) {
            $lastModified = filemtime($file);
            
            // Supprimer les fichiers plus anciens que 2 mois
            if (($now - $lastModified) > (2 * 30 * 24 * 60 * 60)) {
                unlink($file);
                $cleaned++;
            }
        }
        
    } catch (\Exception $e) {
        error_log("Error cleaning weekly reminder cache files: " . $e->getMessage());
    }
    
    return $cleaned;
}

/**
 *  HELPER: Récupérer le dernier rappel quotidien
 */
function getLastDailyReminder(int $userId): ?Carbon
{
    $cacheFile = __DIR__ . "/../storage/daily_reminder_{$userId}.txt";
    
    if (!file_exists($cacheFile)) {
        return null;
    }
    
    try {
        $timestamp = file_get_contents($cacheFile);
        
        if (!$timestamp || !is_numeric($timestamp)) {
            unlink($cacheFile);
            return null;
        }
        
        $reminderTime = Carbon::createFromTimestamp($timestamp, 'UTC');
        
        // Vérification de sécurité: Pas plus de 7 jours dans le passé
        if ($reminderTime->diffInDays(Carbon::now()) > 7) {
            unlink($cacheFile);
            return null;
        }
        
        return $reminderTime;
        
    } catch (\Exception $e) {
        if (file_exists($cacheFile)) {
            unlink($cacheFile);
        }
        return null;
    }
}

/**
 *  HELPER: Sauvegarder le dernier rappel quotidien
 */
function saveLastDailyReminder(int $userId, Carbon $time): void
{
    $cacheFile = __DIR__ . "/../storage/daily_reminder_{$userId}.txt";
    $storageDir = dirname($cacheFile);
    
    try {
        if (!is_dir($storageDir)) {
            mkdir($storageDir, 0755, true);
        }
        
        file_put_contents($cacheFile, $time->getTimestamp());
        
    } catch (\Exception $e) {
        error_log("Error saving daily reminder timestamp: " . $e->getMessage());
    }
}

/**
 *  HELPER: Nettoyer les anciens fichiers cache de rappels quotidiens
 * (À ajouter dans la fonction cleanupNotificationCacheFiles existante)
 */
function cleanupDailyReminderCacheFiles(): int
{
    $cleaned = 0;
    $storageDir = __DIR__ . "/../storage";
    
    if (!is_dir($storageDir)) {
        return 0;
    }
    
    try {
        $files = glob($storageDir . "/daily_reminder_*.txt");
        $now = time();
        
        foreach ($files as $file) {
            $lastModified = filemtime($file);
            
            // Supprimer les fichiers plus anciens que 7 jours
            if (($now - $lastModified) > (7 * 24 * 60 * 60)) {
                unlink($file);
                $cleaned++;
            }
        }
        
    } catch (\Exception $e) {
        error_log("Error cleaning daily reminder cache files: " . $e->getMessage());
    }
    
    return $cleaned;
}