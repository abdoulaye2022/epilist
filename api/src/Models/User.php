<?php
// src/Models/User.php - VERSION COMPLÈTE AVEC TOUTES LES RELATIONS

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Carbon\Carbon;

class User extends Model
{
    use SoftDeletes;

    protected $table = 'users';
    protected $primaryKey = 'id';

    public $timestamps = true;

    protected $fillable = [
        'first_name', 
        'last_name', 
        'email', 
        'password_hash',
        'terms_accepted',
        'password_change_code',
        'password_change_code_expires_at',
        'email_verification_code',
        'email_verification_code_expires_at',
        'email_verified_at',
        'email_verified',
        'currency_id',
        // Champs pour la suppression
        'account_deletion_code',
        'account_deletion_code_expires_at',
        'deletion_reason',
        'is_deletion_requested',
        'deletion_requested_at',
        'is_active',
        'email_marketing_consent',
        'email_marketing_unsubscribed_at',
        'unsubscribe_token'
    ];

    protected $hidden = [
        'password_hash',
        'email_verification_code',
        'password_change_code',
        'account_deletion_code',
        'deleted_at'
    ];

    protected $casts = [
        'terms_accepted' => 'boolean',
        'email_verified' => 'boolean',
        'is_deletion_requested' => 'boolean',
        'is_active' => 'boolean',
        'currency_id' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
        'email_verified_at' => 'datetime',
        'password_change_code_expires_at' => 'datetime',
        'email_verification_code_expires_at' => 'datetime',
        'account_deletion_code_expires_at' => 'datetime',
        'deletion_requested_at' => 'datetime',
        'email_marketing_consent' => 'boolean',
        'email_marketing_unsubscribed_at' => 'datetime'
    ];

    protected $attributes = [
        'currency_id' => 1, // CAD par défaut
        'is_active' => true,
        'email_verified' => false,
        'terms_accepted' => false,
        'is_deletion_requested' => false,
        'email_marketing_consent' => true
    ];

    // ===================== RELATIONS =====================

    /**
     * ✅ Devise préférée de l'utilisateur
     */
    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }

    /**
     * ✅ Listes de courses de l'utilisateur
     */
    public function shoppingLists(): HasMany
    {
        return $this->hasMany(ShoppingList::class);
    }

    /**
     * ✅ Suggestions de produits de l'utilisateur
     */
    public function productSuggestions(): HasMany
    {
        return $this->hasMany(ProductSuggestion::class);
    }

    /**
     * ✅ Listes partagées par l'utilisateur (en tant que propriétaire)
     */
    public function ownedSharedLists(): HasMany
    {
        return $this->hasMany(SharedList::class, 'owner_id');
    }

    /**
     * ✅ Listes partagées avec l'utilisateur (en tant qu'invité)
     */
    public function receivedSharedLists(): HasMany
    {
        return $this->hasMany(SharedList::class, 'shared_with_user_id');
    }

    /**
     * ✅ Appareils de l'utilisateur
     */
    public function devices(): HasMany
    {
        return $this->hasMany(UserDevice::class);
    }

    /**
     * ✅ Appareils actifs seulement
     */
    public function activeDevices(): HasMany
    {
        return $this->hasMany(UserDevice::class)->active();
    }

    /**
     * ✅ NOUVELLE RELATION: Budgets de l'utilisateur
     */
    public function budgets(): HasMany
    {
        return $this->hasMany(Budget::class);
    }

    /**
     * ✅ NOUVELLE RELATION: Budgets actifs de l'utilisateur
     */
    public function activeBudgets(): HasMany
    {
        return $this->hasMany(Budget::class)->active();
    }

    /**
     * ✅ NOUVELLE RELATION: Budgets actifs et actuels
     */
    public function currentBudgets(): HasMany
    {
        return $this->hasMany(Budget::class)->active()->current();
    }

    /**
     * ✅ NOUVELLE RELATION: Budgets dépassés
     */
    public function exceededBudgets(): HasMany
    {
        return $this->hasMany(Budget::class)->active()->current();
        // Note: Le filtrage pour "exceeded" se fait en PHP car complexe en SQL
    }

    // ===================== MÉTHODES STATIQUES =====================

    /**
     * Trouve un utilisateur par email
     */
    public static function findByEmail(string $email): ?User
    {
        return static::where('email', $email)->first();
    }

    // ===================== MÉTHODES D'AUTHENTIFICATION =====================

    public function isEmailVerified(): bool
    {
        return $this->email_verified || $this->email_verified_at !== null;
    }

    public function markEmailAsVerified(): void
    {
        $this->update([
            'email_verified' => true,
            'email_verified_at' => Carbon::now(),
            'email_verification_code' => null,
            'email_verification_code_expires_at' => null
        ]);
    }

    public function isVerificationCodeValid(string $code): bool
    {
        return $this->email_verification_code === $code && 
               $this->email_verification_code_expires_at > now();
    }

    public function isPasswordChangeCodeValid(string $code): bool
    {
        return $this->password_change_code === $code && 
               $this->password_change_code_expires_at > now();
    }

    // ===================== MÉTHODES DE SUPPRESSION =====================

    public function isAccountDeletionCodeValid(string $code): bool
    {
        return $this->account_deletion_code === $code && 
               $this->account_deletion_code_expires_at > Carbon::now();
    }

    public function isDeletionRequested(): bool
    {
        return $this->is_deletion_requested;
    }

    public function isActive(): bool
    {
        return $this->is_active && !$this->isDeletionRequested();
    }

    public function generateDeletionCode(): string
    {
        $code = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
        $expiration = Carbon::now()->addHours(2);

        $this->update([
            'account_deletion_code' => $code,
            'account_deletion_code_expires_at' => $expiration
        ]);

        return $code;
    }

    public function requestDeletion(?string $reason = null): void
    {
        $this->update([
            'is_deletion_requested' => true,
            'deletion_requested_at' => Carbon::now(),
            'deletion_reason' => $reason,
            'is_active' => false,
            'account_deletion_code' => null,
            'account_deletion_code_expires_at' => null
        ]);
    }

    public function cancelDeletionRequest(): void
    {
        $this->update([
            'is_deletion_requested' => false,
            'deletion_requested_at' => null,
            'deletion_reason' => null,
            'is_active' => true,
            'account_deletion_code' => null,
            'account_deletion_code_expires_at' => null
        ]);
    }

    public function anonymizeData(): void
    {
        $anonymizedEmail = "deleted_user_{$this->id}@deleted.local";
        
        $this->update([
            'first_name' => 'Utilisateur',
            'last_name' => 'Supprimé',
            'email' => $anonymizedEmail,
            'password_hash' => null,
            'email_verification_code' => null,
            'password_change_code' => null,
            'account_deletion_code' => null,
            'email_verification_code_expires_at' => null,
            'password_change_code_expires_at' => null,
            'account_deletion_code_expires_at' => null,
            'is_active' => false
        ]);
    }

    // ===================== MÉTHODES POUR LES DEVISES =====================

    public function getPreferredCurrency(): Currency
    {
        if ($this->currency) {
            return $this->currency;
        }

        // Si pas de devise assignée, utiliser CAD par défaut et sauvegarder
        $defaultCurrency = Currency::getDefault();
        $this->update(['currency_id' => $defaultCurrency->id]);
        
        return $defaultCurrency;
    }

    public function setCurrency(int $currencyId): bool
    {
        $currency = Currency::active()->find($currencyId);
        
        if (!$currency) {
            throw new \InvalidArgumentException('Invalid currency ID');
        }

        return $this->update(['currency_id' => $currencyId]);
    }

    public function setCurrencyByCode(string $currencyCode): bool
    {
        $currency = Currency::findByCode($currencyCode);
        
        if (!$currency) {
            throw new \InvalidArgumentException('Invalid currency code: ' . $currencyCode);
        }

        return $this->setCurrency($currency->id);
    }

    public function formatAmount(float $amount, bool $showCode = false): string
    {
        $currency = $this->getPreferredCurrency();
        return $currency->formatAmount($amount, $showCode);
    }

    public function convertToCurrency(float $amount, string $fromCurrencyCode): float
    {
        $userCurrency = $this->getPreferredCurrency();
        return Currency::convert($amount, $fromCurrencyCode, $userCurrency->code);
    }

    public function convertFromCurrency(float $amount, string $toCurrencyCode): float
    {
        $userCurrency = $this->getPreferredCurrency();
        return Currency::convert($amount, $userCurrency->code, $toCurrencyCode);
    }

    // ===================== MÉTHODES POUR LES NOTIFICATIONS =====================

    public function canReceiveNotifications(): bool
    {
        return $this->activeDevices()
            ->canReceiveNotifications()
            ->exists();
    }

    public function hasNotificationPreference(string $type): bool
    {
        return $this->activeDevices()
            ->get()
            ->some(function($device) use ($type) {
                return $device->hasNotificationPreference($type);
            });
    }

    public function registerDevice(array $deviceData): UserDevice
    {
        return UserDevice::registerDevice(array_merge($deviceData, [
            'user_id' => $this->id
        ]));
    }

    // ===================== MÉTHODES POUR LES BUDGETS =====================

    /**
     * ✅ Obtenir les budgets qui nécessitent une alerte
     */
    public function getBudgetsRequiringAlert(): \Illuminate\Database\Eloquent\Collection
    {
        return $this->currentBudgets()
            ->get()
            ->filter(function($budget) {
                return $budget->shouldShowAlert();
            });
    }

    /**
     * ✅ Obtenir les budgets dépassés
     */
    public function getExceededBudgets(): \Illuminate\Database\Eloquent\Collection
    {
        return $this->currentBudgets()
            ->get()
            ->filter(function($budget) {
                return $budget->isExceeded();
            });
    }

    /**
     * ✅ Vérifier si l'utilisateur a des budgets actifs
     */
    public function hasActiveBudgets(): bool
    {
        return $this->currentBudgets()->count() > 0;
    }

    /**
     * ✅ Obtenir le montant total budgété
     */
    public function getTotalBudgetAmount(): float
    {
        return $this->currentBudgets()->sum('budget_amount');
    }

    /**
     * ✅ Obtenir le montant total dépensé
     */
    public function getTotalSpentAmount(): float
    {
        return $this->currentBudgets()
            ->get()
            ->sum(function($budget) {
                return $budget->getSpentAmount();
            });
    }

    // ===================== SCOPES =====================

    public function scopeActive($query)
    {
        return $query->where('is_active', true)
                    ->where('is_deletion_requested', false);
    }

    public function scopeDeletionRequested($query)
    {
        return $query->where('is_deletion_requested', true);
    }

    public function scopeInactive($query)
    {
        return $query->where('is_active', false);
    }

    public function scopeWithCurrency($query, string $currencyCode)
    {
        return $query->whereHas('currency', function($q) use ($currencyCode) {
            $q->where('code', $currencyCode);
        });
    }

    public function scopeWithPopularCurrency($query)
    {
        return $query->whereHas('currency', function($q) {
            $q->where('is_popular', true);
        });
    }

    /**
     * ✅ NOUVEAU SCOPE: Utilisateurs avec appareils actifs
     */
    public function scopeWithActiveDevices($query)
    {
        return $query->whereHas('devices', function($q) {
            $q->active()->canReceiveNotifications();
        });
    }

    /**
     * ✅ NOUVEAU SCOPE: Utilisateurs avec budgets actifs
     */
    public function scopeWithActiveBudgets($query)
    {
        return $query->whereHas('budgets', function($q) {
            $q->active()->current();
        });
    }

    // ===================== ACCESSEURS =====================

    public function getFullNameAttribute(): string
    {
        return trim($this->first_name . ' ' . $this->last_name);
    }

    public function getApiDataAttribute(): array
    {
        $currency = $this->getPreferredCurrency();
        
        return [
            'id' => $this->id,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'full_name' => $this->full_name,
            'email' => $this->email,
            'email_verified' => $this->email_verified,
            'email_verified_at' => $this->email_verified_at?->toISOString(),
            'currency' => $currency->getApiFormatAttribute(),
            'is_active' => $this->is_active,
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString()
        ];
    }

    // ===================== BOOT METHOD =====================

    protected static function boot()
    {
        parent::boot();

        // Assigner automatiquement la devise par défaut lors de la création
        static::creating(function ($user) {
            if (!$user->currency_id) {
                $defaultCurrency = Currency::getDefault();
                $user->currency_id = $defaultCurrency->id;
            }
        });
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Envoyer notification de liste complétée
     */
    public function sendListCompletionNotification($list, float $estimatedTotal = 0): bool
    {
        if (!$this->canReceiveNotifications()) {
            return false;
        }

        $notificationService = new \App\Services\NotificationService();
        return $notificationService->sendListCompletionNotification($this, $list, $estimatedTotal);
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Envoyer notification de budget avec devise
     */
    public function sendBudgetAlert($budget, string $alertType): bool
    {
        if (!$this->canReceiveNotifications()) {
            return false;
        }

        $notificationService = new \App\Services\NotificationService();
        return $notificationService->sendBudgetAlert($this, $budget, $alertType);
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Envoyer rappel d'inactivité
     */
    public function sendInactivityReminder(int $daysSinceLastList): bool
    {
        if (!$this->canReceiveNotifications()) {
            return false;
        }

        $notificationService = new \App\Services\NotificationService();
        return $notificationService->sendInactivityReminder($this, $daysSinceLastList);
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Envoyer notification de partage de liste
     */
    public function sendListSharingNotification($sharedList, User $sharedByUser): bool
    {
        if (!$this->canReceiveNotifications()) {
            return false;
        }

        $notificationService = new \App\Services\NotificationService();
        return $notificationService->sendListSharingNotification($this, $sharedList, $sharedByUser);
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Envoyer notification de mise à jour de liste partagée
     */
    public function sendSharedListUpdateNotification($sharedList, User $updatedByUser, string $updateType = 'item_added'): bool
    {
        if (!$this->canReceiveNotifications()) {
            return false;
        }

        $notificationService = new \App\Services\NotificationService();
        return $notificationService->sendSharedListUpdateNotification($this, $sharedList, $updatedByUser, $updateType);
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Obtenir toutes les notifications en attente
     */
    public function getPendingNotifications(): array
    {
        $notifications = [];

        // Notifications de budgets
        if ($this->hasActiveBudgets()) {
            $budgetAlerts = $this->getBudgetsRequiringAlert();
            foreach ($budgetAlerts as $budget) {
                $notifications[] = [
                    'id' => "budget_alert_{$budget->id}",
                    'type' => 'budget_alert',
                    'priority' => $budget->isExceeded() ? 'high' : 'medium',
                    'title' => $budget->isExceeded() ? '🚨 Budget Dépassé' : '⚠️ Attention Budget',
                    'message' => $this->getBudgetAlertMessage($budget),
                    'data' => [
                        'budget_id' => $budget->id,
                        'budget_name' => $budget->name,
                        'formatted_spent' => $this->formatAmount($budget->getSpentAmount()),
                        'formatted_budget' => $this->formatAmount($budget->getBudgetAmount()),
                        'currency_code' => $this->getPreferredCurrency()->code,
                        'currency_symbol' => $this->getPreferredCurrency()->symbol,
                    ],
                    'created_at' => Carbon::now()->toISOString()
                ];
            }
        }

        // Notifications de listes complétées (à implémenter si nécessaire)
        // ...

        return $notifications;
    }

    /**
     * ✅ HELPER: Générer le message d'alerte budget avec devise
     */
    private function getBudgetAlertMessage($budget): string
    {
        $spentAmount = $budget->getSpentAmount();
        $budgetAmount = $budget->getBudgetAmount();
        $spentPercentage = round($budget->getSpentPercentage(), 1);
        
        $formattedSpent = $this->formatAmount($spentAmount);
        $formattedBudget = $this->formatAmount($budgetAmount);

        if ($budget->isExceeded()) {
            return "Vous avez dépassé le budget \"{$budget->name}\" ({$formattedSpent}/{$formattedBudget})";
        } else {
            return "Vous avez utilisé {$spentPercentage}% du budget \"{$budget->name}\" ({$formattedSpent}/{$formattedBudget})";
        }
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Obtenir les préférences de notification
     */
    public function getNotificationPreferences(): array
    {
        $preferences = [];
        
        $devices = $this->activeDevices;
        foreach ($devices as $device) {
            $devicePreferences = $device->getNotificationPreferences();
            foreach ($devicePreferences as $type => $enabled) {
                if (!isset($preferences[$type])) {
                    $preferences[$type] = false;
                }
                $preferences[$type] = $preferences[$type] || $enabled;
            }
        }

        return $preferences;
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Mettre à jour les préférences de notification pour tous les appareils
     */
    public function updateNotificationPreferences(array $preferences): bool
    {
        $success = true;
        
        foreach ($this->activeDevices as $device) {
            if (!$device->setNotificationPreferences($preferences)) {
                $success = false;
            }
        }

        return $success;
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Vérifier si l'utilisateur peut recevoir un type spécifique de notification
     */
    public function canReceiveNotificationType(string $notificationType): bool
    {
        if (!$this->canReceiveNotifications()) {
            return false;
        }

        // Vérifier si au moins un appareil autorise ce type de notification
        return $this->activeDevices()
            ->get()
            ->some(function($device) use ($notificationType) {
                return $device->hasNotificationPreference($notificationType);
            });
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Obtenir les statistiques de notifications
     */
    public function getNotificationStats(): array
    {
        $stats = [
            'total_devices' => $this->devices()->count(),
            'active_devices' => $this->activeDevices()->count(),
            'can_receive_notifications' => $this->canReceiveNotifications(),
            'notification_types_enabled' => [],
        ];

        if ($stats['can_receive_notifications']) {
            $preferences = $this->getNotificationPreferences();
            $stats['notification_types_enabled'] = array_keys(array_filter($preferences));
        }

        return $stats;
    }

    // ===================== MÉTHODES DE FORMATAGE POUR L'API =====================

    /**
     * ✅ Données API étendues avec informations de devise et notifications
     */
    public function getExtendedApiDataAttribute(): array
    {
        $currency = $this->getPreferredCurrency();
        $baseData = $this->api_data;
        
        return array_merge($baseData, [
            'notification_preferences' => $this->getNotificationPreferences(),
            'notification_stats' => $this->getNotificationStats(),
            'budget_summary' => [
                'has_active_budgets' => $this->hasActiveBudgets(),
                'total_budget_amount' => $this->formatAmount($this->getTotalBudgetAmount()),
                'total_spent_amount' => $this->formatAmount($this->getTotalSpentAmount()),
                'exceeded_budgets_count' => $this->getExceededBudgets()->count(),
                'currency' => $currency->getApiFormatAttribute(),
            ]
        ]);
    }

    /**
     * Vérifier si l'utilisateur consent à recevoir des emails marketing
     */
    public function canReceiveMarketingEmails(): bool
    {
        return $this->email_marketing_consent && 
            $this->email_verified && 
            $this->is_active && 
            !$this->isDeletionRequested();
    }

    /**
     * Générer un token de désabonnement unique
     */
    public function generateUnsubscribeToken(): string
    {
        if (!$this->unsubscribe_token) {
            do {
                $token = bin2hex(random_bytes(32));
                $existingUser = self::where('unsubscribe_token', $token)->first();
            } while ($existingUser);
            
            $this->update(['unsubscribe_token' => $token]);
        }
        
        return $this->unsubscribe_token;
    }

    /**
     * Désabonner l'utilisateur des emails marketing
     */
    public function unsubscribeFromMarketing(?string $reason = null): bool
    {
        return $this->update([
            'email_marketing_consent' => false,
            'email_marketing_unsubscribed_at' => Carbon::now()
        ]);
    }

    /**
     * Réabonner l'utilisateur aux emails marketing
     */
    public function resubscribeToMarketing(): bool
    {
        return $this->update([
            'email_marketing_consent' => true,
            'email_marketing_unsubscribed_at' => null
        ]);
    }

    /**
     * Obtenir l'URL de désabonnement
     */
    public function getUnsubscribeUrl(): string
    {
        $token = $this->generateUnsubscribeToken();
        $baseUrl = $_ENV['APP_URL'] ?? 'https://epilist.app';
        return "{$baseUrl}/unsubscribe/{$token}";
    }

    /**
     * Trouver un utilisateur par son token de désabonnement
     */
    public static function findByUnsubscribeToken(string $token): ?User
    {
        return self::where('unsubscribe_token', $token)->first();
    }

    // ===================== SCOPES POUR LES EMAILS =====================

    /**
     * Scope pour utilisateurs éligibles aux emails marketing
     */
    public function scopeMarketingEmailEligible($query)
    {
        return $query->where('email_marketing_consent', true)
                    ->where('email_verified_at', '!=', null)
                    ->where('is_active', true)
                    ->whereNull('deletion_requested_at');
    }

    /**
     * Scope pour utilisateurs désabonnés
     */
    public function scopeUnsubscribedFromMarketing($query)
    {
        return $query->where('email_marketing_consent', false);
    }
}