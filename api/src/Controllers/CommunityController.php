<?php
// src/Controllers/CommunityController.php — communauté de prix
// anonymisée (§33, Phase 6).
//
// Lecture d'agrégats UNIQUEMENT (community_prices, reconstruite par le
// cron) : produit, magasin, région, statistiques, fraîcheur. Aucun
// identifiant n'existe dans la table, donc aucun ne peut sortir d'ici.
// Le wording côté app reste prudent : « prix observés par la
// communauté », jamais des prix officiels.
//
// Consentement : chaque utilisateur peut retirer ses observations du
// prochain recalcul (community_prices_enabled).

namespace App\Controllers;

use App\Models\PurchaseHistory;
use App\Models\User;
use App\Services\CommunityPriceService;
use Illuminate\Database\Capsule\Manager as DB;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class CommunityController
{
    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    /**
     * GET /community/prices?product=Lait%202%25[&region=moncton]
     * Les agrégats publiés pour un produit, du moins cher au plus cher.
     */
    public function prices(Request $request, Response $response): Response
    {
        $params = $request->getQueryParams();
        $product = trim((string) ($params['product'] ?? ''));
        $region = mb_strtolower(trim((string) ($params['region'] ?? '')), 'UTF-8');

        if ($product === '') {
            return $this->json($response, ['success' => false, 'message' => 'product requis'], 422);
        }

        $rows = DB::connection()->table('community_prices')
            ->where('normalized_name', PurchaseHistory::normalizeProductName($product))
            ->when($region !== '', fn($q) => $q->where('region', $region))
            ->orderBy('median_price')
            ->limit(20)
            ->get();

        return $this->json($response, [
            'success' => true,
            'data' => [
                'product' => $product,
                'window_days' => CommunityPriceService::WINDOW_DAYS,
                'quality' => [
                    'min_contributors' => CommunityPriceService::MIN_CONTRIBUTORS,
                    'min_observations' => CommunityPriceService::MIN_OBSERVATIONS,
                ],
                'stores' => $rows->map(fn($r) => CommunityPriceService::format($r))->values(),
            ],
        ]);
    }

    /** GET /community/settings — mon consentement de partage. */
    public function getSettings(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $enabled = (bool) User::where('id', $userId)->value('community_prices_enabled');

        return $this->json($response, [
            'success' => true,
            'data' => ['enabled' => $enabled],
        ]);
    }

    /**
     * PUT /community/settings { enabled: bool } — retrait (ou retour)
     * du partage anonymisé. Effectif au prochain recalcul du cron.
     */
    public function updateSettings(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $data = $request->getParsedBody() ?? [];

        if (!array_key_exists('enabled', $data)) {
            return $this->json($response, ['success' => false, 'message' => 'enabled requis'], 422);
        }
        $enabled = filter_var($data['enabled'], FILTER_VALIDATE_BOOLEAN);
        User::where('id', $userId)->update(['community_prices_enabled' => $enabled ? 1 : 0]);

        return $this->json($response, [
            'success' => true,
            'data' => ['enabled' => $enabled],
            'message' => $enabled
                ? 'Partage communautaire activé'
                : 'Partage communautaire désactivé (effectif au prochain recalcul)',
        ]);
    }
}
