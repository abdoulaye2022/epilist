<?php
// src/Models/PurchaseRequestEvent.php - Historique d'une demande (§20).

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseRequestEvent extends Model
{
    protected $table = 'purchase_request_events';

    public $timestamps = false;

    protected $fillable = [
        'request_id', 'user_id', 'from_status', 'to_status', 'comment', 'created_at',
    ];
}
