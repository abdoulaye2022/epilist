<?php
// app/Models/ShoppingList.php - VERSION AVEC RELATIONS CORRIGÉES

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

    /**
     * ✅ NOUVELLE RELATION: Get the shared lists where this list is shared
     */
    public function sharedLists(): HasMany
    {
        return $this->hasMany(SharedList::class, 'list_id');
    }

    /**
     * ✅ NOUVELLE RELATION: Get active shared lists only
     */
    public function activeSharedLists(): HasMany
    {
        return $this->hasMany(SharedList::class, 'list_id')
                   ->where('status', SharedList::STATUS_ACCEPTED)
                   ->where('is_active', true);
    }

    /**
     * ✅ MÉTHODE UTILITAIRE: Check if this list is shared with a specific user
     */
    public function isSharedWith(int $userId): bool
    {
        return $this->activeSharedLists()
                   ->where('shared_with_user_id', $userId)
                   ->exists();
    }

    /**
     * ✅ MÉTHODE UTILITAIRE: Get all users who have access to this list
     */
    public function getAllAccessUsers(): array
    {
        $users = [$this->user_id]; // Owner always has access
        
        $sharedUsers = $this->activeSharedLists()
                           ->pluck('shared_with_user_id')
                           ->toArray();
        
        return array_unique(array_merge($users, $sharedUsers));
    }

    /**
     * ✅ SCOPE: Lists accessible by a specific user (own + shared)
     */
    public function scopeAccessibleBy($query, int $userId)
    {
        return $query->where(function($q) use ($userId) {
            // Own lists
            $q->where('user_id', $userId)
              // OR shared lists
              ->orWhereHas('activeSharedLists', function($sq) use ($userId) {
                  $sq->where('shared_with_user_id', $userId);
              });
        });
    }

    /**
     * ✅ SCOPE: Only own lists (not shared)
     */
    public function scopeOwnedBy($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * ✅ SCOPE: Only shared lists for a user
     */
    public function scopeSharedWith($query, int $userId)
    {
        return $query->whereHas('activeSharedLists', function($sq) use ($userId) {
            $sq->where('shared_with_user_id', $userId);
        });
    }
}