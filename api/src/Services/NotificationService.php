<?php
// app/Services/NotificationService.php - VERSION CORRIGÉE AVEC FIX DE LA CONVERSION FLOAT VERS INT

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\ApnsConfig;
use App\Models\UserDevice;
use App\Models\User;
use App\Models\Currency;
use App\Models\EmailPreference;
use Carbon\Carbon;

class NotificationService
{
    protected $messaging;
    
    //  CONSTANTES TYPES DE NOTIFICATIONS
    const TYPE_BUDGET_ALERT = 'budget_alert';
    const TYPE_BUDGET_WARNING = 'budget_warning';
    const TYPE_BUDGET_EXCEEDED = 'budget_exceeded';
    const TYPE_LIST_SHARED = 'list_shared';
    const TYPE_LIST_UPDATED = 'list_updated';
    const TYPE_PURCHASE_REMINDER = 'purchase_reminder';
    const TYPE_DAILY_SUMMARY = 'daily_summary';
    const TYPE_USER_INACTIVE = 'user_inactive';
    const TYPE_LIST_COMPLETED = 'list_completed';
    const TYPE_WEEKLY_LIST_REMINDER = 'weekly_list_reminder';
    const TYPE_DAILY_LIST_REMINDER = 'daily_list_reminder';
    const TYPE_NEW_MESSAGE = 'new_message';

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
     * ✅ NOUVELLE MÉTHODE: Obtenir la langue de l'utilisateur (français par défaut)
     */
    private function getUserLanguage(User $user): string
    {
        // Vérifier si l'utilisateur a une langue définie
        if (isset($user->language) && in_array($user->language, ['fr', 'en'])) {
            return $user->language;
        }

        // Par défaut: français
        return 'fr';
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Vérifier si l'utilisateur accepte ce type de notification
     * Mapping des types de notifications vers les préférences email
     */
    private function canSendNotification(User $user, string $notificationType): bool
    {
        // Mapping des types de notifications vers les colonnes de préférences
        $preferenceMap = [
            self::TYPE_BUDGET_ALERT => 'budget_alert',
            self::TYPE_BUDGET_WARNING => 'budget_alert',
            self::TYPE_BUDGET_EXCEEDED => 'budget_alert',
            self::TYPE_DAILY_SUMMARY => 'budget_summary',
            self::TYPE_LIST_COMPLETED => 'list_completed',
            self::TYPE_LIST_SHARED => 'list_shared_with_me',
            self::TYPE_LIST_UPDATED => 'list_shared_with_me',
            self::TYPE_DAILY_LIST_REMINDER => 'tips_and_tricks', // Rappels considérés comme tips
            self::TYPE_WEEKLY_LIST_REMINDER => 'tips_and_tricks',
            self::TYPE_USER_INACTIVE => 'tips_and_tricks',
            self::TYPE_NEW_MESSAGE => 'list_shared_with_me', // Messages dans listes partagées
        ];

        // Si le type n'est pas mappé, autoriser par défaut
        if (!isset($preferenceMap[$notificationType])) {
            return true;
        }

        $preferenceKey = $preferenceMap[$notificationType];

        // Vérifier les préférences de l'utilisateur
        return EmailPreference::isEmailEnabled($user->id, $preferenceKey);
    }

    /**
     *  NOUVELLE MÉTHODE: Formater un montant selon la devise de l'utilisateur
     */
    public function formatAmountForUser(float $amount, User $user, bool $showCode = false): string
    {
        try {
            //  S'assurer que $amount est bien un float
            $amount = (float) $amount;
            $currency = $user->getPreferredCurrency();
            
            //  Utiliser le formatage international de FormattedAmount
            return $this->formatAmountInternational($amount, $currency, $showCode);
            
        } catch (\Exception $e) {
            error_log("Error formatting amount for user {$user->id}: " . $e->getMessage());
            // Fallback: format CAD par défaut
            return '$' . number_format((float) $amount, 2);
        }
    }

    /**
     *  FORMATAGE INTERNATIONAL (même logique que FormattedAmount)
     */
    private function formatAmountInternational(float $amount, Currency $currency, bool $showCode = false): string
    {
        $code = strtoupper($currency->code);
        $decimals = $this->getDecimalsForCurrency($code);
        $formattedNumber = number_format($amount, $decimals);

        // Appliquer les séparateurs selon la région
        $localizedNumber = $this->applyLocalizedSeparators($formattedNumber, $code);

        // Appliquer le placement du symbole selon les normes internationales
        $result = $this->applySymbolPlacement($localizedNumber, $currency);
        
        if ($showCode) {
            $result .= ' ' . $code;
        }
        
        return $result;
    }

    /**
     *  Obtenir le nombre de décimales selon la norme ISO 4217
     */
    private function getDecimalsForCurrency(string $currencyCode): int
    {
        $decimals = match ($currencyCode) {
            // Devises sans décimales (0 décimales)
            'JPY', 'KRW', 'VND', 'CLP', 'ISK', 'XOF', 'XAF' => 0,

            // Devises avec 3 décimales
            'BHD', 'KWD', 'OMR', 'JOD', 'IQD', 'LYD', 'TND' => 3,

            // Toutes les autres devises (2 décimales - standard)
            default => 2
        };
        
        //  S'assurer explicitement que c'est un entier
        return (int) $decimals;
    }

    /**
     *  Appliquer les séparateurs localisés selon VOS devises
     */
    private function applyLocalizedSeparators(string $formattedNumber, string $currencyCode): string
    {
        // Séparer la partie entière et décimale
        $parts = explode('.', $formattedNumber);
        $integerPart = $parts[0];
        $decimalPart = isset($parts[1]) ? $parts[1] : '';

        // Déterminer les séparateurs selon VOS devises en base
        $thousandSeparator = ',';
        $decimalSeparator = '.';

        //  Régions utilisant virgule comme séparateur décimal selon VOTRE base
        $commaDecimalCountries = [
            'EUR',    // Euro (Europe)
            'CHF',    // Franc suisse
            'MAD',    // Dirham marocain (influence française)
            'TND',    // Dinar tunisien (influence française)
            'DZD',    // Dinar algérien (influence française)
            'XOF',    // Franc CFA BCEAO (influence française)
            'XAF',    // Franc CFA BEAC (influence française)
        ];

        if (in_array($currencyCode, $commaDecimalCountries)) {
            $thousandSeparator = ' '; // Espace pour les milliers (norme française/européenne)
            $decimalSeparator = ',';
        }

        //  Cas spéciaux pour certaines devises de votre base
        if (in_array($currencyCode, ['JPY', 'KRW'])) {
            // Pas de décimales, donc pas besoin de séparateur décimal
            $decimalPart = '';
        }

        // Ajouter les séparateurs de milliers
        $formattedInteger = $this->addThousandSeparators($integerPart, $thousandSeparator);

        // Reconstituer le nombre
        if (!empty($decimalPart)) {
            return $formattedInteger . $decimalSeparator . $decimalPart;
        }
        return $formattedInteger;
    }

    /**
     *  Ajouter les séparateurs de milliers
     */
    private function addThousandSeparators(string $number, string $separator): string
    {
        if (strlen($number) <= 3) return $number;

        $reversed = array_reverse(str_split($number));
        $result = [];

        for ($i = 0; $i < count($reversed); $i++) {
            if ($i > 0 && $i % 3 === 0) {
                $result[] = $separator;
            }
            $result[] = $reversed[$i];
        }

        return implode('', array_reverse($result));
    }

    /**
     *  Appliquer le placement du symbole selon VOS devises en base
     */
    private function applySymbolPlacement(string $formattedNumber, Currency $currency): string
    {
        $code = strtoupper($currency->code);
        $symbol = (string) $currency->symbol; //  Conversion explicite
        
        // Devises avec symbole APRÈS le montant (avec espace)
        $symbolAfterWithSpace = [
            'EUR', 'ZAR', 'XOF', 'XAF', 'MAD', 'TND', 'DZD', 'BWP'
        ];

        // Devises avec symbole AVANT le montant (avec espace) - symboles longs
        $symbolBeforeWithSpace = [
            'CHF', 'KES', 'UGX', 'GHS'
        ];

        // Devises avec symbole AVANT le montant (sans espace) - symboles courts
        $symbolBeforeNoSpace = [
            'USD', 'CAD', 'AUD', 'HKD', 'SGD', 'NAD', 'GBP', 'EGP', 
            'JPY', 'CNY', 'NGN', 'MUR', 'ETB'
        ];

        if (in_array($code, $symbolAfterWithSpace)) {
            return $formattedNumber . ' ' . $symbol;
        } elseif (in_array($code, $symbolBeforeWithSpace)) {
            return $symbol . ' ' . $formattedNumber;
        } elseif (in_array($code, $symbolBeforeNoSpace)) {
            return $symbol . $formattedNumber;
        } else {
            // Fallback: symbole avant sans espace (standard)
            return $symbol . $formattedNumber;
        }
    }

    /**
     *  MÉTHODE PRINCIPALE: Envoyer une notification à un appareil - VERSION CORRIGÉE
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
                error_log("Device {$device->id} cannot receive notifications");
                return false;
            }

            $token = $device->push_token;

            //  CORRECTION: Nettoyer les données pour éviter les arrays dans les valeurs
            $cleanData = $this->cleanNotificationData($data);

            // Préparer les données de base - TOUTES LES VALEURS DOIVENT ÊTRE DES STRINGS
            $notificationData = array_merge([
                'type' => (string) $type,
                'timestamp' => (string) Carbon::now()->timestamp,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ], $cleanData);

            //  LOG POUR DEBUG
            error_log(" Sending notification to device {$device->id}");
            error_log(" Notification data: " . json_encode($notificationData));

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
            
            error_log(" Notification sent successfully to device {$device->id}");
            return true;

        } catch (\Exception $e) {
            error_log(" Failed to send notification to device {$device->id}: " . $e->getMessage());
            error_log(" Stack trace: " . $e->getTraceAsString());
            return false;
        }
    }

    /**
     *  NOUVELLE MÉTHODE: Nettoyer les données de notification
     */
    private function cleanNotificationData(array $data): array
    {
        $cleanData = [];
        
        foreach ($data as $key => $value) {
            if (is_array($value)) {
                //  CORRECTION: Convertir les arrays en JSON strings
                $cleanData[$key] = json_encode($value);
                error_log(" Converted array to JSON for key '{$key}': " . $cleanData[$key]);
            } elseif (is_bool($value)) {
                // Convertir les booleans en strings
                $cleanData[$key] = $value ? 'true' : 'false';
            } elseif (is_numeric($value)) {
                //  CORRECTION: Convertir les nombres en strings (source probable du problème)
                if (is_float($value)) {
                    $cleanData[$key] = number_format($value, 2, '.', ''); // Formatage pour éviter la perte de précision
                } else {
                    $cleanData[$key] = (string) $value;
                }
            } elseif (is_null($value)) {
                // Convertir null en string vide
                $cleanData[$key] = '';
            } else {
                // Garder les strings telles quelles
                $cleanData[$key] = (string) $value;
            }
        }
        
        return $cleanData;
    }

    /**
     *  MÉTHODE PRINCIPALE: Envoyer à tous les appareils d'un utilisateur
     */
    public function sendToUser(
        int $userId,
        string $type,
        string $title,
        string $body,
        array $data = [],
        string $priority = 'normal'
    ): array {
        error_log(" Sending notification to user {$userId}: '{$title}'");
        
        $devices = UserDevice::where('user_id', $userId)
            ->where('is_active', true)
            ->whereNotNull('push_token')
            ->get();

        error_log(" Found {$devices->count()} active devices for user {$userId}");

        if ($devices->isEmpty()) {
            error_log(" No active devices found for user {$userId}");
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
                    error_log(" Sent to device {$device->id}");
                } else {
                    $errors[] = "Failed to send to device {$device->id}";
                    error_log(" Failed to send to device {$device->id}");
                }
            } catch (\Exception $e) {
                $errors[] = "Error with device {$device->id}: " . $e->getMessage();
                error_log(" Error with device {$device->id}: " . $e->getMessage());
            }
        }

        $result = [
            'success' => $sentCount > 0,
            'sent_count' => $sentCount,
            'total_devices' => $devices->count(),
            'errors' => $errors
        ];

        error_log(" Final result for user {$userId}: " . json_encode($result));
        return $result;
    }

    /**
     *  MÉTHODE SPÉCIALISÉE: Envoyer notification de liste complétée - VERSION CORRIGÉE
     */
    public function sendListCompletionNotification(User $user, $list, float $estimatedTotal = 0): bool
    {
        // ✅ VÉRIFICATION DES PRÉFÉRENCES
        if (!$this->canSendNotification($user, self::TYPE_LIST_COMPLETED)) {
            error_log("🚫 User {$user->id} has disabled list completion notifications");
            return false;
        }

        $lang = $this->getUserLanguage($user);
        $totalItems = (int) $list->items->count(); //  Conversion explicite

        $title = $lang === 'en' ? "✅ List completed!" : "✅ Liste terminée !";
        $body = $this->getListCompletionBody($user, $list->name, $totalItems, $estimatedTotal, $lang);
        
        //  CORRECTION: Formater les montants selon la devise de l'utilisateur
        $formattedTotal = $this->formatAmountForUser($estimatedTotal, $user);
        
        $data = [
            'list_id' => (string) $list->id,
            'list_name' => (string) $list->name,
            'total_items' => (string) $totalItems,
            'estimated_total' => number_format($estimatedTotal, 2, '.', ''), //  Format string avec précision
            'formatted_total' => (string) $formattedTotal,
            'currency_code' => (string) $user->getPreferredCurrency()->code,
            'currency_symbol' => (string) $user->getPreferredCurrency()->symbol,
            'completion_type' => 'without_receipt',
            'action' => 'add_receipt'
        ];

        $result = $this->sendToUser(
            $user->id,
            self::TYPE_LIST_COMPLETED,
            $title,
            $body,
            $data,
            'normal'
        );

        return $result['success'];
    }

    /**
     *  MÉTHODE CORRIGÉE: Générer le message de completion avec devise
     */
    private function getListCompletionBody(User $user, string $listName, int $totalItems, float $estimatedTotal, string $lang = 'fr'): string
    {
        if ($lang === 'en') {
            $baseMessage = "Congrats! You completed your list \"{$listName}\" ({$totalItems} item" . ($totalItems > 1 ? 's' : '') . ")";

            if ($estimatedTotal > 0) {
                $formattedAmount = $this->formatAmountForUser($estimatedTotal, $user);
                $baseMessage .= " for about {$formattedAmount}";
            }

            $baseMessage .= ". Would you like to add a receipt for precise tracking?";

            return $baseMessage;
        }

        // Français
        $baseMessage = "Bravo ! Vous avez terminé votre liste \"{$listName}\" ({$totalItems} article" . ($totalItems > 1 ? 's' : '') . ")";

        if ($estimatedTotal > 0) {
            $formattedAmount = $this->formatAmountForUser($estimatedTotal, $user);
            $baseMessage .= " pour environ {$formattedAmount}";
        }

        $baseMessage .= ". Voulez-vous ajouter une facture pour un suivi précis ?";

        return $baseMessage;
    }

    /**
     *  MÉTHODE CORRIGÉE: Envoyer alertes budget avec devise
     */
    public function sendBudgetAlert(User $user, $budget, string $alertType): bool
    {
        // ✅ VÉRIFICATION DES PRÉFÉRENCES: Ne pas envoyer si l'utilisateur a désactivé les alertes budget
        $notificationType = $alertType === 'daily_summary' ? self::TYPE_DAILY_SUMMARY : self::TYPE_BUDGET_ALERT;
        if (!$this->canSendNotification($user, $notificationType)) {
            error_log("🚫 User {$user->id} has disabled budget alerts in preferences");
            return false;
        }

        // ✅ ANTI-SPAM: Vérifier le cooldown avant d'envoyer
        if (!$this->checkBudgetAlertCooldown($budget->id, $alertType)) {
            error_log("⏱️ Budget alert cooldown active for budget {$budget->id} ({$alertType})");
            return false;
        }

        // ✅ Obtenir la langue de l'utilisateur
        $lang = $this->getUserLanguage($user);

        $title = $this->getBudgetAlertTitle($alertType, $lang);
        $body = $this->getBudgetAlertBody($user, $budget, $alertType);

        //  Formater les montants selon la devise de l'utilisateur avec conversions explicites
        $budgetAmount = method_exists($budget, 'getBudgetAmount') ? (float) $budget->getBudgetAmount() : 0.0;
        $spentAmount = method_exists($budget, 'getSpentAmount') ? (float) $budget->getSpentAmount() : 0.0;
        $remainingAmount = $budgetAmount - $spentAmount;

        $data = [
            'budget_id' => (string) $budget->id,
            'budget_name' => (string) $budget->name,
            'alert_type' => (string) $alertType,
            'budget_amount' => number_format($budgetAmount, 2, '.', ''), //  Format string avec précision
            'spent_amount' => number_format($spentAmount, 2, '.', ''),   //  Format string avec précision
            'remaining_amount' => number_format($remainingAmount, 2, '.', ''), //  Format string avec précision
            'formatted_budget' => (string) $this->formatAmountForUser($budgetAmount, $user),
            'formatted_spent' => (string) $this->formatAmountForUser($spentAmount, $user),
            'formatted_remaining' => (string) $this->formatAmountForUser($remainingAmount, $user),
            'currency_code' => (string) $user->getPreferredCurrency()->code,
            'currency_symbol' => (string) $user->getPreferredCurrency()->symbol,
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

        // ✅ Sauvegarder le timestamp de cette alerte
        if ($result['success']) {
            $this->saveBudgetAlertTimestamp($budget->id, $alertType);
        }

        return $result['success'];
    }

    /**
     * ✅ NOUVEAU: Vérifier le cooldown des alertes budget
     * - Alertes "exceeded": max 1 par heure
     * - Alertes "warning": max 1 par 4 heures
     * - Alertes "daily_summary": max 1 par jour
     */
    private function checkBudgetAlertCooldown(int $budgetId, string $alertType): bool
    {
        $cacheFile = $this->getStoragePath() . "/alerts_{$budgetId}_{$alertType}.txt";

        if (!file_exists($cacheFile)) {
            return true; // Pas de cooldown, on peut envoyer
        }

        try {
            $timestamp = file_get_contents($cacheFile);

            if (!$timestamp || !is_numeric($timestamp)) {
                @unlink($cacheFile);
                return true;
            }

            $lastAlert = \Carbon\Carbon::createFromTimestamp($timestamp, 'UTC');
            $now = \Carbon\Carbon::now('UTC');
            $hoursSinceLastAlert = $lastAlert->diffInHours($now);

            // Définir le cooldown selon le type d'alerte
            $cooldownHours = match($alertType) {
                'exceeded' => 1,           // 1 heure pour budget dépassé
                'warning' => 4,            // 4 heures pour avertissement
                'daily_summary' => 24,     // 24 heures pour résumé quotidien
                default => 1
            };

            return $hoursSinceLastAlert >= $cooldownHours;

        } catch (\Exception $e) {
            error_log("Error checking budget alert cooldown: " . $e->getMessage());
            @unlink($cacheFile);
            return true;
        }
    }

    /**
     * ✅ NOUVEAU: Sauvegarder le timestamp de la dernière alerte
     */
    private function saveBudgetAlertTimestamp(int $budgetId, string $alertType): void
    {
        $cacheFile = $this->getStoragePath() . "/alerts_{$budgetId}_{$alertType}.txt";

        try {
            $storageDir = dirname($cacheFile);
            if (!is_dir($storageDir)) {
                mkdir($storageDir, 0755, true);
            }

            file_put_contents($cacheFile, \Carbon\Carbon::now('UTC')->getTimestamp());

        } catch (\Exception $e) {
            error_log("Error saving budget alert timestamp: " . $e->getMessage());
        }
    }

    /**
     * ✅ HELPER: Obtenir le chemin du dossier storage
     */
    private function getStoragePath(): string
    {
        return dirname(__DIR__, 2) . '/storage';
    }

    /**
     *  VERSION AVEC TOUS LES TESTS POSSIBLES
     */
    private function getBudgetAlertBody(User $user, $budget, string $alertType): string
    {
        //  DEBUG: Vérifier toutes les possibilités pour le montant budget
        error_log(" Debug getBudgetAlertBody for budget {$budget->id}:");
        error_log("  - Budget name: {$budget->name}");
        error_log("  - Budget object type: " . get_class($budget));
        
        // Lister TOUTES les propriétés de l'objet budget
        $budgetVars = get_object_vars($budget);
        error_log("  - Budget properties: " . json_encode(array_keys($budgetVars)));
        
        // Tester TOUTES les possibilités courantes pour le montant budget
        $budgetAmount = 0;
        $possibleBudgetFields = [
            'getBudgetAmount', 'getAmount', 'getTotalAmount', 'getTarget',
            'budget_amount', 'amount', 'total_amount', 'target_amount', 'limit_amount',
            'budgetAmount', 'totalAmount', 'targetAmount', 'limitAmount'
        ];
        
        foreach ($possibleBudgetFields as $field) {
            if (method_exists($budget, $field)) {
                $budgetAmount = $budget->$field();
                error_log("  -  Found method {$field}(): {$budgetAmount}");
                break;
            } elseif (property_exists($budget, $field) || isset($budget->$field)) {
                $budgetAmount = $budget->$field;
                error_log("  -  Found property {$field}: {$budgetAmount}");
                break;
            }
        }
        
        if ($budgetAmount == 0) {
            error_log("  -  No budget amount found in any standard field!");
            // Dump de toutes les valeurs pour debug
            foreach ($budgetVars as $key => $value) {
                if (is_numeric($value) && $value > 0) {
                    error_log("    Possible field: {$key} = {$value}");
                }
            }
        }
        
        // Tester pour le montant dépensé
        $spentAmount = 0;
        $possibleSpentFields = [
            'getSpentAmount', 'getUsedAmount', 'getCurrentAmount',
            'spent_amount', 'used_amount', 'current_amount',
            'spentAmount', 'usedAmount', 'currentAmount'
        ];
        
        foreach ($possibleSpentFields as $field) {
            if (method_exists($budget, $field)) {
                $spentAmount = $budget->$field();
                error_log("  -  Found spent method {$field}(): {$spentAmount}");
                break;
            } elseif (property_exists($budget, $field) || isset($budget->$field)) {
                $spentAmount = $budget->$field;
                error_log("  -  Found spent property {$field}: {$spentAmount}");
                break;
            }
        }
        
        // Calculer le pourcentage
        $spentPercentage = 0;
        if (method_exists($budget, 'getSpentPercentage')) {
            //  CORRECTION: Conversion explicite en float puis formatage
            $rawPercentage = (float) $budget->getSpentPercentage();
            $spentPercentage = number_format($rawPercentage, 1, '.', '');
            error_log("  - getSpentPercentage(): {$spentPercentage}%");
        } elseif ($budgetAmount > 0) {
            //  CORRECTION: Éviter round() qui peut retourner un float
            $rawPercentage = ($spentAmount / $budgetAmount) * 100;
            $spentPercentage = number_format($rawPercentage, 1, '.', '');
            error_log("  - Calculated percentage: {$spentPercentage}%");
        }
        
        // Debug du formatage
        error_log("  - User currency: {$user->getPreferredCurrency()->code}");
        $formattedBudget = $this->formatAmountForUser($budgetAmount, $user);
        $formattedSpent = $this->formatAmountForUser($spentAmount, $user);
        error_log("  - Formatted budget: {$formattedBudget}");
        error_log("  - Formatted spent: {$formattedSpent}");
        
        // Déterminer la langue de l'utilisateur
        $lang = $this->getUserLanguage($user);

        if ($lang === 'en') {
            switch ($alertType) {
                case 'exceeded':
                    return "You exceeded the budget \"{$budget->name}\" ({$formattedSpent}/{$formattedBudget})";

                case 'warning':
                    return "Warning! You used {$spentPercentage}% of budget \"{$budget->name}\" ({$formattedSpent}/{$formattedBudget})";

                case 'daily_summary':
                    return "Budget \"{$budget->name}\" summary: {$spentPercentage}% used ({$formattedSpent}/{$formattedBudget})";

                default:
                    return "Budget \"{$budget->name}\" update: {$formattedSpent}/{$formattedBudget}";
            }
        }

        // Français par défaut
        switch ($alertType) {
            case 'exceeded':
                return "Vous avez dépassé le budget \"{$budget->name}\" ({$formattedSpent}/{$formattedBudget})";

            case 'warning':
                return "Attention ! Vous avez utilisé {$spentPercentage}% du budget \"{$budget->name}\" ({$formattedSpent}/{$formattedBudget})";

            case 'daily_summary':
                return "Résumé du budget \"{$budget->name}\": {$spentPercentage}% utilisé ({$formattedSpent}/{$formattedBudget})";

            default:
                return "Mise à jour du budget \"{$budget->name}\": {$formattedSpent}/{$formattedBudget}";
        }
    }

    /**
     *  NOUVELLE MÉTHODE: Envoyer rappel d'inactivité avec devise
     */
    public function sendInactivityReminder(User $user, int $daysSinceLastList): bool
    {
        // ✅ VÉRIFICATION DES PRÉFÉRENCES
        if (!$this->canSendNotification($user, self::TYPE_USER_INACTIVE)) {
            error_log("🚫 User {$user->id} has disabled inactivity reminders");
            return false;
        }

        $lang = $this->getUserLanguage($user);

        $title = $lang === 'en' ? "🛒 We missed you!" : "🛒 On vous a manqué !";
        $body = $this->getInactivityReminderBody($daysSinceLastList, $lang);
        
        $data = [
            'reminder_type' => 'inactivity',
            'days_since_last_list' => (string) $daysSinceLastList,
            'currency_code' => (string) $user->getPreferredCurrency()->code,
            'currency_symbol' => (string) $user->getPreferredCurrency()->symbol,
            'action' => 'create_new_list'
        ];

        $result = $this->sendToUser(
            $user->id,
            self::TYPE_USER_INACTIVE,
            $title,
            $body,
            $data,
            'normal'
        );

        return $result['success'];
    }

    private function getInactivityReminderBody(int $days, string $lang = 'fr'): string
    {
        if ($lang === 'en') {
            if ($days <= 14) {
                return "It's been {$days} days since you created a shopping list. Need help organizing your purchases?";
            } elseif ($days <= 30) {
                return "We hope everything is well! It's been {$days} days since you used EpiList. Ready for a new list?";
            } else {
                return "EpiList is waiting for you! It's been over a month since you created a list. Rediscover our new features!";
            }
        }

        // Français par défaut
        if ($days <= 14) {
            return "Cela fait {$days} jours que vous n'avez pas créé de liste de courses. Besoin d'aide pour organiser vos achats ?";
        } elseif ($days <= 30) {
            return "Nous espérons que tout va bien ! Cela fait {$days} jours que vous n'avez pas utilisé EpiList. Prêt pour une nouvelle liste ?";
        } else {
            return "EpiList vous attend ! Cela fait plus d'un mois que vous n'avez pas créé de liste. Redécouvrez nos nouvelles fonctionnalités !";
        }
    }

    /**
     *  MÉTHODES UTILITAIRES (inchangées)
     */
    private function getNotificationSound(string $type): string
    {
        return match($type) {
            self::TYPE_BUDGET_EXCEEDED => 'budget_alert',
            self::TYPE_BUDGET_WARNING => 'budget_warning',
            self::TYPE_LIST_SHARED => 'list_shared',
            self::TYPE_PURCHASE_REMINDER => 'reminder',
            self::TYPE_USER_INACTIVE => 'gentle_reminder',
            self::TYPE_LIST_COMPLETED => 'success_chime',
            self::TYPE_WEEKLY_LIST_REMINDER => 'weekly_reminder', //  NOUVEAU
            self::TYPE_DAILY_LIST_REMINDER => 'daily_reminder',
            self::TYPE_NEW_MESSAGE => 'message_received',
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
            self::TYPE_LIST_UPDATED,
            self::TYPE_LIST_COMPLETED => 'list_updates',
            self::TYPE_PURCHASE_REMINDER,
            self::TYPE_USER_INACTIVE,
            self::TYPE_WEEKLY_LIST_REMINDER => 'reminders', //  NOUVEAU
            self::TYPE_DAILY_LIST_REMINDER => 'reminders',
            self::TYPE_NEW_MESSAGE => 'messages',
            default => 'general'
        };
    }

    private function getBudgetAlertTitle(string $alertType, string $lang = 'fr'): string
    {
        if ($lang === 'en') {
            return match($alertType) {
                'exceeded' => '⚠️ Budget Exceeded!',
                'warning' => '⚠️ Budget Warning',
                'daily_summary' => '📊 Budget Summary',
                default => '💰 Budget'
            };
        }

        // Français par défaut
        return match($alertType) {
            'exceeded' => '⚠️ Budget Dépassé!',
            'warning' => '⚠️ Attention Budget',
            'daily_summary' => '📊 Résumé Budget',
            default => '💰 Budget'
        };
    }

    /**
     *  CORRECTION PRINCIPALE: getBadgeCount avec conversion float vers int sécurisée
     */
    private function getBadgeCount(int $userId): int
    {
        try {
            if (!class_exists('App\Models\Budget')) {
                return 0;
            }
            
            $budgets = \App\Models\Budget::where('user_id', $userId)
                ->where('is_active', true)
                ->get();
            
            if ($budgets->isEmpty()) {
                return 0;
            }
            
            $alertCount = 0;
            
            foreach ($budgets as $budget) {
                //  CORRECTION: Vérifier explicitement chaque budget individuellement
                if (method_exists($budget, 'shouldShowAlert')) {
                    try {
                        $shouldAlert = $budget->shouldShowAlert();
                        
                        //  CORRECTION: Conversion sécurisée en évitant les floats
                        if ($shouldAlert === true || $shouldAlert === 1 || $shouldAlert === '1') {
                            $alertCount++;
                        } elseif (is_numeric($shouldAlert)) {
                            // Si c'est un nombre (potentiellement float), on utilise intval()
                            $numericValue = intval($shouldAlert);
                            if ($numericValue > 0) {
                                $alertCount++;
                            }
                        }
                        
                    } catch (\Exception $e) {
                        error_log("Error checking budget {$budget->id} shouldShowAlert: " . $e->getMessage());
                        // En cas d'erreur, on assume qu'il n'y a pas d'alerte
                        continue;
                    }
                }
            }
            
            //  S'assurer que le résultat final est bien un entier
            return (int) $alertCount;
            
        } catch (\Exception $e) {
            error_log("Error in getBadgeCount for user {$userId}: " . $e->getMessage());
            return 0;
        }
    }

    /**
     *  CORRECTION: Méthode sendWeeklyListReminder - ligne ~728
     */
    public function sendWeeklyListReminder(User $user, int $daysSinceLastList): bool
    {
        // ✅ VÉRIFICATION DES PRÉFÉRENCES
        if (!$this->canSendNotification($user, self::TYPE_WEEKLY_LIST_REMINDER)) {
            error_log("🚫 User {$user->id} has disabled weekly list reminders");
            return false;
        }

        $lang = $this->getUserLanguage($user);

        $title = $lang === 'en' ? "📅 Your weekly list" : "📅 Votre liste de la semaine";
        $body = $this->getWeeklyReminderBody($daysSinceLastList, $lang);
        
        $data = [
            'reminder_type' => 'weekly_list',
            'days_since_last_list' => (string) $daysSinceLastList,
            'week_number' => (string) Carbon::now()->weekOfYear,
            'year' => (string) Carbon::now()->year,
            'currency_code' => (string) $user->getPreferredCurrency()->code,
            'currency_symbol' => (string) $user->getPreferredCurrency()->symbol,
            'action' => 'create_new_list'
        ];

        $result = $this->sendToUser(
            $user->id,
            self::TYPE_WEEKLY_LIST_REMINDER,
            $title,
            $body,
            $data,
            'normal'
        );

        return $result['success'];
    }

    /**
     *  MÉTHODE PRIVÉE: Générer le message de rappel hebdomadaire
     */
    private function getWeeklyReminderBody(int $daysSinceLastList, string $lang = 'fr'): string
    {
        if ($lang === 'en') {
            $weekDay = Carbon::now()->locale('en')->dayName;

            if ($daysSinceLastList <= 7) {
                return "It's {$weekDay}! You haven't created your weekly shopping list yet. Ready to plan your purchases?";
            } elseif ($daysSinceLastList <= 14) {
                return "Hello! It's been {$daysSinceLastList} days without a new list. How about creating your weekly list?";
            } else {
                return "📅 EpiList is waiting for you! Create your first list of the week and organize your shopping efficiently.";
            }
        }

        // Français
        $weekDay = Carbon::now()->locale('fr')->dayName;

        if ($daysSinceLastList <= 7) {
            return "C'est {$weekDay} ! Vous n'avez pas encore créé votre liste de courses de la semaine. Prêt à planifier vos achats ?";
        } elseif ($daysSinceLastList <= 14) {
            return "Hello ! Cela fait {$daysSinceLastList} jours sans nouvelle liste. Que diriez-vous de créer votre liste hebdomadaire ?";
        } else {
            return "📅 EpiList vous attend ! Créez votre première liste de la semaine et organisez vos courses efficacement.";
        }
    }

    public function sendDailyListReminder(User $user, int $daysSinceLastList): bool
    {
        // ✅ VÉRIFICATION DES PRÉFÉRENCES
        if (!$this->canSendNotification($user, self::TYPE_DAILY_LIST_REMINDER)) {
            error_log("🚫 User {$user->id} has disabled daily list reminders");
            return false;
        }

        $lang = $this->getUserLanguage($user);

        $title = $lang === 'en' ? "🛍 Don't forget your list!" : "🛍 N'oubliez pas votre liste !";
        $body = $this->getDailyReminderBody($daysSinceLastList, $lang);
        
        $data = [
            'reminder_type' => 'daily_list',
            'days_since_last_list' => (string) $daysSinceLastList,
            'date' => (string) Carbon::now()->toDateString(),
            'day_name' => (string) Carbon::now()->locale('fr')->dayName,
            'currency_code' => (string) $user->getPreferredCurrency()->code,
            'currency_symbol' => (string) $user->getPreferredCurrency()->symbol,
            'action' => 'create_new_list'
        ];

        $result = $this->sendToUser(
            $user->id,
            self::TYPE_DAILY_LIST_REMINDER,
            $title,
            $body,
            $data,
            'normal'
        );

        return $result['success'];
    }

    /**
     *  MÉTHODE PRIVÉE: Générer le message de rappel quotidien
     */
    private function getDailyReminderBody(int $daysSinceLastList, string $lang = 'fr'): string
    {
        $timeOfDay = Carbon::now()->hour;

        if ($lang === 'en') {
            // English messages
            if ($timeOfDay >= 17 && $timeOfDay <= 20) {
                // Evening (5 PM - 8 PM)
                if ($daysSinceLastList === 0) {
                    return "Good evening! You haven't created your shopping list yet today. Prepare for tomorrow?";
                } elseif ($daysSinceLastList === 1) {
                    return "Good evening! It's been 1 day without a new list. Any shopping to plan?";
                } elseif ($daysSinceLastList <= 3) {
                    return "Good evening! It's been {$daysSinceLastList} days since you created a list. Need help organizing your purchases?";
                } elseif ($daysSinceLastList <= 7) {
                    return "Good evening! A week without a shopping list really shows! Ready to get back on track?";
                } else {
                    return "Good evening! EpiList has been waiting for you for {$daysSinceLastList} days. Rediscover the joy of organized shopping!";
                }
            } else {
                // General messages for other times
                if ($daysSinceLastList === 0) {
                    return "Hello! You haven't planned your shopping for today yet. Create your list now!";
                } elseif ($daysSinceLastList === 1) {
                    return "Hi! Yesterday, no shopping list... What about today? Let EpiList help you!";
                } elseif ($daysSinceLastList <= 3) {
                    return "Hello! {$daysSinceLastList} days without a list, it's time to get back to it. How about a new list?";
                } elseif ($daysSinceLastList <= 7) {
                    return "Hey! A week without EpiList is too long! Resume your organized shopping habits.";
                } else {
                    return "We're waiting for you! {$daysSinceLastList} days without a list is too much! Rediscover EpiList today.";
                }
            }
        }

        // Messages en français
        if ($timeOfDay >= 17 && $timeOfDay <= 20) {
            // En soirée (17h-20h)
            if ($daysSinceLastList === 0) {
                return "Bonsoir ! Vous n'avez pas encore créé votre liste de courses aujourd'hui. Préparez-vous pour demain ?";
            } elseif ($daysSinceLastList === 1) {
                return "Bonsoir ! Cela fait maintenant 1 jour sans nouvelle liste. Avez-vous des courses à prévoir ?";
            } elseif ($daysSinceLastList <= 3) {
                return "Bonsoir ! Cela fait {$daysSinceLastList} jours que vous n'avez pas créé de liste. Besoin d'aide pour organiser vos achats ?";
            } elseif ($daysSinceLastList <= 7) {
                return "Bonsoir ! Une semaine sans liste de courses, ça se ressent ! Prêt à reprendre de bonnes habitudes ?";
            } else {
                return "Bonsoir ! EpiList vous attend depuis {$daysSinceLastList} jours. Redécouvrez le plaisir d'organiser vos courses !";
            }
        } else {
            // Messages génériques pour autres heures
            if ($daysSinceLastList === 0) {
                return "Bonjour ! Vous n'avez pas encore planifié vos courses pour aujourd'hui. Créez votre liste maintenant !";
            } elseif ($daysSinceLastList === 1) {
                return "Salut ! Hier, pas de liste de courses... Et aujourd'hui ? Laissez EpiList vous aider !";
            } elseif ($daysSinceLastList <= 3) {
                return "Hello ! {$daysSinceLastList} jours sans liste, c'est le moment de s'y remettre. Que diriez-vous d'une nouvelle liste ?";
            } elseif ($daysSinceLastList <= 7) {
                return "Coucou ! Une semaine sans EpiList, ça fait long ! Reprenez vos bonnes habitudes de courses organisées.";
            } else {
                return "🛒 On vous attend ! {$daysSinceLastList} jours sans liste, c'est trop ! Redécouvrez EpiList aujourd'hui.";
            }
        }
    }

    /**
     *  NOUVELLE MÉTHODE: Envoyer notification de nouveau message
     */
    public function sendNewMessageNotification(
        User $sender,
        $list,
        string $messagePreview,
        array $recipientUserIds
    ): array {
        $title = "💬 {$sender->name}";
        $body = "{$list->name}: {$messagePreview}";

        $data = [
            'list_id' => (string) $list->id,
            'list_name' => (string) $list->name,
            'sender_id' => (string) $sender->id,
            'sender_name' => (string) $sender->name,
            'message_preview' => (string) $messagePreview,
            'action' => 'open_chat'
        ];

        $results = [];
        $totalSent = 0;
        $totalDevices = 0;

        // Envoyer à tous les destinataires sauf l'expéditeur
        foreach ($recipientUserIds as $recipientId) {
            if ($recipientId === $sender->id) {
                continue; // Ne pas envoyer à soi-même
            }

            // ✅ VÉRIFICATION DES PRÉFÉRENCES
            $recipientUser = User::find($recipientId);
            if (!$recipientUser || !$this->canSendNotification($recipientUser, self::TYPE_NEW_MESSAGE)) {
                error_log("🚫 User {$recipientId} has disabled message notifications");
                $results[$recipientId] = ['success' => false, 'sent_count' => 0, 'total_devices' => 0];
                continue;
            }

            $result = $this->sendToUser(
                $recipientId,
                self::TYPE_NEW_MESSAGE,
                $title,
                $body,
                $data,
                'high' // Priorité haute pour les messages
            );

            $results[$recipientId] = $result;
            if ($result['success']) {
                $totalSent += $result['sent_count'];
            }
            $totalDevices += $result['total_devices'];
        }

        return [
            'success' => $totalSent > 0,
            'total_sent' => $totalSent,
            'total_devices' => $totalDevices,
            'recipient_results' => $results
        ];
    }
}