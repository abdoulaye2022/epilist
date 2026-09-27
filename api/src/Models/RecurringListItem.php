<?php
// src/Models/RecurringListItem.php - Article modèle d'une liste récurrente.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RecurringListItem extends Model
{
    protected $table = 'recurring_list_items';
    public $timestamps = false;

    protected $fillable = [
        'recurring_list_id',
        'product_name',
        'normalized_name',
        'default_quantity',
        'unit',
        'optional',
    ];

    protected $casts = [
        'default_quantity' => 'integer',
        'optional' => 'boolean',
    ];
}
