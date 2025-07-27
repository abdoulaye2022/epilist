<?php
// src/Models/Currency.php - VERSION AFFICHAGE SEULEMENT

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
        return static::findByCode('CAD') ?? static::find(1);
    }

    /**
     * ✅ MÉTHODES DE FORMATAGE (SANS CONVERSION)
     */

    /**
     * Formater un montant avec le symbole de cette devise (AFFICHAGE SEULEMENT)
     */
    public function formatAmountDisplay(float $amount, bool $showCode = false): string
    {
        $formatted = number_format($amount, 2);
        
        if ($showCode) {
            return "{$this->symbol}{$formatted} {$this->code}";
        }
        
        return "{$this->symbol}{$formatted}";
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
}