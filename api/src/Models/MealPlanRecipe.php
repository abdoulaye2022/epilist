<?php
// src/Models/MealPlanRecipe.php - Recette d'un plan de repas.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MealPlanRecipe extends Model
{
    protected $table = 'meal_plan_recipes';
    public $timestamps = false;

    protected $fillable = ['meal_plan_id', 'recipe_id', 'servings'];

    protected $casts = ['servings' => 'integer'];
}
