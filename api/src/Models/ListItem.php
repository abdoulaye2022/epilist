<?php
// app/Models/ListItem.php - VERSION MISE À JOUR AVEC SUPPORT DEVISE

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
     * ✅ VALIDATION RULES WITH ENGLISH MESSAGES (inchangé)
     */
    public static function getValidationRules(): array
    {
        return [
            'product_name' => [
                'required' => 'Product name is required',
                'lengthMax' => ['255', 'Product name cannot exceed 255 characters'],
                'lengthMin' => ['2', 'Product name must be at least 2 characters']
            ],
            'quantity' => [
                'integer' => 'Quantity must be an integer',
                'min' => ['1', 'Quantity must be at least 1'],
                'max' => ['999', 'Quantity cannot exceed 999']
            ],
            'price' => [
                'numeric' => 'Price must be a number',
                'min' => ['0', 'Price cannot be negative'],
                'max' => ['999999.99', 'Price cannot exceed 999,999.99']
            ],
            'store_name' => [
                'lengthMax' => ['255', 'Store name cannot exceed 255 characters']
            ]
        ];
    }

    // ✅ TOUTES LES MÉTHODES EXISTANTES RESTENT IDENTIQUES
    // (normalizeProductName, normalizeStoreName, validatePrice, validateQuantity, etc.)
    
    public static function normalizeProductName(string $name): string
    {
        $name = trim($name);
        $name = preg_replace('/\s+/', ' ', $name);
        $name = mb_convert_case($name, MB_CASE_TITLE, 'UTF-8');
        
        $corrections = [
            // English plurals to singular
            'Apples' => 'Apple',
            'Bananas' => 'Banana',
            'Oranges' => 'Orange',
            'Tomatoes' => 'Tomato',
            'Potatoes' => 'Potato',
            'Onions' => 'Onion',
            'Carrots' => 'Carrot',
            'Eggs' => 'Egg',
            'Breads' => 'Bread',
            'Cheeses' => 'Cheese',
            'Milks' => 'Milk',
            
            // French plurals to singular
            'Pommes' => 'Pomme',
            'Bananes' => 'Banane',
            'Oranges' => 'Orange',
            'Tomates' => 'Tomate',
            'Pommes De Terre' => 'Pomme de terre',
            'Oignons' => 'Oignon',
            'Carottes' => 'Carotte',
            'Oeufs' => 'Œuf',
            'Pains' => 'Pain',
            'Fromages' => 'Fromage',
            'Laits' => 'Lait',
            
            // Common variations
            'Pâtes' => 'Pâte',
            'Pastas' => 'Pasta',
            'Yaourts' => 'Yaourt',
            'Yogurts' => 'Yogurt',
            'Yoghurts' => 'Yogurt',
            
            // Unit abbreviations (both languages)
            'Kg' => 'kg',
            'G' => 'g',
            'L' => 'l',
            'Ml' => 'ml',
            'Lb' => 'lb',
            'Oz' => 'oz',
            'Lbs' => 'lb',
            
            // Common brand/product corrections
            'Coca Cola' => 'Coca-Cola',
            'Coca-cola' => 'Coca-Cola',
            'Mac Donald' => 'McDonald\'s',
            'Mc Donald' => 'McDonald\'s'
        ];
        
        foreach ($corrections as $from => $to) {
            $name = str_ireplace($from, $to, $name);
        }
        
        return $name;
    }

    public static function normalizeStoreName(?string $store): ?string
    {
        if (empty($store)) {
            return null;
        }
        
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

    public static function validatePrice(?float $price): ?float
    {
        if ($price === null) {
            return null;
        }
        
        $price = round($price, 2);
        
        if ($price < 0) {
            throw new \InvalidArgumentException('Price cannot be negative');
        }
        
        if ($price > 999999.99) {
            throw new \InvalidArgumentException('Price is too high');
        }
        
        return $price;
    }

    public static function validateQuantity(?int $quantity): int
    {
        if ($quantity === null) {
            return 1;
        }
        
        if ($quantity < 1) {
            throw new \InvalidArgumentException('Quantity must be at least 1');
        }
        
        if ($quantity > 999) {
            throw new \InvalidArgumentException('Quantity cannot exceed 999');
        }
        
        return $quantity;
    }

    public static function createClean(array $data): self
    {
        $cleanData = [
            'list_id' => $data['list_id'],
            'product_name' => self::normalizeProductName($data['product_name']),
            'quantity' => self::validateQuantity($data['quantity'] ?? null),
            'price' => self::validatePrice($data['price'] ?? null),
            'store_name' => self::normalizeStoreName($data['store_name'] ?? null),
            'is_purchased' => $data['is_purchased'] ?? false
        ];
        
        return self::create($cleanData);
    }

    public function updateClean(array $data): bool
    {
        $cleanData = [];
        
        if (isset($data['product_name'])) {
            $cleanData['product_name'] = self::normalizeProductName($data['product_name']);
        }
        
        if (isset($data['quantity'])) {
            $cleanData['quantity'] = self::validateQuantity($data['quantity']);
        }
        
        if (isset($data['price'])) {
            $cleanData['price'] = self::validatePrice($data['price']);
        }
        
        if (isset($data['store_name'])) {
            $cleanData['store_name'] = self::normalizeStoreName($data['store_name']);
        }
        
        if (isset($data['is_purchased'])) {
            $cleanData['is_purchased'] = (bool)$data['is_purchased'];
        }
        
        return $this->update($cleanData);
    }

    public static function findPotentialDuplicates(int $listId, string $productName, ?string $storeName = null): array
    {
        $normalizedName = self::normalizeProductName($productName);
        
        $searchVariations = [
            $normalizedName,
            preg_replace('/\b(de|du|des|the|a|an|of)\b/i', '', $normalizedName),
            explode(' ', $normalizedName)[0]
        ];
        
        $query = self::where('list_id', $listId);
        
        $query->where(function($q) use ($searchVariations) {
            foreach ($searchVariations as $variation) {
                $variation = trim($variation);
                if (strlen($variation) >= 2) {
                    $q->orWhere('product_name', 'LIKE', "%{$variation}%");
                }
            }
        });
        
        if ($storeName) {
            $normalizedStore = self::normalizeStoreName($storeName);
            $query->where('store_name', $normalizedStore);
        }
        
        return $query->get()->toArray();
    }

    protected static function boot()
    {
        parent::boot();
        
        static::saving(function ($item) {
            if ($item->product_name) {
                $item->product_name = self::normalizeProductName($item->product_name);
            }
            
            if ($item->store_name) {
                $item->store_name = self::normalizeStoreName($item->store_name);
            }
            
            if ($item->price !== null) {
                $item->price = self::validatePrice($item->price);
            }
            
            if ($item->quantity !== null) {
                $item->quantity = self::validateQuantity($item->quantity);
            }
        });
    }

    public function scopeSearchByName($query, string $search)
    {
        $normalizedSearch = self::normalizeProductName($search);
        
        return $query->where(function($q) use ($search, $normalizedSearch) {
            $q->where('product_name', 'LIKE', "%{$search}%")
              ->orWhere('product_name', 'LIKE', "%{$normalizedSearch}%");
        });
    }

    // ✅ NOUVELLES MÉTHODES POUR LE FORMATAGE AVEC DEVISE

    /**
     * Obtenir le prix formaté dans une devise spécifique
     */
    public function getFormattedPriceInCurrency(?Currency $currency = null): string
    {
        if ($this->price === null) {
            return '';
        }

        if ($currency) {
            return $currency->formatAmount($this->price);
        }

        // Format par défaut en CAD
        return '$' . number_format($this->price, 2);
    }

    /**
     * Obtenir le prix formaté selon la devise de l'utilisateur
     */
    public function getFormattedPriceForUser(?User $user = null): string
    {
        if ($this->price === null) {
            return '';
        }

        if ($user) {
            $currency = $user->getPreferredCurrency();
            return $currency->formatAmount($this->price);
        }

        return $this->getFormattedPriceInCurrency();
    }

    /**
     * Obtenir le prix total formaté (prix × quantité)
     */
    public function getFormattedTotalPriceInCurrency(?Currency $currency = null): string
    {
        if ($this->price === null) {
            return '';
        }

        $totalPrice = $this->price * $this->quantity;

        if ($currency) {
            return $currency->formatAmount($totalPrice);
        }

        return '$' . number_format($totalPrice, 2);
    }

    /**
     * Obtenir le prix total formaté selon la devise de l'utilisateur
     */
    public function getFormattedTotalPriceForUser(?User $user = null): string
    {
        if ($this->price === null) {
            return '';
        }

        $totalPrice = $this->price * $this->quantity;

        if ($user) {
            $currency = $user->getPreferredCurrency();
            return $currency->formatAmount($totalPrice);
        }

        return '$' . number_format($totalPrice, 2);
    }

    /**
     * Convertir le prix vers une autre devise
     */
    public function convertPriceTo(string $toCurrencyCode): ?float
    {
        if ($this->price === null) {
            return null;
        }

        try {
            return Currency::convert($this->price, 'CAD', $toCurrencyCode);
        } catch (\Exception $e) {
            return null;
        }
    }

    // ✅ ACCESSEURS EXISTANTS AMÉLIORÉS

    public function getFormattedNameAttribute(): string
    {
        $name = $this->product_name;
        
        if ($this->quantity > 1) {
            $name = "{$this->quantity}x {$name}";
        }
        
        return $name;
    }

    public function getFormattedPriceAttribute(): string
    {
        return $this->getFormattedPriceInCurrency();
    }

    public function getFormattedTotalPriceAttribute(): string
    {
        return $this->getFormattedTotalPriceInCurrency();
    }

    /**
     * ✅ NOUVEAUX ACCESSEURS POUR LES DONNÉES API
     */
    public function getApiDataAttribute(): array
    {
        return [
            'id' => $this->id,
            'list_id' => $this->list_id,
            'product_name' => $this->product_name,
            'quantity' => $this->quantity,
            'price' => $this->price,
            'store_name' => $this->store_name,
            'is_purchased' => $this->is_purchased,
            'formatted_name' => $this->formatted_name,
            'formatted_price' => $this->formatted_price,
            'formatted_total_price' => $this->formatted_total_price,
            'total_price' => $this->price ? $this->price * $this->quantity : null,
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString()
        ];
    }

    /**
     * Obtenir les données API formatées selon la devise de l'utilisateur
     */
    public function getApiDataForUser(?User $user = null): array
    {
        $data = $this->getApiDataAttribute();
        
        if ($user && $this->price !== null) {
            $currency = $user->getPreferredCurrency();
            $data['formatted_price'] = $currency->formatAmount($this->price);
            $data['formatted_total_price'] = $currency->formatAmount($this->price * $this->quantity);
            $data['currency'] = [
                'code' => $currency->code,
                'symbol' => $currency->symbol
            ];
        }
        
        return $data;
    }

    /**
     * Relation with shopping list
     */
    public function shoppingList(): BelongsTo
    {
        return $this->belongsTo(ShoppingList::class, 'list_id');
    }

    private static function checkAffectedBudgets(ListItem $item): void
    {
        if (!$item->list_id || !$item->price) {
            return;
        }
        
        $list = $item->shoppingList;
        if (!$list) {
            return;
        }
        
        $purchaseAmount = $item->price * $item->quantity;
        $now = Carbon::now();
        
        // Vérifier les budgets spécifiques à cette liste
        $listBudgets = Budget::active()
            ->current()
            ->where('list_id', $item->list_id)
            ->get();
        
        // Vérifier les budgets généraux de l'utilisateur
        $generalBudgets = Budget::active()
            ->current()
            ->where('user_id', $list->user_id)
            ->whereNull('list_id')
            ->get();
        
        $allBudgets = $listBudgets->merge($generalBudgets);
        
        foreach ($allBudgets as $budget) {
            $alertData = BudgetAlertService::checkPurchaseAlert($budget, $purchaseAmount);
            if ($alertData && $alertData['notification_sent']) {
                error_log("Push notification sent for budget {$budget->id} after item purchase: {$alertData['message']}");
            }
        }
    }
}