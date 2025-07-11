<?php
// src/Models/User.php - VERSION AVEC SUPPRESSION DE COMPTE

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
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
        // ✅ Nouveaux champs pour la suppression
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
        'account_deletion_code', // ✅ Cacher le code de suppression
        'deleted_at'
    ];

    protected $casts = [
        'terms_accepted' => 'boolean',
        'email_verified' => 'boolean',
        'is_deletion_requested' => 'boolean', // ✅ Nouveau cast
        'is_active' => 'boolean', // ✅ Nouveau cast
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
        'email_verified_at' => 'datetime',
        'password_change_code_expires_at' => 'datetime',
        'email_verification_code_expires_at' => 'datetime',
        'account_deletion_code_expires_at' => 'datetime', // ✅ Nouveau cast
        'deletion_requested_at' => 'datetime' // ✅ Nouveau cast
    ];

    /**
     * Trouve un utilisateur par email
     */
    public static function findByEmail(string $email): ?User
    {
        return static::where('email', $email)->first();
    }

    /**
     * Vérifie si l'email est vérifié (vérifie les deux systèmes pour compatibilité)
     */
    public function isEmailVerified(): bool
    {
        return $this->email_verified || $this->email_verified_at !== null;
    }

    /**
     * Marque l'email comme vérifié
     */
    public function markEmailAsVerified(): void
    {
        $this->update([
            'email_verified' => true,
            'email_verified_at' => Carbon::now(),
            'email_verification_code' => null,
            'email_verification_code_expires_at' => null
        ]);
    }

    /**
     * Vérifie si le code de vérification est valide
     */
    public function isVerificationCodeValid(string $code): bool
    {
        return $this->email_verification_code === $code && 
               $this->email_verification_code_expires_at > now();
    }

    /**
     * Vérifie si le code de changement de mot de passe est valide
     */
    public function isPasswordChangeCodeValid(string $code): bool
    {
        return $this->password_change_code === $code && 
               $this->password_change_code_expires_at > now();
    }

    // ✅ NOUVELLES MÉTHODES POUR LA SUPPRESSION DE COMPTE

    /**
     * Vérifie si le code de suppression de compte est valide
     */
    public function isAccountDeletionCodeValid(string $code): bool
    {
        return $this->account_deletion_code === $code && 
               $this->account_deletion_code_expires_at > Carbon::now();
    }

    /**
     * Vérifie si une suppression de compte est en cours
     */
    public function isDeletionRequested(): bool
    {
        return $this->is_deletion_requested;
    }

    /**
     * Vérifie si le compte est actif
     */
    public function isActive(): bool
    {
        return $this->is_active && !$this->isDeletionRequested();
    }

    /**
     * Génère un code de suppression de compte
     */
    public function generateDeletionCode(): string
    {
        $code = str_pad(mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
        $expiration = Carbon::now()->addHours(2); // Code valide 2 heures

        $this->update([
            'account_deletion_code' => $code,
            'account_deletion_code_expires_at' => $expiration
        ]);

        return $code;
    }

    /**
     * Marque le compte comme demande de suppression
     */
    public function requestDeletion(?string $reason = null): void
    {
        $this->update([
            'is_deletion_requested' => true,
            'deletion_requested_at' => Carbon::now(),
            'deletion_reason' => $reason,
            'is_active' => false, // Désactiver immédiatement
            'account_deletion_code' => null,
            'account_deletion_code_expires_at' => null
        ]);
    }

    /**
     * Annule la demande de suppression
     */
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

    /**
     * Anonymise les données de l'utilisateur (pour RGPD)
     */
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

    // ✅ SCOPES UTILES

    /**
     * Scope pour les utilisateurs actifs
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true)
                    ->where('is_deletion_requested', false);
    }

    /**
     * Scope pour les utilisateurs avec demande de suppression
     */
    public function scopeDeletionRequested($query)
    {
        return $query->where('is_deletion_requested', true);
    }

    /**
     * Scope pour les utilisateurs inactifs
     */
    public function scopeInactive($query)
    {
        return $query->where('is_active', false);
    }
}