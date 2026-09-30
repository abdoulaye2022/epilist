<?php
// src/Controllers/RecurringListController.php
//
// Listes récurrentes intelligentes :
//  - CRUD des modèles (nom, récurrence, articles par défaut) ;
//  - GET /recurring-lists/{id}/preview : proposition pré-cochée selon
//    prédictions + inventaire + achats récents (§33) ;
//  - POST /recurring-lists/{id}/generate : crée la vraie liste de
//    courses à partir des articles validés par l'utilisateur.

namespace App\Controllers;

use App\Models\HomeInventory;
use App\Models\PurchaseHistory;
use App\Models\RecurringList;
use App\Models\RecurringListItem;
use App\Models\ShoppingList;
use App\Models\ListItem;
use App\Services\PurchasePredictionService;
use Carbon\Carbon;
use Illuminate\Database\Capsule\Manager as DB;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class RecurringListController
{
    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    private function findOwned(\Psr\Http\Message\ServerRequestInterface $request, int $userId, int $id): ?RecurringList
    {
        $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
        return \App\Services\SpaceAccessService::scopeQuery(
            RecurringList::where('id', $id), $space, $userId)->first();
    }

    private function format(RecurringList $list): array
    {
        return [
            'id' => $list->id,
            'name' => $list->name,
            'recurrence_type' => $list->recurrence_type,
            'weekday' => $list->weekday,
            'next_run_at' => $list->next_run_at?->toIso8601String(),
            'store_id' => $list->store_id,
            'enabled' => (bool) $list->enabled,
            'auto_generate' => (bool) $list->auto_generate,
            'last_generated_at' => $list->last_generated_at?->toIso8601String(),
            'items' => $list->items->map(fn($i) => [
                'id' => $i->id,
                'product_name' => $i->product_name,
                'default_quantity' => $i->default_quantity,
                'unit' => $i->unit,
                'optional' => (bool) $i->optional,
            ])->values(),
        ];
    }

    /** GET /recurring-lists */
    public function index(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
        $lists = \App\Services\SpaceAccessService::scopeQuery(RecurringList::with('items'), $space, $userId)
            ->orderBy('name')
            ->get();

        return $this->json($response, [
            'success' => true,
            'data' => ['recurring_lists' => $lists->map(fn($l) => $this->format($l))->values()],
        ]);
    }

    /** POST /recurring-lists { name, recurrence_type, weekday?, store_id?, auto_generate?, items: [{product_name, quantity?, unit?, optional?}] } */
    public function store(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $data = $request->getParsedBody() ?? [];
        $name = trim((string) ($data['name'] ?? ''));
        $type = (string) ($data['recurrence_type'] ?? 'weekly');
        $items = $data['items'] ?? [];

        if ($name === '' || !in_array($type, ['weekly', 'biweekly', 'monthly'], true) || !is_array($items)) {
            return $this->json($response, [
                'success' => false,
                'message' => 'name, recurrence_type (weekly|biweekly|monthly) et items requis',
            ], 422);
        }

        try {
            $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
            \App\Services\SpaceAccessService::assertWrite($space, $userId, 'manage_lists');
            $list = null;
            DB::connection()->transaction(function () use ($userId, $space, $name, $type, $data, $items, &$list) {
                $list = new RecurringList([
                    'user_id' => $userId,
                    'space_id' => $space->id,
                    'created_by_user_id' => $userId,
                    'name' => $name,
                    'recurrence_type' => $type,
                    'weekday' => isset($data['weekday']) ? max(1, min(7, (int) $data['weekday'])) : null,
                    'store_id' => isset($data['store_id']) ? (int) $data['store_id'] : null,
                    'enabled' => true,
                    'auto_generate' => !empty($data['auto_generate']),
                    'next_run_at' => Carbon::now(), // recalculé ci-dessous
                ]);
                $list->next_run_at = $list->computeNextRun();
                $list->save();

                $this->replaceItems($list, $items);
            });

            return $this->json($response, [
                'success' => true,
                'data' => ['recurring_list' => $this->format($list->load('items'))],
                'message' => 'Liste récurrente créée',
            ], 201);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('recurring store: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur création'], 500);
        }
    }

    /** PUT /recurring-lists/{id} — mêmes champs que store, tous optionnels */
    public function update(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $list = $this->findOwned($request, $userId, (int) $args['id']);
        if ($list === null) {
            return $this->json($response, ['success' => false, 'message' => 'Liste introuvable'], 404);
        }
        $data = $request->getParsedBody() ?? [];

        try {
            DB::connection()->transaction(function () use ($list, $data) {
                if (isset($data['name']) && trim($data['name']) !== '') {
                    $list->name = trim($data['name']);
                }
                if (isset($data['recurrence_type']) &&
                    in_array($data['recurrence_type'], ['weekly', 'biweekly', 'monthly'], true)) {
                    $list->recurrence_type = $data['recurrence_type'];
                }
                if (array_key_exists('weekday', $data)) {
                    $list->weekday = $data['weekday'] === null ? null : max(1, min(7, (int) $data['weekday']));
                }
                if (array_key_exists('store_id', $data)) {
                    $list->store_id = $data['store_id'] === null ? null : (int) $data['store_id'];
                }
                if (isset($data['enabled'])) {
                    $list->enabled = (bool) $data['enabled'];
                }
                if (isset($data['auto_generate'])) {
                    $list->auto_generate = (bool) $data['auto_generate'];
                }
                $list->next_run_at = $list->computeNextRun();
                $list->save();

                if (isset($data['items']) && is_array($data['items'])) {
                    $this->replaceItems($list, $data['items']);
                }
            });

            return $this->json($response, [
                'success' => true,
                'data' => ['recurring_list' => $this->format($list->fresh('items'))],
                'message' => 'Liste récurrente mise à jour',
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('recurring update: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur mise à jour'], 500);
        }
    }

    /** DELETE /recurring-lists/{id} */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $list = $this->findOwned($request, $userId, (int) $args['id']);
        if ($list === null) {
            return $this->json($response, ['success' => false, 'message' => 'Liste introuvable'], 404);
        }
        $list->delete();
        return $this->json($response, ['success' => true, 'message' => 'Liste récurrente supprimée']);
    }

    private function replaceItems(RecurringList $list, array $items): void
    {
        RecurringListItem::where('recurring_list_id', $list->id)->delete();
        foreach ($items as $item) {
            $name = trim((string) (is_array($item) ? ($item['product_name'] ?? '') : $item));
            if ($name === '') {
                continue;
            }
            RecurringListItem::create([
                'recurring_list_id' => $list->id,
                'product_name' => $name,
                'normalized_name' => PurchaseHistory::normalizeProductName($name),
                'default_quantity' => is_array($item) ? max(1, (int) ($item['quantity'] ?? 1)) : 1,
                'unit' => is_array($item) && isset($item['unit'])
                    ? substr(trim((string) $item['unit']), 0, 10) : null,
                'optional' => is_array($item) && !empty($item['optional']),
            ]);
        }
    }

    // -------------------------------------------------------------------
    // Génération intelligente
    // -------------------------------------------------------------------

    /**
     * GET /recurring-lists/{id}/preview
     * Chaque article du modèle revient avec suggested (pré-coché ou non)
     * et une raison lisible : inventaire, achat récent, prédiction (§33).
     */
    public function preview(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $list = $this->findOwned($request, $userId, (int) $args['id']);
        if ($list === null) {
            return $this->json($response, ['success' => false, 'message' => 'Liste introuvable'], 404);
        }

        try {
            $items = $this->buildPreview($userId, $list);
            return $this->json($response, [
                'success' => true,
                'data' => ['name' => $list->name, 'items' => $items],
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('recurring preview: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur aperçu'], 500);
        }
    }

    /**
     * Raisons possibles : inventory_out, inventory_at_home, bought_recently,
     * prediction_due, normal_cycle.
     */
    public function buildPreview(int $userId, RecurringList $list): array
    {
        // L'aperçu raisonne dans l'espace DE LA LISTE récurrente (§17) :
        // une liste du foyer s'appuie sur l'inventaire et les achats du foyer.
        $space = $list->space_id !== null ? \App\Models\Space::find($list->space_id) : null;
        if ($space === null || $space->deleted_at !== null) {
            $space = \App\Models\Space::personalFor($userId);
        }

        $service = new PurchasePredictionService();
        $predictions = [];
        foreach ($service->getPredictions($userId, $space, true, 300) as $p) {
            $predictions[$p['normalized_name']] = $p;
        }
        $inventory = \App\Services\SpaceAccessService::scopeQuery(HomeInventory::query(), $space, $userId)
            ->get()->keyBy('normalized_name');

        // Achats des 3 derniers jours = « acheté hier » (§33)
        $recent = \App\Services\SpaceAccessService::scopeQuery(PurchaseHistory::query(), $space, $userId)
            ->where('purchased_at', '>=', Carbon::now()->subDays(3))
            ->pluck('normalized_name')
            ->flip();

        $out = [];
        foreach ($list->items as $item) {
            $norm = $item->normalized_name;
            $inv = $inventory->get($norm);
            $pred = $predictions[$norm] ?? null;

            // Priorité : inventaire manuel > achat récent > prédiction > défaut
            if ($inv !== null && $inv->source === 'manual' && $inv->status === HomeInventory::STATUS_OUT) {
                $suggested = true;
                $reason = 'inventory_out';
            } elseif ($inv !== null && $inv->source === 'manual' && $inv->status === HomeInventory::STATUS_AT_HOME
                && $inv->updated_at !== null && $inv->updated_at->diffInDays(Carbon::now()) < 7) {
                $suggested = false;
                $reason = 'inventory_at_home';
            } elseif (isset($recent[$norm])) {
                $suggested = false;
                $reason = 'bought_recently';
            } elseif ($pred !== null && in_array($pred['status'], [
                PurchasePredictionService::STATUS_SOON,
                PurchasePredictionService::STATUS_LIKELY,
                PurchasePredictionService::STATUS_OVERDUE,
            ], true)) {
                $suggested = true;
                $reason = 'prediction_due';
            } elseif ($pred !== null && $pred['status'] === PurchasePredictionService::STATUS_NOT_NEEDED) {
                $suggested = false;
                $reason = 'normal_cycle';
            } else {
                // Aucune donnée : on garde l'article (comportement neutre)
                $suggested = !$item->optional;
                $reason = 'normal_cycle';
            }

            $out[] = [
                'product_name' => $item->product_name,
                'quantity' => $item->default_quantity,
                'unit' => $item->unit,
                'suggested' => $suggested,
                'reason' => $reason,
            ];
        }
        return $out;
    }

    /**
     * POST /recurring-lists/{id}/generate { items: [{product_name, quantity?}] }
     * Crée la liste de courses avec les articles validés. Sans body,
     * utilise les articles pré-cochés de l'aperçu (mode automatique/cron).
     */
    public function generate(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $list = $this->findOwned($request, $userId, (int) $args['id']);
        if ($list === null) {
            return $this->json($response, ['success' => false, 'message' => 'Liste introuvable'], 404);
        }

        $data = $request->getParsedBody() ?? [];
        $chosen = $data['items'] ?? null;

        try {
            $shoppingList = $this->generateFor($userId, $list, is_array($chosen) ? $chosen : null);
            if ($shoppingList === null) {
                return $this->json($response, [
                    'success' => false,
                    'message' => 'Aucun article à ajouter',
                ], 422);
            }
            return $this->json($response, [
                'success' => true,
                'data' => ['shopping_list_id' => $shoppingList->id, 'name' => $shoppingList->name],
                'message' => 'Liste créée',
            ], 201);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('recurring generate: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur génération'], 500);
        }
    }

    /**
     * Génère la liste réelle. $chosen = articles validés par l'utilisateur
     * (null = pré-cochés de l'aperçu, utilisé par le cron auto_generate).
     * Partagé avec public/cron.php.
     */
    public function generateFor(int $userId, RecurringList $list, ?array $chosen = null): ?ShoppingList
    {
        if ($chosen === null) {
            $chosen = array_values(array_filter(
                $this->buildPreview($userId, $list),
                fn($i) => $i['suggested']
            ));
        }
        $chosen = array_values(array_filter(
            $chosen,
            fn($i) => trim((string) ($i['product_name'] ?? '')) !== ''
        ));
        if ($chosen === []) {
            return null;
        }

        $shoppingList = null;
        DB::connection()->transaction(function () use ($userId, $list, $chosen, &$shoppingList) {
            $shoppingList = ShoppingList::create([
                'user_id' => $userId,
                'space_id' => $list->space_id,
                'created_by_user_id' => $userId,
                'name' => $list->name . ' — ' . Carbon::now()->format('d/m'),
            ]);
            foreach ($chosen as $item) {
                ListItem::create([
                    'list_id' => $shoppingList->id,
                    'product_name' => trim($item['product_name']),
                    'quantity' => max(1, (int) ($item['quantity'] ?? 1)),
                    'is_purchased' => false,
                ]);
            }
            $list->last_generated_at = Carbon::now();
            $list->next_run_at = $list->computeNextRun();
            $list->save();
        });

        return $shoppingList;
    }
}
