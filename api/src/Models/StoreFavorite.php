<?php
// src/Models/StoreFavorite.php — le magasin qu'un MEMBRE a mis en favori.
//
// Le favori n'appartient pas au magasin mais a la personne : dans un
// espace partage, le magasin de quartier de l'un n'est pas celui de
// l'autre. D'ou une table de liaison plutot qu'une colonne sur stores.
//
// Il vivait auparavant dans les preferences de l'APPAREIL (Flutter,
// SharedPreferences) : perdu au changement de telephone, et invisible
// pour les autres membres.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StoreFavorite extends Model
{
    protected $table = 'store_favorites';

    /** Pas de updated_at sur cette table : poser un favori n'a pas d'histoire. */
    public $timestamps = false;

    protected $fillable = ['store_id', 'user_id'];

    protected $casts = [
        'store_id' => 'integer',
        'user_id' => 'integer',
        'created_at' => 'datetime',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
