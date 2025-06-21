<?php
// app/Http/Controllers/ListItemController.php

namespace App\Controllers;

use App\Models\ListItem;
use App\Models\ShoppingList;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class ListItemController
{
    /**
     * Affiche tous les items d'une liste
     */
    public function index(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];

            $items = ListItem::whereHas('shoppingList', function($query) use ($user_id) {
                    $query->where('user_id', $user_id);
                })
                ->where('list_id', $listId)
                ->orderBy('is_purchased')
                ->orderBy('created_at', 'desc')
                ->get();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $items
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
     * Crée un nouvel item dans une liste
     */
    public function store(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = $args['listId'];

        $validator = new Validator($data);
        $validator->rule('required', 'product_name')->message('Le nom du produit est obligatoire');
        $validator->rule('lengthMax', 'product_name', 255);
        $validator->rule('integer', 'quantity');
        $validator->rule('min', 'quantity', 1);
        $validator->rule('numeric', 'price');
        $validator->rule('min', 'price', 0);
        $validator->rule('lengthMax', 'store_name', 255);
        $validator->rule('boolean', 'is_purchased');

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
                ->findOrFail($listId);

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
                'message' => 'Item ajouté avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de l\'ajout de l\'item',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Met à jour un item
     */
    public function update(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = $args['listId'];
        $itemId = $args['itemId'];

        $validator = new Validator($data);
        $validator->rule('lengthMax', 'product_name', 255);
        $validator->rule('integer', 'quantity');
        $validator->rule('min', 'quantity', 1);
        $validator->rule('numeric', 'price');
        $validator->rule('min', 'price', 0);
        $validator->rule('lengthMax', 'store_name', 255);
        $validator->rule('boolean', 'is_purchased');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'errors' => $validator->errors()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');
            $item = ListItem::where('list_id', $listId)
                ->whereHas('shoppingList', function($query) use ($user_id) {
                    $query->where('user_id', $user_id);
                })
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
                'data' => $item,
                'message' => 'Item mis à jour avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de l\'item',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Marque un item comme acheté/non acheté
     */
    public function togglePurchased(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            $item = ListItem::where('list_id', $listId)
                ->whereHas('shoppingList', function($query) use ($user_id) {
                    $query->where('user_id', $user_id);
                })
                ->findOrFail($itemId);

            $item->update(['is_purchased' => !$item->is_purchased]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item,
                'message' => 'Statut d\'achat mis à jour'
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
     * Supprime un item (soft delete)
     */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            $item = ListItem::where('list_id', $listId)
                ->whereHas('shoppingList', function($query) use ($user_id) {
                    $query->where('user_id', $user_id);
                })
                ->findOrFail($itemId);

            $item->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Item supprimé avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la suppression de l\'item',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Restaure un item supprimé
     */
    public function restore(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            $item = ListItem::withTrashed()
                ->where('list_id', $listId)
                ->whereHas('shoppingList', function($query) use ($user_id) {
                    $query->where('user_id', $user_id);
                })
                ->findOrFail($itemId);

            $item->restore();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item,
                'message' => 'Item restauré avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la restauration de l\'item',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}