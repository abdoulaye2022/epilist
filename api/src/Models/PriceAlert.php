<?php
// src/Models/PriceAlert.php — prix cible par espace (§25-§27).
// store_id NULL = « n'importe quel magasin ». L'anti-spam vit dans
// last_triggered_at (48 h) + last_notified_price (re-déclenche seulement
// si le prix observé est STRICTEMENT plus bas que le dernier notifié).

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PriceAlert extends Model
{
    protected $table = 'price_alerts';

    protected $fillable = [
        'space_id',
        'created_by_user_id',
        'product_name',
        'normalized_name',
        'store_id',
        'target_price',
        'is_active',
        'last_triggered_at',
        'last_notified_price',
    ];

    protected $casts = [
        'space_id' => 'integer',
        'created_by_user_id' => 'integer',
        'store_id' => 'integer',
        'target_price' => 'decimal:2',
        'is_active' => 'boolean',
        'last_triggered_at' => 'datetime',
        'last_notified_price' => 'decimal:2',
    ];
}
