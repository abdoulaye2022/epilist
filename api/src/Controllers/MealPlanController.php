<?php
// src/Controllers/MealPlanController.php
//
// Planificateur de repas V1 (§14-19) — sans IA obligatoire :
//  - GET  /recipes : recettes de base + recettes de l'utilisateur ;
//  - POST /meal-plans/preview : ingrédients consolidés des recettes
//    choisies, mis à l'échelle des personnes, avec statut inventaire
//    et coût estimé depuis l'historique de prix (couverture affichée,
//    jamais d'économies inventées) ;
//  - POST /meal-plans : enregistre le plan et crée la liste de courses
//    avec les articles retenus par l'utilisateur.

namespace App\Controllers;

use App\Models\HomeInventory;
use App\Models\ListItem;
use App\Models\MealPlan;
use App\Models\MealPlanRecipe;
use App\Models\PurchaseHistory;
use App\Models\Recipe;
use App\Models\ShoppingList;
use Carbon\Carbon;
use Illuminate\Database\Capsule\Manager as DB;
use App\Services\IngredientConsolidationService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class MealPlanController
{
    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    /** GET /recipes — recettes de base (user_id NULL) + celles de l'utilisateur */
    public function recipes(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');

        $recipes = Recipe::with('ingredients')
            ->where('active', true)
            ->where(fn($q) => $q->whereNull('user_id')->orWhere(fn($qq) => \App\Services\SpaceAccessService::scopeQuery($qq, \App\Services\SpaceAccessService::resolveSpace($request, $userId), $userId)))
            ->orderBy('name')
            ->get()
            ->map(fn($r) => [
                'id' => $r->id,
                'name' => $r->name,
                'description' => $r->description,
                'servings' => $r->servings,
                'preparation_time' => $r->preparation_time,
                'category' => $r->category,
                'is_mine' => $r->user_id !== null,
                'ingredients_count' => $r->ingredients->count(),
            ])->values();

        return $this->json($response, [
            'success' => true,
            'data' => ['recipes' => $recipes],
        ]);
    }

    /**
     * POST /meal-plans/preview { recipe_ids: [..], people: 4, budget_max?: 120 }
     * Retourne les ingrédients consolidés avec, pour chacun :
     * inventaire (at_home -> non coché « Déjà à la maison »), prix estimé
     * (dernier prix connu), et le résumé budget avec couverture.
     */
    public function preview(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $data = $request->getParsedBody() ?? [];
        $recipeIds = array_filter(array_map('intval', (array) ($data['recipe_ids'] ?? [])));
        $people = max(1, min(20, (int) ($data['people'] ?? 4)));
        $budgetMax = isset($data['budget_max']) && is_numeric($data['budget_max'])
            ? (float) $data['budget_max'] : null;

        if ($recipeIds === []) {
            return $this->json($response, ['success' => false, 'message' => 'recipe_ids requis'], 422);
        }

        try {
            $recipes = Recipe::with('ingredients')
                ->whereIn('id', $recipeIds)
                ->where('active', true)
                ->where(fn($q) => $q->whereNull('user_id')->orWhere(fn($qq) => \App\Services\SpaceAccessService::scopeQuery($qq, \App\Services\SpaceAccessService::resolveSpace($request, $userId), $userId)))
                ->get();
            if ($recipes->isEmpty()) {
                return $this->json($response, ['success' => false, 'message' => 'Recettes introuvables'], 404);
            }

            // Mise à l'échelle des portions puis consolidation (§18)
            $raw = [];
            foreach ($recipes as $recipe) {
                $scale = $people / max(1, $recipe->servings);
                foreach ($recipe->ingredients as $ing) {
                    $raw[] = [
                        'name' => $ing->ingredient_name,
                        'normalized_name' => $ing->normalized_name,
                        'quantity' => (float) $ing->quantity * $scale,
                        'unit' => $ing->unit,
                        'optional' => (bool) $ing->optional,
                    ];
                }
            }
            $merged = (new IngredientConsolidationService())->consolidate($raw);

            // Inventaire : « Déjà à la maison » (§17)
            $mpSpace = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
            $inventory = \App\Services\SpaceAccessService::scopeQuery(HomeInventory::query(), $mpSpace, $userId)->get()->keyBy('normalized_name');

            // Prix estimés : dernier prix connu par produit (12 mois),
            // dans le MÊME espace que l'inventaire (audit C3)
            $norms = array_column($merged, 'normalized_name');
            $prices = [];
            if ($norms !== []) {
                $rows = \App\Services\SpaceAccessService::scopeQuery(PurchaseHistory::query(), $mpSpace, $userId)
                    ->whereIn('normalized_name', $norms)
                    ->where('purchased_at', '>=', Carbon::now()->subMonths(12))
                    ->whereNotNull('price')
                    ->orderByDesc('purchased_at')
                    ->get(['normalized_name', 'price', 'quantity', 'unit', 'unit_price']);
                foreach ($rows as $r) {
                    if (isset($prices[$r->normalized_name])) {
                        continue;
                    }
                    $prices[$r->normalized_name] = $r->unit_price !== null
                        ? (float) $r->unit_price
                        : (float) $r->price / max(1, (int) $r->quantity);
                }
            }

            $estimatedTotal = 0.0;
            $pricedCount = 0;
            $items = [];
            foreach ($merged as $m) {
                $inv = $inventory->get($m['normalized_name']);
                $atHome = $inv !== null && $inv->status === HomeInventory::STATUS_AT_HOME;
                $unitPrice = $prices[$m['normalized_name']] ?? null;

                // Estimation : prix unitaire x quantité pour les pièces,
                // prix/kg ou /L x quantité pour le vrac
                $estimated = null;
                if ($unitPrice !== null) {
                    $estimated = round($unitPrice * max(0.1, $m['quantity']), 2);
                    $pricedCount++;
                    if (!$atHome) {
                        $estimatedTotal += $estimated;
                    }
                }

                $items[] = [
                    'product_name' => $m['name'],
                    'quantity' => $m['quantity'],
                    'unit' => $m['unit'],
                    'optional' => $m['optional'],
                    'at_home' => $atHome,
                    'inventory_status' => $inv?->status,
                    'estimated_price' => $estimated,
                    'suggested' => !$atHome && !$m['optional'],
                ];
            }

            $coverage = count($merged) > 0
                ? (int) round($pricedCount / count($merged) * 100) : 0;

            return $this->json($response, [
                'success' => true,
                'data' => [
                    'people' => $people,
                    'recipes' => $recipes->map(fn($r) => ['id' => $r->id, 'name' => $r->name])->values(),
                    'items' => $items,
                    'budget' => [
                        'estimated_total' => round($estimatedTotal, 2),
                        'budget_max' => $budgetMax,
                        'remaining' => $budgetMax !== null ? round($budgetMax - $estimatedTotal, 2) : null,
                        'over_budget' => $budgetMax !== null && $estimatedTotal > $budgetMax,
                        'price_coverage_pct' => $coverage,
                    ],
                ],
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('mealplan preview: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur aperçu'], 500);
        }
    }

    /**
     * POST /meal-plans { name?, recipe_ids, people, budget_max?,
     *   items: [{product_name, quantity?, unit?}] }
     * Enregistre le plan et crée la liste de courses avec les articles
     * validés par l'utilisateur (jamais automatique).
     */
    public function store(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $data = $request->getParsedBody() ?? [];
        $recipeIds = array_filter(array_map('intval', (array) ($data['recipe_ids'] ?? [])));
        $items = $data['items'] ?? [];
        $people = max(1, min(20, (int) ($data['people'] ?? 4)));

        if ($recipeIds === [] || !is_array($items) || $items === []) {
            return $this->json($response, ['success' => false, 'message' => 'recipe_ids et items requis'], 422);
        }

        try {
            $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
            \App\Services\SpaceAccessService::assertWrite($space, $userId, 'add_items');
            $planId = null;
            $shoppingList = null;
            DB::connection()->transaction(function () use ($userId, $space, $data, $recipeIds, $items, $people, &$planId, &$shoppingList) {
                $plan = MealPlan::create([
                    'user_id' => $userId,
                    'space_id' => $space->id,
                    'created_by_user_id' => $userId,
                    'name' => trim((string) ($data['name'] ?? '')) ?: 'Plan de repas ' . Carbon::now()->format('d/m'),
                    'people' => $people,
                    'budget_max' => isset($data['budget_max']) && is_numeric($data['budget_max'])
                        ? (float) $data['budget_max'] : null,
                ]);
                $planId = $plan->id;

                foreach ($recipeIds as $rid) {
                    MealPlanRecipe::create([
                        'meal_plan_id' => $plan->id,
                        'recipe_id' => $rid,
                        'servings' => $people,
                    ]);
                }

                $shoppingList = ShoppingList::create([
                    'user_id' => $userId,
                    'space_id' => $space->id,
                    'created_by_user_id' => $userId,
                    'name' => $plan->name,
                ]);
                foreach ($items as $item) {
                    $name = trim((string) ($item['product_name'] ?? ''));
                    if ($name === '') {
                        continue;
                    }
                    ListItem::create([
                        'list_id' => $shoppingList->id,
                        'product_name' => $name,
                        'quantity' => max(1, (int) ceil((float) ($item['quantity'] ?? 1))),
                        'is_purchased' => false,
                    ]);
                }
            });

            return $this->json($response, [
                'success' => true,
                'data' => ['meal_plan_id' => $planId, 'shopping_list_id' => $shoppingList->id],
                'message' => 'Plan créé et liste générée',
            ], 201);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('mealplan store: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur création du plan'], 500);
        }
    }
}
