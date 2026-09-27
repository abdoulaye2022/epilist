<?php
// src/Models/StoreCategoryOrder.php — position d'un rayon (kind) dans un magasin

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StoreCategoryOrder extends Model
{
    protected $table = 'store_category_orders';

    public $timestamps = false;

    protected $fillable = [
        'store_id',
        'category_kind',
        'position',
    ];

    protected $casts = [
        'store_id' => 'integer',
        'position' => 'integer',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }
}
