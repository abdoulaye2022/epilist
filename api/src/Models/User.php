<?php
// src/Models/User.php - VERSION MISE À JOUR AVEC SUPPORT DEVISE

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
        'currency_id', // ✅ Nouveau champ pour la devise
        // Champs pour la suppression
        'account_deletion_code',
        'account_deletion_code_expires_at',
        'deletion_reason',
        'is_deletion_requested',
        'deletion_requested_at',
        'is_active'
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
        'currency_id' => 'integer', // ✅ Nouveau cast
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
        'email_verified_at' => 'datetime',
        'password_change_code_expires_at' => 'datetime',
        'email_verification_code_expires_at' => 'datetime',
        'account_deletion_code_expires_at' => 'datetime',
        'deletion_requested_at' => 'datetime'
    ];

    protected $attributes = [
        'currency_id' => 1, // ✅ CAD par défaut
        'is_active' => true,
        'email_verified' => false,
        'terms_accepted' => false,
        'is_deletion_requested' => false
    ];

    /**
     * ✅ NOUVELLE RELATION: Devise préférée de l'utilisateur
     */
    public function currency(): BelongsTo
    {
        return $this->belongsTo(Currency::class);
    }

    /**
     * Relation avec les listes de courses
     */
    public function shoppingLists(): HasMany
    {
        return $this->hasMany(ShoppingList::class);
    }

    /**
     * Relation avec les suggestions de produits
     */
    public function productSuggestions(): HasMany
    {
        return $this->hasMany(ProductSuggestion::class);
    }

    /**
     * Relation avec les listes partagées (en tant que propriétaire)
     */
    public function ownedSharedLists(): HasMany
    {
        return $this->hasMany(SharedList::class, 'owner_id');
    }

    /**
     * Relation avec les listes partagées (en tant qu'invité)
     */
    public function receivedSharedLists(): HasMany
    {
        return $this->hasMany(SharedList::class, 'shared_with_user_id');
    }

    /**
     * Trouve un utilisateur par email
     */
    public static function findByEmail(string $email): ?User
    {
        return static::where('email', $email)->first();
    }

    // ✅ MÉTHODES EXISTANTES (inchangées)
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

    // ✅ MÉTHODES DE SUPPRESSION (inchangées)
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

    // ✅ NOUVELLES MÉTHODES POUR LES DEVISES

    /**
     * Obtenir la devise de l'utilisateur ou la devise par défaut
     */
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

    /**
     * Changer la devise préférée de l'utilisateur
     */
    public function setCurrency(int $currencyId): bool
    {
        $currency = Currency::active()->find($currencyId);
        
        if (!$currency) {
            throw new \InvalidArgumentException('Invalid currency ID');
        }

        return $this->update(['currency_id' => $currencyId]);
    }

    /**
     * Changer la devise par code
     */
    public function setCurrencyByCode(string $currencyCode): bool
    {
        $currency = Currency::findByCode($currencyCode);
        
        if (!$currency) {
            throw new \InvalidArgumentException('Invalid currency code: ' . $currencyCode);
        }

        return $this->setCurrency($currency->id);
    }

    /**
     * Formater un montant dans la devise de l'utilisateur
     */
    public function formatAmount(float $amount, bool $showCode = false): string
    {
        $currency = $this->getPreferredCurrency();
        return $currency->formatAmount($amount, $showCode);
    }

    /**
     * Convertir un montant vers la devise de l'utilisateur
     */
    public function convertToCurrency(float $amount, string $fromCurrencyCode): float
    {
        $userCurrency = $this->getPreferredCurrency();
        return Currency::convert($amount, $fromCurrencyCode, $userCurrency->code);
    }

    /**
     * Convertir un montant depuis la devise de l'utilisateur
     */
    public function convertFromCurrency(float $amount, string $toCurrencyCode): float
    {
        $userCurrency = $this->getPreferredCurrency();
        return Currency::convert($amount, $userCurrency->code, $toCurrencyCode);
    }

    // ✅ SCOPES EXISTANTS (inchangés)
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

    // ✅ NOUVEAUX SCOPES POUR LES DEVISES
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
     * ✅ BOOT METHOD pour assigner la devise par défaut
     */
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
     * ✅ ACCESSEUR pour obtenir le nom complet
     */
    public function getFullNameAttribute(): string
    {
        return trim($this->first_name . ' ' . $this->last_name);
    }

    /**
     * ✅ ACCESSEUR pour les données API avec devise
     */
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

    /**
     * ✅ NOUVELLE RELATION: Appareils de l'utilisateur
     */
    public function devices(): HasMany
    {
        return $this->hasMany(UserDevice::class);
    }

    /**
     * ✅ NOUVELLE RELATION: Appareils actifs seulement
     */
    public function activeDevices(): HasMany
    {
        return $this->hasMany(UserDevice::class)->active();
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Vérifier si l'utilisateur peut recevoir des notifications
     */
    public function canReceiveNotifications(): bool
    {
        return $this->activeDevices()
            ->canReceiveNotifications()
            ->exists();
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Vérifier une préférence de notification
     */
    public function hasNotificationPreference(string $type): bool
    {
        return $this->activeDevices()
            ->get()
            ->some(function($device) use ($type) {
                return $device->hasNotificationPreference($type);
            });
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Enregistrer un appareil
     */
    public function registerDevice(array $deviceData): UserDevice
    {
        return UserDevice::registerDevice(array_merge($deviceData, [
            'user_id' => $this->id
        ]));
    }
}