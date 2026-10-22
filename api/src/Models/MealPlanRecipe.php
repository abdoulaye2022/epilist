<?php
// src/Models/MealPlanRecipe.php - Recette d'un plan de repas.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MealPlanRecipe extends Model
{
    protected $table = 'meal_plan_recipes';
    public $timestamps = false;

    protected $fillable = [
        'meal_plan_id',
        'recipe_id',
        'servings',
        // « Lundi vert, Mardi jaune, Mercredi bleu » : la planche pose
        // un plat par jour. 1 = lundi ... 7 = dimanche, la meme
        // convention que recurring_lists.weekday ; NULL = plat du plan,
        // sans jour assigne.
        'weekday',
        'meal_slot',
    ];

    protected $casts = ['servings' => 'integer', 'weekday' => 'integer'];
}
