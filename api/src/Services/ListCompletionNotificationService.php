<?php
// app/Services/ListCompletionNotificationService.php - VERSION FINALE CORRIGÉE

namespace App\Services;

use App\Models\ShoppingList;
use App\Models\User;
use App\Services\NotificationService;
use Carbon\Carbon;

class ListCompletionNotificationService
{
    protected $notificationService;
    
    public function __construct()
    {
        $this->notificationService = new NotificationService();
    }

    /**
     *  VÉRIFIER SI UNE LISTE EST COMPLÉTÉE SANS FACTURE
     */
    public function shouldSendCompletionNotification(ShoppingList $list): bool
    {
        error_log(" Checking completion notification eligibility for list {$list->id}: '{$list->name}'");
        
        // 1. Vérifier que la liste a des items
        $items = $list->items;
        if ($items->isEmpty()) {
            error_log(" List {$list->id} has no items");
            return false;
        }
        
        error_log(" List {$list->id} has {$items->count()} items");

        // 2. Vérifier que TOUS les items sont marqués comme achetés
        $totalItems = $items->count();
        $purchasedItems = $items->where('is_purchased', true)->count();
        
        error_log(" List {$list->id} progress: {$purchasedItems}/{$totalItems} items purchased");
        
        if ($purchasedItems !== $totalItems) {
            error_log(" List {$list->id} not completed ({$purchasedItems}/{$totalItems})");
            return false;
        }
        
        error_log(" List {$list->id} is 100% completed");

        // 3. Vérifier qu'il n'y a PAS de factures
        $receiptsCount = $list->receipts()->count();
        error_log(" List {$list->id} has {$receiptsCount} receipts");
        
        if ($receiptsCount > 0) {
            error_log(" List {$list->id} already has {$receiptsCount} receipt(s)");
            return false;
        }
        
        error_log(" List {$list->id} has no receipts");

        // 4. Vérifier qu'on n'a pas déjà envoyé cette notification récemment
        $lastNotification = $this->getLastCompletionNotification($list->id);
        if ($lastNotification) {
            $hoursSinceLastNotification = $lastNotification->diffInHours(Carbon::now());
            error_log(" List {$list->id} last notification: {$hoursSinceLastNotification}h ago");
            
            if ($hoursSinceLastNotification < 24) {
                error_log(" List {$list->id} notification cooldown active ({$hoursSinceLastNotification}h < 24h)");
                return false;
            }
        } else {
            error_log(" List {$list->id} has no previous notification");
        }

        // 5. Vérifier que la liste a été complétée récemment (dans les 24 dernières heures)
        $lastItemUpdate = $items->max('updated_at');
        if ($lastItemUpdate) {
            $hoursSinceUpdate = $lastItemUpdate->diffInHours(Carbon::now());
            error_log(" List {$list->id} last item update: {$hoursSinceUpdate}h ago");
            
            if ($hoursSinceUpdate > 24) {
                error_log(" List {$list->id} completed too long ago ({$hoursSinceUpdate}h > 24h)");
                return false;
            }
        } else {
            error_log(" List {$list->id} has no item update timestamp");
        }
        
        error_log(" List {$list->id} is eligible for completion notification!");
        return true;
    }

    /**
     *  ENVOYER LA NOTIFICATION DE LISTE COMPLÉTÉE - CORRECTION FINALE
     */
    public function sendCompletionNotification(ShoppingList $list): bool
    {
        error_log(" Attempting to send completion notification for list {$list->id}");
        
        try {
            $user = $list->user;
            
            if (!$user) {
                error_log(" List {$list->id} has no user");
                return false;
            }
            
            error_log(" Sending to user {$user->id} ({$user->email})");
            error_log(" User currency: {$user->getPreferredCurrency()->code} ({$user->getPreferredCurrency()->symbol})");

            // Vérifier l'éligibilité une dernière fois
            if (!$this->shouldSendCompletionNotification($list)) {
                error_log(" List {$list->id} failed final eligibility check");
                return false;
            }

            // Vérifier que l'utilisateur a des appareils actifs
            $activeDevices = $user->devices()
                ->where('is_active', true)
                ->whereNotNull('push_token')
                ->count();
                
            error_log(" User {$user->id} has {$activeDevices} active device(s)");
            
            if ($activeDevices === 0) {
                error_log(" User {$user->id} has no active devices");
                return false;
            }

            $totalAmount = $this->calculateEstimatedTotal($list);

            //  CORRECTION FINALE: Utiliser la méthode spécialisée du NotificationService
            $success = $this->notificationService->sendListCompletionNotification($user, $list, $totalAmount);

            if ($success) {
                $this->saveLastCompletionNotification($list->id, Carbon::now());
                error_log(" Completion notification sent successfully for list {$list->id} to user {$user->id}");
                return true;
            } else {
                error_log(" Failed to send completion notification for list {$list->id}");
                return false;
            }

        } catch (\Exception $e) {
            error_log(" Exception sending completion notification for list {$list->id}: " . $e->getMessage());
            error_log(" Stack trace: " . $e->getTraceAsString());
            return false;
        }
    }

    /**
     *  CORRECTION MAJEURE: VÉRIFIER TOUTES LES LISTES RÉCEMMENT COMPLÉTÉES
     */
    public function checkRecentlyCompletedLists(): array
    {
        error_log(" Starting checkRecentlyCompletedLists()");
        
        $results = [
            'checked' => 0,
            'notifications_sent' => 0,
            'errors' => []
        ];

        try {
            //  CORRECTION: Récupérer TOUTES les listes avec items, sans filtrage par date
            $potentialLists = ShoppingList::with(['items', 'receipts', 'user', 'user.currency'])
                ->whereHas('items') // A au moins un item
                ->whereDoesntHave('receipts') // N'a pas de factures
                ->whereHas('user', function($query) {
                    $query->where('is_active', true); // Utilisateur actif
                })
                ->get();

            error_log(" Found {$potentialLists->count()} lists with items and no receipts to check");

            foreach ($potentialLists as $list) {
                $results['checked']++;
                
                try {
                    //  CORRECTION: Utiliser la même logique que le test direct
                    error_log(" Checking list {$list->id}: '{$list->name}' (User: {$list->user->email})");
                    error_log(" User currency: {$list->user->getPreferredCurrency()->code}");
                    
                    // Vérifier si cette liste est 100% complétée
                    $items = $list->items;
                    $totalItems = $items->count();
                    $purchasedItems = $items->where('is_purchased', true)->count();
                    
                    error_log(" List {$list->id} status: {$purchasedItems}/{$totalItems} purchased");
                    
                    // Si la liste est 100% complétée, essayer d'envoyer la notification
                    if ($purchasedItems === $totalItems && $totalItems > 0) {
                        error_log(" List {$list->id} is 100% completed, checking full eligibility...");
                        
                        if ($this->sendCompletionNotification($list)) {
                            $results['notifications_sent']++;
                            error_log(" Notification sent for list {$list->id}");
                        } else {
                            error_log(" Failed to send notification for list {$list->id}");
                        }
                    } else {
                        error_log(" Skipping list {$list->id} - not 100% completed");
                    }
                    
                } catch (\Exception $e) {
                    $error = "List {$list->id}: " . $e->getMessage();
                    $results['errors'][] = $error;
                    error_log(" Error processing list {$list->id}: " . $e->getMessage());
                }
            }

            error_log(" checkRecentlyCompletedLists final results: " . json_encode($results));

        } catch (\Exception $e) {
            $error = "General error: " . $e->getMessage();
            $results['errors'][] = $error;
            error_log(" Critical error in checkRecentlyCompletedLists: " . $e->getMessage());
        }

        return $results;
    }

    /**
     *  CALCULER LE TOTAL ESTIMÉ D'UNE LISTE
     */
    private function calculateEstimatedTotal(ShoppingList $list): float
    {
        $total = 0;
        
        foreach ($list->items as $item) {
            if ($item->price && $item->is_purchased) {
                $total += $item->price * $item->quantity;
            }
        }
        
        return round($total, 2);
    }

    /**
     *  RÉCUPÉRER LA DERNIÈRE NOTIFICATION DE COMPLETION
     */
    private function getLastCompletionNotification(int $listId): ?Carbon
    {
        $cacheFile = __DIR__ . "/../../storage/completion_notification_{$listId}.txt";
        
        if (!file_exists($cacheFile)) {
            return null;
        }
        
        try {
            $timestamp = file_get_contents($cacheFile);
            
            if (!$timestamp || !is_numeric($timestamp)) {
                unlink($cacheFile);
                return null;
            }
            
            $notificationTime = Carbon::createFromTimestamp($timestamp, 'UTC');
            
            // Vérification de sécurité: Pas plus de 30 jours dans le passé
            if ($notificationTime->diffInDays(Carbon::now()) > 30) {
                unlink($cacheFile);
                return null;
            }
            
            return $notificationTime;
            
        } catch (\Exception $e) {
            if (file_exists($cacheFile)) {
                unlink($cacheFile);
            }
            return null;
        }
    }

    /**
     *  SAUVEGARDER LA DERNIÈRE NOTIFICATION DE COMPLETION
     */
    private function saveLastCompletionNotification(int $listId, Carbon $time): void
    {
        $cacheFile = __DIR__ . "/../../storage/completion_notification_{$listId}.txt";
        $storageDir = dirname($cacheFile);
        
        try {
            if (!is_dir($storageDir)) {
                mkdir($storageDir, 0755, true);
            }
            
            $success = file_put_contents($cacheFile, $time->getTimestamp());
            
            if ($success) {
                error_log(" Saved completion notification timestamp for list {$listId}");
            } else {
                error_log(" Failed to save completion notification timestamp for list {$listId}");
            }
            
        } catch (\Exception $e) {
            error_log(" Error saving completion notification timestamp for list {$listId}: " . $e->getMessage());
        }
    }

    /**
     *  NETTOYER LES ANCIENS FICHIERS CACHE
     */
    public function cleanupOldNotificationFiles(): int
    {
        $cleaned = 0;
        $storageDir = __DIR__ . "/../../storage";
        
        if (!is_dir($storageDir)) {
            return 0;
        }
        
        try {
            $files = glob($storageDir . "/completion_notification_*.txt");
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
            error_log("Error cleaning completion notification files: " . $e->getMessage());
        }
        
        return $cleaned;
    }

    /**
     *  FORCER L'ENVOI D'UNE NOTIFICATION POUR DEBUG
     */
    public function forceTestNotification(int $listId): array
    {
        try {
            $list = ShoppingList::with(['items', 'receipts', 'user', 'user.currency'])->find($listId);
            
            if (!$list) {
                return [
                    'success' => false,
                    'error' => 'List not found'
                ];
            }
            
            // Supprimer temporairement le cache pour permettre l'envoi
            $cacheFile = __DIR__ . "/../../storage/completion_notification_{$listId}.txt";
            if (file_exists($cacheFile)) {
                unlink($cacheFile);
                error_log(" Removed cache file for list {$listId} to allow forced notification");
            }
            
            $sent = $this->sendCompletionNotification($list);
            
            return [
                'success' => $sent,
                'list_id' => $list->id,
                'list_name' => $list->name,
                'user_email' => $list->user->email ?? 'Unknown',
                'user_currency' => $list->user->getPreferredCurrency()->code ?? 'Unknown',
                'estimated_total' => $this->calculateEstimatedTotal($list),
                'formatted_total' => $list->user->formatAmount($this->calculateEstimatedTotal($list))
            ];
            
        } catch (\Exception $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     *  NOUVELLE MÉTHODE: Envoyer notification de partage de liste AVEC DEVISE
     */
    public function sendListSharingNotification(ShoppingList $list, User $sharedWithUser, User $sharedByUser): bool
    {
        try {
            error_log(" Sending list sharing notification for list {$list->id} to user {$sharedWithUser->id}");
            
            //  CORRECTION: Utiliser la méthode spécialisée du NotificationService
            return $this->notificationService->sendListSharingNotification($sharedWithUser, $list, $sharedByUser);
            
        } catch (\Exception $e) {
            error_log(" Error sending list sharing notification: " . $e->getMessage());
            return false;
        }
    }

    /**
     *  NOUVELLE MÉTHODE: Envoyer notification de mise à jour de liste partagée AVEC DEVISE
     */
    public function sendSharedListUpdateNotification(ShoppingList $list, User $updatedByUser, string $updateType = 'item_added'): bool
    {
        try {
            // Récupérer tous les utilisateurs qui partagent cette liste (sauf celui qui l'a modifiée)
            $sharedUsers = collect();
            
            // Si la liste a des partages, récupérer les utilisateurs concernés
            if (method_exists($list, 'sharedWith')) {
                $sharedUsers = $list->sharedWith()->where('user_id', '!=', $updatedByUser->id)->get();
            }
            
            $sentCount = 0;
            
            foreach ($sharedUsers as $user) {
                //  CORRECTION: Utiliser la méthode spécialisée du NotificationService
                $success = $this->notificationService->sendSharedListUpdateNotification($user, $list, $updatedByUser, $updateType);

                if ($success) {
                    $sentCount++;
                }
            }
            
            error_log(" Sent shared list update notifications to {$sentCount} users");
            return $sentCount > 0;
            
        } catch (\Exception $e) {
            error_log(" Error sending shared list update notification: " . $e->getMessage());
            return false;
        }
    }
}