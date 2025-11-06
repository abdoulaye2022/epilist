<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductAssociation extends Model
{
    protected $table = 'product_associations';
    protected $primaryKey = 'id';

    public $timestamps = false; // Only last_updated

    protected $fillable = [
        'product_a',
        'product_b',
        'confidence',
        'support_count',
        'last_updated'
    ];

    protected $casts = [
        'confidence' => 'decimal:4',
        'support_count' => 'integer',
        'last_updated' => 'datetime'
    ];

    /**
     * Get associated products for a given product
     */
    public static function getAssociatedProducts(string $productName, float $minConfidence = 0.3, int $limit = 5): array
    {
        $normalized = PurchaseHistory::normalizeProductName($productName);

        return self::where('product_a', $normalized)
            ->where('confidence', '>=', $minConfidence)
            ->orderByDesc('confidence')
            ->orderByDesc('support_count')
            ->limit($limit)
            ->get()
            ->map(function($assoc) {
                return [
                    'product_name' => $assoc->product_b,
                    'confidence' => $assoc->confidence,
                    'times_bought_together' => $assoc->support_count
                ];
            })
            ->toArray();
    }

    /**
     * Update associations based on a shopping list
     */
    public static function updateFromList(array $productNames): void
    {
        $normalized = array_map([PurchaseHistory::class, 'normalizeProductName'], $productNames);
        $count = count($normalized);

        // For each pair of products in the list
        for ($i = 0; $i < $count - 1; $i++) {
            for ($j = $i + 1; $j < $count; $j++) {
                self::incrementAssociation($normalized[$i], $normalized[$j]);
                self::incrementAssociation($normalized[$j], $normalized[$i]);
            }
        }
    }

    /**
     * Increment association count and recalculate confidence
     */
    private static function incrementAssociation(string $productA, string $productB): void
    {
        $association = self::where('product_a', $productA)
            ->where('product_b', $productB)
            ->first();

        if ($association) {
            $association->support_count++;
            $association->confidence = self::calculateConfidence($productA, $productB, $association->support_count);
            $association->save();
        } else {
            self::create([
                'product_a' => $productA,
                'product_b' => $productB,
                'support_count' => 1,
                'confidence' => self::calculateConfidence($productA, $productB, 1)
            ]);
        }
    }

    /**
     * Calculate confidence score (simple approach)
     */
    private static function calculateConfidence(string $productA, string $productB, int $supportCount): float
    {
        // Get total purchases of product A
        $totalA = PurchaseHistory::where('normalized_name', $productA)->count();

        if ($totalA == 0) {
            return 0;
        }

        // Confidence = (times bought together) / (total times A was bought)
        return min(1.0, $supportCount / $totalA);
    }
}
