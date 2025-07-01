<?php
// app/Http/Controllers/SharedListController.php

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
    // 🌐 Configuration du domaine personnalisé
    private const SHARE_DOMAIN = 'epilist.app';
    private const SHARE_BASE_URL = 'https://epilist.app';

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
            
            // Vérifier que l'utilisateur possède la liste
            $list = ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            // 🆕 Générer un token sécurisé et unique
            $shareToken = $this->generateSecureToken();
            $expirationDays = $data['expiration_days'] ?? 30;
            $expiresAt = Carbon::now()->addDays($expirationDays);
            
            // 🆕 Créer le partage avec données enrichies
            $sharedList = SharedList::create([
                'list_id' => $list_id,
                'owner_id' => $user_id,
                'share_token' => $shareToken,
                'permission' => $data['permission'],
                'expires_at' => $expiresAt,
                'is_active' => true,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
                // shared_with_user_id sera NULL jusqu'à ce que quelqu'un accepte l'invitation
            ]);

            // 🆕 Générer l'URL avec le nouveau domaine
            $shareUrl = self::SHARE_BASE_URL . "/share/{$shareToken}";

            // 🆕 Récupérer les informations du propriétaire
            $owner = User::find($user_id);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'share_token' => $shareToken,
                    'share_url' => $shareUrl,
                    'permission' => $data['permission'],
                    'expires_at' => $expiresAt->toISOString(),
                    'expires_in_days' => $expirationDays,
                    'list_name' => $list->name,
                    'owner_name' => $owner->name ?? $owner->email,
                    // 🆕 URLs alternatives pour différents usages
                    'app_url' => "epilist://share/{$shareToken}",
                    'web_url' => $shareUrl,
                    'qr_data' => $shareUrl
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
            
            // 🆕 Vérifier que le token est valide et actif
            $sharedList = SharedList::with(['shoppingList.items', 'owner'])
                ->where('share_token', $shareToken)
                ->where('is_active', true)
                ->where('expires_at', '>', Carbon::now())
                ->firstOrFail();

            // 🆕 Préparer les données d'invitation enrichies
            $invitation = [
                'token' => $shareToken,
                'list_name' => $sharedList->shoppingList->name,
                'owner_name' => $sharedList->owner->name ?? $sharedList->owner->email,
                'owner_email' => $sharedList->owner->email,
                'permission' => $sharedList->permission,
                'permission_display_name' => $this->getPermissionDisplayName($sharedList->permission),
                'expires_at' => $sharedList->expires_at->toISOString(),
                'is_expired' => $sharedList->expires_at->isPast(),
                'created_at' => $sharedList->created_at->toISOString(),
                
                // 🆕 Informations sur la liste
                'shopping_list' => [
                    'id' => $sharedList->shoppingList->id,
                    'name' => $sharedList->shoppingList->name,
                    'items_count' => $sharedList->shoppingList->items->count(),
                    'purchased_items_count' => $sharedList->shoppingList->items->where('is_purchased', true)->count(),
                    'total_price' => $sharedList->shoppingList->items->sum(function($item) {
                        return ($item->price ?? 0) * $item->quantity;
                    }),
                    'created_at' => $sharedList->shoppingList->created_at->toISOString()
                ]
            ];

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $invitation
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Invitation invalide ou expirée'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'invitation',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Accepter une invitation de partage
     */
    public function acceptShareInvitation(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $shareToken = $args['token'];
            
            // 🆕 Vérifier que le token est valide et pas expiré
            $sharedList = SharedList::with('shoppingList')
                ->where('share_token', $shareToken)
                ->where('is_active', true)
                ->where('expires_at', '>', Carbon::now())
                ->firstOrFail();

            // 🆕 Vérifier que l'utilisateur n'est pas le propriétaire
            if ($sharedList->owner_id == $user_id) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous ne pouvez pas accepter votre propre invitation'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // 🆕 Vérifier que l'invitation n'a pas déjà été acceptée
            if ($sharedList->shared_with_user_id !== null) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Cette invitation a déjà été acceptée'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Mettre à jour avec l'utilisateur qui accepte
            $sharedList->update([
                'shared_with_user_id' => $user_id,
                'accepted_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]);

            // 🆕 Enrichir les données de la liste retournée
            $listData = $sharedList->shoppingList->toArray();
            $listData['permission'] = $sharedList->permission;
            $listData['is_shared'] = true;
            $listData['is_owner'] = false;
            $listData['can_edit'] = in_array($sharedList->permission, ['edit', 'admin']);
            $listData['can_delete'] = $sharedList->permission === 'admin';

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $listData,
                'message' => 'Invitation acceptée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Invitation invalide ou expirée'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
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
     * Refuser une invitation de partage
     */
    public function declineShareInvitation(Request $request, Response $response, array $args): Response
    {
        try {
            $shareToken = $args['token'];
            
            $sharedList = SharedList::where('share_token', $shareToken)
                ->where('is_active', true)
                ->firstOrFail();
            
            // 🆕 Marquer comme refusée au lieu de supprimer (pour l'audit)
            $sharedList->update([
                'is_active' => false,
                'declined_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Invitation refusée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Invitation introuvable'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
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
     * Obtenir toutes les listes partagées avec l'utilisateur
     */
    public function getSharedLists(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            
            // 🆕 Récupérer les listes partagées avec informations enrichies
            $sharedLists = SharedList::with(['shoppingList.items', 'owner'])
                ->where('shared_with_user_id', $user_id)
                ->where('is_active', true)
                ->where('expires_at', '>', Carbon::now())
                ->get()
                ->map(function ($sharedList) {
                    $list = $sharedList->shoppingList;
                    $list->permission = $sharedList->permission;
                    $list->is_shared = true;
                    $list->is_owner = false;
                    $list->can_edit = in_array($sharedList->permission, ['edit', 'admin']);
                    $list->can_delete = $sharedList->permission === 'admin';
                    $list->owner = $sharedList->owner;
                    $list->shared_at = $sharedList->accepted_at;
                    return $list;
                });

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $sharedLists
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des listes partagées',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Obtenir les personnes avec qui une liste est partagée
     */
    public function getListShares(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            $list = ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            // 🆕 Récupérer tous les partages avec informations détaillées
            $shares = SharedList::with('sharedWithUser')
                ->where('list_id', $list_id)
                ->where('owner_id', $user_id)
                ->get()
                ->map(function ($share) {
                    return [
                        'id' => $share->id,
                        'permission' => $share->permission,
                        'permission_display_name' => $this->getPermissionDisplayName($share->permission),
                        'is_active' => $share->is_active,
                        'expires_at' => $share->expires_at->toISOString(),
                        'is_expired' => $share->expires_at->isPast(),
                        'created_at' => $share->created_at->toISOString(),
                        'accepted_at' => $share->accepted_at?->toISOString(),
                        'share_token' => $share->share_token,
                        'share_url' => self::SHARE_BASE_URL . "/share/{$share->share_token}",
                        'shared_with_user' => $share->sharedWithUser ? [
                            'id' => $share->sharedWithUser->id,
                            'name' => $share->sharedWithUser->name,
                            'email' => $share->sharedWithUser->email
                        ] : null,
                        'status' => $this->getShareStatus($share)
                    ];
                });

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $shares
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Liste introuvable'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des partages',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Modifier les permissions d'un partage
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
            
            $sharedList = SharedList::where('owner_id', $user_id)
                ->where('id', $share_id)
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
                    'permission_display_name' => $this->getPermissionDisplayName($sharedList->permission)
                ],
                'message' => 'Permissions mises à jour avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Partage introuvable'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
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
     * Révoquer un partage
     */
    public function revokeShare(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $share_id = $args['id'];
            
            $sharedList = SharedList::where('owner_id', $user_id)
                ->where('id', $share_id)
                ->firstOrFail();
            
            // 🆕 Marquer comme inactif au lieu de supprimer
            $sharedList->update([
                'is_active' => false,
                'revoked_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Partage révoqué avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Partage introuvable'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
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
     * Quitter une liste partagée
     */
    public function leaveSharedList(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            $sharedList = SharedList::where('shared_with_user_id', $user_id)
                ->where('list_id', $list_id)
                ->where('is_active', true)
                ->firstOrFail();
            
            // 🆕 Marquer comme quitté
            $sharedList->update([
                'is_active' => false,
                'left_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Vous avez quitté la liste avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Liste partagée introuvable'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
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
     * Révoquer tous les liens de partage d'une liste
     */
    public function revokeAllShareLinks(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            // 🆕 Marquer tous les partages comme inactifs
            $count = SharedList::where('list_id', $list_id)
                ->where('owner_id', $user_id)
                ->where('is_active', true)
                ->update([
                    'is_active' => false,
                    'revoked_at' => Carbon::now(),
                    'updated_at' => Carbon::now()
                ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => ['revoked_count' => $count],
                'message' => "Tous les liens de partage ont été révoqués ({$count} liens)"
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Liste introuvable'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
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
     * Obtenir les statistiques de partage d'une liste
     */
    public function getShareStats(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            // 🆕 Statistiques détaillées
            $stats = [
                'total_shares' => SharedList::where('list_id', $list_id)->count(),
                'active_shares' => SharedList::where('list_id', $list_id)
                    ->where('is_active', true)
                    ->where('expires_at', '>', Carbon::now())
                    ->count(),
                'accepted_shares' => SharedList::where('list_id', $list_id)
                    ->whereNotNull('shared_with_user_id')
                    ->whereNotNull('accepted_at')
                    ->count(),
                'pending_shares' => SharedList::where('list_id', $list_id)
                    ->whereNull('shared_with_user_id')
                    ->where('is_active', true)
                    ->where('expires_at', '>', Carbon::now())
                    ->count(),
                'expired_shares' => SharedList::where('list_id', $list_id)
                    ->where('expires_at', '<=', Carbon::now())
                    ->count(),
                'revoked_shares' => SharedList::where('list_id', $list_id)
                    ->where('is_active', false)
                    ->whereNotNull('revoked_at')
                    ->count()
            ];

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $stats
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Liste introuvable'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    // 🆕 MÉTHODES UTILITAIRES

    /**
     * Générer un token de partage sécurisé
     */
    private function generateSecureToken(): string
    {
        // Générer un token de 64 caractères (32 bytes en hex)
        $token = bin2hex(random_bytes(32));
        
        // Vérifier l'unicité
        while (SharedList::where('share_token', $token)->exists()) {
            $token = bin2hex(random_bytes(32));
        }
        
        return $token;
    }

    /**
     * Obtenir le nom d'affichage d'une permission
     */
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
     * Obtenir le statut d'un partage
     */
    private function getShareStatus(SharedList $share): string
    {
        if (!$share->is_active) {
            if ($share->revoked_at) return 'revoked';
            if ($share->declined_at) return 'declined';
            if ($share->left_at) return 'left';
            return 'inactive';
        }
        
        if ($share->expires_at->isPast()) {
            return 'expired';
        }
        
        if ($share->shared_with_user_id && $share->accepted_at) {
            return 'accepted';
        }
        
        return 'pending';
    }
}