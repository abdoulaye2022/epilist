<?php
// src/Models/User.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    protected $table = 'users';
    protected $primaryKey = 'id';

    public $timestamps = true;

    protected $fillable = [
        'first_name', 
        'last_name', 
        'email', 
        'password_hash', 
        'terms_accepted',
        'created_at',
        'updated_at',
        'deleted_at',
        'email_verified',
        'password_change_code',
        'password_change_code_expires_at',
        'email_verification_code', // Nouveau champ
        'email_verification_code_expires_at', // Nouveau champ
        'email_verified_at' // Nouveau champ
    ];

    protected $hidden = [
        'password_hash',
        'email_verification_code'
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
        'terms_accepted' => 'boolean',
        'email_verified_at' => 'datetime',
        'email_verification_code_expires_at' => 'datetime'
    ];

    public static function findByEmail(string $email): ?User
    {
        return static::where('email', $email)->first();
    }

    // Vérifie si l'email est vérifié
    public function isEmailVerified(): bool
    {
        return $this->email_verified !== 0;
    }
}