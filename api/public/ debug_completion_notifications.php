<?php
// debug_completion_notifications.php - Script de debug pour les notifications de completion

require __DIR__ . '/../vendor/autoload.php';

use App\Models\ShoppingList;
use App\Models\ListItem;
use App\Models\ListReceipt;
use App\Models\User;
use App\Services\ListCompletionNotificationService;
use App\Services\NotificationService;
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

echo "=== DEBUG COMPLETION NOTIFICATIONS ===\n";
echo "Current time: " . Carbon::now()->toDateTimeString() . "\n\n";

try {
    // 1. ✅ TROUVER TOUTES LES LISTES COMPLÉTÉES SANS FACTURE
    echo "1. SEARCHING FOR COMPLETED LISTS WITHOUT RECEIPTS...\n";
    
    $completedLists = ShoppingList::with(['items', 'receipts', 'user'])
        ->whereHas('items') // A au moins un item
        ->whereDoesntHave('receipts') // N'a pas de factures
        ->get()
        ->filter(function($list) {
            // Filtrer pour ne garder que les listes 100% complétées
            $items = $list->items;
            if ($items->isEmpty()) {
                return false;
            }
            
            $totalItems = $items->count();
            $purchasedItems = $items->where('is_purchased', true)->count();
            
            return $purchasedItems === $totalItems;
        });

    echo "Found " . $completedLists->count() . " completed lists without receipts\n\n";

    if ($completedLists->isEmpty()) {
        echo "❌ NO COMPLETED LISTS FOUND - This explains why no notifications are sent!\n";
        echo "\nLet's check all lists to understand the situation:\n\n";
        debugAllLists();
        exit;
    }

    // 2. ✅ ANALYSER CHAQUE LISTE TROUVÉE
    $completionService = new ListCompletionNotificationService();
    $notificationService = new NotificationService();

    foreach ($completedLists as $list) {
        echo "=== ANALYZING LIST: {$list->name} (ID: {$list->id}) ===\n";
        echo "Owner: {$list->user->email} (ID: {$list->user_id})\n";
        
        $items = $list->items;
        $totalItems = $items->count();
        $purchasedItems = $items->where('is_purchased', true)->count();
        $receiptsCount = $list->receipts->count();
        
        echo "Items: {$purchasedItems}/{$totalItems} purchased\n";
        echo "Receipts: {$receiptsCount}\n";
        
        // Calculer le total estimé
        $estimatedTotal = $items->sum(function($item) {
            return $item->is_purchased && $item->price ? 
                ($item->price * $item->quantity) : 0;
        });
        echo "Estimated total: $" . number_format($estimatedTotal, 2) . "\n";
        
        // Vérifier quand les items ont été mis à jour pour la dernière fois
        $lastItemUpdate = $items->max('updated_at');
        echo "Last item update: " . ($lastItemUpdate ? $lastItemUpdate->toDateTimeString() : 'N/A') . "\n";
        
        if ($lastItemUpdate) {
            $hoursSinceUpdate = $lastItemUpdate->diffInHours(Carbon::now());
            echo "Hours since last update: {$hoursSinceUpdate}\n";
        }
        
        // 3. ✅ TESTER LA LOGIQUE DE VÉRIFICATION
        echo "\n--- ELIGIBILITY CHECK ---\n";
        $shouldSend = $completionService->shouldSendCompletionNotification($list);
        echo "Should send notification: " . ($shouldSend ? "YES ✅" : "NO ❌") . "\n";
        
        if (!$shouldSend) {
            echo "Analyzing why notification is not eligible...\n";
            
            // Test manuel des conditions
            if ($items->isEmpty()) {
                echo "❌ REASON: No items in list\n";
            } else if ($purchasedItems !== $totalItems) {
                echo "❌ REASON: List not 100% completed ({$purchasedItems}/{$totalItems})\n";
            } else if ($receiptsCount > 0) {
                echo "❌ REASON: List has receipts ({$receiptsCount} receipts)\n";
            } else {
                // Vérifier le cooldown
                $lastNotification = getLastCompletionNotificationDebug($list->id);
                if ($lastNotification) {
                    $hoursSinceLastNotification = $lastNotification->diffInHours(Carbon::now());
                    echo "❌ REASON: Cooldown active (last notification {$hoursSinceLastNotification}h ago)\n";
                } else if ($lastItemUpdate && $lastItemUpdate->diffInHours(Carbon::now()) > 2) {
                    echo "❌ REASON: List completed too long ago ({$hoursSinceUpdate}h ago)\n";
                } else {
                    echo "❌ REASON: Unknown - this shouldn't happen!\n";
                }
            }
        } else {
            echo "✅ List is eligible for notification!\n";
            
            // 4. ✅ TESTER L'ENVOI DE NOTIFICATION
            echo "\n--- TESTING NOTIFICATION SEND ---\n";
            $user = $list->user;
            
            // Vérifier que l'utilisateur a des appareils actifs
            $activeDevices = $user->devices()
                ->where('is_active', true)
                ->whereNotNull('push_token')
                ->count();
            
            echo "User has {$activeDevices} active device(s)\n";
            
            if ($activeDevices === 0) {
                echo "❌ CANNOT SEND: User has no active devices\n";
            } else {
                echo "🧪 ATTEMPTING TO SEND TEST NOTIFICATION...\n";
                
                try {
                    $sent = $completionService->sendCompletionNotification($list);
                    
                    if ($sent) {
                        echo "✅ NOTIFICATION SENT SUCCESSFULLY!\n";
                    } else {
                        echo "❌ NOTIFICATION FAILED TO SEND\n";
                    }
                    
                } catch (\Exception $e) {
                    echo "❌ NOTIFICATION ERROR: " . $e->getMessage() . "\n";
                }
            }
        }
        
        echo "\n" . str_repeat("-", 50) . "\n\n";
    }

    // 5. ✅ TESTER LA FONCTION CRON
    echo "=== TESTING CRON FUNCTION ===\n";
    echo "Running checkRecentlyCompletedLists()...\n";
    
    $cronResults = $completionService->checkRecentlyCompletedLists();
    
    echo "Cron results:\n";
    echo "- Lists checked: {$cronResults['checked']}\n";
    echo "- Notifications sent: {$cronResults['notifications_sent']}\n";
    
    if (!empty($cronResults['errors'])) {
        echo "- Errors:\n";
        foreach ($cronResults['errors'] as $error) {
            echo "  * {$error}\n";
        }
    }

} catch (\Exception $e) {
    echo "❌ CRITICAL ERROR: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}

/**
 * ✅ DEBUG: Analyser toutes les listes pour comprendre la situation
 */
function debugAllLists(): void
{
    echo "=== ALL LISTS ANALYSIS ===\n";
    
    $allLists = ShoppingList::with(['items', 'receipts'])->get();
    
    echo "Total lists in database: " . $allLists->count() . "\n\n";
    
    $categories = [
        'empty' => 0,
        'has_items_not_completed' => 0,
        'completed_with_receipts' => 0,
        'completed_without_receipts' => 0,
    ];
    
    foreach ($allLists as $list) {
        $items = $list->items;
        $receipts = $list->receipts;
        
        if ($items->isEmpty()) {
            $categories['empty']++;
        } else {
            $totalItems = $items->count();
            $purchasedItems = $items->where('is_purchased', true)->count();
            $isCompleted = $purchasedItems === $totalItems;
            
            if (!$isCompleted) {
                $categories['has_items_not_completed']++;
            } else if ($receipts->count() > 0) {
                $categories['completed_with_receipts']++;
            } else {
                $categories['completed_without_receipts']++;
                echo "📋 Completed list found: \"{$list->name}\" (ID: {$list->id})\n";
                echo "   Items: {$purchasedItems}/{$totalItems}, Receipts: {$receipts->count()}\n";
                
                $lastUpdate = $items->max('updated_at');
                if ($lastUpdate) {
                    echo "   Last update: " . $lastUpdate->toDateTimeString() . " (" . $lastUpdate->diffForHumans() . ")\n";
                }
                echo "\n";
            }
        }
    }
    
    echo "CATEGORIES:\n";
    echo "- Empty lists: {$categories['empty']}\n";
    echo "- Lists with items (not completed): {$categories['has_items_not_completed']}\n";
    echo "- Completed lists with receipts: {$categories['completed_with_receipts']}\n";
    echo "- Completed lists WITHOUT receipts: {$categories['completed_without_receipts']}\n";
}

/**
 * ✅ DEBUG: Version debug de getLastCompletionNotification
 */
function getLastCompletionNotificationDebug(int $listId): ?Carbon
{
    $cacheFile = __DIR__ . "/../storage/completion_notification_{$listId}.txt";
    
    echo "Checking cache file: {$cacheFile}\n";
    
    if (!file_exists($cacheFile)) {
        echo "Cache file does not exist\n";
        return null;
    }
    
    try {
        $timestamp = file_get_contents($cacheFile);
        echo "Cache file content: {$timestamp}\n";
        
        if (!$timestamp || !is_numeric($timestamp)) {
            echo "Invalid timestamp, deleting cache file\n";
            unlink($cacheFile);
            return null;
        }
        
        $notificationTime = Carbon::createFromTimestamp($timestamp, 'UTC');
        echo "Last notification time: " . $notificationTime->toDateTimeString() . "\n";
        
        // Vérification de sécurité: Pas plus de 30 jours dans le passé
        if ($notificationTime->diffInDays(Carbon::now()) > 30) {
            echo "Cache file too old, deleting\n";
            unlink($cacheFile);
            return null;
        }
        
        return $notificationTime;
        
    } catch (\Exception $e) {
        echo "Error reading cache file: " . $e->getMessage() . "\n";
        if (file_exists($cacheFile)) {
            unlink($cacheFile);
        }
        return null;
    }
}

echo "\n=== DEBUG COMPLETED ===\n";