<?php
// app/Models/ListItem.php - VERSION MULTILINGUE AVEC SUPPORT EN/FR

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
     * ✅ VALIDATION RULES WITH ENGLISH MESSAGES
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

    /**
     * ✅ MULTILINGUAL PRODUCT NAME NORMALIZATION (EN/FR)
     */
    public static function normalizeProductName(string $name): string
    {
        // 1. Basic cleanup
        $name = trim($name);
        $name = preg_replace('/\s+/', ' ', $name);
        
        // 2. Proper capitalization
        $name = mb_convert_case($name, MB_CASE_TITLE, 'UTF-8');
        
        // 3. Multilingual corrections for common food products
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

    /**
     * ✅ MULTILINGUAL STORE NAME NORMALIZATION
     */
    public static function normalizeStoreName(?string $store): ?string
    {
        if (empty($store)) {
            return null;
        }
        
        $store = trim($store);
        $store = mb_convert_case($store, MB_CASE_TITLE, 'UTF-8');
        
        // Store corrections for major Canadian chains
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
     * ✅ ENHANCED PRICE VALIDATION
     */
    public static function validatePrice(?float $price): ?float
    {
        if ($price === null) {
            return null;
        }
        
        // Round to 2 decimals
        $price = round($price, 2);
        
        // Check limits
        if ($price < 0) {
            throw new \InvalidArgumentException('Price cannot be negative');
        }
        
        if ($price > 999999.99) {
            throw new \InvalidArgumentException('Price is too high');
        }
        
        return $price;
    }

    /**
     * ✅ ENHANCED QUANTITY VALIDATION
     */
    public static function validateQuantity(?int $quantity): int
    {
        if ($quantity === null) {
            return 1; // Default value
        }
        
        if ($quantity < 1) {
            throw new \InvalidArgumentException('Quantity must be at least 1');
        }
        
        if ($quantity > 999) {
            throw new \InvalidArgumentException('Quantity cannot exceed 999');
        }
        
        return $quantity;
    }

    /**
     * ✅ CLEAN CREATION METHOD
     */
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

    /**
     * ✅ CLEAN UPDATE METHOD
     */
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

    /**
     * ✅ ENHANCED DUPLICATE DETECTION (MULTILINGUAL)
     */
    public static function findPotentialDuplicates(int $listId, string $productName, ?string $storeName = null): array
    {
        $normalizedName = self::normalizeProductName($productName);
        
        // Create variations for better matching
        $searchVariations = [
            $normalizedName,
            // Remove common words for better matching
            preg_replace('/\b(de|du|des|the|a|an|of)\b/i', '', $normalizedName),
            // First word only for partial matches
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
        
        // If store specified, filter by same store
        if ($storeName) {
            $normalizedStore = self::normalizeStoreName($storeName);
            $query->where('store_name', $normalizedStore);
        }
        
        return $query->get()->toArray();
    }

    /**
     * ✅ MODEL EVENTS FOR AUTO-CLEANING
     */
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

    /**
     * ✅ MULTILINGUAL SEARCH SCOPE
     */
    public function scopeSearchByName($query, string $search)
    {
        $normalizedSearch = self::normalizeProductName($search);
        
        // Search in both original and normalized forms
        return $query->where(function($q) use ($search, $normalizedSearch) {
            $q->where('product_name', 'LIKE', "%{$search}%")
              ->orWhere('product_name', 'LIKE', "%{$normalizedSearch}%");
        });
    }

    /**
     * ✅ FORMATTED ACCESSORS
     */
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
        if ($this->price === null) {
            return '';
        }
        
        return '$' . number_format($this->price, 2);
    }

    /**
     * Relation with shopping list
     */
    public function shoppingList(): BelongsTo
    {
        return $this->belongsTo(ShoppingList::class, 'list_id');
    }
}