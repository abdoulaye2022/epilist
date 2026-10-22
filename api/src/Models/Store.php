<?php
// src/Models/Store.php — magasin d'un utilisateur (ou d'un foyer, plus tard)

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Store extends Model
{
    use SoftDeletes;

    protected $table = 'stores';

    protected $fillable = [
        'space_id',
        'created_by_user_id',
        'user_id',
        'household_id',
        'name',
        'slug',
        'address',
        'city',
        'postal_code',
        'latitude',
        'longitude',
        'opening_hours',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'household_id' => 'integer',
        // Les heures d'ouverture sont un JSON par jour :
        //   {"mon":["08:00","21:00"], "sun":null}
        // `null` ou jour absent = ferme.
        'opening_hours' => 'array',
        'latitude' => 'float',
        'longitude' => 'float',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function categoryOrders(): HasMany
    {
        return $this->hasMany(StoreCategoryOrder::class)->orderBy('position');
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(StoreFavorite::class);
    }

    /**
     * Ce magasin est-il un favori de cette personne ?
     *
     * Le favori est porte par le MEMBRE : dans un espace partage, le
     * magasin de quartier de l'un n'est pas celui de l'autre.
     */
    public function isFavoriteFor(int $userId): bool
    {
        if ($this->relationLoaded('favorites')) {
            return $this->favorites->contains('user_id', $userId);
        }
        return $this->favorites()->where('user_id', $userId)->exists();
    }

    /**
     * Slug de comparaison : minuscules, sans accents, espaces normalisés.
     * Doit produire le même résultat que la normalisation côté app.
     */
    public static function slugify(string $name): string
    {
        $slug = mb_strtolower(trim($name), 'UTF-8');
        $translit = @iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $slug);
        if ($translit !== false && $translit !== '') {
            $slug = $translit;
        }
        return preg_replace('/\s+/', ' ', $slug);
    }
}
