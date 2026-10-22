<?php
// src/Models/Recipe.php - Recette (user_id NULL = recette de base).

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Recipe extends Model
{
    protected $table = 'recipes';

    protected $fillable = [
        'space_id',
        'created_by_user_id',
        'user_id',
        'name',
        'description',
        'servings',
        'preparation_time',
        'category',
        'image_url',
        'active',
    ];

    protected $casts = [
        'servings' => 'integer',
        'preparation_time' => 'integer',
        'active' => 'boolean',
    ];

    public function ingredients(): HasMany
    {
        return $this->hasMany(RecipeIngredient::class, 'recipe_id');
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(RecipeFavorite::class, 'recipe_id');
    }

    /**
     * Cette recette est-elle un favori de cette personne ?
     *
     * Jamais une colonne sur la recette : les recettes livrees avec
     * l'application sont partagees par tous les comptes.
     */
    public function isFavoriteFor(int $userId): bool
    {
        if ($this->relationLoaded('favorites')) {
            return $this->favorites->contains('user_id', $userId);
        }
        return $this->favorites()->where('user_id', $userId)->exists();
    }
}
