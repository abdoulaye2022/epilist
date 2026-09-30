<?php
// src/Services/ListAccessService.php - Accès à une liste, conscient des
// espaces (Phase 2). Remplace les checkListAccess dupliqués des
// contrôleurs (items, reçus, messages) par UN point de contrôle.
//
// Règles :
//  - Espace PERSONNEL actif : mes listes du personnel (space_id =
//    personnel, avec repli historique space_id NULL + user_id) ET les
//    listes partagées avec moi via shared_list (comportement d'avant).
//  - Espace FOYER/RESTAURANT actif : les listes de CET espace
//    uniquement, droits déduits du rôle de membre (add_items,
//    manage_lists) — jamais de repli user_id (aucune fuite du
//    personnel vers le foyer).

namespace App\Services;

use App\Models\SharedList;
use App\Models\ShoppingList;
use App\Models\Space;
use App\Models\SpaceMember;

class ListAccessService
{
    /**
     * Applique le périmètre de l'espace courant à une requête
     * ShoppingList. $space provient TOUJOURS de
     * SpaceAccessService::resolveSpace (appartenance déjà vérifiée).
     */
    public static function scopeLists($query, Space $space, int $userId)
    {
        if ($space->type === Space::TYPE_PERSONAL) {
            // Repli space_id NULL : lignes créées hors ligne avant
            // synchronisation de la Phase 2, jamais l'espace d'un autre.
            return $query->where(function ($q) use ($space, $userId) {
                $q->where('space_id', $space->id)
                  ->orWhere(function ($q2) use ($userId) {
                      $q2->whereNull('space_id')->where('user_id', $userId);
                  });
            });
        }
        return $query->where('space_id', $space->id);
    }

    /**
     * Accès à UNE liste précise. Le critère est l'appartenance à
     * l'espace DE LA LISTE (pas l'espace actif) : un membre du foyer
     * accède aux listes du foyer quel que soit son en-tête X-Space-Id,
     * un non-membre jamais. Même contrat de retour que les anciens
     * checkListAccess : ['list', 'is_owner', 'permission', 'can_read',
     * 'can_edit', 'can_delete'] ou null si refusé.
     * $requiredPermission : read | edit | delete.
     */
    public static function check(int $userId, int $listId, string $requiredPermission = 'read'): ?array
    {
        $list = ShoppingList::where('id', $listId)->first();
        if (!$list) {
            return null;
        }

        // 1. Liste d'un espace partagé : droits du membre actif.
        if ($list->space_id !== null) {
            $space = Space::find($list->space_id);
            // Audit C5 : espace introuvable (supprimé) -> AUCUN repli
            // sur la règle « propriétaire » — la liste est inaccessible.
            if ($space === null) {
                return null;
            }
            if ($space->type !== Space::TYPE_PERSONAL) {
                $member = SpaceMember::where('space_id', $space->id)
                    ->where('user_id', $userId)
                    ->where('status', SpaceMember::STATUS_ACTIVE)
                    ->first();
                if (!$member) {
                    return null; // non-membre : aucune fuite inter-espaces
                }
                $canEdit = $member->can('add_items');
                $canDelete = $member->can('manage_lists');
                $ok = match ($requiredPermission) {
                    'read' => true,
                    'edit' => $canEdit,
                    'delete' => $canDelete,
                    default => false,
                };
                return $ok
                    ? self::grant($list, $member->isAdminLike(), $member->role, $canEdit, $canDelete)
                    : null;
            }
        }

        // 2. Liste personnelle : propriétaire = plein accès.
        if ((int) $list->user_id === $userId) {
            return self::grant($list, true, 'admin', true, true);
        }

        // 3. Partage par liste (héritage shared_list).
        $sharedList = SharedList::with(['shoppingList'])
            ->where('shared_with_user_id', $userId)
            ->whereHas('shoppingList', fn($q) => $q->where('id', $listId))
            ->where('status', SharedList::STATUS_ACCEPTED)
            ->where('is_active', true)
            ->first();

        if (!$sharedList || !$sharedList->shoppingList) {
            return null;
        }

        $canEdit = $sharedList->canEdit();
        $canDelete = $sharedList->canDelete();
        $ok = match ($requiredPermission) {
            'read' => true,
            'edit' => $canEdit,
            'delete' => $canDelete,
            default => false,
        };
        if (!$ok) {
            return null;
        }

        return [
            'list' => $sharedList->shoppingList,
            'is_owner' => false,
            'permission' => $sharedList->permission,
            'can_read' => true,
            'can_edit' => $canEdit,
            'can_delete' => $canDelete,
        ];
    }

    /**
     * Variante pour les contrôleurs qui gardent leur logique historique
     * (personnel + shared_list) : ne traite QUE les listes d'un espace
     * partagé. Retourne :
     *   false  → pas une liste d'espace partagé (continuer le flux legacy)
     *   null   → liste d'espace partagé mais accès/permission refusés
     *   array  → accès accordé (même forme que check()).
     */
    public static function checkSharedSpace(int $userId, int $listId, string $requiredPermission = 'read', bool $withTrashed = false)
    {
        $query = ShoppingList::where('id', $listId);
        if ($withTrashed) {
            $query = $query->withTrashed();
        }
        $list = $query->first();
        if (!$list || $list->space_id === null) {
            return false;
        }
        $space = Space::find($list->space_id);
        // Audit C5 : espace supprimé -> accès refusé, PAS de repli
        // vers le flux legacy (règle « propriétaire »).
        if ($space === null) {
            return null;
        }
        if ($space->type === Space::TYPE_PERSONAL) {
            return false;
        }

        $member = SpaceMember::where('space_id', $space->id)
            ->where('user_id', $userId)
            ->where('status', SpaceMember::STATUS_ACTIVE)
            ->first();
        if (!$member) {
            return null;
        }
        $canEdit = $member->can('add_items');
        $canDelete = $member->can('manage_lists');
        $ok = match ($requiredPermission) {
            'read' => true,
            'edit' => $canEdit,
            'delete' => $canDelete,
            default => false,
        };
        if (!$ok) {
            return null;
        }
        $granted = self::grant($list, $member->isAdminLike(), $member->role, $canEdit, $canDelete);
        $granted['space'] = $space;
        return $granted;
    }

    private static function grant(ShoppingList $list, bool $isOwner, string $permission, bool $canEdit, bool $canDelete): array
    {
        return [
            'list' => $list,
            'is_owner' => $isOwner,
            'permission' => $permission,
            'can_read' => true,
            'can_edit' => $canEdit,
            'can_delete' => $canDelete,
        ];
    }
}
