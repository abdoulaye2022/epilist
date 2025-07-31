<?php
// app/Services/MobileNotificationService.php - VERSION DEBUG

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
        
        echo "    FCM Key configured: " . ($this->fcmServerKey ? "YES" : "NO") . "\n";
        echo "    APNS Key configured: " . ($this->apnsKeyPath ? "YES" : "NO") . "\n";
    }

    /**
     * ✅ ENVOYER NOTIFICATION PUSH BUDGET - VERSION DEBUG
     */
    public function sendBudgetAlert(User $user, Budget $budget, string $alertType): bool
    {
        echo "      → sendBudgetAlert called for user {$user->id}, budget {$budget->id}\n";
        
        // Charger les appareils avec relation
        $devices = $user->load('activeDevices')->activeDevices;
        echo "      → Found {$devices->count()} active devices for user\n";
        
        if ($devices->isEmpty()) {
            echo "      → ERROR: No active devices found for user {$user->id}\n";
            return false;
        }

        $notificationData = $this->prepareBudgetNotification($budget, $alertType);
        echo "      → Notification prepared: {$notificationData['title']}\n";
        
        $sentCount = 0;
        foreach ($devices as $device) {
            echo "        → Trying device {$device->id} ({$device->platform})\n";
            echo "          Push token: " . substr($device->push_token ?? 'NULL', 0, 20) . "...\n";
            echo "          Can receive notifications: " . ($device->canReceiveNotifications() ? 'YES' : 'NO') . "\n";
            
            if (!$device->canReceiveNotifications()) {
                echo "          ❌ Device cannot receive notifications\n";
                continue;
            }
            
            try {
                $result = false;
                
                if ($device->platform === 'android') {
                    echo "          → Sending via FCM...\n";
                    $result = $this->sendFCMNotification($device, $notificationData);
                } elseif ($device->platform === 'ios') {
                    echo "          → Sending via APNS...\n";
                    $result = $this->sendAPNSNotification($device, $notificationData);
                } else {
                    echo "          ❌ Unknown platform: {$device->platform}\n";
                    continue;
                }
                
                if ($result) {
                    $sentCount++;
                    echo "          ✅ SUCCESS\n";
                    $this->logNotificationSent($user->id, $budget->id, $device->id, $alertType);
                } else {
                    echo "          ❌ FAILED\n";
                }
            } catch (\Exception $e) {
                echo "          ❌ EXCEPTION: " . $e->getMessage() . "\n";
            }
        }
        
        echo "      → Total sent: {$sentCount}/{$devices->count()}\n";
        return $sentCount > 0;
    }

    /**
     * ✅ ENVOYER NOTIFICATION FIREBASE (ANDROID) - VERSION FCM v1
     */
    private function sendFCMNotification(UserDevice $device, array $notificationData): bool
    {
        if (!$this->fcmServerKey) {
            echo "            ❌ FCM Server Key not configured\n";
            return false;
        }

        echo "            → Preparing FCM v1 payload...\n";

        // ✅ NOUVEAU FORMAT FCM v1
        $fcmPayload = [
            'message' => [
                'token' => $device->push_token,
                'notification' => [
                    'title' => $notificationData['title'],
                    'body' => $notificationData['body'],
                ],
                'data' => array_map('strval', array_merge($notificationData['data'], [
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    'timestamp' => (string) Carbon::now()->timestamp
                ])),
                'android' => [
                    'priority' => $notificationData['priority'] === 'high' ? 'high' : 'normal',
                    'notification' => [
                        'icon' => $notificationData['icon'] ?? 'ic_notification',
                        'color' => '#FF6B35',
                        'sound' => $notificationData['sound'] ?? 'default',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'tag' => 'budget_alert',
                        'channel_id' => 'budget_alerts'
                    ]
                ]
            ]
        ];

        echo "            → FCM v1 Payload: " . json_encode($fcmPayload, JSON_PRETTY_PRINT) . "\n";

        // ✅ OBTENIR ACCESS TOKEN OAUTH2
        $accessToken = $this->getFCMAccessToken();
        if (!$accessToken) {
            echo "            ❌ Failed to get FCM access token\n";
            return false;
        }

        $headers = [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json'
        ];

        // ✅ NOUVELLE URL FCM v1
        $projectId = $_ENV['FIREBASE_PROJECT_ID'] ?? 'epilist-app'; // Ajoutez votre project ID
        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        echo "            → Sending to FCM v1: {$url}\n";

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fcmPayload));
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);

        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        echo "            → HTTP Code: {$httpCode}\n";
        echo "            → Response: {$result}\n";
        
        if ($curlError) {
            echo "            → CURL Error: {$curlError}\n";
        }

        if ($httpCode === 200) {
            $response = json_decode($result, true);
            if (isset($response['name'])) {
                echo "            → FCM Success! Message name: " . $response['name'] . "\n";
                return true;
            }
        }

        echo "            ❌ FCM Error: HTTP {$httpCode}\n";
        return false;
    }

    /**
     * ✅ OBTENIR ACCESS TOKEN OAUTH2 POUR FCM v1
     */
    private function getFCMAccessToken(): ?string
    {
        try {
            // Méthode 1: Utiliser le service account JSON
            $serviceAccountPath = __DIR__ . '/../../service-account.json';
            
            if (!file_exists($serviceAccountPath)) {
                echo "            ❌ Service account file not found: {$serviceAccountPath}\n";
                return null;
            }

            $serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
            
            if (!$serviceAccount) {
                echo "            ❌ Invalid service account JSON\n";
                return null;
            }

            // Générer JWT
            $header = json_encode(['typ' => 'JWT', 'alg' => 'RS256']);
            $now = time();
            $payload = json_encode([
                'iss' => $serviceAccount['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600
            ]);

            $base64Header = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
            $base64Payload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
            
            $signature = '';
            $privateKey = openssl_pkey_get_private($serviceAccount['private_key']);
            openssl_sign($base64Header . '.' . $base64Payload, $signature, $privateKey, OPENSSL_ALGO_SHA256);
            openssl_free_key($privateKey);
            
            $base64Signature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
            $jwt = $base64Header . '.' . $base64Payload . '.' . $base64Signature;

            // Échanger JWT contre access token
            $tokenData = [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt
            ];

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($tokenData));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);

            $result = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode === 200) {
                $response = json_decode($result, true);
                if (isset($response['access_token'])) {
                    echo "            ✅ Got FCM access token\n";
                    return $response['access_token'];
                }
            }

            echo "            ❌ Failed to get access token: HTTP {$httpCode}, Response: {$result}\n";
            return null;

        } catch (\Exception $e) {
            echo "            ❌ Exception getting access token: " . $e->getMessage() . "\n";
            return null;
        }
    }

    /**
     * ✅ ENVOYER NOTIFICATION APNS (iOS) - VERSION DEBUG
     */
    private function sendAPNSNotification(UserDevice $device, array $notificationData): bool
    {
        echo "            → APNS not fully implemented yet\n";
        return false; // Pour l'instant, retourner false pour iOS
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
                
            default:
                return [
                    'title' => '💰 Budget',
                    'body' => "Mise à jour du budget \"{$budget->name}\"",
                    'icon' => 'budget_info',
                    'sound' => 'default',
                    'priority' => 'normal',
                    'data' => [
                        'type' => 'budget_info',
                        'budget_id' => $budget->id,
                        'budget_name' => $budget->name,
                        'action' => 'open_budget_details'
                    ]
                ];
        }
    }

    // ... autres méthodes restent identiques ...
    
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

    private function logNotificationSent(int $userId, int $budgetId, int $deviceId, string $type): void
    {
        error_log("Notification sent - User: {$userId}, Budget: {$budgetId}, Device: {$deviceId}, Type: {$type}");
    }
}