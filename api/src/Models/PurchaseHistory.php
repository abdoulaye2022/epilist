<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PurchaseHistory extends Model
{
    protected $table = 'purchase_history';
    protected $primaryKey = 'id';

    public $timestamps = false; // Only created_at

    protected $fillable = [
        'user_id',
        'product_name',
        'normalized_name',
        'category_id',
        'quantity',
        'price',
        'store_name',
        'barcode',
        'purchased_at',
        'list_id',
        'day_of_week',
        'month',
        'season',
        'created_at'
    ];

    protected $casts = [
        'quantity' => 'integer',
        'price' => 'decimal:2',
        'day_of_week' => 'integer',
        'month' => 'integer',
        'purchased_at' => 'datetime',
        'created_at' => 'datetime'
    ];

    /**
     * Get the user that owns the purchase
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the category
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Get the shopping list
     */
    public function shoppingList(): BelongsTo
    {
        return $this->belongsTo(ShoppingList::class, 'list_id');
    }

    /**
     * Get purchase frequency for a user and product
     */
    public static function getPurchaseFrequency(int $userId, string $productName): array
    {
        $normalizedName = self::normalizeProductName($productName);

        $purchases = self::where('user_id', $userId)
            ->where('normalized_name', $normalizedName)
            ->orderBy('purchased_at')
            ->get();

        if ($purchases->count() < 2) {
            return [
                'total_purchases' => $purchases->count(),
                'avg_days_between' => null,
                'last_purchased' => $purchases->first()?->purchased_at,
                'next_suggested' => null
            ];
        }

        // Calculate average days between purchases
        $dates = $purchases->pluck('purchased_at')->map(fn($d) => $d->timestamp)->toArray();
        $intervals = [];

        for ($i = 1; $i < count($dates); $i++) {
            $intervals[] = ($dates[$i] - $dates[$i - 1]) / 86400; // Convert to days
        }

        $avgDays = array_sum($intervals) / count($intervals);
        $lastPurchase = $purchases->last()->purchased_at;
        $nextSuggested = $lastPurchase->addDays((int)$avgDays);

        return [
            'total_purchases' => $purchases->count(),
            'avg_days_between' => round($avgDays, 1),
            'last_purchased' => $lastPurchase,
            'next_suggested' => $nextSuggested,
            'avg_quantity' => $purchases->avg('quantity'),
            'avg_price' => $purchases->avg('price')
        ];
    }

    /**
     * Normalize product name (PHP equivalent of SQL function)
     */
    public static function normalizeProductName(string $name): string
    {
        // Convert to lowercase
        $normalized = mb_strtolower($name, 'UTF-8');

        // Remove accents
        $accents = [
            'à' => 'a', 'â' => 'a', 'á' => 'a',
            'é' => 'e', 'è' => 'e', 'ê' => 'e', 'ë' => 'e',
            'î' => 'i', 'ï' => 'i',
            'ô' => 'o', 'ó' => 'o',
            'ù' => 'u', 'û' => 'u', 'ü' => 'u',
            'ç' => 'c', 'ñ' => 'n'
        ];

        $normalized = strtr($normalized, $accents);

        // Remove special characters
        $normalized = preg_replace('/[^a-z0-9 ]/', '', $normalized);

        // Remove multiple spaces
        $normalized = preg_replace('/ +/', ' ', $normalized);

        // Trim
        return trim($normalized);
    }

    /**
     * Get most purchased products by user
     */
    public static function getMostPurchased(int $userId, int $limit = 10): array
    {
        return self::where('user_id', $userId)
            ->selectRaw('normalized_name, product_name, COUNT(*) as purchase_count, AVG(quantity) as avg_quantity')
            ->groupBy('normalized_name', 'product_name')
            ->orderByDesc('purchase_count')
            ->limit($limit)
            ->get()
            ->toArray();
    }

    /**
     * Get seasonal products
     */
    public static function getSeasonalProducts(int $userId, string $season): array
    {
        return self::where('user_id', $userId)
            ->where('season', $season)
            ->selectRaw('normalized_name, product_name, COUNT(*) as purchase_count')
            ->groupBy('normalized_name', 'product_name')
            ->having('purchase_count', '>', 1)
            ->orderByDesc('purchase_count')
            ->get()
            ->toArray();
    }
}
