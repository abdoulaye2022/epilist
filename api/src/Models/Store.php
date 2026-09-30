<?php
// src/Models/Store.php — magasin d'un utilisateur (ou d'un foyer, plus tard)

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Store extends Model
{
    use SoftDeletes;

    protected $table = 'stores';

    protected $fillable = [
        'space_id',
        'created_by_user_id',
        'user_id',
        'household_id',
        'name',
        'slug',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'household_id' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function categoryOrders(): HasMany
    {
        return $this->hasMany(StoreCategoryOrder::class)->orderBy('position');
    }

    /**
     * Slug de comparaison : minuscules, sans accents, espaces normalisés.
     * Doit produire le même résultat que la normalisation côté app.
     */
    public static function slugify(string $name): string
    {
        $slug = mb_strtolower(trim($name), 'UTF-8');
        $translit = @iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $slug);
        if ($translit !== false && $translit !== '') {
            $slug = $translit;
        }
        return preg_replace('/\s+/', ' ', $slug);
    }
}
