<?php
// src/Models/SpaceMember.php - Appartenance d'un utilisateur à un espace.
// Le rôle donne un jeu de permissions PAR DÉFAUT ; la colonne JSON
// `permissions` permet de surcharger finement, membre par membre
// (ex. un employé de restaurant qui ajoute des articles sans voir les
// budgets). Une seule fonction d'évaluation : can().

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SpaceMember extends Model
{
    protected $table = 'space_members';

    public const ROLE_OWNER = 'owner';
    public const ROLE_ADMIN = 'admin';
    public const ROLE_MANAGER = 'manager';
    public const ROLE_MEMBER = 'member';
    public const ROLE_VIEWER = 'viewer';

    public const ROLES = [
        self::ROLE_OWNER, self::ROLE_ADMIN, self::ROLE_MANAGER,
        self::ROLE_MEMBER, self::ROLE_VIEWER,
    ];

    public const STATUS_ACTIVE = 'active';
    public const STATUS_REMOVED = 'removed';
    public const STATUS_LEFT = 'left';

    /**
     * Permissions fines connues. Chaque rôle coche un sous-ensemble par
     * défaut ; `permissions` (JSON) surcharge au cas par cas.
     */
    public const PERMISSIONS = [
        'manage_space',        // renommer, localiser, supprimer l'espace
        'manage_members',      // inviter, retirer, changer les rôles
        'view_budgets',
        'manage_budgets',
        'add_items',
        'manage_lists',
        'approve_purchases',   // demandes d'achat (restaurant, Phase 3)
        'scan_receipts',
        'view_expenses',
        'manage_inventory',
        'manage_suppliers',    // Phase 3
        'view_statistics',
    ];

    /** Permissions accordées par défaut à chaque rôle. */
    public const ROLE_DEFAULTS = [
        self::ROLE_OWNER => self::PERMISSIONS, // tout
        self::ROLE_ADMIN => self::PERMISSIONS, // tout
        self::ROLE_MANAGER => [
            'view_budgets', 'manage_budgets', 'add_items', 'manage_lists',
            'approve_purchases', 'scan_receipts', 'view_expenses',
            'manage_inventory', 'manage_suppliers', 'view_statistics',
        ],
        self::ROLE_MEMBER => [
            'add_items', 'manage_lists', 'scan_receipts',
            'manage_inventory', 'view_budgets', 'view_expenses',
            'view_statistics',
        ],
        self::ROLE_VIEWER => [
            'view_budgets', 'view_expenses', 'view_statistics',
        ],
    ];

    protected $fillable = [
        'space_id', 'user_id', 'role', 'permissions',
        'status', 'invited_by', 'joined_at',
    ];

    protected $casts = [
        'permissions' => 'array',
        'joined_at' => 'datetime',
    ];

    public function space()
    {
        return $this->belongsTo(Space::class, 'space_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Le membre a-t-il cette permission ? Surcharge JSON d'abord
     * (true force, false retire), sinon défauts du rôle.
     */
    public function can(string $permission): bool
    {
        $overrides = $this->permissions ?? [];
        if (array_key_exists($permission, $overrides)) {
            return (bool) $overrides[$permission];
        }
        return in_array($permission, self::ROLE_DEFAULTS[$this->role] ?? [], true);
    }

    /** Rôles autorisés à gérer les membres/l'espace, hors surcharges. */
    public function isAdminLike(): bool
    {
        return in_array($this->role, [self::ROLE_OWNER, self::ROLE_ADMIN], true);
    }
}
