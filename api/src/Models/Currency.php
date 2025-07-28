<?php
// src/Models/Currency.php - VERSION CORRIGÉE AVEC formatAmount()

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Currency extends Model
{
    protected $table = 'currencies';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'code',
        'name',
        'symbol',
        'is_active',
        'is_popular',
        'display_order'
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_popular' => 'boolean',
        'display_order' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime'
    ];

    protected $attributes = [
        'is_active' => true,
        'is_popular' => false,
        'display_order' => 999
    ];

    /**
     * Relation avec les utilisateurs qui utilisent cette devise
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class, 'currency_id');
    }

    /**
     * ✅ SCOPES POUR FILTRER LES DEVISES
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopePopular($query)
    {
        return $query->where('is_popular', true);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('display_order')
                    ->orderBy('name');
    }

    /**
     * ✅ MÉTHODES UTILITAIRES
     */

    /**
     * Obtenir toutes les devises actives ordonnées
     */
    public static function getActiveOrdered(): array
    {
        return static::active()
            ->ordered()
            ->get()
            ->toArray();
    }

    /**
     * Obtenir les devises populaires
     */
    public static function getPopular(): array
    {
        return static::active()
            ->popular()
            ->ordered()
            ->get()
            ->toArray();
    }

    /**
     * Obtenir une devise par son code
     */
    public static function findByCode(string $code): ?self
    {
        return static::where('code', strtoupper($code))
            ->active()
            ->first();
    }

    /**
     * Obtenir la devise par défaut (CAD)
     */
    public static function getDefault(): self
    {
        $default = static::findByCode('CAD');
        
        if (!$default) {
            // Si CAD n'existe pas, retourner la première devise active
            $default = static::active()->first();
        }
        
        if (!$default) {
            // Créer une devise par défaut si aucune n'existe
            $default = new static([
                'code' => 'CAD',
                'name' => 'Dollar canadien',
                'symbol' => '$',
                'is_active' => true,
                'is_popular' => true,
                'display_order' => 1
            ]);
        }
        
        return $default;
    }

    /**
     * ✅ MÉTHODES DE FORMATAGE (SANS CONVERSION)
     */

    /**
     * ✅ MÉTHODE PRINCIPALE utilisée par les contrôleurs
     * Formater un montant avec le symbole de cette devise
     */
    public function formatAmount(float $amount, bool $showCode = false): string
    {
        $formatted = number_format($amount, 2);
        
        if ($showCode) {
            return "{$this->symbol}{$formatted} {$this->code}";
        }
        
        return "{$this->symbol}{$formatted}";
    }

    /**
     * Alias pour la compatibilité (AFFICHAGE SEULEMENT)
     */
    public function formatAmountDisplay(float $amount, bool $showCode = false): string
    {
        return $this->formatAmount($amount, $showCode);
    }

    /**
     * Formatage avec style personnalisé selon la devise
     */
    public function formatAmountWithStyle(float $amount, string $style = 'standard'): string
    {
        $formatted = number_format($amount, 2);
        
        switch ($style) {
            case 'compact':
                return "{$this->symbol}{$formatted}";
                
            case 'full':
                return "{$this->symbol}{$formatted} {$this->code} ({$this->name})";
                
            case 'code_only':
                return "{$formatted} {$this->code}";
                
            case 'standard':
            default:
                return "{$this->symbol}{$formatted}";
        }
    }

    /**
     * Formatage selon les conventions locales de la devise
     */
    public function formatAmountLocalized(float $amount): string
    {
        $formatted = number_format($amount, 2);
        
        // Règles de formatage selon la devise
        switch ($this->code) {
            case 'EUR':
                // Format européen: 1 234,56 €
                return number_format($amount, 2, ',', ' ') . ' ' . $this->symbol;
                
            case 'USD':
            case 'CAD':
            case 'AUD':
            case 'NZD':
                // Format nord-américain: $1,234.56
                return $this->symbol . number_format($amount, 2);
                
            case 'GBP':
                // Format britannique: £1,234.56
                return $this->symbol . number_format($amount, 2);
                
            case 'JPY':
                // Yen japonais sans décimales: ¥1,234
                return $this->symbol . number_format($amount, 0);
                
            case 'CHF':
                // Franc suisse: CHF 1'234.56
                return $this->code . ' ' . number_format($amount, 2, '.', "'");
                
            default:
                return $this->formatAmount($amount);
        }
    }

    /**
     * Obtenir le nom d'affichage complet
     */
    public function getDisplayNameAttribute(): string
    {
        return "{$this->name} ({$this->code})";
    }

    /**
     * Obtenir les informations formatées pour l'API
     */
    public function getApiFormatAttribute(): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,
            'symbol' => $this->symbol,
            'display_name' => $this->display_name,
            'is_popular' => $this->is_popular
        ];
    }

    /**
     * ✅ MÉTHODES DE VALIDATION DES MONTANTS
     */

    /**
     * Valider et nettoyer un montant
     */
    public function validateAmount(float $amount): float
    {
        // Arrondir selon la devise
        $decimals = $this->getDecimalPlaces();
        return round($amount, $decimals);
    }

    /**
     * Obtenir le nombre de décimales pour cette devise
     */
    public function getDecimalPlaces(): int
    {
        // Certaines devises n'utilisent pas de décimales
        $noDecimalCurrencies = ['JPY', 'KRW', 'VND', 'CLP'];
        
        if (in_array($this->code, $noDecimalCurrencies)) {
            return 0;
        }
        
        // La plupart des devises utilisent 2 décimales
        return 2;
    }

    /**
     * ✅ VALIDATION
     */

    /**
     * Règles de validation pour la création/mise à jour
     */
    public static function getValidationRules(): array
    {
        return [
            'code' => [
                'required' => 'Currency code is required',
                'lengthBetween' => [[3, 3], 'Currency code must be exactly 3 characters'],
                'regex' => ['/^[A-Z]{3}$/', 'Currency code must be 3 uppercase letters']
            ],
            'name' => [
                'required' => 'Currency name is required',
                'lengthMax' => [100, 'Currency name cannot exceed 100 characters']
            ],
            'symbol' => [
                'required' => 'Currency symbol is required',
                'lengthMax' => [10, 'Currency symbol cannot exceed 10 characters']
            ],
            'display_order' => [
                'integer' => 'Display order must be an integer',
                'min' => [1, 'Display order must be at least 1']
            ]
        ];
    }

    /**
     * ✅ CONSTANTES UTILES
     */
    public const DEFAULT_CURRENCY_CODE = 'CAD';
    public const SUPPORTED_CURRENCIES = [
        'CAD', 'USD', 'EUR', 'GBP', 'JPY', 'CHF', 'AUD', 'NZD'
    ];

    /**
     * Vérifier si un code de devise est supporté
     */
    public static function isSupported(string $code): bool
    {
        return in_array(strtoupper($code), static::SUPPORTED_CURRENCIES);
    }

    /**
     * ✅ MÉTHODES STATIQUES UTILES
     */

    /**
     * Formater rapidement un montant avec une devise
     */
    public static function quickFormat(float $amount, string $currencyCode = 'CAD'): string
    {
        $currency = static::findByCode($currencyCode) ?? static::getDefault();
        return $currency->formatAmount($amount);
    }

    /**
     * Obtenir la liste des devises pour un select
     */
    public static function getSelectOptions(): array
    {
        return static::active()
            ->ordered()
            ->get()
            ->map(function ($currency) {
                return [
                    'value' => $currency->id,
                    'label' => $currency->display_name,
                    'code' => $currency->code,
                    'symbol' => $currency->symbol
                ];
            })
            ->toArray();
    }

    /**
     * ✅ BOOT METHOD pour les événements du modèle
     */
    protected static function boot()
    {
        parent::boot();
        
        // Normaliser le code en majuscules avant sauvegarde
        static::saving(function ($currency) {
            $currency->code = strtoupper($currency->code);
        });
    }

    /**
     * ✅ ACCESSEURS ET MUTATEURS
     */

    /**
     * Mutateur pour le code de devise
     */
    public function setCodeAttribute($value)
    {
        $this->attributes['code'] = strtoupper($value);
    }

    /**
     * Accesseur pour vérifier si c'est la devise par défaut
     */
    public function getIsDefaultAttribute(): bool
    {
        return $this->code === static::DEFAULT_CURRENCY_CODE;
    }
}