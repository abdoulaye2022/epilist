<?php
// app/Services/MobileNotificationService.php

namespace App\Services;

use App\Models\User;
use App\Models\Budget;
use App\Models\UserDevice;
use Carbon\Carbon;

class MobileNotificationService
{
    private $fcmServerKey;
    private $apnsKeyPath;
    
    public function __construct()
    {
        $this->fcmServerKey = $_ENV['FCM_SERVER_KEY'] ?? null;
        $this->apnsKeyPath = $_ENV['APNS_KEY_PATH'] ?? null;
    }

    /**
     * ✅ ENVOYER NOTIFICATION PUSH BUDGET
     */
    public function sendBudgetAlert(User $user, Budget $budget, string $alertType): bool
    {
        $devices = $user->activeDevices;
        
        if ($devices->isEmpty()) {
            error_log("No active devices found for user {$user->id}");
            return false;
        }

        $notificationData = $this->prepareBudgetNotification($budget, $alertType);
        
        $sentCount = 0;
        foreach ($devices as $device) {
            try {
                if ($device->platform === 'android') {
                    $result = $this->sendFCMNotification($device, $notificationData);
                } elseif ($device->platform === 'ios') {
                    $result = $this->sendAPNSNotification($device, $notificationData);
                } else {
                    continue;
                }
                
                if ($result) {
                    $sentCount++;
                    $this->logNotificationSent($user->id, $budget->id, $device->id, $alertType);
                }
            } catch (\Exception $e) {
                error_log("Failed to send notification to device {$device->id}: " . $e->getMessage());
            }
        }
        
        return $sentCount > 0;
    }

    /**
     * ✅ PRÉPARER LE CONTENU DE LA NOTIFICATION BUDGET
     */
    private function prepareBudgetNotification(Budget $budget, string $alertType): array
    {
        $spentPercentage = round($budget->getSpentPercentage(), 1);
        $currency = $budget->user->getPreferredCurrency();
        $remainingAmount = $budget->getRemainingAmount();
        
        switch ($alertType) {
            case 'exceeded':
                $overspent = $budget->getSpentAmount() - $budget->budget_amount;
                return [
                    'title' => '🚨 Budget Dépassé!',
                    'body' => "Vous avez dépassé le budget \"{$budget->name}\" de {$currency->formatAmount($overspent)}",
                    'icon' => 'budget_exceeded',
                    'sound' => 'budget_alert',
                    'priority' => 'high',
                    'data' => [
                        'type' => 'budget_exceeded',
                        'budget_id' => $budget->id,
                        'budget_name' => $budget->name,
                        'spent_percentage' => $spentPercentage,
                        'overspent_amount' => round($overspent, 2),
                        'formatted_overspent' => $currency->formatAmount($overspent),
                        'action' => 'open_budget_details'
                    ]
                ];
                
            case 'warning':
                return [
                    'title' => '⚠️ Attention Budget',
                    'body' => "Vous avez utilisé {$spentPercentage}% du budget \"{$budget->name}\". Reste: {$currency->formatAmount($remainingAmount)}",
                    'icon' => 'budget_warning',
                    'sound' => 'budget_warning',
                    'priority' => 'normal',
                    'data' => [
                        'type' => 'budget_warning',
                        'budget_id' => $budget->id,
                        'budget_name' => $budget->name,
                        'spent_percentage' => $spentPercentage,
                        'remaining_amount' => round($remainingAmount, 2),
                        'formatted_remaining' => $currency->formatAmount($remainingAmount),
                        'action' => 'open_budget_details'
                    ]
                ];
                
            case 'daily_summary':
                $todaySpent = $this->getTodaySpent($budget);
                return [
                    'title' => '📊 Résumé Budget',
                    'body' => "Aujourd'hui: {$currency->formatAmount($todaySpent)} • Budget \"{$budget->name}\": {$spentPercentage}% utilisé",
                    'icon' => 'budget_summary',
                    'sound' => 'default',
                    'priority' => 'low',
                    'data' => [
                        'type' => 'budget_summary',
                        'budget_id' => $budget->id,
                        'budget_name' => $budget->name,
                        'today_spent' => round($todaySpent, 2),
                        'spent_percentage' => $spentPercentage,
                        'action' => 'open_budget_dashboard'
                    ]
                ];
        }
    }

    /**
     * ✅ ENVOYER NOTIFICATION FIREBASE (ANDROID)
     */
    private function sendFCMNotification(UserDevice $device, array $notificationData): bool
    {
        if (!$this->fcmServerKey) {
            error_log("FCM Server Key not configured");
            return false;
        }

        $fcmPayload = [
            'to' => $device->push_token,
            'notification' => [
                'title' => $notificationData['title'],
                'body' => $notificationData['body'],
                'icon' => $notificationData['icon'] ?? 'ic_notification',
                'sound' => $notificationData['sound'] ?? 'default',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'color' => '#FF6B35',
                'tag' => 'budget_alert'
            ],
            'data' => array_merge($notificationData['data'], [
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'timestamp' => Carbon::now()->timestamp
            ]),
            'priority' => $notificationData['priority'] === 'high' ? 'high' : 'normal',
            'content_available' => true
        ];

        $headers = [
            'Authorization: key=' . $this->fcmServerKey,
            'Content-Type: application/json'
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fcmPayload));
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode === 200) {
            $response = json_decode($result, true);
            return isset($response['success']) && $response['success'] > 0;
        }

        error_log("FCM Error: HTTP {$httpCode}, Response: {$result}");
        return false;
    }

    /**
     * ✅ ENVOYER NOTIFICATION APNS (iOS)
     */
    private function sendAPNSNotification(UserDevice $device, array $notificationData): bool
    {
        if (!$this->apnsKeyPath) {
            error_log("APNS Key Path not configured");
            return false;
        }

        $apnsPayload = [
            'aps' => [
                'alert' => [
                    'title' => $notificationData['title'],
                    'body' => $notificationData['body']
                ],
                'sound' => $notificationData['sound'] ?? 'default',
                'badge' => $this->getBadgeCount($device->user_id),
                'category' => 'budget_alert',
                'content-available' => 1
            ],
            'data' => array_merge($notificationData['data'], [
                'timestamp' => Carbon::now()->timestamp
            ])
        ];

        // Utiliser une librairie APNS (par exemple pusher/pusher-push-notifications)
        // ou curl avec certificats
        
        try {
            // Exemple avec curl (vous devrez configurer les certificats)
            $url = $_ENV['APP_ENV'] === 'production' 
                ? 'https://api.push.apple.com/3/device/' 
                : 'https://api.development.push.apple.com/3/device/';
            
            $url .= $device->push_token;

            $headers = [
                'Authorization: bearer ' . $this->generateAPNSJWT(),
                'Content-Type: application/json',
                'apns-topic: ' . $_ENV['APNS_BUNDLE_ID'],
                'apns-priority: ' . ($notificationData['priority'] === 'high' ? '10' : '5')
            ];

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($apnsPayload));
            curl_setopt($ch, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2_0);

            $result = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            return $httpCode === 200;
        } catch (\Exception $e) {
            error_log("APNS Error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * ✅ NOTIFICATIONS PROGRAMMÉES
     */
    public function scheduleNotifications(): void
    {
        // Notification quotidienne de résumé budget (9h du matin)
        $this->scheduleDailySummary();
        
        // Vérification des budgets qui arrivent à échéance (3 jours avant)
        $this->checkExpiringBudgets();
        
        // Rappel hebdomadaire pour ceux qui n'ont pas de budget actif
        $this->remindNoBudget();
    }

    /**
     * ✅ RÉSUMÉ QUOTIDIEN DES BUDGETS
     */
    private function scheduleDailySummary(): void
    {
        $now = Carbon::now();
        
        // Seulement à 9h du matin
        if ($now->hour !== 9 || $now->minute > 30) {
            return;
        }

        $activeUsers = User::whereHas('activeBudgets')->get();
        
        foreach ($activeUsers as $user) {
            if (!$user->hasNotificationPreference('daily_budget_summary')) {
                continue;
            }

            $budgets = $user->activeBudgets()->get();
            $alertBudgets = $budgets->filter(fn($b) => $b->shouldShowAlert());
            
            if ($alertBudgets->isNotEmpty()) {
                foreach ($alertBudgets as $budget) {
                    $this->sendBudgetAlert($user, $budget, 'daily_summary');
                }
            }
        }
    }

    /**
     * ✅ ALERTES BUDGETS EXPIRANT BIENTÔT
     */
    private function checkExpiringBudgets(): void
    {
        $threeDaysFromNow = Carbon::now()->addDays(3);
        
        $expiringBudgets = Budget::active()
            ->current()
            ->whereDate('end_date', $threeDaysFromNow->toDateString())
            ->with(['user'])
            ->get();

        foreach ($expiringBudgets as $budget) {
            $this->sendBudgetExpirationNotification($budget);
        }
    }

    /**
     * ✅ NOTIFICATION D'EXPIRATION DE BUDGET
     */
    private function sendBudgetExpirationNotification(Budget $budget): bool
    {
        $user = $budget->user;
        $devices = $user->activeDevices;
        
        if ($devices->isEmpty()) {
            return false;
        }

        $daysLeft = $budget->getDaysRemaining();
        $spentPercentage = round($budget->getSpentPercentage(), 1);
        
        $notificationData = [
            'title' => '⏰ Budget se termine bientôt',
            'body' => "Le budget \"{$budget->name}\" se termine dans {$daysLeft} jour(s). Vous avez utilisé {$spentPercentage}%",
            'icon' => 'budget_expiring',
            'sound' => 'default',
            'priority' => 'normal',
            'data' => [
                'type' => 'budget_expiring',
                'budget_id' => $budget->id,
                'budget_name' => $budget->name,
                'days_remaining' => $daysLeft,
                'spent_percentage' => $spentPercentage,
                'action' => 'renew_budget'
            ]
        ];

        $sentCount = 0;
        foreach ($devices as $device) {
            try {
                if ($device->platform === 'android') {
                    $result = $this->sendFCMNotification($device, $notificationData);
                } elseif ($device->platform === 'ios') {
                    $result = $this->sendAPNSNotification($device, $notificationData);
                }
                
                if ($result) {
                    $sentCount++;
                }
            } catch (\Exception $e) {
                error_log("Failed to send expiration notification: " . $e->getMessage());
            }
        }
        
        return $sentCount > 0;
    }

    /**
     * ✅ NOTIFICATION INSTANTANÉE LORS D'ACHAT
     */
    public function sendPurchaseNotification(User $user, Budget $budget, float $purchaseAmount): bool
    {
        if (!$budget->shouldShowAlert()) {
            return false;
        }

        $alertType = $budget->isExceeded() ? 'exceeded' : 'warning';
        return $this->sendBudgetAlert($user, $budget, $alertType);
    }

    /**
     * ✅ HELPER METHODS
     */
    private function getTodaySpent(Budget $budget): float
    {
        $today = Carbon::now()->toDateString();
        
        if ($budget->list_id) {
            return \App\Models\ListReceipt::where('list_id', $budget->list_id)
                ->whereDate('purchase_date', $today)
                ->sum('total_amount');
        } else {
            $userLists = \App\Models\ShoppingList::accessibleBy($budget->user_id)->pluck('id');
            return \App\Models\ListReceipt::whereIn('list_id', $userLists)
                ->whereDate('purchase_date', $today)
                ->sum('total_amount');
        }
    }

    private function getBadgeCount(int $userId): int
    {
        // Retourner le nombre de notifications non lues pour iOS badge
        return \App\Models\Budget::forUser($userId)
            ->active()
            ->current()
            ->get()
            ->filter(fn($b) => $b->shouldShowAlert())
            ->count();
    }

    private function generateAPNSJWT(): string
    {
        // Générer le JWT pour APNS avec votre clé privée
        // Utilisez une librairie comme firebase/php-jwt
        // Retourner le token JWT signé
        return 'your_jwt_token_here';
    }

    private function logNotificationSent(int $userId, int $budgetId, int $deviceId, string $type): void
    {
        // Optionnel: Logger les notifications envoyées pour analytics
        error_log("Notification sent - User: {$userId}, Budget: {$budgetId}, Device: {$deviceId}, Type: {$type}");
    }
}