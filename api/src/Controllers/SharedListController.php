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

    // ... (autres méthodes restent identiques)

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