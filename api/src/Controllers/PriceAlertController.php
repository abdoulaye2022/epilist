<?php
// src/Controllers/PriceAlertController.php — prix cible par espace
// (§25-§27, Phase 4).
//
// Une alerte dit : « préviens-moi quand {produit} passe sous {prix} »,
// éventuellement limitée à un magasin. Les alertes appartiennent à
// l'ESPACE (foyer, restaurant…) : chaque membre les voit ; création
// ouverte aux membres qui peuvent ajouter des articles (add_items) ;
// modification/suppression : le créateur, ou manage_lists.
//
// §26 — prix cible automatique : /price-alerts/suggest calcule un seuil
// PRUDENT à partir de l'historique de l'espace (médiane = prix habituel,
// 25e percentile = bon prix). Jamais présenté comme une certitude :
// c'est à l'utilisateur de confirmer.
//
// Les SpaceAccessException remontent au middleware d'erreurs, qui les
// traduit (403 SPACE_PERMISSION_DENIED, etc.).

namespace App\Controllers;

use App\Models\PriceAlert;
use App\Models\PurchaseHistory;
use App\Models\Space;
use App\Services\SpaceAccessService;
use Carbon\Carbon;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class PriceAlertController
{
    /** Fenêtre d'historique pour la suggestion et le « dernier prix vu ». */
    private const SUGGEST_WINDOW_DAYS = 90;
    private const SUGGEST_MIN_OBSERVATIONS = 3;

    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    private function format(PriceAlert $a, ?array $lastObs = null): array
    {
        return [
            'id' => (int) $a->id,
            'space_id' => (int) $a->space_id,
            'product_name' => $a->product_name,
            'normalized_name' => $a->normalized_name,
            'store_id' => $a->store_id !== null ? (int) $a->store_id : null,
            'target_price' => (float) $a->target_price,
            'is_active' => (bool) $a->is_active,
            'created_by_user_id' => (int) $a->created_by_user_id,
            'created_by_name' => trim(($a->creator_first_name ?? '') . ' ' . ($a->creator_last_name ?? '')) ?: null,
            'last_triggered_at' => $a->last_triggered_at?->toIso8601String(),
            'last_notified_price' => $a->last_notified_price !== null ? (float) $a->last_notified_price : null,
            'last_observed' => $lastObs,
            'created_at' => $a->created_at?->toIso8601String(),
        ];
    }

    /** GET /price-alerts — les alertes de l'espace actif. */
    public function index(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = SpaceAccessService::resolveSpace($request, $userId);

        $alerts = PriceAlert::where('price_alerts.space_id', $space->id)
            ->leftJoin('users', 'users.id', '=', 'price_alerts.created_by_user_id')
            ->orderByDesc('price_alerts.is_active')
            ->orderByDesc('price_alerts.created_at')
            ->get([
                'price_alerts.*',
                'users.first_name as creator_first_name',
                'users.last_name as creator_last_name',
            ]);

        // Dernière observation par produit (une requête pour toutes)
        $lastByProduct = [];
        if ($alerts->isNotEmpty()) {
            $since = Carbon::now()->subDays(self::SUGGEST_WINDOW_DAYS);
            $rows = SpaceAccessService::scopeQuery(PurchaseHistory::query(), $space, $userId)
                ->whereIn('normalized_name', $alerts->pluck('normalized_name')->unique()->all())
                ->where('purchased_at', '>=', $since)
                ->whereNotNull('price')
                ->orderByDesc('purchased_at')
                ->get(['normalized_name', 'price', 'store_name', 'purchased_at']);
            foreach ($rows as $r) {
                if (!isset($lastByProduct[$r->normalized_name])) {
                    $lastByProduct[$r->normalized_name] = [
                        'price' => (float) $r->price,
                        'store_name' => $r->store_name,
                        'at' => Carbon::parse($r->purchased_at)->toDateString(),
                    ];
                }
            }
        }

        return $this->json($response, [
            'success' => true,
            'data' => [
                'alerts' => $alerts
                    ->map(fn($a) => $this->format($a, $lastByProduct[$a->normalized_name] ?? null))
                    ->values(),
            ],
        ]);
    }

    /**
     * GET /price-alerts/suggest?product=Lait%202%25
     * §26 : seuil suggéré à partir de l'historique de l'espace.
     */
    public function suggest(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = SpaceAccessService::resolveSpace($request, $userId);
        $product = trim((string) ($request->getQueryParams()['product'] ?? ''));
        if ($product === '') {
            return $this->json($response, ['success' => false, 'message' => 'product requis'], 422);
        }

        $normalized = PurchaseHistory::normalizeProductName($product);
        $prices = SpaceAccessService::scopeQuery(PurchaseHistory::query(), $space, $userId)
            ->where('normalized_name', $normalized)
            ->where('purchased_at', '>=', Carbon::now()->subDays(self::SUGGEST_WINDOW_DAYS))
            ->whereNotNull('price')
            ->orderBy('price')
            ->pluck('price')
            ->map(fn($p) => (float) $p)
            ->values();

        $count = $prices->count();
        if ($count < self::SUGGEST_MIN_OBSERVATIONS) {
            return $this->json($response, [
                'success' => true,
                'data' => [
                    'product' => $product,
                    'normalized_name' => $normalized,
                    'observations' => $count,
                    'usual_price' => null,
                    'good_price' => null,
                    'suggested_target' => null,
                ],
            ]);
        }

        // Médiane = prix habituel ; 25e percentile = bon prix (prudent).
        $mid = intdiv($count, 2);
        $median = $count % 2 === 1 ? $prices[$mid] : ($prices[$mid - 1] + $prices[$mid]) / 2;
        $good = $prices[max(0, (int) floor(($count - 1) * 0.25))];

        return $this->json($response, [
            'success' => true,
            'data' => [
                'product' => $product,
                'normalized_name' => $normalized,
                'observations' => $count,
                'window_days' => self::SUGGEST_WINDOW_DAYS,
                'usual_price' => round($median, 2),
                'good_price' => round($good, 2),
                'min_price' => round($prices->first(), 2),
                'suggested_target' => round($good, 2),
            ],
        ]);
    }

    /** POST /price-alerts { product_name, target_price, store_id? } */
    public function store(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = SpaceAccessService::resolveSpace($request, $userId);
        SpaceAccessService::assertWrite($space, $userId, 'add_items');

        $data = $request->getParsedBody() ?? [];
        $product = trim((string) ($data['product_name'] ?? ''));
        $target = $data['target_price'] ?? null;
        $storeId = isset($data['store_id']) && is_numeric($data['store_id']) ? (int) $data['store_id'] : null;

        if ($product === '' || mb_strlen($product) > 255) {
            return $this->json($response, ['success' => false, 'message' => 'product_name requis'], 422);
        }
        if (!is_numeric($target) || (float) $target <= 0 || (float) $target > 100000) {
            return $this->json($response, [
                'success' => false,
                'code' => 'TARGET_REQUIRED',
                'message' => 'target_price requis (nombre positif)',
            ], 422);
        }

        $normalized = PurchaseHistory::normalizeProductName($product);

        // Une seule alerte active par (espace, produit, magasin)
        $exists = PriceAlert::where('space_id', $space->id)
            ->where('normalized_name', $normalized)
            ->where('is_active', true)
            ->where(fn($q) => $storeId === null
                ? $q->whereNull('store_id')
                : $q->where('store_id', $storeId))
            ->exists();
        if ($exists) {
            return $this->json($response, [
                'success' => false,
                'code' => 'ALERT_EXISTS',
                'message' => 'Une alerte active existe déjà pour ce produit.',
            ], 409);
        }

        $alert = PriceAlert::create([
            'space_id' => $space->id,
            'created_by_user_id' => $userId,
            'product_name' => $product,
            'normalized_name' => $normalized,
            'store_id' => $storeId,
            'target_price' => round((float) $target, 2),
            'is_active' => true,
        ]);

        return $this->json($response, [
            'success' => true,
            'data' => ['alert' => $this->format($alert)],
            'message' => 'Alerte créée',
        ], 201);
    }

    /**
     * L'alerte appartient-elle à un espace dont je suis membre, avec le
     * droit de la modifier (créateur, ou manage_lists) ?
     */
    private function findEditable(int $userId, int $alertId): ?PriceAlert
    {
        $alert = PriceAlert::find($alertId);
        if (!$alert) {
            return null;
        }
        $space = Space::find($alert->space_id);
        if (!$space || $space->deleted_at !== null) {
            return null;
        }
        if ($space->type === Space::TYPE_PERSONAL) {
            // Espace personnel : seul le propriétaire y est membre.
            return (int) $space->owner_user_id === $userId ? $alert : null;
        }
        $member = SpaceAccessService::assertMember($space->id, $userId); // 403 si non-membre
        if ((int) $alert->created_by_user_id !== $userId && !$member->can('manage_lists')) {
            throw SpaceAccessService::deny(403, 'SPACE_PERMISSION_DENIED');
        }
        return $alert;
    }

    /** PUT /price-alerts/{id} { target_price?, is_active? } */
    public function update(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $alert = $this->findEditable($userId, (int) $args['id']);
        if (!$alert) {
            return $this->json($response, ['success' => false, 'message' => 'Alerte introuvable'], 404);
        }

        $data = $request->getParsedBody() ?? [];
        $updates = [];
        if (isset($data['target_price'])) {
            if (!is_numeric($data['target_price']) || (float) $data['target_price'] <= 0) {
                return $this->json($response, ['success' => false, 'message' => 'target_price invalide'], 422);
            }
            $updates['target_price'] = round((float) $data['target_price'], 2);
            // Nouveau seuil = nouvelle chance de notifier
            $updates['last_triggered_at'] = null;
            $updates['last_notified_price'] = null;
        }
        if (array_key_exists('is_active', $data)) {
            $updates['is_active'] = (bool) $data['is_active'];
        }
        if ($updates === []) {
            return $this->json($response, ['success' => false, 'message' => 'Rien à modifier'], 422);
        }

        $alert->update($updates);

        return $this->json($response, [
            'success' => true,
            'data' => ['alert' => $this->format($alert->fresh())],
            'message' => 'Alerte mise à jour',
        ]);
    }

    /** DELETE /price-alerts/{id} */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $alert = $this->findEditable($userId, (int) $args['id']);
        if (!$alert) {
            return $this->json($response, ['success' => false, 'message' => 'Alerte introuvable'], 404);
        }
        $alert->delete();

        return $this->json($response, ['success' => true, 'message' => 'Alerte supprimée']);
    }
}
