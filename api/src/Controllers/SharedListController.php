<?php
// app/Http/Controllers/SharedListController.php - VERSION CORRIGÉE

namespace App\Controllers;

use App\Models\SharedList;
use App\Models\ShoppingList;
use App\Models\User;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;
use Carbon\Carbon;

class SharedListController
{
    private const CUSTOM_DOMAIN = 'epilist.app';
    private const APP_SCHEME = 'epilist';
    private const ANDROID_STORE_URL = 'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
    private const IOS_STORE_URL = 'https://apps.apple.com/ca/app/epilist/id6748285596';

    /**
     * Créer un lien de partage pour une liste
     */
    public function createShareLink(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        
        $validator = new Validator($data);
        $validator->rule('required', 'permission')->message('Permission requise');
        $validator->rule('in', 'permission', ['readOnly', 'edit', 'admin'])->message('Permission invalide');
        $validator->rule('integer', 'expiration_days')->message('Durée d\'expiration invalide');
        $validator->rule('min', 'expiration_days', 1)->message('Durée minimum 1 jour');
        $validator->rule('max', 'expiration_days', 365)->message('Durée maximum 365 jours');
        
        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'errors' => $validator->errors()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            $list = ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            $shareToken = $this->generateShareToken();
            $expirationDays = $data['expiration_days'] ?? 30;
            $expiresAt = $expirationDays ? Carbon::now()->addDays($expirationDays) : null;
            
            SharedList::create([
                'list_id' => $list_id,
                'owner_id' => $user_id,
                'share_token' => $shareToken,
                'permission' => $data['permission'],
                'status' => SharedList::STATUS_PENDING,
                'expires_at' => $expiresAt,
                'is_active' => true,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]);

            $owner = User::find($user_id);
            $ownerName = $owner->name ?? $owner->email;
            $shareUrl = $this->generateWebUrl($shareToken);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'share_token' => $shareToken,
                    'share_url' => $shareUrl,
                    'list_name' => $list->name,
                    'owner_name' => $ownerName,
                    'permission' => $data['permission'],
                    'expires_at' => $expiresAt ? $expiresAt->toISOString() : null,
                    'expires_in_days' => $expirationDays,
                    'app_url' => $this->generateAppUrl($shareToken),
                    'store_urls' => [
                        'android' => self::ANDROID_STORE_URL,
                        'ios' => self::IOS_STORE_URL
                    ],
                    'share_message' => $this->generateWebShareMessage($shareToken, $list->name, $ownerName, $shareUrl)
                ],
                'message' => 'Lien de partage créé avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la création du lien de partage',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Obtenir les informations d'une invitation - VERSION CORRIGÉE
     */
    public function getShareInvitation(Request $request, Response $response, array $args): Response
    {
        try {
            $shareToken = $args['token'];
            
            // ✅ CORRECTION: Charger explicitement les relations avec vérification
            $sharedList = SharedList::with(['shoppingList', 'owner'])
                ->where('share_token', $shareToken)
                ->where('status', SharedList::STATUS_PENDING)
                ->where('is_active', true)
                ->first();

            if (!$sharedList) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Invitation introuvable ou déjà traitée'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            // Vérifier si expiré et marquer comme tel
            if ($sharedList->isExpired()) {
                $sharedList->markAsExpired();
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Invitation expirée'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(410);
            }

            // ✅ CORRECTION: Charger les items séparément avec vérification
            $shoppingListData = null;
            if ($sharedList->shoppingList) {
                // Charger les items de la liste
                $items = $sharedList->shoppingList->items()->get();
                
                $shoppingListData = [
                    'id' => $sharedList->shoppingList->id,
                    'name' => $sharedList->shoppingList->name,
                    'items_count' => $items ? $items->count() : 0,
                    'purchased_items_count' => $items ? $items->where('is_purchased', true)->count() : 0,
                    'total_price' => $items ? $items->sum(function($item) {
                        return ($item->price ?? 0) * ($item->quantity ?? 1);
                    }) : 0,
                    'created_at' => $sharedList->shoppingList->created_at->toISOString()
                ];
            }

            $invitation = [
                'token' => $shareToken,
                'list_id' => $sharedList->shoppingList->id,
                'list_name' => $sharedList->shoppingList ? $sharedList->shoppingList->name : 'Liste inconnue',
                'owner_name' => $sharedList->owner ? ($sharedList->owner->name ?? $sharedList->owner->email) : 'Utilisateur inconnu',
                'owner_email' => $sharedList->owner ? $sharedList->owner->email : '',
                'permission' => $sharedList->permission,
                'permission_display_name' => $this->getPermissionDisplayName($sharedList->permission),
                'expires_at' => $sharedList->expires_at ? $sharedList->expires_at->toISOString() : null,
                'is_expired' => $sharedList->isExpired(),
                'is_pending' => $sharedList->isPending(),
                'is_accepted' => $sharedList->isAccepted(),
                'is_declined' => $sharedList->isDeclined(),
                'status' => $sharedList->status,
                'status_display_name' => $sharedList->getStatusDisplayNameAttribute(),
                'created_at' => $sharedList->created_at->toISOString(),
                
                'shopping_list' => $shoppingListData,
                
                'share_urls' => [
                    'web' => $this->generateWebUrl($shareToken),
                    'app' => $this->generateAppUrl($shareToken),
                    'android_store' => self::ANDROID_STORE_URL,
                    'ios_store' => self::IOS_STORE_URL
                ]
            ];

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $invitation
            ]));
            return $response->withHeader('Content-Type', 'application/json');
            
        } catch (\Exception $e) {
            // ✅ SUPPRESSION du var_dump et die pour la production
            error_log("Erreur getShareInvitation: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du chargement de l\'invitation',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Accepter une invitation de partage
     */
    public function acceptShareInvitation(Request $request, Response $response, array $args): Response
    {
        try {
            $shareToken = $args['token'];
            $user_id = $request->getAttribute('auth_id');
            
            $sharedList = SharedList::with(['shoppingList', 'owner'])
                ->where('share_token', $shareToken)
                ->where('status', SharedList::STATUS_PENDING)
                ->where('is_active', true)
                ->first();

            if (!$sharedList) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Invitation introuvable'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            // Vérifier si l'invitation peut être acceptée
            if (!$sharedList->canBeAccepted()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Cette invitation ne peut plus être acceptée'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Vérifier que l'utilisateur n'accepte pas sa propre invitation
            if ($sharedList->owner_id == $user_id) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous ne pouvez pas accepter votre propre invitation'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Vérifier si l'utilisateur n'a pas déjà accès à cette liste
            $existingShare = SharedList::where('list_id', $sharedList->list_id)
                ->where('shared_with_user_id', $user_id)
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->first();

            if ($existingShare) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous avez déjà accès à cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Accepter l'invitation
            $sharedList->update([
                'shared_with_user_id' => $user_id,
                'status' => SharedList::STATUS_ACCEPTED,
                'accepted_at' => Carbon::now(),
                'is_active' => true
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'id' => $sharedList->shoppingList->id,
                    'name' => $sharedList->shoppingList->name,
                    'description' => $sharedList->shoppingList->description ?? '',
                    'created_at' => $sharedList->shoppingList->created_at->toISOString(),
                    'user_id' => $sharedList->shoppingList->user_id,
                    'items' => [] // Les items seront chargés séparément
                ],
                'message' => 'Invitation acceptée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de l\'acceptation de l\'invitation',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Refuser une invitation de partage
     */
    public function declineShareInvitation(Request $request, Response $response, array $args): Response
    {
        try {
            $shareToken = $args['token'];
            
            $sharedList = SharedList::where('share_token', $shareToken)
                ->where('status', SharedList::STATUS_PENDING)
                ->where('is_active', true)
                ->first();

            if (!$sharedList) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Invitation introuvable'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            if (!$sharedList->isPending()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Cette invitation ne peut plus être refusée'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Refuser l'invitation
            $sharedList->decline();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Invitation refusée'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du refus de l\'invitation',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Formater un partage pour l'app mobile (SharedList.fromJson).
     * shared_with_user_id est requis non-null côté Flutter : ne formater
     * que des partages rattachés à un utilisateur.
     */
    private function formatShare(SharedList $share, bool $withList = false, bool $withOwner = false, bool $withUser = false): array
    {
        $out = [
            'id' => $share->id,
            'list_id' => $share->list_id,
            'owner_id' => $share->owner_id,
            'shared_with_user_id' => $share->shared_with_user_id,
            'permission' => $share->permission,
            'shared_at' => Carbon::parse($share->shared_at)->toISOString(),
            'is_active' => (bool) $share->is_active,
            'status' => $share->status,
            'share_token' => $share->share_token,
        ];
        if ($withList && $share->shoppingList) {
            $out['shopping_list'] = [
                'id' => $share->shoppingList->id,
                'user_id' => $share->shoppingList->user_id,
                'name' => $share->shoppingList->name,
                'created_at' => $share->shoppingList->created_at->toISOString(),
                'updated_at' => $share->shoppingList->updated_at->toISOString(),
                'items' => [],
            ];
        }
        if ($withOwner && $share->owner) {
            $out['owner'] = $this->formatUser($share->owner);
        }
        if ($withUser && $share->sharedWithUser) {
            $out['shared_with_user'] = $this->formatUser($share->sharedWithUser);
        }
        return $out;
    }

    private function formatUser(User $user): array
    {
        return [
            'id' => $user->id,
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'email' => $user->email,
        ];
    }

    /**
     * GET /shared-lists — les listes partagées AVEC moi (acceptées, actives)
     */
    public function getSharedLists(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');

            $shares = SharedList::with(['shoppingList', 'owner'])
                ->where('shared_with_user_id', $user_id)
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->where('is_active', true)
                ->orderByDesc('accepted_at')
                ->get();

            $data = $shares
                ->filter(fn($s) => $s->shoppingList !== null)
                ->map(fn($s) => $this->formatShare($s, withList: true, withOwner: true))
                ->values();

            $response->getBody()->write(json_encode(['success' => true, 'data' => $data]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Erreur getSharedLists: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du chargement des listes partagées'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * GET /shopping-lists/{id}/shares — les personnes ayant accès à ma liste
     */
    public function getListShares(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = (int) $args['id'];

            if (!$this->canManageShares($user_id, $list_id)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'êtes pas autorisé à voir les partages de cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $shares = SharedList::with(['sharedWithUser'])
                ->where('list_id', $list_id)
                ->whereNotNull('shared_with_user_id')
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->where('is_active', true)
                ->orderBy('accepted_at')
                ->get();

            $data = $shares->map(fn($s) => $this->formatShare($s, withUser: true))->values();

            $response->getBody()->write(json_encode(['success' => true, 'data' => $data]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Erreur getListShares: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du chargement des partages'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * PUT /shared-lists/{id} — modifier la permission d'un partage
     */
    public function updateSharePermission(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();

        $validator = new Validator($data);
        $validator->rule('required', 'permission')->message('Permission requise');
        $validator->rule('in', 'permission', ['readOnly', 'edit', 'admin'])->message('Permission invalide');
        if (!$validator->validate()) {
            $response->getBody()->write(json_encode(['success' => false, 'errors' => $validator->errors()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');
            $share = SharedList::with(['sharedWithUser'])->find((int) $args['id']);

            if (!$share) {
                $response->getBody()->write(json_encode(['success' => false, 'message' => 'Partage introuvable']));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            if (!$this->canManageShares($user_id, $share->list_id)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'êtes pas autorisé à modifier ce partage'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $share->update(['permission' => $data['permission']]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $this->formatShare($share->fresh(['sharedWithUser']), withUser: true),
                'message' => 'Permission mise à jour'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Erreur updateSharePermission: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la modification de la permission'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * DELETE /shared-lists/{id} — révoquer un partage
     */
    public function revokeShare(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $share = SharedList::find((int) $args['id']);

            if (!$share) {
                $response->getBody()->write(json_encode(['success' => false, 'message' => 'Partage introuvable']));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            if (!$this->canManageShares($user_id, $share->list_id)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'êtes pas autorisé à révoquer ce partage'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $share->revoke();

            $response->getBody()->write(json_encode(['success' => true, 'message' => 'Partage révoqué']));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Erreur revokeShare: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la révocation du partage'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * DELETE /shopping-lists/{id}/share-links — révoquer tous les liens
     * d'invitation en attente d'une liste (ne retire pas les accès acceptés)
     */
    public function revokeAllShareLinks(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = (int) $args['id'];

            if (!$this->canManageShares($user_id, $list_id)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'êtes pas autorisé à gérer les liens de cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $count = SharedList::where('list_id', $list_id)
                ->where('status', SharedList::STATUS_PENDING)
                ->where('is_active', true)
                ->update([
                    'status' => SharedList::STATUS_REVOKED,
                    'revoked_at' => Carbon::now(),
                    'is_active' => false,
                ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => ['revoked_links' => $count],
                'message' => "{$count} lien(s) d'invitation révoqué(s)"
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Erreur revokeAllShareLinks: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la révocation des liens'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * GET /shopping-lists/{id}/share-stats — statistiques de partage
     */
    public function getShareStats(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = (int) $args['id'];

            $list = ShoppingList::find($list_id);
            if (!$list || !$list->canBeAccessedBy($user_id)) {
                $response->getBody()->write(json_encode(['success' => false, 'message' => 'Liste introuvable']));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $shares = SharedList::where('list_id', $list_id)->get();
            $accepted = $shares->where('status', SharedList::STATUS_ACCEPTED)->where('is_active', true);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'list_id' => $list_id,
                    'active_shares' => $accepted->count(),
                    'pending_links' => $shares->where('status', SharedList::STATUS_PENDING)->where('is_active', true)->count(),
                    'declined' => $shares->where('status', SharedList::STATUS_DECLINED)->count(),
                    'revoked' => $shares->where('status', SharedList::STATUS_REVOKED)->count(),
                    'left' => $shares->where('status', SharedList::STATUS_LEFT)->count(),
                    'by_permission' => [
                        'readOnly' => $accepted->where('permission', 'readOnly')->count(),
                        'edit' => $accepted->where('permission', 'edit')->count(),
                        'admin' => $accepted->where('permission', 'admin')->count(),
                    ],
                ],
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Erreur getShareStats: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du chargement des statistiques'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * GET /share/{token} — page web publique : redirige vers le site,
     * qui gère le deep link vers l'app et le repli vers les stores.
     */
    public function showSharePage(Request $request, Response $response, array $args): Response
    {
        $token = preg_replace('/[^a-f0-9]/', '', $args['token'] ?? '');
        return $response
            ->withHeader('Location', $this->generateWebUrl($token))
            ->withStatus(302);
    }

    /**
     * Seuls le propriétaire de la liste et les partagés "admin" peuvent
     * gérer les partages (voir, modifier, révoquer).
     */
    private function canManageShares(int $user_id, int $list_id): bool
    {
        $isOwner = ShoppingList::where('id', $list_id)->where('user_id', $user_id)->exists();
        if ($isOwner) {
            return true;
        }
        return SharedList::where('list_id', $list_id)
            ->where('shared_with_user_id', $user_id)
            ->where('status', SharedList::STATUS_ACCEPTED)
            ->where('is_active', true)
            ->where('permission', SharedList::PERMISSION_ADMIN)
            ->exists();
    }

    // ✅ MÉTHODES UTILITAIRES (inchangées)
    private function generateShareToken(): string
    {
        do {
            $token = bin2hex(random_bytes(16));
        } while (SharedList::where('share_token', $token)->exists());
        return $token;
    }

    private function generateWebUrl(string $token): string
    {
        return "https://" . self::CUSTOM_DOMAIN . "/share/{$token}";
    }

    private function generateAppUrl(string $token): string
    {
        return self::APP_SCHEME . "://share/{$token}";
    }

    private function generateWebShareMessage(string $token, string $listName, string $ownerName, string $webUrl): string
    {
        return "{$ownerName} vous invite à collaborer sur la liste d'épicerie \"{$listName}\".\n\n" .
               "🔗 Cliquez sur ce lien pour ouvrir l'app ou la télécharger :\n{$webUrl}\n\n" .
               "📱 EpiList - Vos listes de courses partagées";
    }

    private function getPermissionDisplayName(string $permission): string
    {
        return match ($permission) {
            'readOnly' => 'Lecture seule',
            'edit' => 'Modification',
            'admin' => 'Administration',
            default => 'Inconnu'
        };
    }

    /**
     * ✅ Quitter une liste partagée
     */
    public function leaveSharedList(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur a bien accès à cette liste partagée
            $sharedList = SharedList::where('list_id', $list_id)
                ->where('shared_with_user_id', $user_id)
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->where('is_active', true)
                ->first();

            if (!$sharedList) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'avez pas accès à cette liste ou elle n\'existe pas'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            // Vérifier que l'utilisateur n'est pas le propriétaire de la liste
            $shoppingList = ShoppingList::find($list_id);
            if ($shoppingList && $shoppingList->user_id == $user_id) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous ne pouvez pas quitter une liste dont vous êtes le propriétaire'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Marquer comme quitté
            $sharedList->markAsLeft();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Vous avez quitté la liste partagée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
            
        } catch (\Exception $e) {
            error_log("Erreur leaveSharedList: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la suppression de la liste partagée',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}