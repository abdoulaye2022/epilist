<?php
// src/Models/ReceiptItem.php — ligne d'un reçu importé (OCR ou manuel)

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReceiptItem extends Model
{
    protected $table = 'receipt_items';
    public $timestamps = false;

    protected $fillable = [
        'receipt_id',
        'raw_label',
        'product_name',
        'normalized_name',
        'quantity',
        'unit',
        'unit_price',
        'line_price',
        'confidence',
        'position',
        'created_at',
    ];

    protected $casts = [
        'quantity' => 'float',
        'unit_price' => 'float',
        'line_price' => 'float',
        'confidence' => 'integer',
        'position' => 'integer',
    ];

    public function receipt(): BelongsTo
    {
        return $this->belongsTo(ListReceipt::class, 'receipt_id');
    }
}
