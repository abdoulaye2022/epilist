<?php
// src/Models/SpaceInvitation.php - Invitation à rejoindre un espace.
// Même cycle de vie que le partage de liste (shared_list) : pending,
// accepted, declined, expired, revoked — jeton unique pour le lien.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SpaceInvitation extends Model
{
    protected $table = 'space_invitations';

    public const STATUS_PENDING = 'pending';
    public const STATUS_ACCEPTED = 'accepted';
    public const STATUS_DECLINED = 'declined';
    public const STATUS_EXPIRED = 'expired';
    public const STATUS_REVOKED = 'revoked';

    /** Durée de validité d'une invitation. */
    public const TTL_DAYS = 14;

    protected $fillable = [
        'space_id', 'email', 'role', 'token', 'status',
        'invited_by', 'expires_at', 'accepted_at', 'declined_at', 'revoked_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'accepted_at' => 'datetime',
        'declined_at' => 'datetime',
        'revoked_at' => 'datetime',
    ];

    public function space()
    {
        return $this->belongsTo(Space::class, 'space_id');
    }

    public function inviter()
    {
        return $this->belongsTo(User::class, 'invited_by');
    }

    /** pending et non expirée ; marque expired au passage si besoin. */
    public function isUsable(): bool
    {
        if ($this->status !== self::STATUS_PENDING) {
            return false;
        }
        if ($this->expires_at && $this->expires_at->isPast()) {
            $this->status = self::STATUS_EXPIRED;
            $this->save();
            return false;
        }
        return true;
    }
}
