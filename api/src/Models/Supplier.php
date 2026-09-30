<?php
// src/Models/Supplier.php - Fournisseur d'un espace professionnel (§22).

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Supplier extends Model
{
    use SoftDeletes;

    protected $table = 'suppliers';

    protected $fillable = [
        'space_id', 'name', 'contact_name', 'phone', 'email',
        'notes', 'is_active', 'created_by_user_id',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];
}
