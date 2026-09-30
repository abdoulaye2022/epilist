<?php
// src/Models/HomeInventory.php - Inventaire maison ultra-simple :
// trois états (at_home / running_low / out), quantité facultative.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HomeInventory extends Model
{
    protected $table = 'home_inventory';

    public const STATUS_AT_HOME = 'at_home';
    public const STATUS_RUNNING_LOW = 'running_low';
    public const STATUS_OUT = 'out';

    public const STATUSES = [
        self::STATUS_AT_HOME,
        self::STATUS_RUNNING_LOW,
        self::STATUS_OUT,
    ];

    protected $fillable = [
        'space_id',
        'created_by_user_id',
        'user_id',
        'product_name',
        'normalized_name',
        'category_id',
        'status',
        'quantity',
        'unit',
        'source',
    ];

    protected $casts = [
        'quantity' => 'float',
        'category_id' => 'integer',
        'updated_at' => 'datetime',
    ];
}
