<?php
// app/Http/Controllers/ListItemController.php - VERSION AVEC ORDRE COHÉRENT

namespace App\Controllers;

use App\Models\ListItem;
use App\Models\ShoppingList;
use App\Models\SharedList;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class ListItemController
{
    /**
     * ✅ Méthode utilitaire pour l'ordre cohérent des items
     */
    private function getItemsOrdering()
    {
        return function($query) {
            return $query->orderBy('is_purchased') // Articles non achetés en premier
                        ->orderBy('created_at', 'desc'); // Plus récent en premier
        };
    }

    /**
     * ✅ Vérifier les permissions d'accès à une liste
     */
    private function checkListAccess(int $user_id, int $list_id, string $requiredPermission = 'read'): ?array
    {
        // 1. Vérifier si c'est une liste propre
        $ownList = ShoppingList::where('user_id', $user_id)
            ->where('id', $list_id)
            ->first();

        if ($ownList) {
            return [
                'list' => $ownList,
                'is_owner' => true,
                'permission' => 'admin',
                'can_read' => true,
                'can_edit' => true,
                'can_delete' => true
            ];
        }

        // 2. Vérifier si c'est une liste partagée
        $sharedList = SharedList::with(['shoppingList'])
            ->where('shared_with_user_id', $user_id)
            ->whereHas('shoppingList', function($query) use ($list_id) {
                $query->where('id', $list_id);
            })
            ->where('status', SharedList::STATUS_ACCEPTED)
            ->where('is_active', true)
            ->first();

        if ($sharedList) {
            $canEdit = $sharedList->canEdit();
            $canDelete = $sharedList->canDelete();

            // Vérifier si l'utilisateur a la permission requise
            $hasPermission = match($requiredPermission) {
                'read' => true,
                'edit' => $canEdit,
                'delete' => $canDelete,
                default => false
            };

            if (!$hasPermission) {
                return null; // Pas la permission requise
            }

            return [
                'list' => $sharedList->shoppingList,
                'is_owner' => false,
                'permission' => $sharedList->permission,
                'can_read' => true,
                'can_edit' => $canEdit,
                'can_delete' => $canDelete
            ];
        }

        return null; // Aucun accès
    }

    /**
     * ✅ Affiche tous les items d'une liste (avec permissions et ordre cohérent)
     */
    public function index(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];

            // Vérifier l'accès à la liste
            $access = $this->checkListAccess($user_id, $listId, 'read');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Accès non autorisé à cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            // ✅ Utiliser l'ordre cohérent
            $items = ListItem::where('list_id', $listId)
                ->orderBy('is_purchased') // Articles non achetés en premier
                ->orderBy('created_at', 'desc') // Plus récent en premier
                ->get();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $items,
                'meta' => [
                    'list_name' => $access['list']->name,
                    'is_owner' => $access['is_owner'],
                    'permission' => $access['permission'],
                    'can_edit' => $access['can_edit'],
                    'can_delete' => $access['can_delete']
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des items',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Crée un nouvel item dans une liste (avec permissions)
     */
    public function store(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = $args['listId'];

        $validator = new Validator($data);
        $validator->rule('required', 'product_name')->message('Le nom du produit est obligatoire');
        $validator->rule('lengthMax', 'product_name', 255)->message('Le nom du produit est trop long');
        $validator->rule('integer', 'quantity')->message('La quantité doit être un nombre entier');
        $validator->rule('min', 'quantity', 1)->message('La quantité doit être au moins 1');
        $validator->rule('numeric', 'price')->message('Le prix doit être un nombre');
        $validator->rule('min', 'price', 0)->message('Le prix ne peut pas être négatif');
        $validator->rule('lengthMax', 'store_name', 255)->message('Le nom du magasin est trop long');
        $validator->rule('boolean', 'is_purchased')->message('Le statut d\'achat doit être vrai ou faux');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'errors' => $validator->errors()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');

            // Vérifier les permissions d'édition
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'avez pas les permissions pour ajouter des articles à cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::create([
                'list_id' => $listId,
                'product_name' => $data['product_name'],
                'quantity' => $data['quantity'] ?? 1,
                'price' => $data['price'] ?? null,
                'store_name' => $data['store_name'] ?? null,
                'is_purchased' => $data['is_purchased'] ?? false
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item,
                'message' => 'Article ajouté avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de l\'ajout de l\'article',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Met à jour un item (avec permissions)
     */
    public function update(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = $args['listId'];
        $itemId = $args['itemId'];

        $validator = new Validator($data);
        $validator->rule('lengthMax', 'product_name', 255)->message('Le nom du produit est trop long');
        $validator->rule('integer', 'quantity')->message('La quantité doit être un nombre entier');
        $validator->rule('min', 'quantity', 1)->message('La quantité doit être au moins 1');
        $validator->rule('numeric', 'price')->message('Le prix doit être un nombre');
        $validator->rule('min', 'price', 0)->message('Le prix ne peut pas être négatif');
        $validator->rule('lengthMax', 'store_name', 255)->message('Le nom du magasin est trop long');
        $validator->rule('boolean', 'is_purchased')->message('Le statut d\'achat doit être vrai ou faux');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'errors' => $validator->errors()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');

            // Vérifier les permissions d'édition
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'avez pas les permissions pour modifier les articles de cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::where('list_id', $listId)
                ->findOrFail($itemId);

            $item->update([
                'product_name' => $data['product_name'] ?? $item->product_name,
                'quantity' => $data['quantity'] ?? $item->quantity,
                'price' => $data['price'] ?? $item->price,
                'store_name' => $data['store_name'] ?? $item->store_name,
                'is_purchased' => $data['is_purchased'] ?? $item->is_purchased
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item->fresh(),
                'message' => 'Article mis à jour avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de l\'article',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Marque un item comme acheté/non acheté (avec permissions)
     */
    public function togglePurchased(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            // Vérifier les permissions d'édition
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'avez pas les permissions pour modifier les articles de cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::where('list_id', $listId)
                ->findOrFail($itemId);

            $item->update(['is_purchased' => !$item->is_purchased]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item->fresh(),
                'message' => $item->is_purchased ? 'Article marqué comme acheté' : 'Article marqué comme non acheté'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors du changement de statut',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Supprime un item (avec permissions)
     */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            // Vérifier les permissions d'édition (supprimer nécessite édition)
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'avez pas les permissions pour supprimer les articles de cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::where('list_id', $listId)
                ->findOrFail($itemId);

            $item->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Article supprimé avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la suppression de l\'article',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Restaure un item supprimé (avec permissions)
     */
    public function restore(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            // Vérifier les permissions d'édition pour la restauration
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'avez pas les permissions pour restaurer les articles de cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::withTrashed()
                ->where('list_id', $listId)
                ->findOrFail($itemId);

            $item->restore();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item->fresh(),
                'message' => 'Article restauré avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la restauration de l\'article',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Affiche un article spécifique (avec permissions)
     */
    public function show(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            // Vérifier l'accès en lecture à la liste
            $access = $this->checkListAccess($user_id, $listId, 'read');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Accès non autorisé à cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::where('list_id', $listId)
                ->findOrFail($itemId);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item,
                'meta' => [
                    'can_edit' => $access['can_edit'],
                    'can_delete' => $access['can_edit'], // Suppression nécessite édition
                    'permission' => $access['permission']
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Article non trouvé',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        }
    }

    /**
     * ✅ Marque tous les articles d'une liste comme achetés/non achetés (avec permissions)
     */
    public function markAllPurchased(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $data = $request->getParsedBody();
            $purchased = $data['purchased'] ?? true;

            // Vérifier les permissions d'édition
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'avez pas les permissions pour modifier les articles de cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $updatedCount = ListItem::where('list_id', $listId)
                ->update(['is_purchased' => $purchased]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => ['updated_count' => $updatedCount],
                'message' => $purchased 
                    ? "Tous les articles ont été marqués comme achetés" 
                    : "Tous les articles ont été marqués comme non achetés"
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour des articles',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Supprime tous les articles achetés d'une liste (avec permissions)
     */
    public function clearPurchased(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];

            // Vérifier les permissions d'édition
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Vous n\'avez pas les permissions pour modifier les articles de cette liste'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $deletedCount = ListItem::where('list_id', $listId)
                ->where('is_purchased', true)
                ->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => ['deleted_count' => $deletedCount],
                'message' => "Tous les articles achetés ont été supprimés ($deletedCount articles)"
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la suppression des articles achetés',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}