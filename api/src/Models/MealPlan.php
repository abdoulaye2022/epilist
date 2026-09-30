<?php
// src/Models/MealPlan.php - Plan de repas enregistré.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MealPlan extends Model
{
    protected $table = 'meal_plans';
    public $timestamps = false;

    protected $fillable = [
        'space_id',
        'created_by_user_id','user_id', 'name', 'people', 'budget_max', 'created_at'];

    protected $casts = [
        'people' => 'integer',
        'budget_max' => 'float',
    ];
}
