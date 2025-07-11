<?php
// app/Http/Controllers/ShoppingListController.php - VERSION AVEC ORDRE COHÉRENT DES ITEMS

namespace App\Controllers;

use App\Models\ShoppingList;
use App\Models\SharedList;
use App\Models\User;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class ShoppingListController
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
     * Crée une nouvelle liste de courses
     */
    public function store(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();
        
        $validator = new Validator($data);
        $validator->rule('required', 'name')->message('Le nom est obligatoire');
        $validator->rule('lengthMax', 'name', 255)->message('Le nom est trop long');
        
        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'errors' => $validator->errors()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');
            
            $shoppingList = ShoppingList::create([
                'user_id' => $user_id,
                'name' => $data['name'],
            ]);

            // ✅ Charger la liste fraîchement créée avec ses items (même si vide) dans l'ordre cohérent
            $shoppingListWithItems = ShoppingList::with(['items' => $this->getItemsOrdering()])
                ->find($shoppingList->id);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $shoppingListWithItems,
                'message' => 'Liste créée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la création de la liste',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Récupère toutes les listes (propres + partagées) de l'utilisateur avec ordre cohérent
     */
    public function index(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            
            // ✅ 1. Récupérer les listes propres de l'utilisateur avec ordre cohérent des items
            $ownLists = ShoppingList::where('user_id', $user_id)
                ->with(['items' => $this->getItemsOrdering()])
                ->orderBy('created_at', 'desc')
                ->get();

            // ✅ 2. Récupérer les listes partagées avec l'utilisateur avec ordre cohérent des items
            $sharedListsData = SharedList::with([
                'shoppingList.items' => $this->getItemsOrdering(), 
                'owner' => function($query) {
                    // S'assurer de charger les bons champs selon votre structure de table
                    $query->select('id', 'first_name', 'last_name', 'email');
                }
            ])
                ->where('shared_with_user_id', $user_id)
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->where('is_active', true)
                ->orderBy('accepted_at', 'desc')
                ->get();

            // ✅ 3. Transformer les listes partagées avec les informations de partage
            $sharedLists = $sharedListsData->map(function($sharedList) use ($user_id) {
                $list = $sharedList->shoppingList;
                $owner = $sharedList->owner;
                
                // Ajouter les métadonnées de partage à la liste
                $listArray = $list->toArray();
                $listArray['is_shared'] = true;
                $listArray['is_owner'] = false;
                $listArray['share_permission'] = $sharedList->permission;
                $listArray['permission_display_name'] = $this->getPermissionDisplayName($sharedList->permission);
                
                // ✅ Amélioration pour shared_by.name
                $listArray['shared_by'] = [
                    'id' => $owner->id,
                    'name' => $this->getUserDisplayName($owner),
                    'email' => $owner->email
                ];
                
                $listArray['shared_at'] = $sharedList->accepted_at->toISOString();
                $listArray['can_edit'] = $sharedList->canEdit();
                $listArray['can_delete'] = $sharedList->canDelete();
                
                return $listArray;
            });

            // ✅ 4. Transformer les listes propres avec les métadonnées
            $ownListsFormatted = $ownLists->map(function($list) {
                $listArray = $list->toArray();
                $listArray['is_shared'] = false;
                $listArray['is_owner'] = true;
                $listArray['share_permission'] = 'admin';
                $listArray['permission_display_name'] = 'Propriétaire';
                $listArray['can_edit'] = true;
                $listArray['can_delete'] = true;
                
                return $listArray;
            });

            // ✅ 5. Combiner les deux types de listes
            $allLists = $ownListsFormatted->concat($sharedLists);

            // ✅ 6. Trier par date de création/partage (plus récent en premier)
            $sortedLists = $allLists->sortByDesc(function($list) {
                return $list['shared_at'] ?? $list['created_at'];
            })->values();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $sortedLists,
                'meta' => [
                    'own_lists_count' => $ownLists->count(),
                    'shared_lists_count' => $sharedLists->count(),
                    'total_count' => $allLists->count()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des listes',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Affiche une liste spécifique (propre ou partagée) avec ordre cohérent
     */
    public function show(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // ✅ 1. Vérifier si c'est une liste propre avec ordre cohérent des items
            $ownList = ShoppingList::where('user_id', $user_id)
                ->where('id', $list_id)
                ->with(['items' => $this->getItemsOrdering()])
                ->first();

            if ($ownList) {
                // C'est une liste propre
                $listArray = $ownList->toArray();
                $listArray['is_shared'] = false;
                $listArray['is_owner'] = true;
                $listArray['share_permission'] = 'admin';
                $listArray['permission_display_name'] = 'Propriétaire';
                $listArray['can_edit'] = true;
                $listArray['can_delete'] = true;

                $response->getBody()->write(json_encode([
                    'success' => true,
                    'data' => $listArray
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            // ✅ 2. Vérifier si c'est une liste partagée avec ordre cohérent des items
            $sharedList = SharedList::with([
                'shoppingList.items' => $this->getItemsOrdering(), 
                'owner' => function($query) {
                    $query->select('id', 'first_name', 'last_name', 'email');
                }
            ])
                ->where('shared_with_user_id', $user_id)
                ->whereHas('shoppingList', function($query) use ($list_id) {
                    $query->where('id', $list_id);
                })
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->where('is_active', true)
                ->first();

            if ($sharedList) {
                // C'est une liste partagée
                $list = $sharedList->shoppingList;
                $owner = $sharedList->owner;
                
                $listArray = $list->toArray();
                $listArray['is_shared'] = true;
                $listArray['is_owner'] = false;
                $listArray['share_permission'] = $sharedList->permission;
                $listArray['permission_display_name'] = $this->getPermissionDisplayName($sharedList->permission);
                
                // ✅ Amélioration pour shared_by.name
                $listArray['shared_by'] = [
                    'id' => $owner->id,
                    'name' => $this->getUserDisplayName($owner),
                    'email' => $owner->email
                ];
                
                $listArray['shared_at'] = $sharedList->accepted_at->toISOString();
                $listArray['can_edit'] = $sharedList->canEdit();
                $listArray['can_delete'] = $sharedList->canDelete();

                $response->getBody()->write(json_encode([
                    'success' => true,
                    'data' => $listArray
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            // ✅ 3. Liste non trouvée
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Liste non trouvée ou accès non autorisé'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération de la liste',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Met à jour une liste (avec vérification des permissions)
     */
    public function update(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        
        $validator = new Validator($data);
        $validator->rule('required', 'name')->message('Le nom est obligatoire');
        $validator->rule('lengthMax', 'name', 255)->message('Le nom est trop long');
        
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
            
            // ✅ 1. Vérifier si c'est une liste propre avec ordre cohérent des items
            $ownList = ShoppingList::where('user_id', $user_id)
                ->where('id', $list_id)
                ->with(['items' => $this->getItemsOrdering()])
                ->first();

            if ($ownList) {
                // Propriétaire peut toujours modifier
                $ownList->update(['name' => $data['name']]);
                $ownList->refresh();

                $response->getBody()->write(json_encode([
                    'success' => true,
                    'data' => $ownList,
                    'message' => 'Liste mise à jour avec succès'
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            // ✅ 2. Vérifier si c'est une liste partagée avec permissions d'édition et ordre cohérent
            $sharedList = SharedList::with(['shoppingList.items' => $this->getItemsOrdering()])
                ->where('shared_with_user_id', $user_id)
                ->whereHas('shoppingList', function($query) use ($list_id) {
                    $query->where('id', $list_id);
                })
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->where('is_active', true)
                ->first();

            if ($sharedList && $sharedList->canEdit()) {
                // L'utilisateur a les permissions pour modifier
                $sharedList->shoppingList->update(['name' => $data['name']]);
                $sharedList->shoppingList->refresh();

                $response->getBody()->write(json_encode([
                    'success' => true,
                    'data' => $sharedList->shoppingList,
                    'message' => 'Liste mise à jour avec succès'
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            // ✅ 3. Pas d'autorisation
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Vous n\'avez pas les permissions pour modifier cette liste'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(403);

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de la liste',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Supprime une liste (avec vérification des permissions)
     */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // ✅ 1. Vérifier si c'est une liste propre
            $ownList = ShoppingList::where('user_id', $user_id)
                ->where('id', $list_id)
                ->first();

            if ($ownList) {
                // Propriétaire peut toujours supprimer
                $ownList->delete();

                $response->getBody()->write(json_encode([
                    'success' => true,
                    'message' => 'Liste supprimée avec succès'
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            // ✅ 2. Vérifier si c'est une liste partagée avec permissions d'admin
            $sharedList = SharedList::with(['shoppingList'])
                ->where('shared_with_user_id', $user_id)
                ->whereHas('shoppingList', function($query) use ($list_id) {
                    $query->where('id', $list_id);
                })
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->where('is_active', true)
                ->first();

            if ($sharedList && $sharedList->canDelete()) {
                // L'utilisateur a les permissions d'admin pour supprimer
                $sharedList->shoppingList->delete();

                $response->getBody()->write(json_encode([
                    'success' => true,
                    'message' => 'Liste supprimée avec succès'
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            // ✅ 3. Pas d'autorisation
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Vous n\'avez pas les permissions pour supprimer cette liste'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(403);

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la suppression de la liste',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Restaure une liste supprimée (propriétaire seulement)
     */
    public function restore(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            
            // Seul le propriétaire peut restaurer
            $shoppingList = ShoppingList::withTrashed()
                ->where('user_id', $user_id)
                ->findOrFail($args['id']);

            $shoppingList->restore();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $shoppingList,
                'message' => 'Liste restaurée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la restauration de la liste',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Duplique une liste (avec vérification des permissions et ordre cohérent)
     */
    public function duplicate(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // ✅ 1. Essayer de récupérer comme liste propre avec ordre cohérent
            $originalList = ShoppingList::with(['items' => $this->getItemsOrdering()])
                ->where('user_id', $user_id)
                ->where('id', $list_id)
                ->first();

            // ✅ 2. Si pas trouvée, essayer comme liste partagée avec ordre cohérent
            if (!$originalList) {
                $sharedList = SharedList::with(['shoppingList.items' => $this->getItemsOrdering()])
                    ->where('shared_with_user_id', $user_id)
                    ->whereHas('shoppingList', function($query) use ($list_id) {
                        $query->where('id', $list_id);
                    })
                    ->where('status', SharedList::STATUS_ACCEPTED)
                    ->where('is_active', true)
                    ->first();

                if ($sharedList) {
                    $originalList = $sharedList->shoppingList;
                }
            }

            if (!$originalList) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Liste non trouvée ou accès non autorisé'
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            // ✅ 3. Créer une nouvelle liste (toujours propriété de l'utilisateur actuel)
            $newList = ShoppingList::create([
                'user_id' => $user_id,
                'name' => $originalList->name . ' (Copie)',
            ]);

            // ✅ 4. Duplique tous les items
            foreach ($originalList->items as $item) {
                $newList->items()->create([
                    'product_name' => $item->product_name,
                    'quantity' => $item->quantity,
                    'price' => $item->price,
                    'store_name' => $item->store_name,
                    'is_purchased' => false, // Remet à false pour les items dupliqués
                ]);
            }

            // ✅ Recharge la nouvelle liste avec ses items dans l'ordre cohérent
            $newListWithItems = ShoppingList::with(['items' => $this->getItemsOrdering()])
                ->find($newList->id);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $newListWithItems,
                'message' => 'Liste dupliquée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la duplication de la liste',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Méthode utilitaire pour obtenir le nom d'affichage d'un utilisateur
     */
    private function getUserDisplayName($user): string
    {
        // Concaténer first_name et last_name selon votre structure de table
        if (!empty($user->first_name) || !empty($user->last_name)) {
            return trim($user->first_name . ' ' . $user->last_name);
        }
        
        // En dernier recours, utiliser la partie avant @ de l'email
        if (!empty($user->email)) {
            $emailParts = explode('@', $user->email);
            return $emailParts[0];
        }
        
        return 'Utilisateur inconnu';
    }

    /**
     * ✅ Méthode utilitaire pour les noms de permissions
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
}