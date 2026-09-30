<?php
// src/Controllers/SpaceController.php
//
// Espaces (Phase 1 — fondation) :
//  - GET    /spaces                        mes espaces (crée le personnel au besoin)
//  - POST   /spaces                        créer un espace (household/restaurant/organization)
//  - GET    /spaces/{id}                   détail (membre requis)
//  - PUT    /spaces/{id}                   renommer / localiser (manage_space)
//  - DELETE /spaces/{id}                   supprimer (owner uniquement, jamais le personnel)
//  - GET    /spaces/{id}/members           membres actifs (membre requis)
//  - PUT    /spaces/{id}/members/{userId}  rôle / permissions (manage_members)
//  - DELETE /spaces/{id}/members/{userId}  retirer un membre (manage_members)
//  - POST   /spaces/{id}/leave             quitter l'espace (jamais l'owner ni le personnel)
//  - POST   /spaces/{id}/invitations       inviter par email (manage_members)
//  - GET    /spaces/{id}/invitations       invitations en attente (manage_members)
//  - DELETE /spaces/{id}/invitations/{invId} révoquer (manage_members)
//  - GET    /space-invitations             mes invitations reçues (par email du compte)
//  - POST   /space-invitations/{token}/accept
//  - POST   /space-invitations/{token}/decline
//
// Toute vérification d'appartenance/permission passe par
// SpaceAccessService : AUCUN space_id client n'est cru sur parole.

namespace App\Controllers;

use App\Models\Space;
use App\Models\SpaceInvitation;
use App\Models\SpaceMember;
use App\Models\User;
use App\Services\SpaceAccessException;
use App\Services\SpaceAccessService;
use Carbon\Carbon;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class SpaceController
{
    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    private function denied(Response $response, SpaceAccessException $e): Response
    {
        return $this->json($response, ['success' => false, 'code' => $e->getMessage()], $e->getStatus());
    }

    private function formatSpace(Space $space, ?SpaceMember $me = null): array
    {
        return [
            'id' => $space->id,
            'name' => $space->name,
            'type' => $space->type,
            'owner_user_id' => $space->owner_user_id,
            'country' => $space->country,
            'region' => $space->region,
            'city' => $space->city,
            'postal_code' => $space->postal_code,
            'currency' => $space->currency,
            'members_count' => $space->activeMembers()->count(),
            'my_role' => $me?->role,
            'created_at' => $space->created_at?->toIso8601String(),
        ];
    }

    private function formatMember(SpaceMember $m): array
    {
        return [
            'user_id' => $m->user_id,
            'first_name' => $m->user?->first_name,
            'last_name' => $m->user?->last_name,
            'email' => $m->user?->email,
            'avatar_url' => $m->user?->avatar_url,
            'role' => $m->role,
            'permissions' => $m->permissions,
            'status' => $m->status,
            'joined_at' => $m->joined_at?->toIso8601String(),
        ];
    }

    /** GET /spaces — tous mes espaces, personnel garanti et en premier. */
    public function index(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');

        // Garantit l'espace personnel (nouveaux comptes post-backfill).
        Space::personalFor($userId);

        $memberships = SpaceMember::with('space')
            ->where('user_id', $userId)
            ->where('status', SpaceMember::STATUS_ACTIVE)
            ->get()
            ->filter(fn($m) => $m->space && $m->space->deleted_at === null)
            ->sortBy(fn($m) => [$m->space->type === Space::TYPE_PERSONAL ? 0 : 1, $m->space->name])
            ->values();

        return $this->json($response, [
            'success' => true,
            'data' => ['spaces' => $memberships->map(fn($m) => $this->formatSpace($m->space, $m))->values()],
        ]);
    }

    /** POST /spaces — créer un foyer / restaurant / organisation. */
    public function create(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $data = (array) $request->getParsedBody();

        $type = (string) ($data['type'] ?? '');
        $name = trim((string) ($data['name'] ?? ''));

        // L'espace personnel est unique et géré par le système.
        $allowed = [Space::TYPE_HOUSEHOLD, Space::TYPE_RESTAURANT, Space::TYPE_ORGANIZATION];
        if (!in_array($type, $allowed, true)) {
            return $this->json($response, ['success' => false, 'code' => 'INVALID_SPACE_TYPE'], 422);
        }
        if ($name === '' || mb_strlen($name) > 120) {
            return $this->json($response, ['success' => false, 'code' => 'INVALID_SPACE_NAME'], 422);
        }

        $space = Space::create([
            'name' => $name,
            'type' => $type,
            'owner_user_id' => $userId,
            'country' => self::optional($data, 'country', 2),
            'region' => self::optional($data, 'region', 120),
            'city' => self::optional($data, 'city', 120),
            'postal_code' => self::optional($data, 'postal_code', 20),
            'currency' => self::optional($data, 'currency', 3),
        ]);

        $me = SpaceMember::create([
            'space_id' => $space->id,
            'user_id' => $userId,
            'role' => SpaceMember::ROLE_OWNER,
            'status' => SpaceMember::STATUS_ACTIVE,
            'joined_at' => Carbon::now(),
        ]);

        return $this->json($response, [
            'success' => true,
            'data' => ['space' => $this->formatSpace($space, $me)],
        ], 201);
    }

    private static function optional(array $data, string $key, int $max): ?string
    {
        $v = trim((string) ($data[$key] ?? ''));
        return ($v === '' || mb_strlen($v) > $max) ? null : $v;
    }

    /** GET /spaces/{id} */
    public function show(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        try {
            $me = SpaceAccessService::assertMember((int) $args['id'], $userId);
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }
        return $this->json($response, [
            'success' => true,
            'data' => ['space' => $this->formatSpace($me->space, $me)],
        ]);
    }

    /** PUT /spaces/{id} — nom et localisation (permission manage_space). */
    public function update(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        try {
            $me = SpaceAccessService::assertPermission((int) $args['id'], $userId, 'manage_space');
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }

        $space = $me->space;
        $data = (array) $request->getParsedBody();

        if (array_key_exists('name', $data)) {
            $name = trim((string) $data['name']);
            if ($name === '' || mb_strlen($name) > 120) {
                return $this->json($response, ['success' => false, 'code' => 'INVALID_SPACE_NAME'], 422);
            }
            // Le nom de l'espace personnel est affiché traduit côté app.
            if ($space->type !== Space::TYPE_PERSONAL) {
                $space->name = $name;
            }
        }
        foreach ([['country', 2], ['region', 120], ['city', 120], ['postal_code', 20], ['currency', 3]] as [$key, $max]) {
            if (array_key_exists($key, $data)) {
                $space->{$key} = self::optional($data, $key, $max);
            }
        }
        $space->save();

        return $this->json($response, [
            'success' => true,
            'data' => ['space' => $this->formatSpace($space, $me)],
        ]);
    }

    /** DELETE /spaces/{id} — owner uniquement ; jamais l'espace personnel. */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        try {
            $me = SpaceAccessService::assertMember((int) $args['id'], $userId);
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }

        $space = $me->space;
        if ($me->role !== SpaceMember::ROLE_OWNER) {
            return $this->json($response, ['success' => false, 'code' => 'SPACE_PERMISSION_DENIED'], 403);
        }
        if ($space->type === Space::TYPE_PERSONAL) {
            return $this->json($response, ['success' => false, 'code' => 'PERSONAL_SPACE_PROTECTED'], 422);
        }

        $space->delete(); // soft delete ; les données liées suivront en Phase 2
        return $this->json($response, ['success' => true]);
    }

    /** GET /spaces/{id}/members */
    public function members(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        try {
            SpaceAccessService::assertMember((int) $args['id'], $userId);
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }

        $members = SpaceMember::with('user')
            ->where('space_id', (int) $args['id'])
            ->where('status', SpaceMember::STATUS_ACTIVE)
            ->orderByRaw("FIELD(role,'owner','admin','manager','member','viewer')")
            ->get();

        return $this->json($response, [
            'success' => true,
            'data' => ['members' => $members->map(fn($m) => $this->formatMember($m))->values()],
        ]);
    }

    /** PUT /spaces/{id}/members/{userId} — rôle / permissions fines. */
    public function updateMember(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $spaceId = (int) $args['id'];
        $targetId = (int) $args['userId'];

        try {
            $me = SpaceAccessService::assertPermission($spaceId, $userId, 'manage_members');
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }

        $target = SpaceMember::where('space_id', $spaceId)
            ->where('user_id', $targetId)
            ->where('status', SpaceMember::STATUS_ACTIVE)
            ->first();
        if (!$target) {
            return $this->json($response, ['success' => false, 'code' => 'MEMBER_NOT_FOUND'], 404);
        }
        // L'owner est intouchable (et personne ne peut se promouvoir owner).
        if ($target->role === SpaceMember::ROLE_OWNER) {
            return $this->json($response, ['success' => false, 'code' => 'OWNER_PROTECTED'], 422);
        }

        $data = (array) $request->getParsedBody();
        if (array_key_exists('role', $data)) {
            $role = (string) $data['role'];
            if (!in_array($role, SpaceMember::ROLES, true) || $role === SpaceMember::ROLE_OWNER) {
                return $this->json($response, ['success' => false, 'code' => 'INVALID_ROLE'], 422);
            }
            // Un non-owner ne peut pas fabriquer un autre admin au-dessus de lui.
            if ($role === SpaceMember::ROLE_ADMIN && $me->role !== SpaceMember::ROLE_OWNER) {
                return $this->json($response, ['success' => false, 'code' => 'SPACE_PERMISSION_DENIED'], 403);
            }
            $target->role = $role;
        }
        if (array_key_exists('permissions', $data)) {
            $overrides = $data['permissions'];
            if ($overrides !== null && !is_array($overrides)) {
                return $this->json($response, ['success' => false, 'code' => 'INVALID_PERMISSIONS'], 422);
            }
            if (is_array($overrides)) {
                $unknown = array_diff(array_keys($overrides), SpaceMember::PERMISSIONS);
                if ($unknown) {
                    return $this->json($response, ['success' => false, 'code' => 'INVALID_PERMISSIONS'], 422);
                }
                $overrides = array_map(fn($v) => (bool) $v, $overrides);
            }
            $target->permissions = $overrides;
        }
        $target->save();

        return $this->json($response, [
            'success' => true,
            'data' => ['member' => $this->formatMember($target->load('user'))],
        ]);
    }

    /** DELETE /spaces/{id}/members/{userId} — retirer un membre. */
    public function removeMember(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $spaceId = (int) $args['id'];
        $targetId = (int) $args['userId'];

        try {
            SpaceAccessService::assertPermission($spaceId, $userId, 'manage_members');
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }

        $target = SpaceMember::where('space_id', $spaceId)
            ->where('user_id', $targetId)
            ->where('status', SpaceMember::STATUS_ACTIVE)
            ->first();
        if (!$target) {
            return $this->json($response, ['success' => false, 'code' => 'MEMBER_NOT_FOUND'], 404);
        }
        if ($target->role === SpaceMember::ROLE_OWNER) {
            return $this->json($response, ['success' => false, 'code' => 'OWNER_PROTECTED'], 422);
        }

        $target->status = SpaceMember::STATUS_REMOVED;
        $target->save();

        return $this->json($response, ['success' => true]);
    }

    /** POST /spaces/{id}/leave — quitter de sa propre initiative. */
    public function leave(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        try {
            $me = SpaceAccessService::assertMember((int) $args['id'], $userId);
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }

        if ($me->space->type === Space::TYPE_PERSONAL) {
            return $this->json($response, ['success' => false, 'code' => 'PERSONAL_SPACE_PROTECTED'], 422);
        }
        if ($me->role === SpaceMember::ROLE_OWNER) {
            return $this->json($response, ['success' => false, 'code' => 'OWNER_CANNOT_LEAVE'], 422);
        }

        $me->status = SpaceMember::STATUS_LEFT;
        $me->save();

        return $this->json($response, ['success' => true]);
    }

    /** POST /spaces/{id}/invitations — inviter par email. */
    public function invite(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $spaceId = (int) $args['id'];

        try {
            $me = SpaceAccessService::assertPermission($spaceId, $userId, 'manage_members');
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }
        if ($me->space->type === Space::TYPE_PERSONAL) {
            // Le personnel ne se partage pas : c'est le rôle du foyer.
            return $this->json($response, ['success' => false, 'code' => 'PERSONAL_SPACE_PROTECTED'], 422);
        }

        $data = (array) $request->getParsedBody();
        $email = strtolower(trim((string) ($data['email'] ?? '')));
        $role = (string) ($data['role'] ?? SpaceMember::ROLE_MEMBER);

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $this->json($response, ['success' => false, 'code' => 'INVALID_EMAIL'], 422);
        }
        if (!in_array($role, SpaceMember::ROLES, true) || $role === SpaceMember::ROLE_OWNER) {
            return $this->json($response, ['success' => false, 'code' => 'INVALID_ROLE'], 422);
        }

        // Déjà membre actif ?
        $existingUser = User::where('email', $email)->first();
        if ($existingUser) {
            $already = SpaceMember::where('space_id', $spaceId)
                ->where('user_id', $existingUser->id)
                ->where('status', SpaceMember::STATUS_ACTIVE)
                ->exists();
            if ($already) {
                return $this->json($response, ['success' => false, 'code' => 'ALREADY_MEMBER'], 422);
            }
        }

        // Une seule invitation pending par email et par espace.
        $pending = SpaceInvitation::where('space_id', $spaceId)
            ->where('email', $email)
            ->where('status', SpaceInvitation::STATUS_PENDING)
            ->first();
        if ($pending && $pending->isUsable()) {
            return $this->json($response, ['success' => false, 'code' => 'INVITATION_ALREADY_PENDING'], 422);
        }

        $invitation = SpaceInvitation::create([
            'space_id' => $spaceId,
            'email' => $email,
            'role' => $role,
            'token' => bin2hex(random_bytes(32)),
            'status' => SpaceInvitation::STATUS_PENDING,
            'invited_by' => $userId,
            'expires_at' => Carbon::now()->addDays(SpaceInvitation::TTL_DAYS),
        ]);

        return $this->json($response, [
            'success' => true,
            'data' => ['invitation' => $this->formatInvitation($invitation)],
        ], 201);
    }

    private function formatInvitation(SpaceInvitation $inv, bool $withToken = false): array
    {
        // Le jeton n'est renvoyé QU'AU destinataire authentifié (mes
        // invitations) : jamais dans les listes vues par les admins.
        return ($withToken ? ['token' => $inv->token] : []) + [
            'id' => $inv->id,
            'space_id' => $inv->space_id,
            'space_name' => $inv->space?->name,
            'space_type' => $inv->space?->type,
            'email' => $inv->email,
            'role' => $inv->role,
            'status' => $inv->status,
            'invited_by_name' => trim(($inv->inviter?->first_name ?? '') . ' ' . ($inv->inviter?->last_name ?? '')),
            'expires_at' => $inv->expires_at?->toIso8601String(),
            'created_at' => $inv->created_at?->toIso8601String(),
        ];
    }

    /** GET /spaces/{id}/invitations — en attente (manage_members). */
    public function invitations(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        try {
            SpaceAccessService::assertPermission((int) $args['id'], $userId, 'manage_members');
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }

        $list = SpaceInvitation::with(['space', 'inviter'])
            ->where('space_id', (int) $args['id'])
            ->where('status', SpaceInvitation::STATUS_PENDING)
            ->orderByDesc('created_at')
            ->get()
            ->filter(fn($i) => $i->isUsable())
            ->values();

        return $this->json($response, [
            'success' => true,
            'data' => ['invitations' => $list->map(fn($i) => $this->formatInvitation($i))->values()],
        ]);
    }

    /** DELETE /spaces/{id}/invitations/{invId} — révoquer. */
    public function revokeInvitation(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        try {
            SpaceAccessService::assertPermission((int) $args['id'], $userId, 'manage_members');
        } catch (SpaceAccessException $e) {
            return $this->denied($response, $e);
        }

        $inv = SpaceInvitation::where('space_id', (int) $args['id'])
            ->where('id', (int) $args['invId'])
            ->where('status', SpaceInvitation::STATUS_PENDING)
            ->first();
        if (!$inv) {
            return $this->json($response, ['success' => false, 'code' => 'INVITATION_NOT_FOUND'], 404);
        }

        $inv->status = SpaceInvitation::STATUS_REVOKED;
        $inv->revoked_at = Carbon::now();
        $inv->save();

        return $this->json($response, ['success' => true]);
    }

    /** GET /space-invitations — mes invitations reçues (email du compte). */
    public function myInvitations(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $user = User::find($userId);
        if (!$user) {
            return $this->json($response, ['success' => false, 'code' => 'UNAUTHORIZED'], 401);
        }

        $list = SpaceInvitation::with(['space', 'inviter'])
            ->where('email', strtolower($user->email))
            ->where('status', SpaceInvitation::STATUS_PENDING)
            ->orderByDesc('created_at')
            ->get()
            ->filter(fn($i) => $i->isUsable())
            ->values();

        return $this->json($response, [
            'success' => true,
            'data' => ['invitations' => $list->map(fn($i) => $this->formatInvitation($i, true))->values()],
        ]);
    }

    /** POST /space-invitations/{token}/accept */
    public function acceptInvitation(Request $request, Response $response, array $args): Response
    {
        return $this->answerInvitation($request, $response, (string) $args['token'], true);
    }

    /** POST /space-invitations/{token}/decline */
    public function declineInvitation(Request $request, Response $response, array $args): Response
    {
        return $this->answerInvitation($request, $response, (string) $args['token'], false);
    }

    private function answerInvitation(Request $request, Response $response, string $token, bool $accept): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $user = User::find($userId);

        $inv = SpaceInvitation::with('space')->where('token', $token)->first();
        if (!$inv || !$inv->isUsable() || !$inv->space || $inv->space->deleted_at !== null) {
            return $this->json($response, ['success' => false, 'code' => 'INVITATION_NOT_FOUND'], 404);
        }
        // L'invitation est nominative : seul le compte portant cet email
        // peut y répondre (pas de vol d'invitation par lien intercepté).
        if (!$user || strtolower($user->email) !== $inv->email) {
            return $this->json($response, ['success' => false, 'code' => 'INVITATION_EMAIL_MISMATCH'], 403);
        }

        if (!$accept) {
            $inv->status = SpaceInvitation::STATUS_DECLINED;
            $inv->declined_at = Carbon::now();
            $inv->save();
            return $this->json($response, ['success' => true]);
        }

        // Accepter : membre actif (réactive un ancien membre retiré/parti).
        $member = SpaceMember::firstOrNew([
            'space_id' => $inv->space_id,
            'user_id' => $userId,
        ]);
        $member->role = $inv->role;
        $member->status = SpaceMember::STATUS_ACTIVE;
        $member->invited_by = $inv->invited_by;
        $member->joined_at = Carbon::now();
        $member->save();

        $inv->status = SpaceInvitation::STATUS_ACCEPTED;
        $inv->accepted_at = Carbon::now();
        $inv->save();

        return $this->json($response, [
            'success' => true,
            'data' => ['space' => $this->formatSpace($inv->space, $member)],
        ]);
    }
}
