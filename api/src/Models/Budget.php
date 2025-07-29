<?php
// app/Models/Budget.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class Budget extends Model
{
    use SoftDeletes;

    protected $table = 'budgets';
    protected $primaryKey = 'id';
    public $timestamps = true;

    const PERIOD_WEEKLY = 'weekly';
    const PERIOD_MONTHLY = 'monthly';
    const PERIOD_YEARLY = 'yearly';
    const PERIOD_CUSTOM = 'custom';

    const ALERT_STATUS_OK = 'ok';
    const ALERT_STATUS_WARNING = 'warning';
    const ALERT_STATUS_EXCEEDED = 'exceeded';

    protected $fillable = [
        'user_id',
        'list_id',
        'name',
        'budget_amount',
        'period_type',
        'start_date',
        'end_date',
        'alert_threshold',
        'is_active',
        'created_at',
        'updated_at',
        'deleted_at'
    ];

    protected $casts = [
        'budget_amount' => 'float',
        'alert_threshold' => 'integer',
        'is_active' => 'boolean',
        'start_date' => 'date',
        'end_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
    ];

    protected $attributes = [
        'period_type' => self::PERIOD_MONTHLY,
        'alert_threshold' => 80,
        'is_active' => true
    ];

    /**
     * ✅ VALIDATION RULES
     */
    public static function getValidationRules(): array
    {
        return [
            'name' => [
                'required' => 'Budget name is required',
                'lengthMax' => ['255', 'Budget name cannot exceed 255 characters'],
                'lengthMin' => ['3', 'Budget name must be at least 3 characters']
            ],
            'budget_amount' => [
                'required' => 'Budget amount is required',
                'numeric' => 'Budget amount must be a number',
                'min' => ['0.01', 'Budget amount must be at least 0.01'],
                'max' => ['999999.99', 'Budget amount cannot exceed 999,999.99']
            ],
            'period_type' => [
                'required' => 'Period type is required',
                'in' => [['weekly', 'monthly', 'yearly', 'custom'], 'Invalid period type']
            ],
            'start_date' => [
                'required' => 'Start date is required',
                'date' => 'Start date must be a valid date'
            ],
            'end_date' => [
                'required' => 'End date is required',
                'date' => 'End date must be a valid date'
            ],
            'alert_threshold' => [
                'integer' => 'Alert threshold must be an integer',
                'min' => ['1', 'Alert threshold must be at least 1%'],
                'max' => ['100', 'Alert threshold cannot exceed 100%']
            ]
        ];
    }

    /**
     * ✅ RELATIONS
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function shoppingList(): BelongsTo
    {
        return $this->belongsTo(ShoppingList::class, 'list_id');
    }

    /**
     * ✅ VALIDATION METHODS
     */
    public static function validateBudgetAmount($amount): float
    {
        $amount = (float) $amount;
        $amount = round($amount, 2);
        
        if ($amount < 0.01) {
            throw new \InvalidArgumentException('Budget amount must be at least 0.01');
        }
        
        if ($amount > 999999.99) {
            throw new \InvalidArgumentException('Budget amount is too high');
        }
        
        return $amount;
    }

    public static function validatePeriodDates(string $periodType, Carbon $startDate, Carbon $endDate): array
    {
        // End date must be after start date
        if ($endDate->lte($startDate)) {
            throw new \InvalidArgumentException('End date must be after start date');
        }

        // Validate period consistency
        switch ($periodType) {
            case self::PERIOD_WEEKLY:
                if ($startDate->diffInDays($endDate) > 7) {
                    throw new \InvalidArgumentException('Weekly budget period cannot exceed 7 days');
                }
                break;
            
            case self::PERIOD_MONTHLY:
                if ($startDate->diffInDays($endDate) > 31) {
                    throw new \InvalidArgumentException('Monthly budget period cannot exceed 31 days');
                }
                break;
            
            case self::PERIOD_YEARLY:
                if ($startDate->diffInDays($endDate) > 366) {
                    throw new \InvalidArgumentException('Yearly budget period cannot exceed 366 days');
                }
                break;
        }

        // Cannot be more than 2 years in the future
        if ($endDate->isFuture() && $endDate->isAfter(Carbon::now()->addYears(2))) {
            throw new \InvalidArgumentException('Budget period cannot be more than 2 years in the future');
        }

        return [$startDate, $endDate];
    }

    /**
     * ✅ BUDGET CALCULATION METHODS
     */
    public function getSpentAmount(): float
    {
        if ($this->list_id) {
            // Budget spécifique à une liste
            return $this->getListSpentAmount();
        } else {
            // Budget général pour toutes les listes de l'utilisateur
            return $this->getUserSpentAmount();
        }
    }

    private function getListSpentAmount(): float
    {
        $list = $this->shoppingList;
        if (!$list) {
            return 0.0;
        }

        // Calculer depuis les factures dans la période
        $receiptsTotal = ListReceipt::where('list_id', $this->list_id)
            ->whereBetween('purchase_date', [
                $this->start_date->format('Y-m-d'),
                $this->end_date->format('Y-m-d')
            ])
            ->sum('total_amount');

        // Si pas de factures, calculer depuis les items achetés
        if ($receiptsTotal == 0) {
            $itemsTotal = ListItem::where('list_id', $this->list_id)
                ->where('is_purchased', true)
                ->whereNotNull('price')
                ->whereBetween('updated_at', [
                    $this->start_date->startOfDay(),
                    $this->end_date->endOfDay()
                ])
                ->get()
                ->sum(function($item) {
                    return $item->price * $item->quantity;
                });
            
            return $itemsTotal;
        }

        return $receiptsTotal;
    }

    private function getUserSpentAmount(): float
    {
        $userLists = ShoppingList::accessibleBy($this->user_id)->pluck('id');

        // Calculer depuis les factures
        $receiptsTotal = ListReceipt::whereIn('list_id', $userLists)
            ->whereBetween('purchase_date', [
                $this->start_date->format('Y-m-d'),
                $this->end_date->format('Y-m-d')
            ])
            ->sum('total_amount');

        // Si pas de factures, calculer depuis les items
        if ($receiptsTotal == 0) {
            $itemsTotal = ListItem::whereIn('list_id', $userLists)
                ->where('is_purchased', true)
                ->whereNotNull('price')
                ->whereBetween('updated_at', [
                    $this->start_date->startOfDay(),
                    $this->end_date->endOfDay()
                ])
                ->get()
                ->sum(function($item) {
                    return $item->price * $item->quantity;
                });
            
            return $itemsTotal;
        }

        return $receiptsTotal;
    }

    /**
     * ✅ BUDGET STATUS METHODS
     */
    public function getRemainingAmount(): float
    {
        return max(0, $this->budget_amount - $this->getSpentAmount());
    }

    public function getSpentPercentage(): float
    {
        if ($this->budget_amount <= 0) {
            return 0;
        }

        return min(100, ($this->getSpentAmount() / $this->budget_amount) * 100);
    }

    public function getAlertStatus(): string
    {
        $spentPercentage = $this->getSpentPercentage();

        if ($spentPercentage >= 100) {
            return self::ALERT_STATUS_EXCEEDED;
        } elseif ($spentPercentage >= $this->alert_threshold) {
            return self::ALERT_STATUS_WARNING;
        }

        return self::ALERT_STATUS_OK;
    }

    public function isExceeded(): bool
    {
        return $this->getSpentAmount() >= $this->budget_amount;
    }

    public function isNearLimit(): bool
    {
        return $this->getSpentPercentage() >= $this->alert_threshold;
    }

    public function isActive(): bool
    {
        return $this->is_active && 
               $this->start_date->lte(Carbon::now()) && 
               $this->end_date->gte(Carbon::now());
    }

    public function getDaysRemaining(): int
    {
        if ($this->end_date->isPast()) {
            return 0;
        }

        return max(0, Carbon::now()->diffInDays($this->end_date, false));
    }

    /**
     * ✅ ALERT METHODS
     */
    public function getAlertMessage(): ?string
    {
        $status = $this->getAlertStatus();
        $spentAmount = $this->getSpentAmount();
        $spentPercentage = round($this->getSpentPercentage(), 1);

        switch ($status) {
            case self::ALERT_STATUS_EXCEEDED:
                $overspent = $spentAmount - $this->budget_amount;
                return "Budget exceeded! You've overspent by " . number_format($overspent, 2) . " (" . $spentPercentage . "% of budget)";
            
            case self::ALERT_STATUS_WARNING:
                $remaining = $this->getRemainingAmount();
                return "Budget warning! You've spent " . $spentPercentage . "% of your budget. " . number_format($remaining, 2) . " remaining";
            
            default:
                return null;
        }
    }

    public function shouldShowAlert(): bool
    {
        return $this->isActive() && 
               ($this->isNearLimit() || $this->isExceeded());
    }

    /**
     * ✅ PERIOD HELPER METHODS
     */
    public static function createWeeklyBudget(int $userId, string $name, float $amount, Carbon $startDate, ?int $listId = null): self
    {
        $endDate = $startDate->copy()->addDays(6);
        
        return self::createClean([
            'user_id' => $userId,
            'list_id' => $listId,
            'name' => $name,
            'budget_amount' => $amount,
            'period_type' => self::PERIOD_WEEKLY,
            'start_date' => $startDate,
            'end_date' => $endDate
        ]);
    }

    public static function createMonthlyBudget(int $userId, string $name, float $amount, ?Carbon $startDate = null, ?int $listId = null): self
    {
        $startDate = $startDate ?? Carbon::now()->startOfMonth();
        $endDate = $startDate->copy()->endOfMonth();
        
        return self::createClean([
            'user_id' => $userId,
            'list_id' => $listId,
            'name' => $name,
            'budget_amount' => $amount,
            'period_type' => self::PERIOD_MONTHLY,
            'start_date' => $startDate,
            'end_date' => $endDate
        ]);
    }

    public static function createYearlyBudget(int $userId, string $name, float $amount, ?Carbon $startDate = null, ?int $listId = null): self
    {
        $startDate = $startDate ?? Carbon::now()->startOfYear();
        $endDate = $startDate->copy()->endOfYear();
        
        return self::createClean([
            'user_id' => $userId,
            'list_id' => $listId,
            'name' => $name,
            'budget_amount' => $amount,
            'period_type' => self::PERIOD_YEARLY,
            'start_date' => $startDate,
            'end_date' => $endDate
        ]);
    }

    /**
     * ✅ CRUD METHODS
     */
    public static function createClean(array $data): self
    {
        $cleanData = [
            'user_id' => $data['user_id'],
            'list_id' => $data['list_id'] ?? null,
            'name' => trim($data['name']),
            'budget_amount' => self::validateBudgetAmount($data['budget_amount']),
            'period_type' => $data['period_type'],
            'alert_threshold' => $data['alert_threshold'] ?? 80,
            'is_active' => $data['is_active'] ?? true
        ];

        [$startDate, $endDate] = self::validatePeriodDates(
            $cleanData['period_type'],
            Carbon::parse($data['start_date']),
            Carbon::parse($data['end_date'])
        );

        $cleanData['start_date'] = $startDate;
        $cleanData['end_date'] = $endDate;

        return self::create($cleanData);
    }

    public function updateClean(array $data): bool
    {
        $cleanData = [];
        
        if (isset($data['name'])) {
            $cleanData['name'] = trim($data['name']);
        }
        
        if (isset($data['budget_amount'])) {
            $cleanData['budget_amount'] = self::validateBudgetAmount($data['budget_amount']);
        }
        
        if (isset($data['alert_threshold'])) {
            $cleanData['alert_threshold'] = max(1, min(100, (int)$data['alert_threshold']));
        }
        
        if (isset($data['is_active'])) {
            $cleanData['is_active'] = (bool)$data['is_active'];
        }

        // Handle date updates
        if (isset($data['start_date']) || isset($data['end_date'])) {
            $startDate = isset($data['start_date']) ? Carbon::parse($data['start_date']) : $this->start_date;
            $endDate = isset($data['end_date']) ? Carbon::parse($data['end_date']) : $this->end_date;
            $periodType = $data['period_type'] ?? $this->period_type;

            [$validatedStart, $validatedEnd] = self::validatePeriodDates($periodType, $startDate, $endDate);
            
            $cleanData['start_date'] = $validatedStart;
            $cleanData['end_date'] = $validatedEnd;
            
            if (isset($data['period_type'])) {
                $cleanData['period_type'] = $data['period_type'];
            }
        }
        
        return $this->update($cleanData);
    }

    /**
     * ✅ API DATA METHODS
     */
    public function getApiDataForUser(?User $user = null): array
    {
        $spentAmount = $this->getSpentAmount();
        $spentPercentage = $this->getSpentPercentage();
        $remainingAmount = $this->getRemainingAmount();
        $status = $this->getAlertStatus();

        $currency = $user ? $user->getPreferredCurrency() : Currency::getDefault();

        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'list_id' => $this->list_id,
            'list_name' => $this->shoppingList ? $this->shoppingList->name : null,
            'name' => $this->name,
            'budget_amount' => $this->budget_amount,
            'formatted_budget_amount' => $currency->formatAmount($this->budget_amount),
            'period_type' => $this->period_type,
            'start_date' => $this->start_date->toDateString(),
            'end_date' => $this->end_date->toDateString(),
            'alert_threshold' => $this->alert_threshold,
            'is_active' => $this->is_active,
            
            // Calculated fields
            'spent_amount' => round($spentAmount, 2),
            'formatted_spent_amount' => $currency->formatAmount($spentAmount),
            'remaining_amount' => round($remainingAmount, 2),
            'formatted_remaining_amount' => $currency->formatAmount($remainingAmount),
            'spent_percentage' => round($spentPercentage, 1),
            'days_remaining' => $this->getDaysRemaining(),
            'status' => $status,
            'is_exceeded' => $this->isExceeded(),
            'is_near_limit' => $this->isNearLimit(),
            'alert_message' => $this->getAlertMessage(),
            'should_show_alert' => $this->shouldShowAlert(),
            
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString()
        ];
    }

    /**
     * ✅ SCOPES
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeForList($query, int $listId)
    {
        return $query->where('list_id', $listId);
    }

    public function scopeGeneral($query)
    {
        return $query->whereNull('list_id');
    }

    public function scopeCurrent($query)
    {
        $now = Carbon::now();
        return $query->where('start_date', '<=', $now)
                    ->where('end_date', '>=', $now);
    }

    public function scopeExpired($query)
    {
        return $query->where('end_date', '<', Carbon::now());
    }

    public function scopeUpcoming($query)
    {
        return $query->where('start_date', '>', Carbon::now());
    }

    public function scopeByPeriod($query, string $periodType)
    {
        return $query->where('period_type', $periodType);
    }

    public function scopeExceeded($query)
    {
        // This would need to be implemented with raw SQL for performance
        return $query->whereRaw('(SELECT COALESCE(SUM(total_amount), 0) FROM list_receipts lr WHERE lr.list_id = budgets.list_id AND lr.purchase_date BETWEEN budgets.start_date AND budgets.end_date) >= budgets.budget_amount');
    }

    /**
     * ✅ BOOT METHOD
     */
    protected static function boot()
    {
        parent::boot();
        
        static::saving(function ($budget) {
            if ($budget->name) {
                $budget->name = trim($budget->name);
            }
            
            if ($budget->budget_amount !== null) {
                $budget->budget_amount = self::validateBudgetAmount($budget->budget_amount);
            }
            
            if ($budget->alert_threshold !== null) {
                $budget->alert_threshold = max(1, min(100, $budget->alert_threshold));
            }
        });
    }
}