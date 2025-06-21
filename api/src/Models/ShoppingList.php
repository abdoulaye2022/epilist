<?php
// src/Models/ShoppingList.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShoppingList extends Model
{
    use SoftDeletes;

    protected $table = 'shopping_lists';
    protected $primaryKey = 'id';

    public $timestamps = true;

    protected $fillable = [
        'user_id',
        'name',
        'created_at',
        'updated_at',
        'deleted_at'
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
    ];

    /**
     * Get the user that owns the shopping list.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
