<?php
// src/Models/User.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    protected $table = 'users';
    protected $primaryKey = 'id';

    // Active automatiquement les colonnes created_at et updated_at
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
    ];

    protected $hidden = [
        'password_hash',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
        'terms_accepted' => 'boolean',
    ];

    public static function findByEmail(string $email): ?User
    {
        return static::where('email', $email)->first();
    }
}
