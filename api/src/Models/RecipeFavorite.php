<?php
// src/Models/RecipeFavorite.php — la recette qu'un MEMBRE a mise en favori.
//
// Pas une colonne sur recipes : les huit recettes livrees avec
// l'application ont `user_id IS NULL`, donc elles sont PARTAGEES. Un
// favori pose la aurait valu pour tout le monde. Meme raison, meme
// forme que StoreFavorite.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RecipeFavorite extends Model
{
    protected $table = 'recipe_favorites';

    public $timestamps = false;

    protected $fillable = ['recipe_id', 'user_id'];

    protected $casts = [
        'recipe_id' => 'integer',
        'user_id' => 'integer',
        'created_at' => 'datetime',
    ];

    public function recipe(): BelongsTo
    {
        return $this->belongsTo(Recipe::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
