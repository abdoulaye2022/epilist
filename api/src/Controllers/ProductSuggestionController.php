<?php
// app/Controllers/ProductSuggestionController.php

namespace App\Controllers;

use App\Models\ProductSuggestion;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class ProductSuggestionController
{
    /**
     * ✅ Recherche des suggestions par nom de produit
     */
    public function search(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $validator = new Validator($params);
            $validator->rule('required', 'q')->message('Le paramètre de recherche est obligatoire');
            $validator->rule('lengthMin', 'q', 2)->message('Le terme de recherche doit contenir au moins 2 caractères');
            $validator->rule('lengthMax', 'q', 100)->message('Le terme de recherche est trop long');
            $validator->rule('integer', 'limit')->message('La limite doit être un nombre entier');
            $validator->rule('min', 'limit', 1)->message('La limite doit être au moins 1');
            $validator->rule('max', 'limit', 50)->message('La limite ne peut pas dépasser 50');

            if (!$validator->validate()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'errors' => $validator->errors()
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $query = trim($params['q']);
            $limit = (int)($params['limit'] ?? 10);

            $suggestions = ProductSuggestion::searchByName($user_id, $query, $limit);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $suggestions,
                'meta' => [
                    'query' => $query,
                    'count' => count($suggestions),
                    'limit' => $limit
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la recherche de suggestions',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Obtient les suggestions les plus populaires
     */
    public function getPopular(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            $limit = (int)($params['limit'] ?? 20);

            $validator = new Validator(['limit' => $limit]);
            $validator->rule('integer', 'limit')->message('La limite doit être un nombre entier');
            $validator->rule('min', 'limit', 1)->message('La limite doit être au moins 1');
            $validator->rule('max', 'limit', 100)->message('La limite ne peut pas dépasser 100');

            if (!$validator->validate()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'errors' => $validator->errors()
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $suggestions = ProductSuggestion::getPopular($user_id, $limit);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $suggestions,
                'meta' => [
                    'count' => count($suggestions),
                    'limit' => $limit
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des suggestions populaires',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Supprime une suggestion spécifique
     */
    public function delete(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $suggestionId = $args['id'];

            $suggestion = ProductSuggestion::where('user_id', $user_id)
                ->findOrFail($suggestionId);

            $suggestion->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Suggestion supprimée avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la suppression de la suggestion',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Supprime toutes les suggestions de l'utilisateur
     */
    public function clear(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');

            $deletedCount = ProductSuggestion::where('user_id', $user_id)->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => ['deleted_count' => $deletedCount],
                'message' => "Toutes les suggestions ont été supprimées ($deletedCount suggestions)"
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la suppression des suggestions',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Met à jour manuellement une suggestion
     */
    public function update(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $suggestionId = $args['id'];

        $validator = new Validator($data);
        $validator->rule('lengthMax', 'product_name', 255)->message('Le nom du produit est trop long');
        $validator->rule('numeric', 'price')->message('Le prix doit être un nombre');
        $validator->rule('min', 'price', 0)->message('Le prix ne peut pas être négatif');
        $validator->rule('lengthMax', 'store_name', 255)->message('Le nom du magasin est trop long');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'errors' => $validator->errors()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');

            $suggestion = ProductSuggestion::where('user_id', $user_id)
                ->findOrFail($suggestionId);

            $updateData = [];
            
            if (isset($data['product_name'])) {
                $updateData['product_name'] = $data['product_name'];
                $updateData['normalized_name'] = ProductSuggestion::normalizeName($data['product_name']);
            }
            
            if (isset($data['price'])) {
                $updateData['price'] = $data['price'];
            }
            
            if (isset($data['store_name'])) {
                $updateData['store_name'] = $data['store_name'];
            }

            $suggestion->update($updateData);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $suggestion->fresh(),
                'message' => 'Suggestion mise à jour avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de la suggestion',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Obtient les statistiques des suggestions
     */
    public function getStats(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');

            $totalSuggestions = ProductSuggestion::where('user_id', $user_id)->count();
            $totalUsage = ProductSuggestion::where('user_id', $user_id)->sum('usage_count');
            $mostUsed = ProductSuggestion::where('user_id', $user_id)
                ->orderBy('usage_count', 'desc')
                ->first();
            $recentlyUsed = ProductSuggestion::where('user_id', $user_id)
                ->orderBy('last_used_at', 'desc')
                ->limit(5)
                ->get();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'total_suggestions' => $totalSuggestions,
                    'total_usage' => $totalUsage,
                    'most_used' => $mostUsed,
                    'recently_used' => $recentlyUsed
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}