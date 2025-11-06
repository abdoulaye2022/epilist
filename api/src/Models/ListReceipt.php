<?php
// app/Models/ListReceipt.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class ListReceipt extends Model
{
    use SoftDeletes;

    protected $table = 'list_receipts';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'list_id',
        'store_name',
        'total_amount',
        'notes',
        'purchase_date',
        'created_at',
        'updated_at',
        'deleted_at'
    ];

    protected $casts = [
        'total_amount' => 'float',
        'purchase_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
    ];

    /**
     *  VALIDATION RULES WITH ENGLISH MESSAGES
     */
    public static function getValidationRules(): array
    {
        return [
            'store_name' => [
                'required' => 'Store name is required',
                'lengthMax' => ['255', 'Store name cannot exceed 255 characters'],
                'lengthMin' => ['2', 'Store name must be at least 2 characters']
            ],
            'total_amount' => [
                'required' => 'Total amount is required',
                'numeric' => 'Total amount must be a number',
                'min' => ['0.01', 'Total amount must be at least 0.01'],
                'max' => ['999999.99', 'Total amount cannot exceed 999,999.99']
            ],
            'purchase_date' => [
                'required' => 'Purchase date is required',
                'date' => 'Purchase date must be a valid date'
            ],
            'notes' => [
                'lengthMax' => ['1000', 'Notes cannot exceed 1000 characters']
            ]
        ];
    }

    /**
     *  NORMALIZE STORE NAME (similar to ListItem)
     */
    public static function normalizeStoreName(string $store): string
    {
        $store = trim($store);
        $store = mb_convert_case($store, MB_CASE_TITLE, 'UTF-8');
        
        $storeCorrections = [
            // Quebec/French Canada
            'Iga' => 'IGA',
            'I.g.a' => 'IGA',
            'I.G.A' => 'IGA',
            'Metro' => 'Métro',
            'Provigo' => 'Provigo',
            'Super C' => 'Super C',
            'Maxi' => 'Maxi',
            'Maxi Et Cie' => 'Maxi & Cie',
            'Jean Coutu' => 'Jean Coutu',
            'Pharmaprix' => 'Pharmaprix',
            'Uniprix' => 'Uniprix',
            'Brunet' => 'Brunet',
            
            // English Canada
            'Walmart' => 'Walmart',
            'Wal Mart' => 'Walmart',
            'Wal-mart' => 'Walmart',
            'Costco' => 'Costco',
            'Sobeys' => 'Sobeys',
            'Loblaws' => 'Loblaws',
            'No Frills' => 'No Frills',
            'Nofrills' => 'No Frills',
            'Real Canadian Superstore' => 'Real Canadian Superstore',
            'Superstore' => 'Real Canadian Superstore',
            'Zehrs' => 'Zehrs',
            'Food Basics' => 'Food Basics',
            'Freshco' => 'FreshCo',
            'Fresh Co' => 'FreshCo',
            'Metro Ontario' => 'Metro',
            'Farm Boy' => 'Farm Boy',
            'Longo\'s' => 'Longo\'s',
            'Longos' => 'Longo\'s',
            
            // Generic terms
            'Grocery Store' => 'Grocery Store',
            'Épicerie' => 'Épicerie',
            'Supermarket' => 'Supermarket',
            'Supermarché' => 'Supermarché',
            'Convenience Store' => 'Convenience Store',
            'Dépanneur' => 'Dépanneur'
        ];
        
        foreach ($storeCorrections as $pattern => $correction) {
            if (stripos($store, $pattern) !== false) {
                return $correction;
            }
        }
        
        return $store;
    }

    /**
     *  VALIDATE TOTAL AMOUNT
     */
    public static function validateTotalAmount($amount): float
    {
        $amount = (float) $amount;
        $amount = round($amount, 2);
        
        if ($amount < 0.01) {
            throw new \InvalidArgumentException('Total amount must be at least 0.01');
        }
        
        if ($amount > 999999.99) {
            throw new \InvalidArgumentException('Total amount is too high');
        }
        
        return $amount;
    }

    /**
     *  VALIDATE PURCHASE DATE
     */
    public static function validatePurchaseDate($date): Carbon
    {
        if (is_string($date)) {
            $carbonDate = Carbon::parse($date);
        } elseif ($date instanceof Carbon) {
            $carbonDate = $date;
        } else {
            throw new \InvalidArgumentException('Invalid date format');
        }
        
        // Ne peut pas être dans le futur
        if ($carbonDate->isFuture()) {
            throw new \InvalidArgumentException('Purchase date cannot be in the future');
        }
        
        // Ne peut pas être trop ancienne (ex: plus de 2 ans)
        if ($carbonDate->isBefore(Carbon::now()->subYears(2))) {
            throw new \InvalidArgumentException('Purchase date cannot be more than 2 years ago');
        }
        
        return $carbonDate;
    }

    /**
     *  CREATE CLEAN RECEIPT
     */
    public static function createClean(array $data): self
    {
        $cleanData = [
            'list_id' => $data['list_id'],
            'store_name' => self::normalizeStoreName($data['store_name']),
            'total_amount' => self::validateTotalAmount($data['total_amount']),
            'purchase_date' => self::validatePurchaseDate($data['purchase_date']),
            'notes' => !empty($data['notes']) ? trim($data['notes']) : null
        ];
        
        return self::create($cleanData);
    }

    /**
     *  UPDATE CLEAN RECEIPT - VERSION AVEC LOGS DÉTAILLÉS
     */
    public function updateClean(array $data): bool
    {
        error_log(" ListReceipt::updateClean called");
        error_log(" Input data: " . json_encode($data));
        
        $cleanData = [];
        
        try {
            if (isset($data['store_name'])) {
                $cleanData['store_name'] = self::normalizeStoreName($data['store_name']);
                error_log(" Normalized store name: " . $cleanData['store_name']);
            }
            
            if (isset($data['total_amount'])) {
                $cleanData['total_amount'] = self::validateTotalAmount($data['total_amount']);
                error_log(" Validated amount: " . $cleanData['total_amount']);
            }
            
            if (isset($data['purchase_date'])) {
                $cleanData['purchase_date'] = self::validatePurchaseDate($data['purchase_date']);
                error_log(" Validated date: " . $cleanData['purchase_date']->toDateString());
            }
            
            if (isset($data['notes'])) {
                $cleanData['notes'] = !empty($data['notes']) ? trim($data['notes']) : null;
                error_log(" Notes: " . ($cleanData['notes'] ?? 'NULL'));
            }
            
            error_log(" Clean data prepared: " . json_encode($cleanData));
            
            if (empty($cleanData)) {
                error_log(" No data to update in updateClean");
                return true; // Rien à mettre à jour, considéré comme succès
            }
            
            //  UTILISER LA MÉTHODE UPDATE D'ELOQUENT
            error_log(" Calling Eloquent update method...");
            error_log(" Current receipt ID: " . $this->id);
            error_log(" Current receipt data before update: " . json_encode([
                'store_name' => $this->store_name,
                'total_amount' => $this->total_amount,
                'purchase_date' => $this->purchase_date?->toDateString(),
                'notes' => $this->notes
            ]));
            
            $result = $this->update($cleanData);
            
            error_log(" Eloquent update result: " . ($result ? 'SUCCESS' : 'FAILED'));
            
            if ($result) {
                // Recharger le modèle pour vérifier les changements
                $this->refresh();
                error_log(" Receipt data after update: " . json_encode([
                    'store_name' => $this->store_name,
                    'total_amount' => $this->total_amount,
                    'purchase_date' => $this->purchase_date?->toDateString(),
                    'notes' => $this->notes
                ]));
            }
            
            return $result;
            
        } catch (\Exception $e) {
            error_log(" Exception in updateClean: " . $e->getMessage());
            error_log(" Exception trace: " . $e->getTraceAsString());
            throw $e;
        }
    }

    /**
     *  FORMATAGE AVEC DEVISE - VERSION CORRIGÉE
     */
    public function getFormattedAmountInCurrency(?Currency $currency = null): string
    {
        if ($currency) {
            return $currency->formatAmount($this->total_amount);
        }

        // Format par défaut en CAD
        return '$' . number_format($this->total_amount, 2);
    }

    public function getFormattedAmountForUser(?User $user = null): string
    {
        if ($user && method_exists($user, 'getPreferredCurrency')) {
            $currency = $user->getPreferredCurrency();
            return $currency->formatAmount($this->total_amount);
        }

        return $this->getFormattedAmountInCurrency();
    }

    /**
     *  DONNÉES API - VERSION CORRIGÉE
     */
    public function getApiDataAttribute(): array
    {
        return [
            'id' => $this->id,
            'list_id' => $this->list_id,
            'store_name' => $this->store_name,
            'total_amount' => $this->total_amount,
            'notes' => $this->notes,
            'purchase_date' => $this->purchase_date->toDateString(),
            'formatted_amount' => $this->getFormattedAmountInCurrency(),
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString()
        ];
    }

    public function getApiDataForUser(?User $user = null): array
    {
        $data = $this->getApiDataAttribute();
        
        if ($user) {
            //  GESTION SÉCURISÉE DES DEVISES
            try {
                if (method_exists($user, 'getPreferredCurrency')) {
                    $currency = $user->getPreferredCurrency();
                } elseif ($user->currency) {
                    $currency = $user->currency;
                } else {
                    $currency = Currency::getDefault();
                }
                
                $data['formatted_amount'] = $currency->formatAmount($this->total_amount);
                $data['currency'] = [
                    'code' => $currency->code,
                    'symbol' => $currency->symbol
                ];
            } catch (\Exception $e) {
                // Fallback en cas d'erreur
                $data['formatted_amount'] = '$' . number_format($this->total_amount, 2);
                $data['currency'] = [
                    'code' => 'CAD',
                    'symbol' => '$'
                ];
            }
        }
        
        return $data;
    }

    /**
     *  BOOT METHOD AVEC LOGS
     */
    protected static function boot()
    {
        parent::boot();
        
        static::saving(function ($receipt) {
            error_log(" ListReceipt saving event triggered");
            error_log(" Data being saved: " . json_encode($receipt->toArray()));
            
            if ($receipt->store_name) {
                $oldStoreName = $receipt->store_name;
                $receipt->store_name = self::normalizeStoreName($receipt->store_name);
                if ($oldStoreName !== $receipt->store_name) {
                    error_log(" Store name normalized: '$oldStoreName' -> '{$receipt->store_name}'");
                }
            }
            
            if ($receipt->total_amount !== null) {
                $oldAmount = $receipt->total_amount;
                $receipt->total_amount = self::validateTotalAmount($receipt->total_amount);
                if ($oldAmount !== $receipt->total_amount) {
                    error_log(" Amount validated: $oldAmount -> {$receipt->total_amount}");
                }
            }
            
            if ($receipt->purchase_date) {
                $oldDate = $receipt->purchase_date;
                $receipt->purchase_date = self::validatePurchaseDate($receipt->purchase_date);
                if ($oldDate != $receipt->purchase_date) {
                    error_log(" Date validated: $oldDate -> {$receipt->purchase_date}");
                }
            }
        });
        
        static::saved(function ($receipt) {
            error_log(" ListReceipt saved successfully");
            error_log(" Final saved data: " . json_encode($receipt->toArray()));
        });
    }

    /**
     *  SCOPES
     */
    public function scopeByStore($query, string $storeName)
    {
        $normalizedStore = self::normalizeStoreName($storeName);
        return $query->where('store_name', $normalizedStore);
    }

    public function scopeInPeriod($query, Carbon $startDate, Carbon $endDate)
    {
        return $query->whereBetween('purchase_date', [$startDate, $endDate]);
    }

    public function scopeInMonth($query, int $year, int $month)
    {
        return $query->whereYear('purchase_date', $year)
                    ->whereMonth('purchase_date', $month);
    }

    /**
     *  RELATIONS
     */
    public function shoppingList(): BelongsTo
    {
        return $this->belongsTo(ShoppingList::class, 'list_id');
    }

    private static function checkAffectedBudgets(ListReceipt $receipt): void
    {
        if (!$receipt->list_id) {
            return;
        }
        
        $list = $receipt->shoppingList;
        if (!$list) {
            return;
        }
        
        // Vérifier les budgets spécifiques à cette liste
        $listBudgets = Budget::active()
            ->current()
            ->where('list_id', $receipt->list_id)
            ->where('start_date', '<=', $receipt->purchase_date)
            ->where('end_date', '>=', $receipt->purchase_date)
            ->get();
        
        // Vérifier les budgets généraux de l'utilisateur
        $generalBudgets = Budget::active()
            ->current()
            ->where('user_id', $list->user_id)
            ->whereNull('list_id')
            ->where('start_date', '<=', $receipt->purchase_date)
            ->where('end_date', '>=', $receipt->purchase_date)
            ->get();
        
        $allBudgets = $listBudgets->merge($generalBudgets);
        
        foreach ($allBudgets as $budget) {
            $alertData = BudgetAlertService::checkPurchaseAlert($budget, $receipt->total_amount);
            if ($alertData && $alertData['notification_sent']) {
                error_log("Push notification sent for budget {$budget->id} after receipt: {$alertData['message']}");
            }
        }
    }
}