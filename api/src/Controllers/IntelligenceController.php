<?php
// src/Controllers/IntelligenceController.php
//
// Endpoints de l'intelligence du foyer :
//  - GET  /predictions              suggestions « Il te manque probablement »
//  - POST /predictions/feedback     added | not_now | still_have | never
//  - GET  /inventory                inventaire maison (+ statuts estimés)
//  - POST /inventory/status         upsert d'un état (at_home/running_low/out)
//  - DELETE /inventory/{id}         retirer un produit de l'inventaire
//  - GET  /budgets/forecast         projection budgétaire du mois

namespace App\Controllers;

use App\Models\Budget;
use App\Models\HomeInventory;
use App\Models\PurchaseHistory;
use App\Services\PurchasePredictionService;
use Carbon\Carbon;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class IntelligenceController
{
    private PurchasePredictionService $predictions;

    public function __construct()
    {
        $this->predictions = new PurchasePredictionService();
    }

    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    // --- Prédictions --------------------------------------------------------

    /** GET /predictions?all=1&limit=20 */
    public function getPredictions(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $params = $request->getQueryParams();
        $all = filter_var($params['all'] ?? false, FILTER_VALIDATE_BOOLEAN);
        $limit = max(1, min(100, (int) ($params['limit'] ?? 20)));

        try {
            // §17/§34 : prédictions calculées DANS l'espace actif
            $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
            $items = $this->predictions->getPredictions($userId, $space, $all, $limit);
            return $this->json($response, [
                'success' => true,
                'data' => ['predictions' => $items, 'count' => count($items)],
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('getPredictions: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur prédictions'], 500);
        }
    }

    /** POST /predictions/feedback { product_name, action } */
    public function predictionFeedback(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $data = $request->getParsedBody() ?? [];
        $product = trim((string) ($data['product_name'] ?? ''));
        $action = (string) ($data['action'] ?? '');

        if ($product === '' || !in_array($action, ['added', 'not_now', 'still_have', 'never'], true)) {
            return $this->json($response, [
                'success' => false,
                'message' => 'product_name et action (added|not_now|still_have|never) requis',
            ], 422);
        }

        try {
            $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
            $this->predictions->recordFeedback($userId, $product, $action, $space);
            return $this->json($response, ['success' => true, 'message' => 'Feedback enregistré']);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('predictionFeedback: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur feedback'], 500);
        }
    }

    // --- Inventaire maison ---------------------------------------------------

    /**
     * GET /inventory — l'inventaire de l'utilisateur. Chaque produit peut
     * porter un statut estimé issu des prédictions (jamais prioritaire sur
     * un état manuel récent : la priorité est décidée par le service).
     */
    public function getInventory(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');

        try {
            $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
            $items = \App\Services\SpaceAccessService::scopeQuery(HomeInventory::query(), $space, $userId)
                ->orderBy('product_name')
                ->get();

            // Statuts estimés par l'historique (§11) — informatif seulement
            $estimates = [];
            foreach ($this->predictions->getPredictions($userId, $space, true, 200) as $p) {
                $estimates[$p['normalized_name']] = match ($p['status']) {
                    PurchasePredictionService::STATUS_OVERDUE => HomeInventory::STATUS_OUT,
                    PurchasePredictionService::STATUS_LIKELY,
                    PurchasePredictionService::STATUS_SOON => HomeInventory::STATUS_RUNNING_LOW,
                    default => HomeInventory::STATUS_AT_HOME,
                };
            }

            $payload = $items->map(fn($i) => [
                'id' => $i->id,
                'product_name' => $i->product_name,
                'normalized_name' => $i->normalized_name,
                'category_id' => $i->category_id,
                'status' => $i->status,
                'min_quantity' => $i->min_quantity !== null ? (float) $i->min_quantity : null,
                'reorder_quantity' => $i->reorder_quantity !== null ? (float) $i->reorder_quantity : null,
                'preferred_supplier_id' => $i->preferred_supplier_id,
                'below_min' => $i->min_quantity !== null && $i->quantity !== null
                    && (float) $i->quantity <= (float) $i->min_quantity,
                'quantity' => $i->quantity,
                'unit' => $i->unit,
                'source' => $i->source,
                'updated_at' => $i->updated_at?->toIso8601String(),
                'estimated_status' => $estimates[$i->normalized_name] ?? null,
            ])->values();

            return $this->json($response, [
                'success' => true,
                'data' => ['items' => $payload, 'count' => $payload->count()],
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('getInventory: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur inventaire'], 500);
        }
    }

    /**
     * POST /inventory/status { product_name, status, quantity?, unit? }
     * Upsert manuel : la source passe à « manual » (priorité maximale).
     */
    public function setInventoryStatus(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $data = $request->getParsedBody() ?? [];
        $product = trim((string) ($data['product_name'] ?? ''));
        $status = (string) ($data['status'] ?? '');

        if ($product === '' || !in_array($status, HomeInventory::STATUSES, true)) {
            return $this->json($response, [
                'success' => false,
                'message' => 'product_name et status (at_home|running_low|out) requis',
            ], 422);
        }

        try {
            $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
            \App\Services\SpaceAccessService::assertWrite($space, $userId, 'manage_inventory');
            // Les champs ABSENTS du payload ne sont pas touchés : un
            // simple changement de statut ne doit jamais effacer la
            // quantité ni les seuils (§21). Une clé envoyée à null ou
            // non numérique efface volontairement la valeur.
            $values = [
                'user_id' => $userId,
                'created_by_user_id' => $userId,
                'product_name' => $product,
                'status' => $status,
                'source' => 'manual',
            ];
            foreach (['quantity', 'min_quantity', 'reorder_quantity'] as $field) {
                if (array_key_exists($field, $data)) {
                    $values[$field] = is_numeric($data[$field]) ? (float) $data[$field] : null;
                }
            }
            if (array_key_exists('unit', $data)) {
                $unit = trim((string) $data['unit']);
                $values['unit'] = $unit !== '' ? substr($unit, 0, 10) : null;
            }
            if (array_key_exists('category_id', $data)) {
                $values['category_id'] = is_numeric($data['category_id']) ? (int) $data['category_id'] : null;
            }
            if (array_key_exists('preferred_supplier_id', $data)) {
                $values['preferred_supplier_id'] = is_numeric($data['preferred_supplier_id'])
                    ? (int) $data['preferred_supplier_id'] : null;
            }

            $item = HomeInventory::updateOrCreate(
                [
                    'space_id' => $space->id,
                    'normalized_name' => PurchaseHistory::normalizeProductName($product),
                ],
                $values
            );

            if ($status === HomeInventory::STATUS_OUT) {
                \App\Services\SpaceActivityService::log($space, $userId,
                    \App\Services\SpaceActivityService::INVENTORY_OUT,
                    ['product_name' => $product]);
            }

            return $this->json($response, [
                'success' => true,
                'data' => ['item' => $item->fresh()],
                'message' => 'Inventaire mis à jour',
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('setInventoryStatus: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur inventaire'], 500);
        }
    }

    /** DELETE /inventory/{id} */
    public function deleteInventoryItem(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
        \App\Services\SpaceAccessService::assertWrite($space, $userId, 'manage_inventory');
        $deleted = \App\Services\SpaceAccessService::scopeQuery(
                HomeInventory::where('id', (int) $args['id']), $space, $userId)
            ->delete();

        if (!$deleted) {
            return $this->json($response, ['success' => false, 'message' => 'Produit introuvable'], 404);
        }
        return $this->json($response, ['success' => true, 'message' => 'Produit retiré']);
    }

    // --- Projection budgétaire ------------------------------------------------

    /**
     * GET /budgets/forecast — indicateurs du mois courant (§20-24) :
     * dépensé, restant, jours restants, budget/jour disponible,
     * projection fin de mois (rythme robuste : médiane des moyennes
     * quotidiennes sur 7 j / 14 j / mois courant), recommandation semaine.
     */
    public function budgetForecast(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $now = Carbon::now();

        try {
            // Budget mensuel actif couvrant aujourd'hui (le plus récent)
            $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
            $budget = \App\Services\SpaceAccessService::scopeQuery(Budget::query(), $space, $userId)
                ->where('is_active', true)
                ->where('period_type', 'monthly')
                ->whereDate('start_date', '<=', $now)
                ->whereDate('end_date', '>=', $now)
                ->orderByDesc('start_date')
                ->first();

            if ($budget === null) {
                return $this->json($response, [
                    'success' => true,
                    'data' => ['has_budget' => false],
                ]);
            }

            $spent = $budget->getSpentAmount();
            $amount = (float) $budget->budget_amount;
            $remaining = $amount - $spent;

            $endDate = Carbon::parse($budget->end_date)->endOfDay();
            $startDate = Carbon::parse($budget->start_date)->startOfDay();
            $daysLeft = max(0, (int) ceil($now->diffInDays($endDate, false)));
            $daysElapsed = max(1, (int) floor($startDate->diffInDays($now)) + 1);

            // Rythme quotidien robuste : dépenses purchase_history DE L'ESPACE
            $dailyRate = $this->robustDailyRate($userId, $space, $startDate, $now, $spent, $daysElapsed);

            $projection = $spent + $dailyRate * $daysLeft;
            $perDayRemaining = $daysLeft > 0 ? $remaining / $daysLeft : 0;
            $weeksLeft = max(1, $daysLeft / 7);
            $weeklyRecommended = $daysLeft > 0 ? $remaining / $weeksLeft : 0;

            // Rythme relatif : dépensé vs prorata du budget
            $expectedByNow = $amount * ($daysElapsed / max(1, $daysElapsed + $daysLeft));
            $paceDeltaPct = $expectedByNow > 0
                ? round(($spent - $expectedByNow) / $expectedByNow * 100, 1)
                : null;

            return $this->json($response, [
                'success' => true,
                'data' => [
                    'has_budget' => true,
                    'budget_id' => $budget->id,
                    'budget_amount' => round($amount, 2),
                    'spent' => round($spent, 2),
                    'remaining' => round($remaining, 2),
                    'days_left' => $daysLeft,
                    'per_day_remaining' => round(max(0, $perDayRemaining), 2),
                    'daily_rate' => round($dailyRate, 2),
                    'projection' => round($projection, 2),
                    'projection_gap' => round($projection - $amount, 2),
                    'weekly_recommended' => round(max(0, $weeklyRecommended), 2),
                    'pace_delta_pct' => $paceDeltaPct,
                ],
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Throwable $e) {
            error_log('budgetForecast: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur projection'], 500);
        }
    }

    /**
     * Moyenne quotidienne robuste : médiane des moyennes sur 7 j, 14 j et
     * depuis le début du mois — une grosse course exceptionnelle ne domine
     * pas la projection (§21).
     */
    private function robustDailyRate(int $userId, \App\Models\Space $space, Carbon $monthStart, Carbon $now, float $spentMonth, int $daysElapsed): float
    {
        $sumSince = function (Carbon $since) use ($userId, $space, $now): float {
            return (float) \App\Services\SpaceAccessService::scopeQuery(PurchaseHistory::query(), $space, $userId)
                ->where('purchased_at', '>=', $since)
                ->where('purchased_at', '<=', $now)
                ->whereNotNull('price')
                ->sum('price');
        };

        $rates = [];
        foreach ([7, 14] as $window) {
            $since = $now->copy()->subDays($window);
            $start = $since->greaterThan($monthStart) ? $since : $monthStart;
            $days = max(1, (int) floor($start->diffInDays($now)) + 1);
            $rates[] = $sumSince($start) / $days;
        }
        $rates[] = $spentMonth / $daysElapsed;

        sort($rates);
        return $rates[1]; // médiane de 3 valeurs
    }
}
