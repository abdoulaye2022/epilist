<?php
// src/Models/Employee.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

use App\Models\ConnectedAccount;

class User extends Model
{
    protected $table = 'users';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'first_name', 
        'last_name', 
        'phone', 
        'email', 
        'password_hash'
    ];

    protected $hidden = [
        'password_hash',
    ];

    protected $casts = [
        'created_at' => 'date'
    ];

    public static function findByEmail(string $email): ?User
    {
        return static::where('email', $email)->first();
    }

}