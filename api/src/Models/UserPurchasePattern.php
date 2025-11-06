<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserPurchasePattern extends Model
{
    protected $table = 'user_purchase_patterns';
    protected $primaryKey = 'id';

    public $timestamps = true;

    protected $fillable = [
        'user_id',
        'product_name',
        'total_purchases',
        'avg_quantity',
        'avg_price',
        'avg_days_between',
        'last_purchased_at',
        'next_suggested_date',
        'preferred_store',
        'preferred_category_id',
        'frequency_score',
        'recency_score',
        'regularity_score'
    ];

    protected $casts = [
        'total_purchases' => 'integer',
        'avg_quantity' => 'decimal:2',
        'avg_price' => 'decimal:2',
        'avg_days_between' => 'integer',
        'last_purchased_at' => 'datetime',
        'next_suggested_date' => 'date',
        'frequency_score' => 'decimal:2',
        'recency_score' => 'decimal:2',
        'regularity_score' => 'decimal:2'
    ];

    /**
     * Get the user
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the preferred category
     */
    public function preferredCategory(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'preferred_category_id');
    }

    /**
     * Calculate overall suggestion score
     */
    public function getSuggestionScore(): float
    {
        // Weighted average of different scores
        $frequencyWeight = 0.4;
        $recencyWeight = 0.35;
        $regularityWeight = 0.25;

        return ($this->frequency_score * $frequencyWeight) +
               ($this->recency_score * $recencyWeight) +
               ($this->regularity_score * $regularityWeight);
    }

    /**
     * Check if product should be suggested today
     */
    public function shouldSuggestToday(): bool
    {
        if (!$this->next_suggested_date) {
            return false;
        }

        $today = now()->startOfDay();
        $suggestedDate = $this->next_suggested_date->startOfDay();

        // Suggest if within 2 days of predicted date
        $daysDiff = $today->diffInDays($suggestedDate, false);

        return $daysDiff >= -2 && $daysDiff <= 2;
    }

    /**
     * Get top suggestions for a user
     */
    public static function getTopSuggestions(int $userId, int $limit = 10): array
    {
        return self::where('user_id', $userId)
            ->where('total_purchases', '>=', 2)
            ->orderByDesc('frequency_score')
            ->orderByDesc('recency_score')
            ->limit($limit)
            ->with('preferredCategory')
            ->get()
            ->map(function($pattern) {
                return [
                    'product_name' => $pattern->product_name,
                    'suggested_quantity' => (int)ceil($pattern->avg_quantity),
                    'avg_price' => $pattern->avg_price,
                    'preferred_store' => $pattern->preferred_store,
                    'category_id' => $pattern->preferred_category_id,
                    'confidence_score' => $pattern->getSuggestionScore(),
                    'last_purchased' => $pattern->last_purchased_at?->format('Y-m-d'),
                    'should_buy_soon' => $pattern->shouldSuggestToday(),
                    'reason' => $pattern->getSuggestionReason()
                ];
            })
            ->toArray();
    }

    /**
     * Get human-readable suggestion reason
     */
    public function getSuggestionReason(): string
    {
        if ($this->shouldSuggestToday()) {
            if ($this->avg_days_between) {
                return "You usually buy this every {$this->avg_days_between} days";
            }
            return "Based on your purchase history";
        }

        if ($this->frequency_score > 70) {
            return "You buy this frequently";
        }

        if ($this->regularity_score > 70) {
            return "You buy this regularly";
        }

        return "Based on your preferences";
    }
}
