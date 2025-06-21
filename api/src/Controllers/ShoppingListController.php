<?php
// app/Http/Controllers/ShoppingListController.php

namespace App\Controllers;

use App\Models\ShoppingList;
use App\Models\User;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class ShoppingListController
{
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
            $user_id = $request->getAttribute('auth_id'); // Récupéré depuis le middleware JWT
            
            $shoppingList = ShoppingList::create([
                'user_id' => $user_id,
                'name' => $data['name'],
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $shoppingList,
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

   // Dans la méthode index
    public function index(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $shoppingLists = ShoppingList::where('user_id', $user_id)
                ->with('items') // Charge les items associés
                ->orderBy('created_at', 'desc')
                ->get();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $shoppingLists
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

    // Dans la méthode show
    public function show(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $shoppingList = ShoppingList::where('user_id', $user_id)
                ->with('items') // Charge les items associés
                ->findOrFail($args['id']);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $shoppingList
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Liste non trouvée',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        }
    }

    /**
     * Met à jour une liste de courses
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
            $shoppingList = ShoppingList::where('user_id', $user_id)
                ->findOrFail($args['id']);

            $shoppingList->update(['name' => $data['name']]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $shoppingList,
                'message' => 'Liste mise à jour avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
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
     * Supprime une liste de courses (soft delete)
     */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $shoppingList = ShoppingList::where('user_id', $user_id)
                ->findOrFail($args['id']);

            $shoppingList->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Liste supprimée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
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
     * Restaure une liste de courses supprimée
     */
    public function restore(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
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
     * Duplique une liste de courses avec ses items
     */
    public function duplicate(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            
            // Récupère la liste originale avec ses items
            $originalList = ShoppingList::with('items')
                ->where('user_id', $user_id)
                ->findOrFail($args['id']);

            // Crée une nouvelle liste avec le même nom + " (Copie)"
            $newList = ShoppingList::create([
                'user_id' => $user_id,
                'name' => $originalList->name . ' (Copie)',
            ]);

            // Duplique tous les items de la liste originale
            foreach ($originalList->items as $item) {
                $newList->items()->create([
                    'product_name' => $item->product_name,
                    'quantity' => $item->quantity,
                    'price' => $item->price,
                    'store_name' => $item->store_name,
                    'is_purchased' => false, // On remet à false pour les items dupliqués
                ]);
            }

            // Recharge la nouvelle liste avec ses items pour la réponse
            $newListWithItems = ShoppingList::with('items')->find($newList->id);

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
}