<?php
// app/Http/Controllers/SharedListController.php

namespace App\Controllers;

use App\Models\SharedList;
use App\Models\ShoppingList;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class SharedListController
{
    /**
     * Créer un lien de partage pour une liste
     */
    public function createShareLink(Request $request, Response $response, array $args): Response
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
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            $list = ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            // Créer le partage
            $shareToken = bin2hex(random_bytes(32));
            $expirationDays = $data['expiration_days'] ?? 30;
            
            $sharedList = SharedList::create([
                'list_id' => $list_id,
                'owner_id' => $user_id,
                'share_token' => $shareToken,
                'permission' => $data['permission'],
                'is_active' => true
                // shared_with_user_id sera NULL jusqu'à ce que quelqu'un accepte l'invitation
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'share_url' => "https://epilist.app.com/share/{$shareToken}"
                ],
                'message' => 'Lien de partage créé avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la création du lien',
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
            
            $sharedList = SharedList::with('shoppingList', 'owner')
                ->where('share_token', $shareToken)
                ->where('is_active', true)
                ->firstOrFail();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $sharedList
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
     * Accepter une invitation de partage
     */
    public function acceptShareInvitation(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $shareToken = $args['token'];
            
            $sharedList = SharedList::with('shoppingList')
                ->where('share_token', $shareToken)
                ->where('is_active', true)
                ->firstOrFail();

            // Mettre à jour avec l'utilisateur qui accepte
            $sharedList->update([
                'shared_with_user_id' => $user_id
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $sharedList->shoppingList,
                'message' => 'Invitation acceptée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de l\'acceptation'
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
            
            $sharedList = SharedList::where('share_token', $shareToken)->firstOrFail();
            $sharedList->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Invitation refusée'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du refus'
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
            
            $sharedLists = SharedList::with('shoppingList', 'owner')
                ->where('shared_with_user_id', $user_id)
                ->where('is_active', true)
                ->get();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $sharedLists
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération'
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
            ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            $shares = SharedList::with('sharedWithUser')
                ->where('list_id', $list_id)
                ->get();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $shares
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération'
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
        $validator->rule('required', 'permission');
        $validator->rule('in', 'permission', ['readOnly', 'edit', 'admin']);
        
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
            
            $sharedList = SharedList::where('owner_id', $user_id)->findOrFail($share_id);
            $sharedList->update(['permission' => $data['permission']]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $sharedList,
                'message' => 'Permission mise à jour'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour'
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
            
            $sharedList = SharedList::where('owner_id', $user_id)->findOrFail($share_id);
            $sharedList->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Partage révoqué'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la révocation'
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
                ->firstOrFail();
            
            $sharedList->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Vous avez quitté la liste'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Révoquer tous les liens de partage
     */
    public function revokeAllShareLinks(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            SharedList::where('list_id', $list_id)
                ->where('owner_id', $user_id)
                ->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Tous les liens révoqués'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Obtenir les statistiques de partage
     */
    public function getShareStats(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            $stats = [
                'total_shares' => SharedList::where('list_id', $list_id)->count(),
                'active_shares' => SharedList::where('list_id', $list_id)
                    ->whereNotNull('shared_with_user_id')->count(),
                'pending_shares' => SharedList::where('list_id', $list_id)
                    ->whereNull('shared_with_user_id')->count()
            ];

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $stats
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}