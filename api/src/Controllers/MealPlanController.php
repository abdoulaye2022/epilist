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

    /**
     * GET /recipes — recettes de base (user_id NULL) + celles de
     * l'utilisateur.
     *
     * Trois filtres, parce que « chercher une recette » n'a de sens
     * qu'avec eux :
     *   q         : par NOM ou par INGREDIENT (« qu'est-ce que je fais
     *               avec du poulet ? ») ;
     *   max_time  : temps de preparation, en minutes ;
     *   favorites : les favorites seulement.
     */
    public function recipes(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $params = $request->getQueryParams();
        $q = trim((string) ($params['q'] ?? ''));
        $maxTime = isset($params['max_time']) && is_numeric($params['max_time'])
            ? (int) $params['max_time'] : null;
        $favorisSeuls = in_array($params['favorites'] ?? null, ['1', 'true', true], true);

        $requete = Recipe::with(['ingredients', 'favorites'])
            ->where('active', true)
            ->where(fn($q2) => $q2->whereNull('user_id')->orWhere(fn($qq) => \App\Services\SpaceAccessService::scopeQuery($qq, \App\Services\SpaceAccessService::resolveSpace($request, $userId), $userId)));

        if ($q !== '') {
            // Le nom OU un ingredient : « poulet » doit trouver le
            // poulet roti comme la recette qui en contient.
            $normalise = \App\Models\PurchaseHistory::normalizeProductName($q);
            $requete->where(function ($w) use ($q, $normalise) {
                $w->where('name', 'like', '%' . $q . '%')
                  ->orWhereIn('id', function ($sub) use ($normalise, $q) {
                      $sub->select('recipe_id')
                          ->from('recipe_ingredients')
                          ->where('normalized_name', 'like', '%' . $normalise . '%')
                          ->orWhere('ingredient_name', 'like', '%' . $q . '%');
                  });
            });
        }
        if ($maxTime !== null) {
            // Une recette sans temps renseigne n'est pas exclue : on ne
            // sait pas qu'elle est longue.
            $requete->where(function ($w) use ($maxTime) {
                $w->whereNull('preparation_time')->orWhere('preparation_time', '<=', $maxTime);
            });
        }

        $recipes = $requete->orderBy('name')
            ->get()
            ->filter(fn($r) => !$favorisSeuls || $r->isFavoriteFor($userId))
            // Les favorites d'abord : la planche en fait une grille a
            // part. Le tri se fait ici et non en SQL, parce que le
            // favori appartient au membre, pas a la recette.
            ->sortByDesc(fn($r) => $r->isFavoriteFor($userId) ? 1 : 0)
            ->map(fn($r) => [
                'id' => $r->id,
                'name' => $r->name,
                'description' => $r->description,
                'servings' => $r->servings,
                'preparation_time' => $r->preparation_time,
                'category' => $r->category,
                // La photo du plat existait en base depuis le debut
                // (recipes.image_url) : c'est cette reponse qui ne la
                // transmettait pas, et la planche la demande sur chaque
                // carte de jour.
                'image_url' => $r->image_url,
                'is_favorite' => $r->isFavoriteFor($userId),
                'is_mine' => $r->user_id !== null,
                'ingredients_count' => $r->ingredients->count(),
            ])->values();

        return $this->json($response, [
            'success' => true,
            'data' => ['recipes' => $recipes],
        ]);
    }

    /**
     * POST /recipes { name, servings?, preparation_time?, ingredients? }
     *
     * « Ecrire mon repas » : les cinq repas de la planche etaient fixes,
     * et aucun chemin ne menait a un sixieme. La recette appartient a
     * l'espace (user_id non nul) ; les recettes livrees avec
     * l'application gardent user_id NULL et restent partagees.
     *
     * Les ingredients sont FACULTATIFS, et c'est dit a l'ecran : sans
     * eux, le repas n'ajoutera rien aux courses.
     */
    public function storeRecipe(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $data = $request->getParsedBody() ?? [];
        $nom = trim(is_scalar($data['name'] ?? null) ? (string) $data['name'] : '');

        if ($nom === '' || mb_strlen($nom) > 150) {
            return $this->json($response, [
                'success' => false,
                'message' => 'name requis (150 caracteres au plus)',
            ], 422);
        }

        try {
            $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
            \App\Services\SpaceAccessService::assertWrite($space, $userId, 'add_items');

            $recette = null;
            DB::connection()->transaction(function () use ($data, $nom, $userId, $space, &$recette) {
                $recette = Recipe::create([
                    'space_id' => $space->id,
                    'created_by_user_id' => $userId,
                    'user_id' => $userId,
                    'name' => $nom,
                    'description' => isset($data['description']) && is_scalar($data['description'])
                        ? mb_substr(trim((string) $data['description']), 0, 500) : null,
                    'servings' => max(1, min(20, (int) ($data['servings'] ?? 4))),
                    'preparation_time' => isset($data['preparation_time']) && is_numeric($data['preparation_time'])
                        ? max(0, min(600, (int) $data['preparation_time'])) : null,
                    'category' => isset($data['category']) && is_scalar($data['category'])
                        ? mb_substr(trim((string) $data['category']), 0, 30) : null,
                    'active' => true,
                ]);

                foreach ((array) ($data['ingredients'] ?? []) as $ing) {
                    $nomIng = trim(
                        is_array($ing)
                            ? (string) ($ing['ingredient_name'] ?? $ing['product_name'] ?? '')
                            : (string) $ing
                    );
                    if ($nomIng === '') {
                        continue;
                    }
                    \App\Models\RecipeIngredient::create([
                        'recipe_id' => $recette->id,
                        'ingredient_name' => mb_substr($nomIng, 0, 150),
                        'normalized_name' => \App\Models\PurchaseHistory::normalizeProductName($nomIng),
                        'quantity' => is_array($ing) && is_numeric($ing['quantity'] ?? null)
                            ? max(0.001, (float) $ing['quantity']) : 1,
                        'unit' => is_array($ing) && isset($ing['unit']) && trim((string) $ing['unit']) !== ''
                            ? mb_substr(trim((string) $ing['unit']), 0, 10) : null,
                        'optional' => is_array($ing) && !empty($ing['optional']) ? 1 : 0,
                    ]);
                }
            });

            $recette->load('ingredients');

            return $this->json($response, [
                'success' => true,
                'data' => [
                    'recipe' => [
                        'id' => $recette->id,
                        'name' => $recette->name,
                        'description' => $recette->description,
                        'servings' => $recette->servings,
                        'preparation_time' => $recette->preparation_time,
                        'category' => $recette->category,
                        'image_url' => $recette->image_url,
                        'is_favorite' => false,
                        'is_mine' => true,
                        'ingredients_count' => $recette->ingredients->count(),
                    ],
                ],
                'message' => 'Recette enregistree',
            ], 201);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('storeRecipe: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur enregistrement'], 500);
        }
    }

    /**
     * PUT /recipes/{id}/favorite — met cette recette en favori.
     *
     * Idempotent, comme l'etoile des magasins.
     */
    public function setRecipeFavorite(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $recette = Recipe::find((int) $args['id']);
        if (!$recette || !$recette->active) {
            return $this->json($response, ['success' => false, 'message' => 'Recette introuvable'], 404);
        }

        \App\Models\RecipeFavorite::firstOrCreate([
            'recipe_id' => $recette->id,
            'user_id' => $userId,
        ]);

        return $this->json($response, [
            'success' => true,
            'data' => ['id' => $recette->id, 'is_favorite' => true],
        ]);
    }

    /** DELETE /recipes/{id}/favorite — retire cette recette des favoris. */
    public function unsetRecipeFavorite(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $recette = Recipe::find((int) $args['id']);
        if (!$recette) {
            return $this->json($response, ['success' => false, 'message' => 'Recette introuvable'], 404);
        }

        \App\Models\RecipeFavorite::where('recipe_id', $recette->id)
            ->where('user_id', $userId)
            ->delete();

        return $this->json($response, [
            'success' => true,
            'data' => ['id' => $recette->id, 'is_favorite' => false],
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
        // « Lundi vert, Mardi jaune, Mercredi bleu ». Facultatif : un
        // plan sans jours reste un plan, et c'est ce que l'application
        // envoyait jusqu'ici.
        //   assignments: [{recipe_id: 3, weekday: 1, meal_slot: 'dinner'}]
        //
        // Une LISTE, et non une table indexee par recette : le meme
        // plat peut revenir deux fois dans la semaine, et deux repas
        // peuvent tomber le meme jour (midi et soir). Indexer par
        // recipe_id n'en gardait qu'un.
        $jours = [];
        foreach ((array) ($data['assignments'] ?? []) as $a) {
            $rid = (int) ($a['recipe_id'] ?? 0);
            $jour = $a['weekday'] ?? null;
            $moment = $a['meal_slot'] ?? null;
            if ($rid <= 0) {
                continue;
            }
            if ($jour !== null && (!is_numeric($jour) || (int) $jour < 1 || (int) $jour > 7)) {
                return $this->json($response, [
                    'success' => false,
                    'message' => 'weekday doit valoir de 1 (lundi) a 7 (dimanche)',
                ], 422);
            }
            if ($moment !== null && !in_array($moment, ['lunch', 'dinner'], true)) {
                return $this->json($response, [
                    'success' => false,
                    'message' => "meal_slot doit valoir 'lunch' ou 'dinner'",
                ], 422);
            }
            $jours[] = [
                'recipe_id' => $rid,
                'weekday' => $jour === null ? null : (int) $jour,
                'meal_slot' => $moment,
            ];
        }
        $people = max(1, min(20, (int) ($data['people'] ?? 4)));
        $budgetMax = isset($data['budget_max']) && is_numeric($data['budget_max'])
            ? (float) $data['budget_max'] : null;

        if ($recipeIds === []) {
            return $this->json($response, ['success' => false, 'message' => 'recipe_ids requis'], 422);
        }

        try {
            $recipes = Recipe::with(['ingredients', 'favorites'])
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
        // « Lundi vert, Mardi jaune, Mercredi bleu ». Facultatif : un
        // plan sans jours reste un plan, et c'est ce que l'application
        // envoyait jusqu'ici.
        //   assignments: [{recipe_id: 3, weekday: 1, meal_slot: 'dinner'}]
        //
        // Une LISTE, et non une table indexee par recette : le meme
        // plat peut revenir deux fois dans la semaine, et deux repas
        // peuvent tomber le meme jour (midi et soir). Indexer par
        // recipe_id n'en gardait qu'un.
        $jours = [];
        foreach ((array) ($data['assignments'] ?? []) as $a) {
            $rid = (int) ($a['recipe_id'] ?? 0);
            $jour = $a['weekday'] ?? null;
            $moment = $a['meal_slot'] ?? null;
            if ($rid <= 0) {
                continue;
            }
            if ($jour !== null && (!is_numeric($jour) || (int) $jour < 1 || (int) $jour > 7)) {
                return $this->json($response, [
                    'success' => false,
                    'message' => 'weekday doit valoir de 1 (lundi) a 7 (dimanche)',
                ], 422);
            }
            if ($moment !== null && !in_array($moment, ['lunch', 'dinner'], true)) {
                return $this->json($response, [
                    'success' => false,
                    'message' => "meal_slot doit valoir 'lunch' ou 'dinner'",
                ], 422);
            }
            $jours[] = [
                'recipe_id' => $rid,
                'weekday' => $jour === null ? null : (int) $jour,
                'meal_slot' => $moment,
            ];
        }
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
            DB::connection()->transaction(function () use ($userId, $space, $data, $recipeIds, $jours, $items, $people, &$planId, &$shoppingList) {
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

                // Les assignations font loi quand elles sont la : une
                // ligne par repas place, meme plat deux fois comprise.
                // Sans elles, les recettes choisies, sans jour.
                $lignes = $jours !== []
                    ? $jours
                    : array_map(fn($rid) => ['recipe_id' => $rid, 'weekday' => null, 'meal_slot' => null], $recipeIds);
                foreach ($lignes as $ligne) {
                    MealPlanRecipe::create([
                        'meal_plan_id' => $plan->id,
                        'recipe_id' => $ligne['recipe_id'],
                        'servings' => $people,
                        'weekday' => $ligne['weekday'],
                        'meal_slot' => $ligne['meal_slot'],
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
