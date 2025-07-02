<?php
// src/Models/User.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

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
        'email_verified'
    ];

    protected $hidden = [
        'password_hash',
        'email_verification_code',
        'password_change_code',
        'deleted_at'
    ];

    protected $casts = [
        'terms_accepted' => 'boolean',
        'email_verified' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
        'email_verified_at' => 'datetime',
        'password_change_code_expires_at' => 'datetime',
        'email_verification_code_expires_at' => 'datetime'
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
            'email_verified_at' => now(),
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
}