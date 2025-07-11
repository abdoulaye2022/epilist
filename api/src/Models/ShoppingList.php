<?php
// src/Models/ShoppingList.php - VERSION AVEC ORDRE PAR DÉFAUT

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

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

    /**
     * ✅ Get the items for the shopping list with consistent ordering.
     * Articles non achetés en premier, puis par date de création décroissante
     */
    public function items(): HasMany
    {
        return $this->hasMany(ListItem::class, 'list_id')
                   ->orderBy('is_purchased') // Articles non achetés en premier (false = 0, true = 1)
                   ->orderBy('created_at', 'desc'); // Plus récent en premier
    }

    /**
     * ✅ Get items without any ordering (pour des cas spéciaux si nécessaire)
     */
    public function itemsRaw(): HasMany
    {
        return $this->hasMany(ListItem::class, 'list_id');
    }
}