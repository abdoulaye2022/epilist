<?php
// app/Models/ProductSuggestion.php - VERSION CORRIGÉE POUR SLIM

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon; // ✅ AJOUT DE L'IMPORT CARBON

class ProductSuggestion extends Model
{
    protected $table = 'product_suggestions';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'user_id',
        'product_name',
        'normalized_name', // Version normalisée pour les recherches
        'price',
        'store_name',
        'usage_count', // Nombre de fois utilisé
        'last_used_at',
        'created_at',
        'updated_at'
    ];

    protected $casts = [
        'price' => 'float',
        'usage_count' => 'integer',
        'last_used_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime'
    ];

    /**
     * Relation avec l'utilisateur
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Normalise le nom du produit pour les recherches
     */
    public static function normalizeName(string $name): string
    {
        // Convertir en minuscules, supprimer les accents et caractères spéciaux
        $normalized = strtolower($name);
        $normalized = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $normalized);
        $normalized = preg_replace('/[^a-z0-9\s]/', '', $normalized);
        $normalized = preg_replace('/\s+/', ' ', $normalized);
        return trim($normalized);
    }

    /**
     * Recherche des suggestions par nom
     */
    public static function searchByName(int $userId, string $query, int $limit = 10): array
    {
        $normalizedQuery = self::normalizeName($query);
        
        return self::where('user_id', $userId)
            ->where('normalized_name', 'LIKE', "%{$normalizedQuery}%")
            ->orderBy('usage_count', 'desc')
            ->orderBy('last_used_at', 'desc')
            ->limit($limit)
            ->get()
            ->toArray();
    }

    /**
     * Créer ou mettre à jour une suggestion
     */
    public static function createOrUpdate(int $userId, array $productData): self
    {
        $normalizedName = self::normalizeName($productData['product_name']);
        
        // Chercher une suggestion existante
        $suggestion = self::where('user_id', $userId)
            ->where('normalized_name', $normalizedName)
            ->first();

        if ($suggestion) {
            // Mettre à jour la suggestion existante
            $suggestion->update([
                'product_name' => $productData['product_name'], // Garder la version la plus récente
                'price' => $productData['price'] ?? $suggestion->price,
                'store_name' => $productData['store_name'] ?? $suggestion->store_name,
                'usage_count' => $suggestion->usage_count + 1,
                'last_used_at' => Carbon::now() // ✅ CORRECTION: utiliser Carbon::now()
            ]);
        } else {
            // Créer une nouvelle suggestion
            $suggestion = self::create([
                'user_id' => $userId,
                'product_name' => $productData['product_name'],
                'normalized_name' => $normalizedName,
                'price' => $productData['price'] ?? null,
                'store_name' => $productData['store_name'] ?? null,
                'usage_count' => 1,
                'last_used_at' => Carbon::now() // ✅ CORRECTION: utiliser Carbon::now()
            ]);
        }

        return $suggestion;
    }

    /**
     * Obtenir les suggestions les plus populaires
     */
    public static function getPopular(int $userId, int $limit = 20): array
    {
        return self::where('user_id', $userId)
            ->orderBy('usage_count', 'desc')
            ->orderBy('last_used_at', 'desc')
            ->limit($limit)
            ->get()
            ->toArray();
    }

    /**
     * ✅ NOUVELLES MÉTHODES UTILES
     */

    /**
     * Obtenir le prix formaté
     */
    public function getFormattedPriceAttribute(): string
    {
        if ($this->price === null) {
            return '';
        }
        return '$' . number_format($this->price, 2);
    }

    /**
     * Obtenir les informations d'usage
     */
    public function getUsageInfoAttribute(): string
    {
        return "Utilisé {$this->usage_count} fois";
    }

    /**
     * Obtenir la date de dernière utilisation formatée
     */
    public function getLastUsedFormattedAttribute(): ?string
    {
        if ($this->last_used_at === null) {
            return null;
        }

        $date = Carbon::parse($this->last_used_at);
        $now = Carbon::now();
        
        if ($date->isToday()) {
            return "Aujourd'hui";
        } elseif ($date->isYesterday()) {
            return "Hier";
        } elseif ($date->diffInDays($now) < 7) {
            return "Il y a " . $date->diffInDays($now) . " jours";
        } elseif ($date->diffInWeeks($now) < 4) {
            $weeks = $date->diffInWeeks($now);
            return "Il y a {$weeks} semaine" . ($weeks > 1 ? 's' : '');
        } else {
            $months = $date->diffInMonths($now);
            return "Il y a {$months} mois";
        }
    }

    /**
     * Incrémenter le compteur d'usage
     */
    public function incrementUsage(): void
    {
        $this->update([
            'usage_count' => $this->usage_count + 1,
            'last_used_at' => Carbon::now()
        ]);
    }

    /**
     * Mettre à jour les informations du produit
     */
    public function updateProductInfo(array $data): void
    {
        $updateData = [];
        
        if (isset($data['product_name'])) {
            $updateData['product_name'] = $data['product_name'];
            $updateData['normalized_name'] = self::normalizeName($data['product_name']);
        }
        
        if (isset($data['price'])) {
            $updateData['price'] = $data['price'];
        }
        
        if (isset($data['store_name'])) {
            $updateData['store_name'] = $data['store_name'];
        }

        if (!empty($updateData)) {
            $this->update($updateData);
        }
    }

    /**
     * Scope pour rechercher par nom normalisé
     */
    public function scopeSearchByNormalizedName($query, string $search)
    {
        $normalizedSearch = self::normalizeName($search);
        return $query->where('normalized_name', 'LIKE', "%{$normalizedSearch}%");
    }

    /**
     * Scope pour un utilisateur spécifique
     */
    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope pour ordonner par popularité
     */
    public function scopeOrderByPopularity($query)
    {
        return $query->orderBy('usage_count', 'desc')
                    ->orderBy('last_used_at', 'desc');
    }

    /**
     * Scope pour les suggestions récemment utilisées
     */
    public function scopeRecentlyUsed($query, int $days = 30)
    {
        return $query->where('last_used_at', '>=', Carbon::now()->subDays($days));
    }

    /**
     * Obtenir les statistiques d'usage pour un utilisateur
     */
    public static function getUserStats(int $userId): array
    {
        $totalSuggestions = self::where('user_id', $userId)->count();
        $totalUsage = self::where('user_id', $userId)->sum('usage_count');
        
        $mostUsed = self::where('user_id', $userId)
            ->orderBy('usage_count', 'desc')
            ->first();
            
        $recentlyUsed = self::where('user_id', $userId)
            ->orderBy('last_used_at', 'desc')
            ->limit(5)
            ->get();

        return [
            'total_suggestions' => $totalSuggestions,
            'total_usage' => $totalUsage,
            'average_usage' => $totalSuggestions > 0 ? round($totalUsage / $totalSuggestions, 2) : 0,
            'most_used' => $mostUsed ? $mostUsed->toArray() : null,
            'recently_used' => $recentlyUsed->toArray()
        ];
    }

    /**
     * Nettoyer les anciennes suggestions non utilisées
     */
    public static function cleanupOldSuggestions(int $userId, int $daysOld = 90, int $minUsage = 1): int
    {
        return self::where('user_id', $userId)
            ->where('last_used_at', '<', Carbon::now()->subDays($daysOld))
            ->where('usage_count', '<', $minUsage)
            ->delete();
    }
}