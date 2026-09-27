<?php
// src/Models/ProductPredictionPref.php - Préférences de prédiction par
// produit : désactivation, snooze, fréquence personnalisée.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductPredictionPref extends Model
{
    protected $table = 'product_prediction_prefs';

    protected $fillable = [
        'user_id',
        'product_name',
        'normalized_name',
        'enabled',
        'snoozed_until',
        'last_feedback',
        'custom_frequency_days',
    ];

    protected $casts = [
        'enabled' => 'boolean',
        'snoozed_until' => 'datetime',
        'custom_frequency_days' => 'integer',
    ];
}
