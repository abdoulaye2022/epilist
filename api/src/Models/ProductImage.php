<?php
// src/Models/ProductImage.php — la photo d'un PRODUIT, pas d'un ecran.
//
// `list_items.image_url` existait depuis longtemps, mais rattachee a UN
// article d'UNE liste : la meme boite de pates photographiee la semaine
// derniere ne pouvait pas illustrer l'alerte de prix d'aujourd'hui.
//
// Clef : (space_id, normalized_name). L'espace, car une photo prise par
// un membre sert tout le foyer. Le nom normalise, car c'est la clef que
// tout le reste du projet utilise deja — purchase_history,
// product_aliases, community_prices.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductImage extends Model
{
    protected $table = 'product_images';

    protected $fillable = [
        'space_id',
        'normalized_name',
        'product_label',
        'image_url',
        'source',
        'created_by_user_id',
    ];

    protected $casts = [
        'space_id' => 'integer',
        'created_by_user_id' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Pose ou remplace la photo d'un produit.
     *
     * La normalisation passe TOUJOURS par
     * PurchaseHistory::normalizeProductName : deux implementations des
     * memes regles finiraient par diverger, et les photos cesseraient
     * de se retrouver.
     */
    public static function poser(
        ?int $spaceId,
        string $productName,
        string $imageUrl,
        ?int $userId = null,
        string $source = 'user'
    ): ?self {
        $clef = PurchaseHistory::normalizeProductName($productName);
        if ($clef === '' || trim($imageUrl) === '') {
            return null;
        }

        $image = self::where('space_id', $spaceId)->where('normalized_name', $clef)->first();
        if ($image) {
            $image->update([
                'product_label' => $productName,
                'image_url' => $imageUrl,
                'source' => $source,
            ]);
            return $image;
        }

        return self::create([
            'space_id' => $spaceId,
            'normalized_name' => $clef,
            'product_label' => $productName,
            'image_url' => $imageUrl,
            'source' => $source,
            'created_by_user_id' => $userId,
        ]);
    }

    /**
     * Les photos d'une liste de noms normalises, pretes a etre posees
     * sur des alertes ou des suggestions.
     *
     * @param string[] $clefs
     * @return array<string, string> clef normalisee => URL
     */
    public static function pourClefs(?int $spaceId, array $clefs): array
    {
        $clefs = array_values(array_unique(array_filter($clefs)));
        if ($clefs === []) {
            return [];
        }
        return self::where('space_id', $spaceId)
            ->whereIn('normalized_name', $clefs)
            ->pluck('image_url', 'normalized_name')
            ->all();
    }
}
