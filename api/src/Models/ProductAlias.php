<?php
// src/Models/ProductAlias.php — apprentissage libellé de reçu -> produit
// canonique (nom normalisé). Rempli quand l'utilisateur confirme une
// correspondance dans l'écran de validation de reçu.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductAlias extends Model
{
    protected $table = 'product_aliases';

    protected $fillable = [
        'user_id',
        'store_id',
        'alias',
        'normalized_alias',
        'product_name',
        'normalized_name',
        'barcode',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'store_id' => 'integer',
    ];
}
