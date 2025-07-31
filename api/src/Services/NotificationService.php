<?php
// app/Services/NotificationService.php - VERSION NETTOYÉE

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\ApnsConfig;
use App\Models\UserDevice;
use App\Models\User;
use Carbon\Carbon;

class NotificationService
{
    protected $messaging;
    
    // ✅ CONSTANTES TYPES DE NOTIFICATIONS
    const TYPE_BUDGET_ALERT = 'budget_alert';
    const TYPE_BUDGET_WARNING = 'budget_warning';
    const TYPE_BUDGET_EXCEEDED = 'budget_exceeded';
    const TYPE_LIST_SHARED = 'list_shared';
    const TYPE_LIST_UPDATED = 'list_updated';
    const TYPE_PURCHASE_REMINDER = 'purchase_reminder';
    const TYPE_DAILY_SUMMARY = 'daily_summary';

    public function __construct()
    {
        try {
            $serviceAccountPath = __DIR__ . '/../../service-account.json';
            
            if (!file_exists($serviceAccountPath)) {
                throw new \Exception("Service account file not found: {$serviceAccountPath}");
            }
            
            $factory = (new Factory)->withServiceAccount($serviceAccountPath);
            $this->messaging = $factory->createMessaging();
            
        } catch (\Exception $e) {
            error_log("Firebase initialization failed: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * ✅ MÉTHODE PRINCIPALE: Envoyer une notification à un appareil
     */
    public function sendEpiListNotification(
        UserDevice $device,
        string $type,
        string $title,
        string $body,
        array $data = [],
        string $priority = 'normal'
    ): bool {
        try {
            // Vérifier que l'appareil peut recevoir des notifications
            if (!$device->canReceiveNotifications()) {
                return false;
            }

            $token = $device->push_token;

            // Préparer les données de base
            $notificationData = array_merge([
                'type' => $type,
                'timestamp' => Carbon::now()->timestamp,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ], $data);

            // Créer le message de base
            $message = CloudMessage::withTarget('token', $token)
                ->withNotification(Notification::create($title, $body))
                ->withData($notificationData);

            // Configuration Android
            if ($device->platform === 'android') {
                $androidConfig = [
                    'priority' => $priority === 'high' ? 'high' : 'normal',
                    'notification' => [
                        'icon' => 'ic_notification',
                        'color' => '#4CAF50', // Vert EpiList
                        'sound' => $this->getNotificationSound($type),
                        'channel_id' => $this->getChannelId($type),
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'tag' => $type
                    ]
                ];
                $message = $message->withAndroidConfig(AndroidConfig::fromArray($androidConfig));
            }

            // Configuration iOS
            if ($device->platform === 'ios') {
                $apnsConfig = [
                    'headers' => [
                        'apns-priority' => $priority === 'high' ? '10' : '5',
                        'apns-push-type' => 'alert'
                    ],
                    'payload' => [
                        'aps' => [
                            'alert' => [
                                'title' => $title,
                                'body' => $body
                            ],
                            'sound' => $this->getNotificationSound($type),
                            'badge' => $this->getBadgeCount($device->user_id),
                            'category' => $type,
                            'content-available' => 1
                        ]
                    ]
                ];
                $message = $message->withApnsConfig(ApnsConfig::fromArray($apnsConfig));
            }

            // Envoyer la notification
            $result = $this->messaging->send($message);
            
            // Marquer l'appareil comme actif
            $device->markAsActive();
            
            return true;

        } catch (\Exception $e) {
            error_log("Failed to send notification to device {$device->id}: " . $e->getMessage());
            return false;
        }
    }

    /**
     * ✅ MÉTHODE PRINCIPALE: Envoyer à tous les appareils d'un utilisateur
     */
    public function sendToUser(
        int $userId,
        string $type,
        string $title,
        string $body,
        array $data = [],
        string $priority = 'normal'
    ): array {
        $devices = UserDevice::forUser($userId)
            ->canReceiveNotifications()
            ->get();

        if ($devices->isEmpty()) {
            return [
                'success' => false,
                'message' => 'No active devices found for user',
                'sent_count' => 0,
                'total_devices' => 0
            ];
        }

        $sentCount = 0;
        $errors = [];

        foreach ($devices as $device) {
            try {
                $success = $this->sendEpiListNotification(
                    $device,
                    $type,
                    $title,
                    $body,
                    $data,
                    $priority
                );

                if ($success) {
                    $sentCount++;
                } else {
                    $errors[] = "Failed to send to device {$device->id}";
                }
            } catch (\Exception $e) {
                $errors[] = "Error with device {$device->id}: " . $e->getMessage();
            }
        }

        return [
            'success' => $sentCount > 0,
            'sent_count' => $sentCount,
            'total_devices' => $devices->count(),
            'errors' => $errors
        ];
    }

    /**
     * ✅ MÉTHODE SPÉCIALISÉE: Envoyer alerte budget
     */
    public function sendBudgetAlert(User $user, $budget, string $alertType): bool
    {
        $title = $this->getBudgetAlertTitle($alertType);
        $body = $this->getBudgetAlertBody($budget, $alertType);
        
        $data = [
            'budget_id' => (string) $budget->id,
            'budget_name' => $budget->name,
            'alert_type' => $alertType,
            'action' => 'open_budget_details'
        ];

        $result = $this->sendToUser(
            $user->id,
            self::TYPE_BUDGET_ALERT,
            $title,
            $body,
            $data,
            $alertType === 'exceeded' ? 'high' : 'normal'
        );

        return $result['success'];
    }

    /**
     * ✅ MÉTHODES UTILITAIRES
     */
    private function getNotificationSound(string $type): string
    {
        return match($type) {
            self::TYPE_BUDGET_EXCEEDED => 'budget_alert',
            self::TYPE_BUDGET_WARNING => 'budget_warning',
            self::TYPE_LIST_SHARED => 'list_shared',
            self::TYPE_PURCHASE_REMINDER => 'reminder',
            default => 'default'
        };
    }

    private function getChannelId(string $type): string
    {
        return match($type) {
            self::TYPE_BUDGET_ALERT,
            self::TYPE_BUDGET_WARNING,
            self::TYPE_BUDGET_EXCEEDED => 'budget_alerts',
            self::TYPE_LIST_SHARED,
            self::TYPE_LIST_UPDATED => 'list_updates',
            self::TYPE_PURCHASE_REMINDER => 'reminders',
            default => 'general'
        };
    }

    private function getBudgetAlertTitle(string $alertType): string
    {
        return match($alertType) {
            'exceeded' => '🚨 Budget Dépassé!',
            'warning' => '⚠️ Attention Budget',
            'daily_summary' => '📊 Résumé Budget',
            default => '💰 Budget'
        };
    }

    private function getBudgetAlertBody($budget, string $alertType): string
    {
        $spentPercentage = round($budget->getSpentPercentage(), 1);
        
        return match($alertType) {
            'exceeded' => "Vous avez dépassé le budget \"{$budget->name}\"",
            'warning' => "Vous avez utilisé {$spentPercentage}% du budget \"{$budget->name}\"",
            'daily_summary' => "Résumé du budget \"{$budget->name}\": {$spentPercentage}% utilisé",
            default => "Mise à jour du budget \"{$budget->name}\""
        };
    }

    private function getBadgeCount(int $userId): int
    {
        return \App\Models\Budget::forUser($userId)
            ->active()
            ->get()
            ->filter(fn($b) => $b->shouldShowAlert())
            ->count();
    }
}