<?php
// src/Services/SpaceAccessService.php - LE point de contrôle multi-tenant.
//
// Règle absolue (§40 du cahier des charges) : on ne fait JAMAIS
// confiance à un space_id fourni par le client. Chaque requête liée à
// un espace passe par ce service, qui vérifie en base :
//   1. l'espace existe ;
//   2. l'utilisateur authentifié en est membre ACTIF ;
//   3. le membre a la permission demandée (rôle + surcharges).
//
// L'espace demandé arrive via l'en-tête X-Space-Id ; en son absence,
// l'espace PERSONNEL de l'utilisateur fait foi (comportement identique
// à l'application d'avant les espaces).

namespace App\Services;

use App\Models\Space;
use App\Models\SpaceMember;
use Psr\Http\Message\ServerRequestInterface as Request;

class SpaceAccessService
{
    /** Levée quand l'accès est refusé : code HTTP + message stable. */
    public static function deny(int $status, string $code): \RuntimeException
    {
        return new SpaceAccessException($code, $status);
    }

    /**
     * Résout l'espace ciblé par la requête.
     * - Sans en-tête X-Space-Id : espace personnel (créé au besoin).
     * - Avec : l'espace N'EST retourné QUE si l'utilisateur en est
     *   membre actif — sinon 403, sans révéler si l'espace existe.
     */
    public static function resolveSpace(Request $request, int $userId): Space
    {
        $raw = trim($request->getHeaderLine('X-Space-Id'));

        if ($raw === '') {
            return Space::personalFor($userId);
        }

        if (!ctype_digit($raw)) {
            throw self::deny(400, 'INVALID_SPACE_ID');
        }

        return self::assertMember((int) $raw, $userId)->space;
    }

    /**
     * L'utilisateur est-il membre ACTIF de l'espace ? Retourne le
     * membre (avec l'espace chargé) ou refuse en 403. Réponse
     * identique que l'espace existe ou non : pas d'énumération.
     */
    public static function assertMember(int $spaceId, int $userId): SpaceMember
    {
        $member = SpaceMember::with('space')
            ->where('space_id', $spaceId)
            ->where('user_id', $userId)
            ->where('status', SpaceMember::STATUS_ACTIVE)
            ->first();

        if (!$member || !$member->space || $member->space->deleted_at !== null) {
            throw self::deny(403, 'SPACE_ACCESS_DENIED');
        }

        return $member;
    }

    /** Membre actif AVEC la permission demandée, sinon 403. */
    public static function assertPermission(int $spaceId, int $userId, string $permission): SpaceMember
    {
        $member = self::assertMember($spaceId, $userId);
        if (!$member->can($permission)) {
            throw self::deny(403, 'SPACE_PERMISSION_DENIED');
        }
        return $member;
    }
}

/** Exception dédiée : les contrôleurs la traduisent en réponse JSON. */
class SpaceAccessException extends \RuntimeException
{
    public function __construct(string $code, private int $status)
    {
        parent::__construct($code);
    }

    public function getStatus(): int
    {
        return $this->status;
    }
}
