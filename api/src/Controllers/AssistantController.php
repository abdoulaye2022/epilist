<?php
// src/Controllers/AssistantController.php — assistant intelligent
// (Phase 5, §28-§30).
//
// « Avant les courses » (§28) : UN appel qui compose, pour l'espace
// actif, ce qu'il faut savoir avant de partir — à racheter
// (prédictions), inventaire en rupture/sous seuil, où en est le budget,
// alertes de prix récentes, et (espaces pro) demandes d'achat en
// attente = « prochaine commande ».
//
// « Économies estimées » (§30) : chaque économie est DOCUMENTÉE —
// produit, prix payé, prix habituel D'AVANT l'achat (médiane des
// observations antérieures), date, magasin. Jamais un chiffre sorti
// du chapeau : l'app peut afficher le détail ligne par ligne.
//
// Les SpaceAccessException remontent au middleware d'erreurs.

namespace App\Controllers;

use App\Models\Budget;
use App\Models\HomeInventory;
use App\Models\PriceAlert;
use App\Models\PurchaseHistory;
use App\Models\PurchaseRequest;
use App\Models\Space;
use App\Services\PurchasePredictionService;
use App\Services\SpaceAccessService;
use Carbon\Carbon;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class AssistantController
{
    /** Fenêtre des économies estimées et des prix « habituels ». */
    private const SAVINGS_DEFAULT_DAYS = 30;
    private const USUAL_PRICE_WINDOW_DAYS = 90;
    private const USUAL_PRICE_MIN_PRIORS = 2;

    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    /** GET /assistant/pre-shopping — le brief avant les courses (§28). */
    public function preShopping(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = SpaceAccessService::resolveSpace($request, $userId);
        $isPro = in_array($space->type, [Space::TYPE_RESTAURANT, Space::TYPE_ORGANIZATION], true);

        // 1. À racheter : prédictions de l'espace, urgentes d'abord
        $restock = array_map(fn($p) => [
            'product_name' => $p['product_name'],
            'status' => $p['status'],
            'confidence' => $p['confidence'],
            'days_since_last' => $p['days_since_last'],
            'frequency_days' => $p['frequency_days'],
            'usual_store' => $p['usual_store'],
            'below_min' => $p['below_min'] ?? false,
        ], (new PurchasePredictionService())->getPredictions($userId, $space, false, 8));

        // 2. Inventaire : ruptures déclarées + produits sous le seuil
        $inventoryAlerts = SpaceAccessService::scopeQuery(HomeInventory::query(), $space, $userId)
            ->where(function ($q) {
                $q->where('status', HomeInventory::STATUS_OUT)
                  ->orWhere(function ($q2) {
                      $q2->whereNotNull('min_quantity')
                         ->whereNotNull('quantity')
                         ->whereColumn('quantity', '<=', 'min_quantity');
                  });
            })
            ->orderBy('product_name')
            ->limit(10)
            ->get()
            ->map(fn($i) => [
                'product_name' => $i->product_name,
                'status' => $i->status,
                'quantity' => $i->quantity !== null ? (float) $i->quantity : null,
                'min_quantity' => $i->min_quantity !== null ? (float) $i->min_quantity : null,
                'unit' => $i->unit,
            ])->values();

        // 3. Budget : où on en est ce mois-ci (léger — le détail est
        //    dans /budgets/forecast)
        $now = Carbon::now();
        $budget = SpaceAccessService::scopeQuery(Budget::query(), $space, $userId)
            ->where('is_active', true)
            ->where('period_type', 'monthly')
            ->whereDate('start_date', '<=', $now)
            ->whereDate('end_date', '>=', $now)
            ->orderByDesc('start_date')
            ->first();
        $budgetBrief = null;
        if ($budget !== null) {
            $spent = $budget->getSpentAmount();
            $remaining = (float) $budget->budget_amount - $spent;
            $daysLeft = max(0, (int) ceil($now->diffInDays(Carbon::parse($budget->end_date)->endOfDay(), false)));
            $budgetBrief = [
                'name' => $budget->name,
                'remaining' => round($remaining, 2),
                'budget_amount' => round((float) $budget->budget_amount, 2),
                'days_left' => $daysLeft,
                'per_day_remaining' => $daysLeft > 0 ? round(max(0, $remaining / $daysLeft), 2) : null,
            ];
        }

        // 4. Alertes de prix déclenchées ces 7 derniers jours
        $priceWatch = PriceAlert::where('space_id', $space->id)
            ->where('is_active', true)
            ->whereNotNull('last_triggered_at')
            ->where('last_triggered_at', '>=', $now->copy()->subDays(7))
            ->orderByDesc('last_triggered_at')
            ->limit(5)
            ->get()
            ->map(fn($a) => [
                'product_name' => $a->product_name,
                'target_price' => (float) $a->target_price,
                'last_notified_price' => $a->last_notified_price !== null ? (float) $a->last_notified_price : null,
                'last_triggered_at' => $a->last_triggered_at?->toIso8601String(),
            ])->values();

        // 5. Espaces pro : « prochaine commande » = demandes en attente
        $pendingRequests = $isPro
            ? PurchaseRequest::where('space_id', $space->id)
                ->where('status', PurchaseRequest::STATUS_PENDING)
                ->count()
            : null;

        return $this->json($response, [
            'success' => true,
            'data' => [
                'space_type' => $space->type,
                'restock' => $restock,
                'inventory_alerts' => $inventoryAlerts,
                'budget' => $budgetBrief,
                'price_watch' => $priceWatch,
                'pending_requests' => $pendingRequests,
            ],
        ]);
    }

    /**
     * GET /assistant/savings?days=30 — économies estimées DOCUMENTÉES
     * (§30). Pour chaque achat de la fenêtre : prix habituel = médiane
     * des observations ANTÉRIEURES à l'achat (90 j, minimum 2) ; une
     * économie n'est comptée que si payé < habituel. Le détail complet
     * accompagne toujours le total.
     */
    public function savings(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = SpaceAccessService::resolveSpace($request, $userId);
        $days = max(7, min(90, (int) (($request->getQueryParams()['days'] ?? null) ?: self::SAVINGS_DEFAULT_DAYS)));

        $windowStart = Carbon::now()->subDays($days);
        $purchases = SpaceAccessService::scopeQuery(PurchaseHistory::query(), $space, $userId)
            ->where('purchased_at', '>=', $windowStart)
            ->whereNotNull('price')
            ->orderBy('purchased_at')
            ->limit(300)
            ->get(['normalized_name', 'product_name', 'price', 'store_name', 'purchased_at']);

        if ($purchases->isEmpty()) {
            return $this->json($response, [
                'success' => true,
                'data' => [
                    'window_days' => $days,
                    'total_saving' => 0.0,
                    'purchases_analyzed' => 0,
                    'items' => [],
                ],
            ]);
        }

        // Historique antérieur des mêmes produits (une seule requête)
        $names = $purchases->pluck('normalized_name')->unique()->values()->all();
        $priorsStart = $windowStart->copy()->subDays(self::USUAL_PRICE_WINDOW_DAYS);
        $history = SpaceAccessService::scopeQuery(PurchaseHistory::query(), $space, $userId)
            ->whereIn('normalized_name', $names)
            ->where('purchased_at', '>=', $priorsStart)
            ->whereNotNull('price')
            ->orderBy('purchased_at')
            ->get(['normalized_name', 'price', 'purchased_at'])
            ->groupBy('normalized_name');

        $total = 0.0;
        $items = [];
        foreach ($purchases as $p) {
            $paidAt = Carbon::parse($p->purchased_at);
            $priors = ($history[$p->normalized_name] ?? collect())
                ->filter(fn($h) => Carbon::parse($h->purchased_at)->lt($paidAt)
                    && Carbon::parse($h->purchased_at)->gte($paidAt->copy()->subDays(self::USUAL_PRICE_WINDOW_DAYS)))
                ->pluck('price')->map(fn($v) => (float) $v)->sort()->values();

            if ($priors->count() < self::USUAL_PRICE_MIN_PRIORS) {
                continue; // pas assez de repères : on ne devine pas (§30)
            }
            $mid = intdiv($priors->count(), 2);
            $usual = $priors->count() % 2 === 1
                ? $priors[$mid]
                : ($priors[$mid - 1] + $priors[$mid]) / 2;

            $saving = $usual - (float) $p->price;
            if ($saving < 0.05) {
                continue; // pas d'économie significative
            }
            $total += $saving;
            $items[] = [
                'product_name' => $p->product_name,
                'paid' => round((float) $p->price, 2),
                'usual_price' => round($usual, 2),
                'saving' => round($saving, 2),
                'priors_count' => $priors->count(),
                'store_name' => $p->store_name,
                'purchased_at' => $paidAt->toDateString(),
            ];
        }

        usort($items, fn($a, $b) => $b['saving'] <=> $a['saving']);

        return $this->json($response, [
            'success' => true,
            'data' => [
                'window_days' => $days,
                'total_saving' => round($total, 2),
                'purchases_analyzed' => $purchases->count(),
                'items' => array_slice($items, 0, 20),
            ],
        ]);
    }
}
