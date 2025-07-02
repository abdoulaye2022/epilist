<?php
// src/Models/SharedList.php - VERSION AMÉLIORÉE AVEC STATUS

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class SharedList extends Model
{
    use SoftDeletes;

    protected $table = 'shared_list';
    protected $primaryKey = 'id';

    public $timestamps = true;

    // ✅ CONSTANTES POUR LES STATUS
    public const STATUS_PENDING = 'pending';           // En attente (invitation envoyée)
    public const STATUS_ACCEPTED = 'accepted';         // Acceptée
    public const STATUS_DECLINED = 'declined';         // Refusée
    public const STATUS_EXPIRED = 'expired';           // Expirée
    public const STATUS_REVOKED = 'revoked';           // Révoquée par le propriétaire
    public const STATUS_LEFT = 'left';                 // Utilisateur a quitté

    // ✅ CONSTANTES POUR LES PERMISSIONS
    public const PERMISSION_READ_ONLY = 'readOnly';
    public const PERMISSION_EDIT = 'edit';
    public const PERMISSION_ADMIN = 'admin';

    protected $fillable = [
        'list_id',
        'owner_id',
        'shared_with_user_id',
        'permission',
        'share_token',
        'status',           // ✅ Nouveau champ
        'is_active',
        'expires_at',
        'accepted_at',      // ✅ Date d'acceptation
        'declined_at',      // ✅ Date de refus
        'revoked_at',       // ✅ Date de révocation
    ];

    protected $casts = [
        'permission' => 'string',
        'status' => 'string',
        'is_active' => 'boolean',
        'expires_at' => 'datetime',
        'accepted_at' => 'datetime',
        'declined_at' => 'datetime',
        'revoked_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
    ];

    protected $attributes = [
        'status' => self::STATUS_PENDING,
        'is_active' => true,
    ];

    /**
     * Get the shopping list being shared
     */
    public function shoppingList(): BelongsTo
    {
        return $this->belongsTo(ShoppingList::class, 'list_id');
    }

    /**
     * Get the owner of the list
     */
    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /**
     * Get the user with whom the list is shared
     */
    public function sharedWithUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'shared_with_user_id');
    }

    // ✅ SCOPES AVANCÉS
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    public function scopeAccepted($query)
    {
        return $query->where('status', self::STATUS_ACCEPTED);
    }

    public function scopeNotExpired($query)
    {
        return $query->where(function($q) {
            $q->whereNull('expires_at')
              ->orWhere('expires_at', '>', Carbon::now());
        });
    }

    public function scopeExpired($query)
    {
        return $query->where('expires_at', '<=', Carbon::now());
    }

    public function scopeByToken($query, string $token)
    {
        return $query->where('share_token', $token);
    }

    // ✅ MÉTHODES UTILITAIRES
    public function isExpired(): bool
    {
        return $this->expires_at && $this->expires_at->isPast();
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function isAccepted(): bool
    {
        return $this->status === self::STATUS_ACCEPTED;
    }

    public function isDeclined(): bool
    {
        return $this->status === self::STATUS_DECLINED;
    }

    public function isRevoked(): bool
    {
        return $this->status === self::STATUS_REVOKED;
    }

    public function canBeAccepted(): bool
    {
        return $this->isPending() && 
               $this->is_active && 
               !$this->isExpired();
    }

    public function canEdit(): bool
    {
        return $this->isAccepted() && 
               in_array($this->permission, [self::PERMISSION_EDIT, self::PERMISSION_ADMIN]);
    }

    public function canDelete(): bool
    {
        return $this->isAccepted() && 
               $this->permission === self::PERMISSION_ADMIN;
    }

    // ✅ MÉTHODES D'ACTION
    public function accept(): bool
    {
        if (!$this->canBeAccepted()) {
            return false;
        }

        return $this->update([
            'status' => self::STATUS_ACCEPTED,
            'accepted_at' => Carbon::now(),
            'is_active' => true
        ]);
    }

    public function decline(): bool
    {
        if (!$this->isPending()) {
            return false;
        }

        return $this->update([
            'status' => self::STATUS_DECLINED,
            'declined_at' => Carbon::now(),
            'is_active' => false
        ]);
    }

    public function revoke(): bool
    {
        return $this->update([
            'status' => self::STATUS_REVOKED,
            'revoked_at' => Carbon::now(),
            'is_active' => false
        ]);
    }

    public function markAsLeft(): bool
    {
        return $this->update([
            'status' => self::STATUS_LEFT,
            'is_active' => false
        ]);
    }

    public function markAsExpired(): bool
    {
        return $this->update([
            'status' => self::STATUS_EXPIRED,
            'is_active' => false
        ]);
    }

    // ✅ ACCESSEURS
    public function getStatusDisplayNameAttribute(): string
    {
        return match($this->status) {
            self::STATUS_PENDING => 'En attente',
            self::STATUS_ACCEPTED => 'Accepté',
            self::STATUS_DECLINED => 'Refusé',
            self::STATUS_EXPIRED => 'Expiré',
            self::STATUS_REVOKED => 'Révoqué',
            self::STATUS_LEFT => 'Quitté',
            default => 'Inconnu'
        };
    }

    public function getPermissionDisplayNameAttribute(): string
    {
        return match($this->permission) {
            self::PERMISSION_READ_ONLY => 'Lecture seule',
            self::PERMISSION_EDIT => 'Modification',
            self::PERMISSION_ADMIN => 'Administration',
            default => 'Inconnu'
        };
    }

    // ✅ BOOT METHOD pour gérer l'expiration automatique
    protected static function boot()
    {
        parent::boot();

        // Marquer automatiquement comme expiré lors de la récupération
        static::retrieved(function ($model) {
            if ($model->isPending() && $model->isExpired()) {
                $model->markAsExpired();
            }
        });
    }

    // ✅ MÉTHODES STATIQUES UTILES
    public static function getValidStatuses(): array
    {
        return [
            self::STATUS_PENDING,
            self::STATUS_ACCEPTED,
            self::STATUS_DECLINED,
            self::STATUS_EXPIRED,
            self::STATUS_REVOKED,
            self::STATUS_LEFT,
        ];
    }

    public static function getValidPermissions(): array
    {
        return [
            self::PERMISSION_READ_ONLY,
            self::PERMISSION_EDIT,
            self::PERMISSION_ADMIN,
        ];
    }

    // ✅ QUERY HELPERS
    public static function findByToken(string $token): ?self
    {
        return static::where('share_token', $token)->first();
    }

    public static function findActiveByToken(string $token): ?self
    {
        return static::where('share_token', $token)
                    ->active()
                    ->pending()
                    ->notExpired()
                    ->first();
    }
}