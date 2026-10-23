<?php
// src/Models/HomeInventory.php - Inventaire maison : trois états
// (at_home / running_low / out), quantité facultative, seuil, date de
// péremption facultative, et un niveau pour ce qui ne se compte pas.
//
// L'état n'est PLUS saisi quand une quantité existe : il s'en déduit.
// Une capture montrait « Alerte rupture : il n'y en a plus à la maison »
// juste à côté de « Quantité restante : 2, pour un seuil de 1 ». Les
// deux étaient vrais séparément — l'état venait d'un appui, la quantité
// d'un formulaire — et faux ensemble.

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

    /// Pour le liquide vaisselle et tout ce qui n'a pas de quantité
    /// juste : plein, à moitié, presque vide.
    public const LEVEL_FULL = 'full';
    public const LEVEL_HALF = 'half';
    public const LEVEL_LOW = 'low';

    public const LEVELS = [self::LEVEL_FULL, self::LEVEL_HALF, self::LEVEL_LOW];

    /// « Péremption 2 à 3 jours avant la date », dit l'analyse. Trois,
    /// pour que le produit tienne encore un repas de retard.
    public const EXPIRY_WARNING_DAYS = 3;

    /// Où le produit est rangé. L'analyse demande la zone parmi les
    /// données de chaque provision, et c'est elle qui donne son fond
    /// coloré à chaque bloc de l'écran.
    ///
    /// NULL est permis : un produit suivi avant la migration 014 n'a
    /// pas de zone, et lui en inventer une serait faux.
    public const ZONE_PANTRY = 'pantry';
    public const ZONE_FRIDGE = 'fridge';
    public const ZONE_FREEZER = 'freezer';
    public const ZONE_HOUSEHOLD = 'household';

    public const ZONES = [
        self::ZONE_PANTRY,
        self::ZONE_FRIDGE,
        self::ZONE_FREEZER,
        self::ZONE_HOUSEHOLD,
    ];

    protected $fillable = [
        'space_id',
        'created_by_user_id',
        'user_id',
        'product_name',
        'normalized_name',
        'category_id',
        'zone',
        'status',
        'quantity',
        'min_quantity',
        'reorder_quantity',
        'preferred_supplier_id',
        'unit',
        'expires_at',
        'level',
        'source',
    ];

    protected $casts = [
        'quantity' => 'float',
        'category_id' => 'integer',
        'expires_at' => 'date',
        'updated_at' => 'datetime',
    ];

    /**
     * L'état que la quantité impose.
     *
     * Sans quantité connue, le choix manuel ($manuel) est rendu tel
     * quel : c'est le cas des produits suivis au niveau (plein / à
     * moitié / presque vide) ou pas suivis du tout.
     *
     * Avec une quantité :
     *   - zéro ou moins -> rupture. Et SEULEMENT là : la rupture est un
     *     fait, pas une appréciation ;
     *   - au seuil ou en dessous -> stock bas ;
     *   - au-dessus -> à la maison. Deux unités pour un seuil de une ne
     *     sont pas un stock bas, même si quelqu'un l'a coché un jour.
     */
    public static function deduireStatut(?float $quantity, ?float $minQuantity, string $manuel): string
    {
        if ($quantity === null) {
            return in_array($manuel, self::STATUSES, true) ? $manuel : self::STATUS_AT_HOME;
        }
        if ($quantity <= 0) {
            return self::STATUS_OUT;
        }
        if ($minQuantity !== null && $quantity <= $minQuantity) {
            return self::STATUS_RUNNING_LOW;
        }
        return self::STATUS_AT_HOME;
    }

    /** Jours restants avant la péremption. null = pas de date. */
    public function joursAvantPeremption(): ?int
    {
        if ($this->expires_at === null) {
            return null;
        }
        // En jours de calendrier : « demain » doit valoir 1, même à 23 h.
        return \Carbon\Carbon::now()->startOfDay()
            ->diffInDays($this->expires_at->copy()->startOfDay(), false);
    }

    /** À terminer bientôt — ou déjà périmé. */
    public function peremptionProche(): bool
    {
        $jours = $this->joursAvantPeremption();
        return $jours !== null && $jours <= self::EXPIRY_WARNING_DAYS;
    }
}
