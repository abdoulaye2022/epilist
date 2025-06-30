<?php
// src/Models/SharedList.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SharedList extends Model
{
    use SoftDeletes;

    protected $table = 'shared_list';
    protected $primaryKey = 'id';

    public $timestamps = true;

    protected $fillable = [
        'list_id',
        'owner_id',
        'shared_with_user_id',
        'permission',        // correspond à votre table SQL
        'share_token',
        'is_active'
    ];

    protected $casts = [
        'permission' => 'string',
        'shared_at' => 'datetime',
        'is_active' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
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

    /**
     * Scope active shares
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}