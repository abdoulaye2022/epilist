<?php
// app/Http/Controllers/SharedListController.php - VERSION COMPLÈTE

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
    private const IOS_STORE_URL = 'https://apps.apple.com/app/epilist/id123456789';

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
     * Obtenir les informations d'une invitation
     */
    public function getShareInvitation(Request $request, Response $response, array $args): Response
    {
        try {
            $shareToken = $args['token'];
            
            $sharedList = SharedList::with(['shoppingList.items', 'owner'])
                ->where('share_token', $shareToken)
                ->where('status', SharedList::STATUS_PENDING)
                ->where('is_active', true)
                ->firstOrFail();

            // Vérifier si expiré et marquer comme tel
            if ($sharedList->isExpired()) {
                $sharedList->markAsExpired();
                throw new \Exception('Invitation expirée');
            }

            $invitation = [
                'token' => $shareToken,
                'list_name' => $sharedList->shoppingList->name,
                'owner_name' => $sharedList->owner->name ?? $sharedList->owner->email,
                'owner_email' => $sharedList->owner->email,
                'permission' => $sharedList->permission,
                'permission_display_name' => $this->getPermissionDisplayName($sharedList->permission),
                'expires_at' => $sharedList->expires_at ? $sharedList->expires_at->toISOString() : null,
                'is_expired' => $sharedList->isExpired(),
                'status' => $sharedList->status,
                'status_display_name' => $sharedList->getStatusDisplayNameAttribute(),
                'created_at' => $sharedList->created_at->toISOString(),
                
                'shopping_list' => [
                    'id' => $sharedList->shoppingList->id,
                    'name' => $sharedList->shoppingList->name,
                    'items_count' => $sharedList->shoppingList->items->count(),
                    'purchased_items_count' => $sharedList->shoppingList->items->where('is_purchased', true)->count(),
                    'total_price' => $sharedList->shoppingList->items->sum(function($item) {
                        return ($item->price ?? 0) * $item->quantity;
                    }),
                    'created_at' => $sharedList->shoppingList->created_at->toISOString()
                ],
                
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
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Invitation invalide ou expirée'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
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
                ->firstOrFail();

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
                    'description' => $sharedList->shoppingList->description,
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
                ->firstOrFail();

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
     * ✅ Obtenir toutes les listes partagées avec l'utilisateur
     */
    public function getSharedLists(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            
            $sharedLists = SharedList::with(['shoppingList', 'owner'])
                ->where('shared_with_user_id', $user_id)
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->where('is_active', true)
                ->orderBy('created_at', 'desc')
                ->get();

            $data = $sharedLists->map(function($sharedList) {
                return [
                    'id' => $sharedList->id,
                    'list_id' => $sharedList->list_id,
                    'owner_id' => $sharedList->owner_id,
                    'shared_with_user_id' => $sharedList->shared_with_user_id,
                    'permission' => $sharedList->permission,
                    'permission_display_name' => $this->getPermissionDisplayName($sharedList->permission),
                    'status' => $sharedList->status,
                    'shared_at' => $sharedList->accepted_at ? $sharedList->accepted_at->toISOString() : $sharedList->created_at->toISOString(),
                    'is_active' => $sharedList->is_active,
                    'shopping_list' => [
                        'id' => $sharedList->shoppingList->id,
                        'name' => $sharedList->shoppingList->name,
                        'description' => $sharedList->shoppingList->description,
                        'created_at' => $sharedList->shoppingList->created_at->toISOString()
                    ],
                    'owner' => [
                        'id' => $sharedList->owner->id,
                        'name' => $sharedList->owner->name,
                        'email' => $sharedList->owner->email
                    ]
                ];
            });

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $data
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du chargement des listes partagées',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Obtenir les partages d'une liste spécifique
     */
    public function getListShares(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            $list = ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            $shares = SharedList::with(['sharedWithUser'])
                ->where('list_id', $list_id)
                ->where('owner_id', $user_id)
                ->orderBy('created_at', 'desc')
                ->get();

            $data = $shares->map(function($share) {
                return [
                    'id' => $share->id,
                    'shared_with_user_id' => $share->shared_with_user_id,
                    'permission' => $share->permission,
                    'permission_display_name' => $this->getPermissionDisplayName($share->permission),
                    'status' => $share->status,
                    'status_display_name' => $share->getStatusDisplayNameAttribute(),
                    'share_token' => $share->share_token,
                    'expires_at' => $share->expires_at ? $share->expires_at->toISOString() : null,
                    'is_expired' => $share->isExpired(),
                    'is_active' => $share->is_active,
                    'created_at' => $share->created_at->toISOString(),
                    'accepted_at' => $share->accepted_at ? $share->accepted_at->toISOString() : null,
                    'declined_at' => $share->declined_at ? $share->declined_at->toISOString() : null,
                    'revoked_at' => $share->revoked_at ? $share->revoked_at->toISOString() : null,
                    'shared_with_user' => $share->sharedWithUser ? [
                        'id' => $share->sharedWithUser->id,
                        'name' => $share->sharedWithUser->name,
                        'email' => $share->sharedWithUser->email
                    ] : null
                ];
            });

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $data
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du chargement des partages',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Modifier les permissions d'un partage
     */
    public function updateSharePermission(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        
        $validator = new Validator($data);
        $validator->rule('required', 'permission')->message('Permission requise');
        $validator->rule('in', 'permission', ['readOnly', 'edit', 'admin'])->message('Permission invalide');
        
        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'errors' => $validator->errors()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');
            $share_id = $args['id'];
            
            $sharedList = SharedList::with(['shoppingList'])
                ->where('id', $share_id)
                ->where('owner_id', $user_id)
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->firstOrFail();

            $sharedList->update([
                'permission' => $data['permission'],
                'updated_at' => Carbon::now()
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'id' => $sharedList->id,
                    'permission' => $sharedList->permission,
                    'permission_display_name' => $this->getPermissionDisplayName($sharedList->permission),
                    'updated_at' => $sharedList->updated_at->toISOString()
                ],
                'message' => 'Permissions mises à jour avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour des permissions',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Révoquer un partage
     */
    public function revokeShare(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $share_id = $args['id'];
            
            $sharedList = SharedList::where('id', $share_id)
                ->where('owner_id', $user_id)
                ->firstOrFail();

            $sharedList->revoke();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Partage révoqué avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la révocation du partage',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Quitter une liste partagée
     */
    public function leaveSharedList(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            $sharedList = SharedList::where('list_id', $list_id)
                ->where('shared_with_user_id', $user_id)
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->firstOrFail();

            $sharedList->markAsLeft();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Vous avez quitté la liste partagée'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la sortie de la liste',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Révoquer tous les liens de partage d'une liste
     */
    public function revokeAllShareLinks(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            $list = ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            $revokedCount = SharedList::where('list_id', $list_id)
                ->where('owner_id', $user_id)
                ->whereIn('status', [SharedList::STATUS_PENDING, SharedList::STATUS_ACCEPTED])
                ->update([
                    'status' => SharedList::STATUS_REVOKED,
                    'revoked_at' => Carbon::now(),
                    'is_active' => false,
                    'updated_at' => Carbon::now()
                ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'revoked_count' => $revokedCount
                ],
                'message' => "Tous les liens de partage ont été révoqués ($revokedCount liens)"
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la révocation des liens',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Obtenir les statistiques de partage pour une liste
     */
    public function getShareStats(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            $list = ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            $stats = [
                'total_shares' => SharedList::where('list_id', $list_id)->where('owner_id', $user_id)->count(),
                'pending_shares' => SharedList::where('list_id', $list_id)->where('owner_id', $user_id)->where('status', SharedList::STATUS_PENDING)->count(),
                'accepted_shares' => SharedList::where('list_id', $list_id)->where('owner_id', $user_id)->where('status', SharedList::STATUS_ACCEPTED)->count(),
                'declined_shares' => SharedList::where('list_id', $list_id)->where('owner_id', $user_id)->where('status', SharedList::STATUS_DECLINED)->count(),
                'expired_shares' => SharedList::where('list_id', $list_id)->where('owner_id', $user_id)->where('status', SharedList::STATUS_EXPIRED)->count(),
                'revoked_shares' => SharedList::where('list_id', $list_id)->where('owner_id', $user_id)->where('status', SharedList::STATUS_REVOKED)->count(),
                'active_shares' => SharedList::where('list_id', $list_id)->where('owner_id', $user_id)->where('is_active', true)->count(),
            ];

            // Calculer le taux d'acceptation
            $totalInvitations = $stats['accepted_shares'] + $stats['declined_shares'];
            $stats['acceptance_rate'] = $totalInvitations > 0 ? round(($stats['accepted_shares'] / $totalInvitations) * 100, 2) : 0;

            // Répartition par permission
            $permissionStats = SharedList::where('list_id', $list_id)
                ->where('owner_id', $user_id)
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->selectRaw('permission, COUNT(*) as count')
                ->groupBy('permission')
                ->get()
                ->pluck('count', 'permission')
                ->toArray();

            $stats['permissions'] = [
                'readOnly' => $permissionStats['readOnly'] ?? 0,
                'edit' => $permissionStats['edit'] ?? 0,
                'admin' => $permissionStats['admin'] ?? 0,
            ];

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $stats
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du chargement des statistiques',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
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
}