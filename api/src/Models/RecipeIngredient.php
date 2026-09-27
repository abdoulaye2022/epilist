<?php
// src/Models/RecipeIngredient.php - Ingrédient d'une recette, avec nom
// normalisé pour le mapping vers les produits EpiList.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RecipeIngredient extends Model
{
    protected $table = 'recipe_ingredients';
    public $timestamps = false;

    protected $fillable = [
        'recipe_id',
        'ingredient_name',
        'normalized_name',
        'quantity',
        'unit',
        'optional',
        'category_kind',
    ];

    protected $casts = [
        'quantity' => 'float',
        'optional' => 'boolean',
    ];
}
