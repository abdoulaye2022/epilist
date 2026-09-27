<?php
// src/Models/Recipe.php - Recette (user_id NULL = recette de base).

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Recipe extends Model
{
    protected $table = 'recipes';

    protected $fillable = [
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
}
