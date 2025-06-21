<?php
// app/Models/ListItem.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ListItem extends Model
{
    use SoftDeletes;

    protected $table = 'list_items';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'list_id',
        'product_name',
        'quantity',
        'price',
        'store_name',
        'is_purchased',
        'created_at',
        'updated_at',
        'deleted_at'
    ];

    protected $casts = [
        'is_purchased' => 'boolean',
        'quantity' => 'integer',
        'price' => 'float',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
    ];

    /**
     * Relation avec la liste de courses
     */
    public function shoppingList(): BelongsTo
    {
        return $this->belongsTo(ShoppingList::class, 'list_id');
    }
}
