<?php
// src/Controllers/PriceController.php
//
// Intelligence prix d'EpiList :
//  - import structuré d'un reçu (OCR ou manuel) -> lignes + historique
//    de prix + apprentissage des alias produit ;
//  - résolution de libellés de reçu vers les produits de l'utilisateur ;
//  - historique de prix d'un produit (observations + statistiques) ;
//  - comparaison du coût d'une liste entre magasins ;
//  - optimisation multi-magasins (2 max par défaut, seuil d'économie).
//
// IMPORTANT : les prix comparés sont « les derniers prix connus par
// EpiList à partir des achats enregistrés », jamais des prix officiels.
// Chaque observation garde sa provenance (source, receipt_id, date).

namespace App\Controllers;

use App\Models\ListReceipt;
use App\Models\ProductAlias;
use App\Models\PurchaseHistory;
use App\Models\ReceiptItem;
use App\Models\SharedList;
use App\Models\ShoppingList;
use App\Models\Store;
use Carbon\Carbon;
use Illuminate\Database\Capsule\Manager as DB;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class PriceController
{
    /** Fraîcheur des observations (jours) pour le comparateur. */
    private const DEFAULT_WINDOW_DAYS = 90;
    private const FRESH_DAYS = 14;
    private const ACCEPTABLE_DAYS = 30;

    /** Optimiseur : valeurs par défaut, configurables par requête. */
    private const DEFAULT_MAX_STORES = 2;
    private const DEFAULT_MIN_SAVING = 5.0;

    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    /** Même règle d'accès que les autres contrôleurs de listes. */
    private function canEditList(int $userId, int $listId): bool
    {
        if (ShoppingList::where('id', $listId)->where('user_id', $userId)->exists()) {
            return true;
        }
        $share = SharedList::where('list_id', $listId)
            ->where('shared_with_user_id', $userId)
            ->where('status', SharedList::STATUS_ACCEPTED)
            ->where('is_active', true)
            ->first();
        return $share !== null && $share->canEdit();
    }

    private function canReadList(int $userId, int $listId): bool
    {
        $list = ShoppingList::find($listId);
        return $list !== null && $list->canBeAccessedBy($userId);
    }

    // =========================================================================
    // IMPORT STRUCTURÉ D'UN REÇU
    // =========================================================================

    /**
     * POST /shopping-lists/{listId}/receipts/import
     * body: { store_id?, store_name, purchase_date, total_amount,
     *         receipt_number?, subtotal?, taxes?, currency?, image_url?,
     *         source: 'receipt_ocr'|'manual', force?: bool,
     *         items: [{ raw_label, product_name?, quantity?, unit?,
     *                   unit_price?, line_price, confidence?, barcode? }] }
     */
    public function importReceipt(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $listId = (int) $args['listId'];
        $data = $request->getParsedBody() ?? [];

        if (!$this->canEditList($userId, $listId)) {
            return $this->json($response, ['success' => false, 'message' => 'Permission refusée'], 403);
        }

        $storeName = trim((string) ($data['store_name'] ?? ''));
        $total = $data['total_amount'] ?? null;
        $date = $data['purchase_date'] ?? null;
        $items = $data['items'] ?? [];

        if ($storeName === '' || !is_numeric($total) || !$date || !is_array($items) || $items === []) {
            return $this->json($response, [
                'success' => false,
                'message' => 'store_name, purchase_date, total_amount et items sont requis',
            ], 422);
        }

        try {
            $purchaseDate = Carbon::parse($date)->toDateString();
        } catch (\Throwable $e) {
            return $this->json($response, ['success' => false, 'message' => 'purchase_date invalide'], 422);
        }

        // Magasin : id fourni (et possédé), sinon résolution/création par slug
        $store = null;
        if (!empty($data['store_id'])) {
            $store = Store::where('id', (int) $data['store_id'])->where('user_id', $userId)->first();
        }
        if ($store === null) {
            $slug = Store::slugify($storeName);
            $store = Store::withTrashed()->where('user_id', $userId)->where('slug', $slug)->first();
            if ($store !== null && $store->trashed()) {
                $store->restore();
            }
            $store ??= Store::create(['user_id' => $userId, 'name' => $storeName, 'slug' => $slug]);
        }

        // Déduplication : signature user|store|date|total|numero
        $receiptNumber = trim((string) ($data['receipt_number'] ?? ''));
        $signature = sha1(implode('|', [
            $userId, $store->id, $purchaseDate,
            number_format((float) $total, 2, '.', ''), $receiptNumber,
        ]));
        if (empty($data['force'])) {
            // La signature encode déjà user_id : une correspondance = doublon
            $existing = ListReceipt::where('signature', $signature)->first();
            if ($existing !== null) {
                return $this->json($response, [
                    'success' => false,
                    'code' => 'DUPLICATE_RECEIPT',
                    'message' => 'Ce reçu semble déjà avoir été ajouté.',
                    'data' => ['existing_receipt_id' => $existing->id],
                ], 409);
            }
        }

        $source = ($data['source'] ?? 'manual') === 'receipt_ocr' ? 'receipt_ocr' : 'manual';

        try {
            $receipt = null;
            DB::connection()->transaction(function () use (
                $data, $items, $userId, $listId, $store, $purchaseDate,
                $total, $receiptNumber, $signature, $source, &$receipt
            ) {
                $receipt = ListReceipt::create([
                    'list_id' => $listId,
                    'store_name' => $store->name,
                    'store_id' => $store->id,
                    'receipt_number' => $receiptNumber !== '' ? $receiptNumber : null,
                    'total_amount' => (float) $total,
                    'subtotal' => isset($data['subtotal']) && is_numeric($data['subtotal']) ? (float) $data['subtotal'] : null,
                    'taxes' => isset($data['taxes']) && is_numeric($data['taxes']) ? (float) $data['taxes'] : null,
                    'currency' => isset($data['currency']) ? substr((string) $data['currency'], 0, 3) : null,
                    'image_url' => $data['image_url'] ?? null,
                    'source' => $source,
                    'signature' => $signature,
                    'notes' => $data['notes'] ?? null,
                    'purchase_date' => $purchaseDate,
                ]);

                $now = Carbon::parse($purchaseDate);
                foreach (array_values($items) as $i => $item) {
                    $rawLabel = trim((string) ($item['raw_label'] ?? ''));
                    $linePrice = $item['line_price'] ?? null;
                    if ($rawLabel === '' || !is_numeric($linePrice)) {
                        continue;
                    }
                    $productName = trim((string) ($item['product_name'] ?? '')) ?: null;
                    $canonical = $productName ?? $rawLabel;
                    $normalized = PurchaseHistory::normalizeProductName($canonical);
                    $quantity = is_numeric($item['quantity'] ?? null) ? (float) $item['quantity'] : 1.0;
                    $unit = isset($item['unit']) ? substr(trim((string) $item['unit']), 0, 10) : null;
                    $unitPrice = $this->normalizedUnitPrice((float) $linePrice, $quantity, $unit, $item['unit_price'] ?? null);

                    ReceiptItem::create([
                        'receipt_id' => $receipt->id,
                        'raw_label' => $rawLabel,
                        'product_name' => $productName,
                        'normalized_name' => $normalized,
                        'quantity' => $quantity,
                        'unit' => $unit,
                        'unit_price' => $unitPrice,
                        'line_price' => (float) $linePrice,
                        'confidence' => isset($item['confidence']) ? max(0, min(100, (int) $item['confidence'])) : null,
                        'position' => $i,
                    ]);

                    // Observation de prix (l'historique N'EST PAS remplacé :
                    // chaque achat ajoute une ligne)
                    // quantity (int) = nombre d'unités quand l'unité est la
                    // pièce ; 1 pour les articles au poids/volume (le détail
                    // exact reste dans receipt_items.quantity DECIMAL)
                    $isPerPiece = $unit === null || $unit === '' || $unit === 'un';
                    PurchaseHistory::create([
                        'user_id' => $userId,
                        'product_name' => $canonical,
                        'normalized_name' => $normalized,
                        'category_id' => null,
                        'quantity' => $isPerPiece ? max(1, (int) round($quantity)) : 1,
                        'unit' => $unit,
                        'unit_price' => $unitPrice,
                        'price' => (float) $linePrice,
                        'store_name' => $store->name,
                        'store_id' => $store->id,
                        'barcode' => $item['barcode'] ?? null,
                        'purchased_at' => $now,
                        'list_id' => $receipt->list_id,
                        'receipt_id' => $receipt->id,
                        'source' => $source,
                        'day_of_week' => $now->dayOfWeek,
                        'month' => $now->month,
                        'season' => match (true) {
                            in_array($now->month, [12, 1, 2]) => 'winter',
                            in_array($now->month, [3, 4, 5]) => 'spring',
                            in_array($now->month, [6, 7, 8]) => 'summer',
                            default => 'fall',
                        },
                    ]);

                    // Apprentissage : l'utilisateur a confirmé rawLabel -> produit
                    if ($productName !== null && $productName !== $rawLabel) {
                        ProductAlias::updateOrCreate(
                            [
                                'user_id' => $userId,
                                'store_id' => $store->id,
                                'normalized_alias' => PurchaseHistory::normalizeProductName($rawLabel),
                            ],
                            [
                                'alias' => $rawLabel,
                                'product_name' => $productName,
                                'normalized_name' => $normalized,
                                'barcode' => $item['barcode'] ?? null,
                            ]
                        );
                    }
                }
            });

            return $this->json($response, [
                'success' => true,
                'data' => [
                    'receipt' => $receipt->fresh(),
                    'items' => ReceiptItem::where('receipt_id', $receipt->id)->orderBy('position')->get(),
                ],
                'message' => 'Reçu enregistré',
            ], 201);
        } catch (\Throwable $e) {
            error_log('importReceipt: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => "Erreur lors de l'enregistrement du reçu"], 500);
        }
    }

    /** Prix normalisé par unité de référence (kg, L, unité). */
    private function normalizedUnitPrice(float $linePrice, float $quantity, ?string $unit, $explicit): ?float
    {
        if (is_numeric($explicit)) {
            return round((float) $explicit, 4);
        }
        if ($quantity <= 0) {
            return null;
        }
        return match ($unit) {
            'kg', 'l', 'L' => round($linePrice / $quantity, 4),
            'g' => round($linePrice / ($quantity / 1000), 4),   // -> $/kg
            'ml' => round($linePrice / ($quantity / 1000), 4),  // -> $/L
            'un', null, '' => round($linePrice / $quantity, 4), // -> $/unité
            default => null,
        };
    }

    // =========================================================================
    // RÉSOLUTION DE LIBELLÉS (écran de validation du scan)
    // =========================================================================

    /**
     * POST /receipts/resolve-labels
     * body: { store_id?, labels: [ {label, barcode?} | "label" ] }
     * Ordre de résolution : code-barres > alias appris > nom normalisé exact
     * > fuzzy. Retourne match nul si trop incertain (l'utilisateur tranche).
     */
    public function resolveLabels(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $data = $request->getParsedBody() ?? [];
        $labels = $data['labels'] ?? [];
        $storeId = isset($data['store_id']) ? (int) $data['store_id'] : null;

        if (!is_array($labels) || $labels === []) {
            return $this->json($response, ['success' => false, 'message' => 'labels requis'], 422);
        }
        $labels = array_slice($labels, 0, 80);

        // Candidats canoniques de l'utilisateur (suggestions + historique)
        $known = DB::connection()->table('product_suggestions')
            ->where('user_id', $userId)
            ->pluck('product_name')->all();
        $known = array_merge($known, PurchaseHistory::where('user_id', $userId)
            ->orderByDesc('purchased_at')->limit(300)->pluck('product_name')->all());
        $candidates = [];
        foreach ($known as $name) {
            $candidates[PurchaseHistory::normalizeProductName($name)] = $name;
        }

        $aliases = ProductAlias::where('user_id', $userId)
            ->when($storeId, fn($q) => $q->where(fn($w) => $w->where('store_id', $storeId)->orWhereNull('store_id')))
            ->get()
            ->keyBy('normalized_alias');

        $barcodes = PurchaseHistory::where('user_id', $userId)
            ->whereNotNull('barcode')
            ->orderByDesc('purchased_at')->limit(500)
            ->get(['barcode', 'product_name'])
            ->keyBy('barcode');

        $results = [];
        foreach ($labels as $entry) {
            $label = is_array($entry) ? trim((string) ($entry['label'] ?? '')) : trim((string) $entry);
            $barcode = is_array($entry) ? ($entry['barcode'] ?? null) : null;
            if ($label === '') {
                continue;
            }
            $norm = PurchaseHistory::normalizeProductName($label);
            $match = null; $method = null; $confidence = 0;

            if ($barcode !== null && isset($barcodes[$barcode])) {
                $match = $barcodes[$barcode]->product_name; $method = 'barcode'; $confidence = 98;
            } elseif (isset($aliases[$norm])) {
                $match = $aliases[$norm]->product_name; $method = 'alias'; $confidence = 95;
            } elseif (isset($candidates[$norm])) {
                $match = $candidates[$norm]; $method = 'exact'; $confidence = 90;
            } else {
                // Fuzzy : plus petite distance de Levenshtein relative
                $best = null; $bestScore = 0.0;
                foreach ($candidates as $candNorm => $candName) {
                    $maxLen = max(strlen($norm), strlen($candNorm));
                    if ($maxLen === 0 || abs(strlen($norm) - strlen($candNorm)) > $maxLen * 0.5) {
                        continue;
                    }
                    $score = 1 - levenshtein($norm, $candNorm) / $maxLen;
                    if ($score > $bestScore) {
                        $bestScore = $score; $best = $candName;
                    }
                }
                if ($best !== null && $bestScore >= 0.72) {
                    $match = $best; $method = 'fuzzy'; $confidence = (int) round($bestScore * 80);
                }
            }

            $results[] = [
                'label' => $label,
                'match' => $match,
                'method' => $method,
                'confidence' => $confidence,
            ];
        }

        return $this->json($response, ['success' => true, 'data' => $results]);
    }

    // =========================================================================
    // HISTORIQUE DE PRIX D'UN PRODUIT
    // =========================================================================

    /**
     * GET /price-history?product=Lait%202%25&days=180
     * Observations (avec provenance) + statistiques : dernier prix, prix
     * habituel (moyenne fenêtrée hors dernier achat), variation %, min/max,
     * moyenne par magasin.
     */
    public function priceHistory(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $params = $request->getQueryParams();
        $product = trim((string) ($params['product'] ?? ''));
        $days = max(7, min(730, (int) ($params['days'] ?? 180)));

        if ($product === '') {
            return $this->json($response, ['success' => false, 'message' => 'product requis'], 422);
        }
        $normalized = PurchaseHistory::normalizeProductName($product);
        $since = Carbon::now()->subDays($days);

        $rows = PurchaseHistory::where('user_id', $userId)
            ->where('normalized_name', $normalized)
            ->where('purchased_at', '>=', $since)
            ->whereNotNull('price')
            ->orderByDesc('purchased_at')
            ->limit(200)
            ->get();

        $observations = $rows->map(fn($r) => [
            'price' => (float) $r->price,
            'unit_price' => $r->unit_price !== null ? (float) $r->unit_price : null,
            'unit' => $r->unit,
            'quantity' => (int) $r->quantity,
            'store_id' => $r->store_id,
            'store_name' => $r->store_name,
            'purchased_at' => Carbon::parse($r->purchased_at)->toDateString(),
            'source' => $r->source ?? 'shopping_list',
            'receipt_id' => $r->receipt_id,
        ])->values();

        $stats = null;
        if ($rows->isNotEmpty()) {
            $prices = $rows->pluck('price')->map(fn($p) => (float) $p);
            $last = (float) $rows->first()->price;
            $others = $rows->slice(1)->pluck('price')->map(fn($p) => (float) $p);
            $usual = $others->isNotEmpty() ? $others->avg() : $last;
            $sorted = $prices->sort()->values();
            $mid = intdiv($sorted->count(), 2);
            $median = $sorted->count() % 2 === 1
                ? $sorted[$mid]
                : ($sorted[$mid - 1] + $sorted[$mid]) / 2;

            $byStore = $rows->whereNotNull('store_name')->groupBy('store_name')->map(fn($g) => [
                'avg_price' => round($g->avg('price'), 2),
                'last_price' => (float) $g->first()->price,
                'last_at' => Carbon::parse($g->first()->purchased_at)->toDateString(),
                'observations' => $g->count(),
            ]);

            $stats = [
                'last_price' => round($last, 2),
                'last_store' => $rows->first()->store_name,
                'last_at' => Carbon::parse($rows->first()->purchased_at)->toDateString(),
                'usual_price' => round($usual, 2),
                'median_price' => round($median, 2),
                'min_price' => round($prices->min(), 2),
                'max_price' => round($prices->max(), 2),
                'variation_pct' => $usual > 0 ? round(($last - $usual) / $usual * 100, 1) : null,
                'observations' => $rows->count(),
                'window_days' => $days,
                'by_store' => $byStore,
            ];
        }

        return $this->json($response, [
            'success' => true,
            'data' => [
                'product' => $product,
                'normalized_name' => $normalized,
                'stats' => $stats,
                'observations' => $observations,
            ],
        ]);
    }

    // =========================================================================
    // COMPARATEUR & OPTIMISEUR
    // =========================================================================

    /**
     * Meilleure observation par (produit normalisé x magasin) dans la
     * fenêtre : la plus récente gagne. Retourne
     * [norm => [store_id => {price, age_days, store_name, source}]].
     */
    private function bestPrices(int $userId, array $normalizedNames, int $days): array
    {
        if ($normalizedNames === []) {
            return [];
        }
        $since = Carbon::now()->subDays($days);
        $rows = PurchaseHistory::where('user_id', $userId)
            ->whereIn('normalized_name', $normalizedNames)
            ->where('purchased_at', '>=', $since)
            ->whereNotNull('price')
            ->whereNotNull('store_id')
            ->orderByDesc('purchased_at')
            ->get(['normalized_name', 'store_id', 'store_name', 'price',
                   'quantity', 'unit', 'unit_price', 'purchased_at', 'source']);

        $out = [];
        foreach ($rows as $r) {
            $sid = (int) $r->store_id;
            if (isset($out[$r->normalized_name][$sid])) {
                continue; // déjà la plus récente (tri desc)
            }
            // Prix estimé pour « 1 article de la liste » : à la pièce, le
            // prix unitaire ; au poids/volume, le montant du dernier achat
            // (meilleure approximation d'un achat typique).
            $perPiece = $r->unit === null || $r->unit === '' || $r->unit === 'un';
            if ($perPiece) {
                $price = $r->unit_price !== null
                    ? (float) $r->unit_price
                    : (float) $r->price / max(1, (int) $r->quantity);
            } else {
                $price = (float) $r->price;
            }
            $out[$r->normalized_name][$sid] = [
                'price' => round($price, 2),
                'age_days' => (int) floor(Carbon::parse($r->purchased_at)->diffInDays(Carbon::now())),
                'store_name' => $r->store_name,
                'source' => $r->source ?? 'shopping_list',
            ];
        }
        return $out;
    }

    private function freshness(int $ageDays): string
    {
        return match (true) {
            $ageDays <= self::FRESH_DAYS => 'fresh',
            $ageDays <= self::ACCEPTABLE_DAYS => 'acceptable',
            $ageDays <= self::DEFAULT_WINDOW_DAYS => 'old',
            default => 'stale',
        };
    }

    /** Articles non achetés de la liste, avec quantité et nom normalisé. */
    private function listItems(int $listId): array
    {
        return DB::connection()->table('list_items')
            ->where('list_id', $listId)
            ->whereNull('deleted_at')
            ->where('is_purchased', false)
            ->get(['id', 'product_name', 'quantity'])
            ->map(fn($r) => [
                'id' => (int) $r->id,
                'name' => $r->product_name,
                'normalized' => PurchaseHistory::normalizeProductName($r->product_name),
                'quantity' => max(1, (int) $r->quantity),
            ])->all();
    }

    /**
     * GET /shopping-lists/{id}/store-comparison?days=90
     * Coût estimé de la liste par magasin, avec couverture et fraîcheur.
     */
    public function storeComparison(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $listId = (int) $args['id'];
        if (!$this->canReadList($userId, $listId)) {
            return $this->json($response, ['success' => false, 'message' => 'Liste introuvable'], 404);
        }
        $days = max(14, min(365, (int) (($request->getQueryParams()['days'] ?? null) ?: self::DEFAULT_WINDOW_DAYS)));

        $items = $this->listItems($listId);
        if ($items === []) {
            return $this->json($response, [
                'success' => true,
                'data' => ['items_count' => 0, 'stores' => [], 'window_days' => $days],
            ]);
        }

        $prices = $this->bestPrices($userId, array_column($items, 'normalized'), $days);

        // Magasins candidats = ceux où au moins un prix est connu
        $storeIds = [];
        foreach ($prices as $byStore) {
            foreach ($byStore as $sid => $_) {
                $storeIds[$sid] = true;
            }
        }

        $stores = [];
        foreach (array_keys($storeIds) as $sid) {
            $total = 0.0;
            $known = 0;
            $details = [];
            foreach ($items as $item) {
                $obs = $prices[$item['normalized']][$sid] ?? null;
                if ($obs !== null) {
                    $known++;
                    $total += $obs['price'] * $item['quantity'];
                    $details[] = [
                        'item_id' => $item['id'],
                        'name' => $item['name'],
                        'quantity' => $item['quantity'],
                        'price' => $obs['price'],
                        'age_days' => $obs['age_days'],
                        'freshness' => $this->freshness($obs['age_days']),
                        'source' => $obs['source'],
                    ];
                } else {
                    $details[] = [
                        'item_id' => $item['id'],
                        'name' => $item['name'],
                        'quantity' => $item['quantity'],
                        'price' => null,
                    ];
                }
            }
            $storeName = null;
            foreach ($prices as $byStore) {
                if (isset($byStore[$sid])) {
                    $storeName = $byStore[$sid]['store_name'];
                    break;
                }
            }
            $stores[] = [
                'store_id' => $sid,
                'store_name' => $storeName,
                'estimated_total' => round($total, 2),
                'known_items' => $known,
                'items_count' => count($items),
                'coverage_pct' => (int) round($known / count($items) * 100),
                'items' => $details,
            ];
        }

        // Tri : couverture d'abord, puis total croissant
        usort($stores, function ($a, $b) {
            if ($a['known_items'] !== $b['known_items']) {
                return $b['known_items'] <=> $a['known_items'];
            }
            return $a['estimated_total'] <=> $b['estimated_total'];
        });

        return $this->json($response, [
            'success' => true,
            'data' => [
                'items_count' => count($items),
                'window_days' => $days,
                'stores' => $stores,
            ],
        ]);
    }

    /**
     * GET /shopping-lists/{id}/optimization?max_stores=2&min_saving=5&days=90
     * Répartition de la liste sur 1..max_stores magasins. Un magasin
     * supplémentaire n'est retenu que si l'économie dépasse min_saving.
     */
    public function optimization(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $listId = (int) $args['id'];
        if (!$this->canReadList($userId, $listId)) {
            return $this->json($response, ['success' => false, 'message' => 'Liste introuvable'], 404);
        }
        $q = $request->getQueryParams();
        $maxStores = max(1, min(3, (int) (($q['max_stores'] ?? null) ?: self::DEFAULT_MAX_STORES)));
        $minSaving = max(0, (float) (($q['min_saving'] ?? null) ?: self::DEFAULT_MIN_SAVING));
        $days = max(14, min(365, (int) (($q['days'] ?? null) ?: self::DEFAULT_WINDOW_DAYS)));

        $items = $this->listItems($listId);
        $prices = $this->bestPrices($userId, array_column($items, 'normalized'), $days);

        // Articles comparables = au moins un prix connu quelque part
        $comparable = array_values(array_filter($items, fn($it) => isset($prices[$it['normalized']])));
        if (count($comparable) < 2) {
            return $this->json($response, [
                'success' => true,
                'data' => ['feasible' => false, 'reason' => 'not_enough_data', 'comparable_items' => count($comparable)],
            ]);
        }

        // Top magasins par couverture (bornés pour le brute force)
        $coverage = [];
        $storeNames = [];
        foreach ($comparable as $it) {
            foreach ($prices[$it['normalized']] as $sid => $obs) {
                $coverage[$sid] = ($coverage[$sid] ?? 0) + 1;
                $storeNames[$sid] = $obs['store_name'];
            }
        }
        arsort($coverage);
        $topStores = array_slice(array_keys($coverage), 0, 5);

        // Coût d'un combo : chaque article au moins cher parmi les magasins
        // du combo ; repli sur son meilleur prix connu ailleurs (marqué
        // estimation) pour garder les totaux comparables entre combos.
        $evaluate = function (array $combo) use ($comparable, $prices) {
            $total = 0.0;
            $assignment = [];
            $estimated = 0;
            foreach ($comparable as $it) {
                $best = null;
                foreach ($combo as $sid) {
                    $obs = $prices[$it['normalized']][$sid] ?? null;
                    if ($obs !== null && ($best === null || $obs['price'] < $best['price'])) {
                        $best = $obs + ['store_id' => $sid, 'estimated' => false];
                    }
                }
                if ($best === null) {
                    foreach ($prices[$it['normalized']] as $sid => $obs) {
                        if ($best === null || $obs['price'] < $best['price']) {
                            $best = $obs + ['store_id' => $sid, 'estimated' => true];
                        }
                    }
                    $estimated++;
                }
                $total += $best['price'] * $it['quantity'];
                $assignment[] = [
                    'item_id' => $it['id'],
                    'name' => $it['name'],
                    'quantity' => $it['quantity'],
                    'store_id' => $best['store_id'],
                    'price' => $best['price'],
                    'estimated' => $best['estimated'],
                ];
            }
            return ['total' => round($total, 2), 'assignment' => $assignment, 'estimated_items' => $estimated];
        };

        // Meilleur magasin unique
        $bestSingle = null;
        foreach ($topStores as $sid) {
            $r = $evaluate([$sid]) + ['stores' => [$sid]];
            if ($bestSingle === null || $r['total'] < $bestSingle['total']) {
                $bestSingle = $r;
            }
        }

        // Meilleur combo jusqu'a max_stores (paires/triplets des top magasins)
        $bestCombo = $bestSingle;
        if ($maxStores >= 2) {
            $n = count($topStores);
            for ($i = 0; $i < $n; $i++) {
                for ($j = $i + 1; $j < $n; $j++) {
                    $combos = [[$topStores[$i], $topStores[$j]]];
                    if ($maxStores >= 3) {
                        for ($k = $j + 1; $k < $n; $k++) {
                            $combos[] = [$topStores[$i], $topStores[$j], $topStores[$k]];
                        }
                    }
                    foreach ($combos as $combo) {
                        $r = $evaluate($combo) + ['stores' => $combo];
                        // Un magasin de plus doit justifier son economie
                        $extraStores = count($combo) - count($bestCombo['stores']);
                        $saving = $bestCombo['total'] - $r['total'];
                        if ($r['total'] < $bestCombo['total'] &&
                            ($extraStores <= 0 || $saving >= $minSaving * $extraStores)) {
                            $bestCombo = $r;
                        }
                    }
                }
            }
        }

        // Regroupement par magasin pour l'affichage. Les articles sans prix
        // dans les magasins du plan (repli « estimation ailleurs ») sortent
        // dans une liste à part : ils ne font pas partie du trajet proposé.
        $group = [];
        $estimatedElsewhere = [];
        foreach ($bestCombo['assignment'] as $a) {
            if ($a['estimated']) {
                $a['store_name'] = $storeNames[$a['store_id']] ?? null;
                $estimatedElsewhere[] = $a;
                continue;
            }
            $sid = $a['store_id'];
            $group[$sid]['store_id'] = $sid;
            $group[$sid]['store_name'] = $storeNames[$sid] ?? null;
            $group[$sid]['items'][] = $a;
            $group[$sid]['subtotal'] = round(($group[$sid]['subtotal'] ?? 0) + $a['price'] * $a['quantity'], 2);
        }

        return $this->json($response, [
            'success' => true,
            'data' => [
                'feasible' => true,
                'window_days' => $days,
                'max_stores' => $maxStores,
                'min_saving_for_extra_store' => $minSaving,
                'comparable_items' => count($comparable),
                'items_count' => count($items),
                'single_store' => [
                    'store_id' => $bestSingle['stores'][0],
                    'store_name' => $storeNames[$bestSingle['stores'][0]] ?? null,
                    'total' => $bestSingle['total'],
                ],
                'optimized' => [
                    'stores' => array_values($group),
                    'total' => $bestCombo['total'],
                    'estimated_items' => $bestCombo['estimated_items'],
                    'estimated_elsewhere' => $estimatedElsewhere,
                ],
                'saving' => round($bestSingle['total'] - $bestCombo['total'], 2),
            ],
        ]);
    }
}
