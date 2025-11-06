<?php
// src/Models/Category.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Category extends Model
{
    use SoftDeletes;

    protected $table = 'categories';
    protected $primaryKey = 'id';

    public $timestamps = true;

    protected $fillable = [
        'user_id',
        'name',
        'icon_code',
        'color_hex',
        'order_index',
        'created_at',
        'updated_at',
        'deleted_at'
    ];

    protected $casts = [
        'user_id' => 'integer',
        'order_index' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
    ];

    /**
     * Get the user that owns the category.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the list items that belong to this category.
     */
    public function listItems(): HasMany
    {
        return $this->hasMany(ListItem::class, 'category_id');
    }
}
