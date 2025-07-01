<?php
// app/Http/Controllers/SharedListController.php - VERSION BRANCH.IO

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
    // 🌿 Configuration Branch.io - VOS DOMAINES
    private const BRANCH_DOMAIN = '9g24t.app.link';
    private const BRANCH_TEST_DOMAIN = '9g24t.test-app.link';
    private const APP_SCHEME = 'epilist';
    
    // 🌿 Fallbacks pour les stores
    private const ANDROID_STORE_URL = 'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
    private const IOS_STORE_URL = 'https://apps.apple.com/app/epilist/id123456789';
    
    // 🌿 Utiliser le domaine de test pour le développement
    private const CURRENT_DOMAIN = self::BRANCH_TEST_DOMAIN;

    /**
     * Créer un lien de partage pour une liste - VERSION BRANCH.IO
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
            
            // 🌿 Générer un token sécurisé pour Branch.io
            $shareToken = $this->generateBranchToken();
            $expirationDays = $data['expiration_days'] ?? 30;
            $expiresAt = Carbon::now()->addDays($expirationDays);
            
            // 🌿 Créer le partage avec métadonnées Branch.io
            $sharedList = SharedList::create([
                'list_id' => $list_id,
                'owner_id' => $user_id,
                'share_token' => $shareToken,
                'permission' => $data['permission'],
                'expires_at' => $expiresAt,
                'is_active' => true,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
                // 🌿 Métadonnées Branch.io
                'branch_data' => json_encode([
                    'list_name' => $list->name,
                    'owner_name' => User::find($user_id)->name ?? User::find($user_id)->email,
                    'permission' => $data['permission'],
                    'created_at' => Carbon::now()->toISOString()
                ])
            ]);

            // 🌿 Récupérer les informations pour Branch.io
            $owner = User::find($user_id);
            $ownerName = $owner->name ?? $owner->email;

            // 🌿 Préparer les données pour Branch.io SDK côté client
            $branchData = [
                'share_token' => $shareToken,
                'list_name' => $list->name,
                'owner_name' => $ownerName,
                'permission' => $data['permission'],
                'expires_at' => $expiresAt->toISOString(),
                'type' => 'list_share'
            ];

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    // 🌿 Données nécessaires pour Branch.io SDK
                    'share_token' => $shareToken,
                    'list_name' => $list->name,
                    'owner_name' => $ownerName,
                    'permission' => $data['permission'],
                    'expires_at' => $expiresAt->toISOString(),
                    'expires_in_days' => $expirationDays,
                    
                    // 🌿 URLs de base (Branch.io SDK créera le lien final)
                    'canonical_url' => "https://" . self::CURRENT_DOMAIN . "/share/{$shareToken}",
                    'app_url' => self::APP_SCHEME . "://share/{$shareToken}",
                    'fallback_url' => self::ANDROID_STORE_URL,
                    
                    // 🌿 Métadonnées pour Branch.io
                    'branch_data' => $branchData,
                    
                    // 🌿 Configuration Branch.io
                    'branch_config' => [
                        'domain' => self::CURRENT_DOMAIN,
                        'android_fallback' => self::ANDROID_STORE_URL,
                        'ios_fallback' => self::IOS_STORE_URL,
                        'desktop_fallback' => "https://" . self::CURRENT_DOMAIN . "/share/{$shareToken}"
                    ]
                ],
                'message' => 'Token de partage créé avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la création du token de partage',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Obtenir les informations d'une invitation - COMPATIBLE BRANCH.IO
     */
    public function getShareInvitation(Request $request, Response $response, array $args): Response
    {
        try {
            $shareToken = $args['token'];
            
            // 🌿 Vérifier que le token est valide et actif
            $sharedList = SharedList::with(['shoppingList.items', 'owner'])
                ->where('share_token', $shareToken)
                ->where('is_active', true)
                ->where('expires_at', '>', Carbon::now())
                ->firstOrFail();

            // 🌿 Décoder les métadonnées Branch.io
            $branchData = json_decode($sharedList->branch_data ?? '{}', true);

            // 🌿 Préparer les données d'invitation enrichies pour Branch.io
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
                
                // 🌿 Informations sur la liste pour Branch.io
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
                
                // 🌿 Métadonnées Branch.io
                'branch_data' => $branchData,
                
                // 🌿 URLs pour partage social
                'share_urls' => [
                    'canonical' => "https://" . self::CURRENT_DOMAIN . "/share/{$shareToken}",
                    'app' => self::APP_SCHEME . "://share/{$shareToken}",
                    'android_store' => self::ANDROID_STORE_URL,
                    'ios_store' => self::IOS_STORE_URL
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
            
            // 🌿 Vérifier que le token est valide et pas expiré
            $sharedList = SharedList::with('shoppingList')
                ->where('share_token', $shareToken)
                ->where('is_active', true)
                ->where('expires_at', '>', Carbon::now())
                ->firstOrFail();

            // Vérifier que l'utilisateur n'est pas le propriétaire
            if ($sharedList->owner_id == $user_id) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous ne pouvez pas accepter votre propre invitation'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Vérifier que l'invitation n'a pas déjà été acceptée
            if ($sharedList->shared_with_user_id !== null) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Cette invitation a déjà été acceptée'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // 🌿 Mettre à jour avec données d'acceptation pour analytics Branch.io
            $acceptedAt = Carbon::now();
            $acceptedUser = User::find($user_id);
            
            $branchData = json_decode($sharedList->branch_data ?? '{}', true);
            $branchData['accepted_at'] = $acceptedAt->toISOString();
            $branchData['accepted_by'] = $acceptedUser->name ?? $acceptedUser->email;

            $sharedList->update([
                'shared_with_user_id' => $user_id,
                'accepted_at' => $acceptedAt,
                'updated_at' => $acceptedAt,
                'branch_data' => json_encode($branchData)
            ]);

            // 🌿 Enrichir les données de la liste retournée
            $listData = $sharedList->shoppingList->toArray();
            $listData['permission'] = $sharedList->permission;
            $listData['is_shared'] = true;
            $listData['is_owner'] = false;
            $listData['can_edit'] = in_array($sharedList->permission, ['edit', 'admin']);
            $listData['can_delete'] = $sharedList->permission === 'admin';
            $listData['can_share'] = $sharedList->permission === 'admin';
            $listData['shared_at'] = $acceptedAt->toISOString();

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
            
            // 🌿 Marquer comme refusée avec métadonnées Branch.io
            $declinedAt = Carbon::now();
            $branchData = json_decode($sharedList->branch_data ?? '{}', true);
            $branchData['declined_at'] = $declinedAt->toISOString();

            $sharedList->update([
                'is_active' => false,
                'declined_at' => $declinedAt,
                'updated_at' => $declinedAt,
                'branch_data' => json_encode($branchData)
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
            
            // Récupérer les listes partagées avec informations enrichies
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
                    $list->can_share = $sharedList->permission === 'admin';
                    $list->owner = $sharedList->owner;
                    $list->shared_at = $sharedList->accepted_at;
                    
                    // 🌿 Ajouter les métadonnées Branch.io
                    $list->branch_data = json_decode($sharedList->branch_data ?? '{}', true);
                    
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
            
            // Récupérer tous les partages avec informations détaillées
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
                        
                        // 🌿 URLs Branch.io
                        'share_urls' => [
                            'canonical' => "https://" . self::CURRENT_DOMAIN . "/share/{$share->share_token}",
                            'app' => self::APP_SCHEME . "://share/{$share->share_token}",
                            'fallback' => self::ANDROID_STORE_URL
                        ],
                        
                        'shared_with_user' => $share->sharedWithUser ? [
                            'id' => $share->sharedWithUser->id,
                            'name' => $share->sharedWithUser->name,
                            'email' => $share->sharedWithUser->email
                        ] : null,
                        'status' => $this->getShareStatus($share),
                        
                        // 🌿 Métadonnées Branch.io
                        'branch_data' => json_decode($share->branch_data ?? '{}', true)
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

    // 🌿 MÉTHODES UTILITAIRES BRANCH.IO

    /**
     * Générer un token de partage optimisé pour Branch.io
     */
    private function generateBranchToken(): string
    {
        // 🌿 Token plus court et plus lisible pour Branch.io
        // Format: 6 caractères + timestamp court
        $prefix = substr(bin2hex(random_bytes(3)), 0, 6); // 6 caractères
        $timestamp = base_convert(time(), 10, 36); // Timestamp en base 36
        $token = $prefix . $timestamp;
        
        // Vérifier l'unicité
        while (SharedList::where('share_token', $token)->exists()) {
            $prefix = substr(bin2hex(random_bytes(3)), 0, 6);
            $token = $prefix . $timestamp . rand(10, 99);
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

    /**
     * 🌿 Obtenir les informations de configuration Branch.io
     */
    public function getBranchConfig(Request $request, Response $response): Response
    {
        $config = [
            'domain' => self::CURRENT_DOMAIN,
            'test_domain' => self::BRANCH_TEST_DOMAIN,
            'prod_domain' => self::BRANCH_DOMAIN,
            'app_scheme' => self::APP_SCHEME,
            'android_store' => self::ANDROID_STORE_URL,
            'ios_store' => self::IOS_STORE_URL,
            'environment' => 'test' // ou 'production'
        ];

        $response->getBody()->write(json_encode([
            'success' => true,
            'data' => $config
        ]));
        return $response->withHeader('Content-Type', 'application/json');
    }

    /**
     * 🌿 Endpoint pour valider un token de partage (pour Branch.io)
     */
    public function validateShareToken(Request $request, Response $response, array $args): Response
    {
        try {
            $shareToken = $args['token'];
            
            $sharedList = SharedList::where('share_token', $shareToken)
                ->where('is_active', true)
                ->where('expires_at', '>', Carbon::now())
                ->exists();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'is_valid' => $sharedList,
                    'token' => $shareToken
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'data' => [
                    'is_valid' => false,
                    'token' => $args['token'] ?? null
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        }
    }

    // ... (autres méthodes inchangées: updateSharePermission, revokeShare, etc.)
}