<?php
// src/Models/Space.php - Un espace = le contexte dans lequel les achats
// sont gérés : personnel, foyer, restaurant, organisation.
// Phase 1 (fondation) : voir docs/audit-espaces-epilist.md.

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Space extends Model
{
    use SoftDeletes;

    protected $table = 'spaces';

    public const TYPE_PERSONAL = 'personal';
    public const TYPE_HOUSEHOLD = 'household';
    public const TYPE_RESTAURANT = 'restaurant';
    public const TYPE_ORGANIZATION = 'organization';

    public const TYPES = [
        self::TYPE_PERSONAL,
        self::TYPE_HOUSEHOLD,
        self::TYPE_RESTAURANT,
        self::TYPE_ORGANIZATION,
    ];

    protected $fillable = [
        'name', 'type', 'owner_user_id',
        'country', 'region', 'city', 'postal_code',
        'currency', 'settings',
    ];

    protected $casts = [
        'settings' => 'array',
    ];

    public function members()
    {
        return $this->hasMany(SpaceMember::class, 'space_id');
    }

    public function activeMembers()
    {
        return $this->members()->where('status', SpaceMember::STATUS_ACTIVE);
    }

    public function invitations()
    {
        return $this->hasMany(SpaceInvitation::class, 'space_id');
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_user_id');
    }

    /**
     * Espace personnel d'un utilisateur, créé à la volée s'il manque
     * (idempotent : le backfill SQL couvre l'existant, ceci couvre les
     * nouveaux comptes). C'est l'espace par défaut de toute requête.
     */
    public static function personalFor(int $userId): self
    {
        $space = self::where('owner_user_id', $userId)
            ->where('type', self::TYPE_PERSONAL)
            ->first();

        if (!$space) {
            $space = self::create([
                'name' => 'Personnel',
                'type' => self::TYPE_PERSONAL,
                'owner_user_id' => $userId,
            ]);
        }

        SpaceMember::firstOrCreate(
            ['space_id' => $space->id, 'user_id' => $userId],
            ['role' => SpaceMember::ROLE_OWNER, 'status' => SpaceMember::STATUS_ACTIVE, 'joined_at' => Carbon::now()]
        );

        return $space;
    }
}
