<?php

namespace App\Services;

use App\Models\PurchaseHistory;
use App\Models\UserPurchasePattern;
use App\Models\ProductAssociation;
use Illuminate\Database\Capsule\Manager as DB;
use Carbon\Carbon;

class SmartSuggestionService
{
    /**
     * Get personalized product suggestions for a user
     */
    public function getSuggestionsForUser(int $userId, array $options = []): array
    {
        $limit = $options['limit'] ?? 10;
        $includeAssociations = $options['include_associations'] ?? true;
        $currentListItems = $options['current_list_items'] ?? [];

        // 1. Get pattern-based suggestions
        $patternSuggestions = $this->getPatternBasedSuggestions($userId, $limit);

        // 2. Get seasonal suggestions
        $seasonalSuggestions = $this->getSeasonalSuggestions($userId);

        // 3. Get association-based suggestions (if items in current list)
        $associationSuggestions = [];
        if ($includeAssociations && !empty($currentListItems)) {
            $associationSuggestions = $this->getAssociationSuggestions($currentListItems);
        }

        // 4. Merge and rank all suggestions
        $allSuggestions = $this->mergeAndRankSuggestions(
            $patternSuggestions,
            $seasonalSuggestions,
            $associationSuggestions
        );

        // 5. Remove duplicates and limit
        return array_slice($allSuggestions, 0, $limit);
    }

    /**
     * Get suggestions based on purchase patterns
     */
    private function getPatternBasedSuggestions(int $userId, int $limit): array
    {
        return UserPurchasePattern::getTopSuggestions($userId, $limit);
    }

    /**
     * Get seasonal product suggestions
     */
    private function getSeasonalSuggestions(int $userId): array
    {
        $currentSeason = $this->getCurrentSeason();

        $seasonalProducts = PurchaseHistory::getSeasonalProducts($userId, $currentSeason);

        return array_map(function($product) {
            return [
                'product_name' => $product['product_name'],
                'suggested_quantity' => 1,
                'confidence_score' => 60, // Medium confidence
                'reason' => "Popular in {$this->getCurrentSeason()}",
                'type' => 'seasonal'
            ];
        }, $seasonalProducts);
    }

    /**
     * Get suggestions based on product associations
     */
    private function getAssociationSuggestions(array $currentProducts): array
    {
        $suggestions = [];

        foreach ($currentProducts as $product) {
            $associated = ProductAssociation::getAssociatedProducts($product, 0.3, 3);

            foreach ($associated as $assoc) {
                $suggestions[] = [
                    'product_name' => $assoc['product_name'],
                    'suggested_quantity' => 1,
                    'confidence_score' => $assoc['confidence'] * 100,
                    'reason' => "Often bought with {$product}",
                    'type' => 'association',
                    'based_on' => $product
                ];
            }
        }

        return $suggestions;
    }

    /**
     * Merge and rank suggestions from different sources
     */
    private function mergeAndRankSuggestions(
        array $patterns,
        array $seasonal,
        array $associations
    ): array {
        // Combine all suggestions
        $all = array_merge($patterns, $seasonal, $associations);

        // Remove duplicates (same product name)
        $unique = [];
        $seen = [];

        foreach ($all as $suggestion) {
            $normalized = PurchaseHistory::normalizeProductName($suggestion['product_name']);

            if (!isset($seen[$normalized])) {
                $seen[$normalized] = true;
                $unique[] = $suggestion;
            } else {
                // If duplicate, keep the one with higher confidence
                foreach ($unique as $key => $existing) {
                    if (PurchaseHistory::normalizeProductName($existing['product_name']) === $normalized) {
                        if ($suggestion['confidence_score'] > $existing['confidence_score']) {
                            $unique[$key] = $suggestion;
                        }
                        break;
                    }
                }
            }
        }

        // Sort by confidence score
        usort($unique, function($a, $b) {
            return $b['confidence_score'] <=> $a['confidence_score'];
        });

        return $unique;
    }

    /**
     * Recalculate purchase patterns for a user
     */
    public function recalculatePatterns(int $userId): void
    {
        // Call the stored procedure
        DB::statement('CALL calculate_purchase_patterns(?)', [$userId]);
    }

    /**
     * Record suggestion feedback (accepted/rejected)
     */
    public function recordFeedback(
        int $userId,
        string $productName,
        string $action,
        ?int $suggestedQuantity = null,
        ?int $actualQuantity = null
    ): void {
        DB::table('suggestion_feedback')->insert([
            'user_id' => $userId,
            'product_name' => $productName,
            'action' => $action,
            'suggested_quantity' => $suggestedQuantity,
            'actual_quantity' => $actualQuantity,
            'created_at' => Carbon::now()
        ]);
    }

    /**
     * Get suggestion statistics
     */
    public function getStatistics(int $userId): array
    {
        $totalPurchases = PurchaseHistory::where('user_id', $userId)->count();
        $uniqueProducts = PurchaseHistory::where('user_id', $userId)
            ->distinct('normalized_name')
            ->count();

        $patterns = UserPurchasePattern::where('user_id', $userId)->count();

        $feedback = DB::table('suggestion_feedback')
            ->where('user_id', $userId)
            ->selectRaw('action, COUNT(*) as count')
            ->groupBy('action')
            ->get()
            ->pluck('count', 'action')
            ->toArray();

        $acceptanceRate = 0;
        if (isset($feedback['accepted']) && isset($feedback['rejected'])) {
            $total = $feedback['accepted'] + $feedback['rejected'];
            $acceptanceRate = ($feedback['accepted'] / $total) * 100;
        }

        return [
            'total_purchases' => $totalPurchases,
            'unique_products' => $uniqueProducts,
            'active_patterns' => $patterns,
            'suggestion_acceptance_rate' => round($acceptanceRate, 1),
            'feedback' => $feedback
        ];
    }

    /**
     * Get current season
     */
    private function getCurrentSeason(): string
    {
        $month = (int)date('n');

        if ($month >= 3 && $month <= 5) {
            return 'spring';
        } elseif ($month >= 6 && $month <= 8) {
            return 'summer';
        } elseif ($month >= 9 && $month <= 11) {
            return 'fall';
        } else {
            return 'winter';
        }
    }

    /**
     * Get smart quantity suggestion
     */
    public function suggestQuantity(int $userId, string $productName): int
    {
        $pattern = UserPurchasePattern::where('user_id', $userId)
            ->where('product_name', PurchaseHistory::normalizeProductName($productName))
            ->first();

        if ($pattern && $pattern->avg_quantity) {
            return (int)ceil($pattern->avg_quantity);
        }

        return 1; // Default
    }

    /**
     * Get smart price suggestion
     */
    public function suggestPrice(int $userId, string $productName): ?float
    {
        $pattern = UserPurchasePattern::where('user_id', $userId)
            ->where('product_name', PurchaseHistory::normalizeProductName($productName))
            ->first();

        return $pattern?->avg_price;
    }

    /**
     * Get trending products (across all users)
     */
    public function getTrendingProducts(int $limit = 10): array
    {
        $lastWeek = Carbon::now()->subDays(7);

        return PurchaseHistory::where('purchased_at', '>=', $lastWeek)
            ->selectRaw('normalized_name, product_name, COUNT(*) as purchase_count')
            ->groupBy('normalized_name', 'product_name')
            ->orderByDesc('purchase_count')
            ->limit($limit)
            ->get()
            ->map(function($item) {
                return [
                    'product_name' => $item->product_name,
                    'purchase_count' => $item->purchase_count,
                    'trend' => 'hot'
                ];
            })
            ->toArray();
    }

    /**
     * Update product associations when a list is completed
     */
    public function updateAssociationsFromList(int $listId): void
    {
        // Get all items from the list
        $items = DB::table('list_items')
            ->where('list_id', $listId)
            ->where('is_purchased', true)
            ->pluck('product_name')
            ->toArray();

        if (count($items) >= 2) {
            ProductAssociation::updateFromList($items);
        }
    }
}
