<?php
// src/Controllers/CategoryController.php

namespace App\Controllers;

use App\Models\Category;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class CategoryController
{
    /**
     * Récupérer toutes les catégories de l'utilisateur
     */
    public function index(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('user_id');

        try {
            $categories = Category::where('user_id', $userId)
                ->whereNull('deleted_at')
                ->orderBy('order_index', 'ASC')
                ->get();

            $response->getBody()->write(json_encode([
                'categories' => $categories->toArray()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'error' => 'Erreur lors du chargement des catégories',
                'message' => $e->getMessage()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }

    /**
     * Récupérer une catégorie spécifique
     */
    public function show(Request $request, Response $response, array $args): Response
    {
        $userId = $request->getAttribute('user_id');
        $categoryId = $args['id'];

        try {
            $category = Category::where('user_id', $userId)
                ->where('id', $categoryId)
                ->whereNull('deleted_at')
                ->first();

            if (!$category) {
                $response->getBody()->write(json_encode([
                    'error' => 'Catégorie non trouvée'
                ]));

                return $response
                    ->withHeader('Content-Type', 'application/json')
                    ->withStatus(404);
            }

            $response->getBody()->write(json_encode([
                'category' => $category->toArray()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'error' => 'Erreur lors du chargement de la catégorie',
                'message' => $e->getMessage()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }

    /**
     * Créer une nouvelle catégorie
     */
    public function store(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('user_id');
        $data = json_decode($request->getBody()->getContents(), true);

        // Validation
        if (empty($data['name'])) {
            $response->getBody()->write(json_encode([
                'error' => 'Le nom de la catégorie est requis'
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        if (strlen($data['name']) < 2) {
            $response->getBody()->write(json_encode([
                'error' => 'Le nom doit contenir au moins 2 caractères'
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            // Obtenir le prochain order_index
            $maxOrder = Category::where('user_id', $userId)
                ->whereNull('deleted_at')
                ->max('order_index');

            $category = Category::create([
                'user_id' => $userId,
                'name' => $data['name'],
                'icon_code' => $data['icon_code'] ?? 'category',
                'color_hex' => $data['color_hex'] ?? '#4CAF50',
                'order_index' => $data['order_index'] ?? ($maxOrder + 1),
            ]);

            $response->getBody()->write(json_encode([
                'message' => 'Catégorie créée avec succès',
                'category' => $category->toArray()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'error' => 'Erreur lors de la création de la catégorie',
                'message' => $e->getMessage()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }

    /**
     * Mettre à jour une catégorie
     */
    public function update(Request $request, Response $response, array $args): Response
    {
        $userId = $request->getAttribute('user_id');
        $categoryId = $args['id'];
        $data = json_decode($request->getBody()->getContents(), true);

        try {
            $category = Category::where('user_id', $userId)
                ->where('id', $categoryId)
                ->whereNull('deleted_at')
                ->first();

            if (!$category) {
                $response->getBody()->write(json_encode([
                    'error' => 'Catégorie non trouvée'
                ]));

                return $response
                    ->withHeader('Content-Type', 'application/json')
                    ->withStatus(404);
            }

            // Validation du nom si fourni
            if (isset($data['name'])) {
                if (strlen($data['name']) < 2) {
                    $response->getBody()->write(json_encode([
                        'error' => 'Le nom doit contenir au moins 2 caractères'
                    ]));

                    return $response
                        ->withHeader('Content-Type', 'application/json')
                        ->withStatus(400);
                }
                $category->name = $data['name'];
            }

            if (isset($data['icon_code'])) {
                $category->icon_code = $data['icon_code'];
            }

            if (isset($data['color_hex'])) {
                $category->color_hex = $data['color_hex'];
            }

            if (isset($data['order_index'])) {
                $category->order_index = $data['order_index'];
            }

            $category->save();

            $response->getBody()->write(json_encode([
                'message' => 'Catégorie mise à jour avec succès',
                'category' => $category->toArray()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'error' => 'Erreur lors de la mise à jour de la catégorie',
                'message' => $e->getMessage()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }

    /**
     * Supprimer une catégorie (soft delete)
     */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        $userId = $request->getAttribute('user_id');
        $categoryId = $args['id'];

        try {
            $category = Category::where('user_id', $userId)
                ->where('id', $categoryId)
                ->whereNull('deleted_at')
                ->first();

            if (!$category) {
                $response->getBody()->write(json_encode([
                    'error' => 'Catégorie non trouvée'
                ]));

                return $response
                    ->withHeader('Content-Type', 'application/json')
                    ->withStatus(404);
            }

            // Soft delete
            $category->deleted_at = date('Y-m-d H:i:s');
            $category->save();

            $response->getBody()->write(json_encode([
                'message' => 'Catégorie supprimée avec succès'
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'error' => 'Erreur lors de la suppression de la catégorie',
                'message' => $e->getMessage()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }

    /**
     * Réorganiser les catégories
     */
    public function reorder(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('user_id');
        $data = json_decode($request->getBody()->getContents(), true);

        if (empty($data['category_ids']) || !is_array($data['category_ids'])) {
            $response->getBody()->write(json_encode([
                'error' => 'Liste des IDs de catégories requise'
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            foreach ($data['category_ids'] as $index => $categoryId) {
                Category::where('user_id', $userId)
                    ->where('id', $categoryId)
                    ->whereNull('deleted_at')
                    ->update(['order_index' => $index]);
            }

            $response->getBody()->write(json_encode([
                'message' => 'Catégories réorganisées avec succès'
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'error' => 'Erreur lors de la réorganisation des catégories',
                'message' => $e->getMessage()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }

    /**
     * Initialiser les catégories par défaut
     */
    public function initializeDefaults(Request $request, Response $response): Response
    {
        error_log("=== DEBUG CategoryController::initializeDefaults START ===");

        $userId = $request->getAttribute('user_id');
        error_log("DEBUG: user_id = " . var_export($userId, true));

        try {
            // Vérifier si l'utilisateur a déjà des catégories
            error_log("DEBUG: Checking existing categories for user_id: $userId");

            $existingCount = Category::where('user_id', $userId)
                ->whereNull('deleted_at')
                ->count();

            error_log("DEBUG: Existing count = " . $existingCount);

            if ($existingCount > 0) {
                $response->getBody()->write(json_encode([
                    'error' => 'L\'utilisateur a déjà des catégories'
                ]));

                return $response
                    ->withHeader('Content-Type', 'application/json')
                    ->withStatus(400);
            }

            // Catégories par défaut
            $defaultCategories = [
                ['name' => 'Fruits & Légumes', 'icon_code' => 'eco', 'color_hex' => '#4CAF50'],
                ['name' => 'Viandes & Poissons', 'icon_code' => 'set_meal', 'color_hex' => '#F44336'],
                ['name' => 'Produits laitiers', 'icon_code' => 'egg', 'color_hex' => '#FFC107'],
                ['name' => 'Boulangerie', 'icon_code' => 'bakery_dining', 'color_hex' => '#FF9800'],
                ['name' => 'Boissons', 'icon_code' => 'local_cafe', 'color_hex' => '#00BCD4'],
                ['name' => 'Snacks & Sucreries', 'icon_code' => 'cake', 'color_hex' => '#E91E63'],
                ['name' => 'Hygiène & Beauté', 'icon_code' => 'spa', 'color_hex' => '#9C27B0'],
                ['name' => 'Entretien ménager', 'icon_code' => 'cleaning_services', 'color_hex' => '#2196F3'],
                ['name' => 'Bébé & Enfants', 'icon_code' => 'child_care', 'color_hex' => '#FF5722'],
                ['name' => 'Animaux', 'icon_code' => 'pets', 'color_hex' => '#795548'],
                ['name' => 'Santé & Pharmacie', 'icon_code' => 'medical_services', 'color_hex' => '#F44336'],
                ['name' => 'Autre', 'icon_code' => 'category', 'color_hex' => '#9E9E9E'],
            ];

            $categories = [];
            foreach ($defaultCategories as $index => $categoryData) {
                $category = Category::create([
                    'user_id' => $userId,
                    'name' => $categoryData['name'],
                    'icon_code' => $categoryData['icon_code'],
                    'color_hex' => $categoryData['color_hex'],
                    'order_index' => $index,
                ]);
                $categories[] = $category->toArray();
            }

            $response->getBody()->write(json_encode([
                'message' => 'Catégories par défaut initialisées avec succès',
                'categories' => $categories
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(201);
        } catch (\Exception $e) {
            error_log("=== EXCEPTION CAUGHT ===");
            error_log("Exception class: " . get_class($e));
            error_log("Exception message: " . $e->getMessage());
            error_log("Exception file: " . $e->getFile());
            error_log("Exception line: " . $e->getLine());
            error_log("Stack trace: " . $e->getTraceAsString());

            $response->getBody()->write(json_encode([
                'error' => 'Erreur lors de l\'initialisation des catégories',
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(500);
        }
    }
}
