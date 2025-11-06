<?php
// app/Models/ShoppingList.php - VERSION AVEC SUPPORT FACTURES

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
     *  Get the items for the shopping list with consistent ordering.
     * Articles non achetés en premier, puis par date de création décroissante
     */
    public function items(): HasMany
    {
        return $this->hasMany(ListItem::class, 'list_id')
                   ->orderBy('is_purchased') // Articles non achetés en premier (false = 0, true = 1)
                   ->orderBy('created_at', 'desc'); // Plus récent en premier
    }

    /**
     *  Get items without any ordering (pour des cas spéciaux si nécessaire)
     */
    public function itemsRaw(): HasMany
    {
        return $this->hasMany(ListItem::class, 'list_id');
    }

    /**
     *  NOUVELLE RELATION: Get the receipts for this shopping list
     */
    public function receipts(): HasMany
    {
        return $this->hasMany(ListReceipt::class, 'list_id')
                   ->orderBy('purchase_date', 'desc')
                   ->orderBy('created_at', 'desc');
    }

    /**
     *  NOUVELLE RELATION: Get the shared lists where this list is shared
     */
    public function sharedLists(): HasMany
    {
        return $this->hasMany(SharedList::class, 'list_id');
    }

    /**
     *  NOUVELLE RELATION: Get active shared lists only
     */
    public function activeSharedLists(): HasMany
    {
        return $this->hasMany(SharedList::class, 'list_id')
                   ->where('status', SharedList::STATUS_ACCEPTED)
                   ->where('is_active', true);
    }

    /**
     *  MÉTHODE UTILITAIRE: Check if this list is shared with a specific user
     */
    public function isSharedWith(int $userId): bool
    {
        return $this->activeSharedLists()
                   ->where('shared_with_user_id', $userId)
                   ->exists();
    }

    /**
     *  MÉTHODE UTILITAIRE: Get all users who have access to this list
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
     *  NOUVELLES MÉTHODES POUR LES CALCULS DE TOTAUX AVEC FACTURES
     */

    /**
     * Calcule le total basé sur les prix des items individuels
     */
    public function getItemsTotalAmount(): float
    {
        return $this->items()
            ->where('is_purchased', true)
            ->whereNotNull('price')
            ->get()
            ->sum(function($item) {
                return $item->price * $item->quantity;
            });
    }

    /**
     * Calcule le total basé sur les factures
     */
    public function getReceiptsTotalAmount(): float
    {
        return $this->receipts()->sum('total_amount');
    }

    /**
     * Obtient le montant total le plus fiable (factures prioritaires)
     */
    public function getBestTotalAmount(): float
    {
        $receiptsTotal = $this->getReceiptsTotalAmount();
        
        if ($receiptsTotal > 0) {
            return $receiptsTotal;
        }
        
        return $this->getItemsTotalAmount();
    }

    /**
     * Indique quelle méthode de calcul est utilisée
     */
    public function getTotalAmountSource(): string
    {
        $receiptsTotal = $this->getReceiptsTotalAmount();
        
        if ($receiptsTotal > 0) {
            return 'receipts';
        }
        
        $itemsTotal = $this->getItemsTotalAmount();
        if ($itemsTotal > 0) {
            return 'items';
        }
        
        return 'none';
    }

    /**
     * Obtient les statistiques complètes de la liste
     */
    public function getComprehensiveStats(): array
    {
        $items = $this->items;
        $receipts = $this->receipts;
        
        $totalItems = $items->count();
        $purchasedItems = $items->where('is_purchased', true)->count();
        $pendingItems = $totalItems - $purchasedItems;
        
        $itemsTotal = $this->getItemsTotalAmount();
        $receiptsTotal = $this->getReceiptsTotalAmount();
        $bestTotal = $this->getBestTotalAmount();
        $totalSource = $this->getTotalAmountSource();
        
        // Statistiques par magasin
        $storeStats = [];
        
        // Depuis les factures
        foreach ($receipts as $receipt) {
            if (!isset($storeStats[$receipt->store_name])) {
                $storeStats[$receipt->store_name] = [
                    'store_name' => $receipt->store_name,
                    'receipt_total' => 0,
                    'items_total' => 0,
                    'items_count' => 0
                ];
            }
            $storeStats[$receipt->store_name]['receipt_total'] += $receipt->total_amount;
        }
        
        // Depuis les items (pour compléter)
        foreach ($items->where('is_purchased', true)->whereNotNull('store_name') as $item) {
            if (!isset($storeStats[$item->store_name])) {
                $storeStats[$item->store_name] = [
                    'store_name' => $item->store_name,
                    'receipt_total' => 0,
                    'items_total' => 0,
                    'items_count' => 0
                ];
            }
            
            if ($item->price) {
                $storeStats[$item->store_name]['items_total'] += $item->price * $item->quantity;
            }
            $storeStats[$item->store_name]['items_count'] += $item->quantity;
        }
        
        return [
            'total_items' => $totalItems,
            'purchased_items' => $purchasedItems,
            'pending_items' => $pendingItems,
            'completion_percentage' => $totalItems > 0 ? round(($purchasedItems / $totalItems) * 100, 1) : 0,
            
            'items_total' => round($itemsTotal, 2),
            'receipts_total' => round($receiptsTotal, 2),
            'best_total' => round($bestTotal, 2),
            'total_source' => $totalSource,
            
            'receipts_count' => $receipts->count(),
            'stores_count' => count($storeStats),
            'store_breakdown' => array_values($storeStats),
            
            'has_pricing_data' => $itemsTotal > 0 || $receiptsTotal > 0,
            'pricing_completeness' => $this->calculatePricingCompleteness()
        ];
    }

    /**
     * Calcule le pourcentage de complétude des prix
     */
    public function calculatePricingCompleteness(): float
    {
        $purchasedItems = $this->items()->where('is_purchased', true)->get();
        
        if ($purchasedItems->isEmpty()) {
            return 0;
        }
        
        // Si on a des factures qui couvrent tous les magasins
        $receiptsTotal = $this->getReceiptsTotalAmount();
        if ($receiptsTotal > 0) {
            $storesWithReceipts = $this->receipts()->distinct('store_name')->count();
            $storesWithItems = $purchasedItems->whereNotNull('store_name')->unique('store_name')->count();
            
            if ($storesWithReceipts >= $storesWithItems) {
                return 100.0; // Couverture complète par factures
            }
        }
        
        // Sinon, calculer basé sur les prix individuels
        $itemsWithPrice = $purchasedItems->whereNotNull('price')->count();
        return round(($itemsWithPrice / $purchasedItems->count()) * 100, 1);
    }

    /**
     * Obtient les données formatées pour l'API avec les totaux
     */
    public function getApiDataWithTotals(?User $user = null): array
    {
        $stats = $this->getComprehensiveStats();
        $currency = $user ? $user->getPreferredCurrency() : Currency::getDefault();
        
        $data = $this->toArray();
        $data['stats'] = $stats;
        $data['formatted_totals'] = [
            'items_total' => $currency->formatAmount($stats['items_total']),
            'receipts_total' => $currency->formatAmount($stats['receipts_total']),
            'best_total' => $currency->formatAmount($stats['best_total'])
        ];
        
        return $data;
    }

    /**
     *  SCOPE: Lists accessible by a specific user (own + shared)
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
     *  SCOPE: Only own lists (not shared)
     */
    public function scopeOwnedBy($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     *  SCOPE: Only shared lists for a user
     */
    public function scopeSharedWith($query, int $userId)
    {
        return $query->whereHas('activeSharedLists', function($sq) use ($userId) {
            $sq->where('shared_with_user_id', $userId);
        });
    }

    /**
     *  SCOPE: Lists with receipts data
     */
    public function scopeWithReceiptsData($query)
    {
        return $query->with(['receipts' => function($q) {
            $q->orderBy('purchase_date', 'desc');
        }]);
    }

    /**
     *  SCOPE: Lists with spending data (items or receipts)
     */
    public function scopeWithSpendingData($query)
    {
        return $query->where(function($q) {
            $q->whereHas('items', function($sq) {
                $sq->where('is_purchased', true)->whereNotNull('price');
            })->orWhereHas('receipts');
        });
    }
}