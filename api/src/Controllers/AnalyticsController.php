<?php
// app/Controllers/AnalyticsController.php - VERSION COMPLÈTE AVEC I18N

namespace App\Controllers;

use App\Models\ListItem;
use App\Models\ListReceipt; // ✅ AJOUT DE L'IMPORT MANQUANT
use App\Models\ShoppingList;
use App\Models\SharedList;
use App\Models\User;
use App\Models\Currency;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;

class AnalyticsController
{
    /**
     * ✅ DICTIONNAIRE DE TRADUCTIONS POUR LES CATÉGORIES
     */
    private function getCategoryTranslations(): array
    {
        return [
            'fruits_vegetables' => [
                'en' => 'Fruits & Vegetables',
                'fr' => 'Fruits & Légumes'
            ],
            'meat_fish' => [
                'en' => 'Meat & Fish',
                'fr' => 'Viandes & Poissons'
            ],
            'dairy' => [
                'en' => 'Dairy Products',
                'fr' => 'Produits Laitiers'
            ],
            'grains_bread' => [
                'en' => 'Grains & Bread',
                'fr' => 'Céréales & Pain'
            ],
            'beverages' => [
                'en' => 'Beverages',
                'fr' => 'Boissons'
            ],
            'cleaning_products' => [
                'en' => 'Cleaning Products',
                'fr' => 'Produits d\'entretien'
            ],
            'snacks_sweets' => [
                'en' => 'Snacks & Sweets',
                'fr' => 'Snacks & Sucreries'
            ],
            'household' => [
                'en' => 'Household Items',
                'fr' => 'Articles ménagers'
            ],
            'health_beauty' => [
                'en' => 'Health & Beauty',
                'fr' => 'Santé & Beauté'
            ],
            'frozen' => [
                'en' => 'Frozen Foods',
                'fr' => 'Produits surgelés'
            ],
            'condiments_spices' => [
                'en' => 'Condiments & Spices',
                'fr' => 'Condiments & Épices'
            ],
            'baby_products' => [
                'en' => 'Baby Products',
                'fr' => 'Produits pour bébé'
            ],
            'pet_supplies' => [
                'en' => 'Pet Supplies',
                'fr' => 'Produits pour animaux'
            ],
            'other' => [
                'en' => 'Other',
                'fr' => 'Autres'
            ]
        ];
    }

    /**
     * ✅ DÉTECTION DE LA LANGUE UTILISATEUR
     */
    private function getUserLanguage(Request $request): string
    {
        // Essayer de récupérer la langue depuis les headers
        $acceptLanguage = $request->getHeaderLine('Accept-Language');
        
        // Ou depuis les paramètres de requête
        $params = $request->getQueryParams();
        $langParam = $params['lang'] ?? null;
        
        if ($langParam && in_array($langParam, ['en', 'fr'])) {
            return $langParam;
        }
        
        // Parser Accept-Language header
        if ($acceptLanguage) {
            if (strpos($acceptLanguage, 'fr') !== false) {
                return 'fr';
            }
            if (strpos($acceptLanguage, 'en') !== false) {
                return 'en';
            }
        }
        
        // Défaut : français
        return 'fr';
    }

    /**
     * ✅ VÉRIFICATION D'ACCÈS À UNE LISTE (SIMPLIFIÉE)
     */
    private function checkListAccess(int $user_id, int $list_id): ?array
    {
        // Vérifier liste propre
        $ownList = ShoppingList::where('user_id', $user_id)
            ->where('id', $list_id)
            ->first();

        if ($ownList) {
            return ['list' => $ownList, 'is_owner' => true];
        }

        // Vérifier liste partagée
        $sharedList = SharedList::with(['shoppingList'])
            ->where('shared_with_user_id', $user_id)
            ->where('list_id', $list_id)
            ->where('status', 'accepted')
            ->where('is_active', true)
            ->first();

        if ($sharedList) {
            return ['list' => $sharedList->shoppingList, 'is_owner' => false];
        }

        return null;
    }

    /**
     * ✅ QUERY BUILDER SIMPLIFIÉ POUR LES ITEMS ACCESSIBLES
     */
    private function getUserAccessibleItemsQuery(int $user_id): Builder
    {
        // Récupérer toutes les listes accessibles d'abord
        $accessibleListIds = $this->getUserAccessibleListIds($user_id);
        
        // Puis filtrer les items par ces listes
        return ListItem::whereIn('list_id', $accessibleListIds);
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Récupérer les IDs des listes accessibles
     */
    private function getUserAccessibleListIds(int $user_id): array
    {
        // Listes propres
        $ownListIds = ShoppingList::where('user_id', $user_id)
                                 ->pluck('id')
                                 ->toArray();

        // Listes partagées (récupérer les list_id depuis shared_lists)
        $sharedListIds = SharedList::where('shared_with_user_id', $user_id)
                                  ->where('status', 'accepted')
                                  ->where('is_active', true)
                                  ->pluck('list_id')
                                  ->toArray();

        return array_unique(array_merge($ownListIds, $sharedListIds));
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Obtenir les données de dépenses combinées (items + factures)
     */
    private function getCombinedSpendingData(int $user_id, Carbon $startDate, Carbon $endDate): array
    {
        $accessibleListIds = $this->getUserAccessibleListIds($user_id);
        
        if (empty($accessibleListIds)) {
            return [];
        }

        $spendingData = [];

        // 1. Données depuis les factures (priorité)
        $receipts = ListReceipt::whereIn('list_id', $accessibleListIds)
            ->whereBetween('purchase_date', [$startDate, $endDate])
            ->get();

        foreach ($receipts as $receipt) {
            $key = $receipt->purchase_date->format('Y-m-d') . '|' . $receipt->list_id . '|receipt';
            $spendingData[$key] = [
                'date' => $receipt->purchase_date,
                'amount' => $receipt->total_amount,
                'source' => 'receipt',
                'store_name' => $receipt->store_name,
                'list_id' => $receipt->list_id,
                'details' => [
                    'receipt_id' => $receipt->id,
                    'notes' => $receipt->notes
                ]
            ];
        }

        // 2. Listes qui ont des factures (pour éviter double comptage)
        $listsWithReceipts = $receipts->pluck('list_id')->unique()->toArray();

        // 3. Données depuis les items (seulement pour les listes sans factures)
        $listsForItemsData = array_diff($accessibleListIds, $listsWithReceipts);
        
        if (!empty($listsForItemsData)) {
            $items = ListItem::whereIn('list_id', $listsForItemsData)
                ->where('is_purchased', true)
                ->whereNotNull('price')
                ->whereBetween('updated_at', [$startDate, $endDate])
                ->get();

            // Grouper les items par date et liste
            foreach ($items as $item) {
                $date = $item->updated_at->toDateString();
                $key = $date . '|' . $item->list_id . '|items';
                
                if (!isset($spendingData[$key])) {
                    $spendingData[$key] = [
                        'date' => $item->updated_at,
                        'amount' => 0,
                        'source' => 'items',
                        'store_name' => $item->store_name,
                        'list_id' => $item->list_id,
                        'details' => [
                            'items_count' => 0,
                            'items' => []
                        ]
                    ];
                }
                
                $itemTotal = $item->price * $item->quantity;
                $spendingData[$key]['amount'] += $itemTotal;
                $spendingData[$key]['details']['items_count']++;
                $spendingData[$key]['details']['items'][] = [
                    'product_name' => $item->product_name,
                    'quantity' => $item->quantity,
                    'price' => $item->price,
                    'total' => $itemTotal
                ];
            }
        }

        return array_values($spendingData);
    }

    /**
     * ✅ GRAPHIQUES DE TENDANCES (CORRIGÉ)
     */
    public function spendingTrends(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period = $params['period'] ?? 'month'; // week, month, year
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur avec sa devise
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

            // Définir les périodes
            switch ($period) {
                case 'week':
                    $startDate = Carbon::now()->subWeeks(12)->startOfWeek();
                    $endDate = Carbon::now()->endOfWeek();
                    $groupFormat = 'Y-W';
                    break;
                case 'year':
                    $startDate = Carbon::now()->subYears(5)->startOfYear();
                    $endDate = Carbon::now()->endOfYear();
                    $groupFormat = 'Y';
                    break;
                default: // month
                    $startDate = Carbon::now()->subMonths(12)->startOfMonth();
                    $endDate = Carbon::now()->endOfMonth();
                    $groupFormat = 'Y-m';
                    break;
            }

            // Query items
            $items = $this->getUserAccessibleItemsQuery($user_id)
                ->where('is_purchased', true)
                ->whereNotNull('price')
                ->whereBetween('updated_at', [$startDate, $endDate])
                ->get();

            // Grouper par période
            $trendData = [];
            $currentDate = $startDate->copy();
            
            while ($currentDate->lte($endDate)) {
                $periodKey = $currentDate->format($groupFormat);
                $trendData[$periodKey] = [
                    'period' => $periodKey,
                    'period_start' => $currentDate->copy()->toDateString(),
                    'year' => $currentDate->year,
                    'month' => $period === 'month' ? $currentDate->month : null,
                    'total_spent' => 0,
                    'total_items' => 0,
                    'unique_products' => 0
                ];
                
                switch ($period) {
                    case 'week':
                        $currentDate->addWeek();
                        break;
                    case 'year':
                        $currentDate->addYear();
                        break;
                    default:
                        $currentDate->addMonth();
                        break;
                }
            }

            // Calculer les données
            $productsByPeriod = [];
            foreach ($items as $item) {
                $periodKey = $item->updated_at->format($groupFormat);
                if (isset($trendData[$periodKey])) {
                    $totalPrice = $item->price * $item->quantity;
                    $trendData[$periodKey]['total_spent'] += $totalPrice;
                    $trendData[$periodKey]['total_items'] += $item->quantity;
                    
                    // Track unique products
                    if (!isset($productsByPeriod[$periodKey])) {
                        $productsByPeriod[$periodKey] = [];
                    }
                    $productsByPeriod[$periodKey][$item->product_name] = true;
                }
            }

            // Finaliser les données
            foreach ($trendData as $periodKey => &$data) {
                $data['total_spent'] = round($data['total_spent'], 2);
                $data['unique_products'] = count($productsByPeriod[$periodKey] ?? []);
                $data['formatted_total'] = $targetCurrency->formatAmountDisplay($data['total_spent']);
            }

            // ✅ Trier les données par ordre chronologique
            $sortedTrendData = array_values($trendData);
            if ($period === 'month') {
                usort($sortedTrendData, function($a, $b) {
                    if ($a['year'] !== $b['year']) {
                        return $a['year'] <=> $b['year'];
                    }
                    return $a['month'] <=> $b['month'];
                });
            } else {
                usort($sortedTrendData, function($a, $b) {
                    return $a['period_start'] <=> $b['period_start'];
                });
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'period_type' => $period,
                    'currency' => $targetCurrency->code,
                    'trends' => $sortedTrendData,
                    'date_range' => [
                        'start' => $startDate->toDateString(),
                        'end' => $endDate->toDateString()
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'TRENDS_ERROR',
                    'message' => 'Error retrieving trend data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ DASHBOARD SIMPLIFIÉ (CORRIGÉ)
     */
    public function dashboard(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::findByCode($currency_code) : 
                ($user->currency ?? Currency::getDefault());

            // Période actuelle (mois en cours)
            $currentMonthStart = Carbon::now()->startOfMonth();
            $currentMonthEnd = Carbon::now()->endOfMonth();

            // Stats du mois actuel
            $currentMonthItems = $this->getUserAccessibleItemsQuery($user_id)
                ->where('is_purchased', true)
                ->whereNotNull('price')
                ->whereBetween('updated_at', [$currentMonthStart, $currentMonthEnd])
                ->get();

            $currentTotal = $currentMonthItems->sum(function($item) {
                return $item->price * $item->quantity;
            });

            // Données des 7 derniers jours
            $last7Days = [];
            for ($i = 6; $i >= 0; $i--) {
                $date = Carbon::now()->subDays($i);
                $dayItems = $this->getUserAccessibleItemsQuery($user_id)
                    ->where('is_purchased', true)
                    ->whereNotNull('price')
                    ->whereDate('updated_at', $date->toDateString())
                    ->get();

                $dayTotal = $dayItems->sum(function($item) {
                    return $item->price * $item->quantity;
                });

                $last7Days[] = [
                    'date' => $date->toDateString(),
                    'day_name' => $date->format('l'),
                    'total_spent' => round($dayTotal, 2),
                    'items_count' => $dayItems->sum('quantity'),
                    'formatted_total' => $targetCurrency->formatAmountDisplay($dayTotal)
                ];
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'currency' => $targetCurrency->code,
                    'current_month' => [
                        'total_spent' => round($currentTotal, 2),
                        'items_purchased' => $currentMonthItems->sum('quantity'),
                        'unique_products' => $currentMonthItems->unique('product_name')->count(),
                        'shopping_sessions' => $currentMonthItems->count(),
                        'formatted_total' => $targetCurrency->formatAmountDisplay($currentTotal)
                    ],
                    'last_7_days' => $last7Days,
                    'quick_stats' => [
                        'average_daily_spending' => round(array_sum(array_column($last7Days, 'total_spent')) / 7, 2)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'DASHBOARD_ERROR',
                    'message' => 'Error retrieving dashboard data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ COMPARAISON ENTRE PÉRIODES (SIMPLIFIÉ)
     */
    public function periodComparison(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period_type = $params['period_type'] ?? 'month'; // month, quarter, year
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::findByCode($currency_code) : 
                ($user->currency ?? Currency::getDefault());

            // Définir les périodes actuelles et précédentes
            switch ($period_type) {
                case 'quarter':
                    $currentStart = Carbon::now()->startOfQuarter();
                    $currentEnd = Carbon::now()->endOfQuarter();
                    $previousStart = Carbon::now()->subQuarter()->startOfQuarter();
                    $previousEnd = Carbon::now()->subQuarter()->endOfQuarter();
                    break;
                case 'year':
                    $currentStart = Carbon::now()->startOfYear();
                    $currentEnd = Carbon::now()->endOfYear();
                    $previousStart = Carbon::now()->subYear()->startOfYear();
                    $previousEnd = Carbon::now()->subYear()->endOfYear();
                    break;
                default: // month
                    $currentStart = Carbon::now()->startOfMonth();
                    $currentEnd = Carbon::now()->endOfMonth();
                    $previousStart = Carbon::now()->subMonth()->startOfMonth();
                    $previousEnd = Carbon::now()->subMonth()->endOfMonth();
                    break;
            }

            // Fonction pour calculer les stats d'une période
            $calculatePeriodStats = function($startDate, $endDate) use ($user_id) {
                $items = $this->getUserAccessibleItemsQuery($user_id)
                    ->where('is_purchased', true)
                    ->whereNotNull('price')
                    ->whereBetween('updated_at', [$startDate, $endDate])
                    ->get();

                $totalSpent = 0;
                $totalItems = 0;
                $uniqueProducts = [];

                foreach ($items as $item) {
                    $itemTotal = $item->price * $item->quantity;
                    $totalSpent += $itemTotal;
                    $totalItems += $item->quantity;
                    $uniqueProducts[$item->product_name] = true;
                }

                return [
                    'total_spent' => round($totalSpent, 2),
                    'total_items' => $totalItems,
                    'unique_products' => count($uniqueProducts),
                    'average_item_price' => $totalItems > 0 ? round($totalSpent / $totalItems, 2) : 0,
                    'shopping_sessions' => count($items)
                ];
            };

            $currentStats = $calculatePeriodStats($currentStart, $currentEnd);
            $previousStats = $calculatePeriodStats($previousStart, $previousEnd);

            // Calculer les changements
            $changes = [];
            foreach ($currentStats as $key => $currentValue) {
                if (is_numeric($currentValue) && is_numeric($previousStats[$key])) {
                    $change = $previousStats[$key] > 0 ? 
                        round((($currentValue - $previousStats[$key]) / $previousStats[$key]) * 100, 1) : 0;
                    $changes[$key] = [
                        'absolute' => round($currentValue - $previousStats[$key], 2),
                        'percentage' => $change
                    ];
                }
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'period_type' => $period_type,
                    'currency' => $targetCurrency->code,
                    'current_period' => [
                        'start' => $currentStart->toDateString(),
                        'end' => $currentEnd->toDateString(),
                        'stats' => $currentStats,
                        'formatted_total' => $targetCurrency->formatAmountDisplay($currentStats['total_spent'])
                    ],
                    'previous_period' => [
                        'start' => $previousStart->toDateString(),
                        'end' => $previousEnd->toDateString(),
                        'stats' => $previousStats,
                        'formatted_total' => $targetCurrency->formatAmountDisplay($previousStats['total_spent'])
                    ],
                    'changes' => $changes,
                    'summary' => [
                        'spending_trend' => $changes['total_spent']['percentage'] > 0 ? 'increased' : 
                                          ($changes['total_spent']['percentage'] < 0 ? 'decreased' : 'stable'),
                        'efficiency_change' => $changes['average_item_price']['percentage']
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'COMPARISON_ERROR',
                    'message' => 'Error retrieving comparison data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ DÉPENSES PAR CATÉGORIE (AVEC SUPPORT I18N)
     */
    public function spendingByCategory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period = $params['period'] ?? 'month'; // week, month, quarter, year, all
            $currency_code = $params['currency'] ?? null;
            $limit = min((int)($params['limit'] ?? 20), 50);
            
            // ✅ Détecter la langue
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::findByCode($currency_code) : 
                ($user->currency ?? Currency::getDefault());

            // Définir la période
            $startDate = match($period) {
                'week' => Carbon::now()->subWeek(),
                'quarter' => Carbon::now()->subQuarter(),
                'year' => Carbon::now()->subYear(),
                'all' => Carbon::create(2020, 1, 1),
                default => Carbon::now()->subMonth()
            };

            // Récupérer les items
            $query = $this->getUserAccessibleItemsQuery($user_id)
                ->where('is_purchased', true)
                ->whereNotNull('price');

            if ($period !== 'all') {
                $query->where('updated_at', '>=', $startDate);
            }

            $items = $query->get();

            // Catégoriser les produits avec la langue
            $categories = $this->categorizeProducts($items, $language);

            // Trier par dépenses totales
            uasort($categories, function($a, $b) {
                return $b['total_spent'] <=> $a['total_spent'];
            });

            // Limiter les résultats
            $categories = array_slice($categories, 0, $limit, true);

            // Calculer le total pour les pourcentages
            $grandTotal = array_sum(array_column($categories, 'total_spent'));

            // Formater les données
            $formattedCategories = [];
            foreach ($categories as $categoryName => $data) {
                $percentage = $grandTotal > 0 ? round(($data['total_spent'] / $grandTotal) * 100, 1) : 0;
                
                $formattedCategories[] = [
                    'category' => $categoryName,
                    'category_key' => $data['category_key'], // ✅ Clé pour identification côté client
                    'total_spent' => round($data['total_spent'], 2),
                    'total_items' => $data['total_items'],
                    'unique_products' => $data['unique_products'],
                    'average_price' => round($data['average_price'], 2),
                    'percentage_of_total' => $percentage,
                    'formatted_total' => $targetCurrency->formatAmountDisplay($data['total_spent']),
                    'formatted_average' => $targetCurrency->formatAmountDisplay($data['average_price']),
                    'top_products' => array_slice($data['top_products'], 0, 5)
                ];
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'period' => $period,
                    'language' => $language, // ✅ Indiquer la langue utilisée
                    'currency' => $targetCurrency->code,
                    'categories' => $formattedCategories,
                    'summary' => [
                        'total_spent' => round($grandTotal, 2),
                        'total_categories' => count($formattedCategories),
                        'period_start' => $period !== 'all' ? $startDate->toDateString() : null,
                        'formatted_total' => $targetCurrency->formatAmountDisplay($grandTotal)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'CATEGORY_ERROR',
                    'message' => 'Error retrieving category data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ TOP PRODUITS (AVEC SUPPORT I18N)
     */
    public function topProducts(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period = $params['period'] ?? 'month';
            $sort_by = $params['sort_by'] ?? 'total_spent'; // total_spent, quantity, frequency
            $currency_code = $params['currency'] ?? null;
            $limit = min((int)($params['limit'] ?? 10), 50);
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::findByCode($currency_code) : 
                ($user->currency ?? Currency::getDefault());

            // Définir la période
            $startDate = match($period) {
                'week' => Carbon::now()->subWeek(),
                'quarter' => Carbon::now()->subQuarter(),
                'year' => Carbon::now()->subYear(),
                'all' => Carbon::create(2020, 1, 1),
                default => Carbon::now()->subMonth()
            };

            // Récupérer les items
            $query = $this->getUserAccessibleItemsQuery($user_id)
                ->where('is_purchased', true);

            if ($period !== 'all') {
                $query->where('updated_at', '>=', $startDate);
            }

            $items = $query->get();

            // Grouper par produit
            $productStats = [];
            foreach ($items as $item) {
                $productName = $item->product_name;
                
                if (!isset($productStats[$productName])) {
                    $productStats[$productName] = [
                        'product_name' => $productName,
                        'total_spent' => 0,
                        'total_quantity' => 0,
                        'purchase_frequency' => 0,
                        'average_price' => 0,
                        'stores' => [],
                        'last_purchased' => null
                    ];
                }

                $itemTotal = ($item->price ?? 0) * $item->quantity;
                $productStats[$productName]['total_spent'] += $itemTotal;
                $productStats[$productName]['total_quantity'] += $item->quantity;
                $productStats[$productName]['purchase_frequency']++;
                
                if ($item->store_name) {
                    $productStats[$productName]['stores'][$item->store_name] = true;
                }

                if (!$productStats[$productName]['last_purchased'] || 
                    $item->updated_at > $productStats[$productName]['last_purchased']) {
                    $productStats[$productName]['last_purchased'] = $item->updated_at;
                }
            }

            // Calculer les moyennes et finaliser
            foreach ($productStats as &$stats) {
                $stats['average_price'] = $stats['purchase_frequency'] > 0 ? 
                    $stats['total_spent'] / $stats['total_quantity'] : 0;
                $stats['stores'] = array_keys($stats['stores']);
                $stats['unique_stores'] = count($stats['stores']);
            }

            // Trier selon le critère choisi
            uasort($productStats, function($a, $b) use ($sort_by) {
                return match($sort_by) {
                    'quantity' => $b['total_quantity'] <=> $a['total_quantity'],
                    'frequency' => $b['purchase_frequency'] <=> $a['purchase_frequency'],
                    default => $b['total_spent'] <=> $a['total_spent']
                };
            });

            // Limiter et formater
            $topProducts = array_slice(array_values($productStats), 0, $limit);
            
            foreach ($topProducts as &$product) {
                $product['total_spent'] = round($product['total_spent'], 2);
                $product['average_price'] = round($product['average_price'], 2);
                $product['formatted_total'] = $targetCurrency->formatAmountDisplay($product['total_spent']);
                $product['formatted_average'] = $targetCurrency->formatAmountDisplay($product['average_price']);
                $product['last_purchased'] = $product['last_purchased']->toDateString();
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'period' => $period,
                    'sort_by' => $sort_by,
                    'currency' => $targetCurrency->code,
                    'products' => $topProducts,
                    'summary' => [
                        'total_unique_products' => count($productStats),
                        'showing_top' => count($topProducts),
                        'period_start' => $period !== 'all' ? $startDate->toDateString() : null
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'TOP_PRODUCTS_ERROR',
                    'message' => 'Error retrieving top products data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ MÉTHODE PRIVÉE POUR CATÉGORISER LES PRODUITS (AVEC I18N)
     */
    private function categorizeProducts($items, string $language = 'fr'): array
    {
        $categories = [];
        $translations = $this->getCategoryTranslations();
        
        // Définition des catégories avec mots-clés (en français et anglais)
        $categoryKeywords = [
            'fruits_vegetables' => [
                'pomme', 'banana', 'orange', 'tomate', 'carotte', 'oignon', 'pommes de terre',
                'apple', 'tomato', 'potato', 'onion', 'carrot', 'lettuce', 'spinach',
                'fruit', 'légume', 'vegetable', 'avocado', 'avocat', 'broccoli', 'brocoli',
                'concombre', 'cucumber', 'poivron', 'pepper', 'celery', 'céleri', 'corn', 'maïs',
                'cabbage', 'chou', 'radish', 'radis', 'turnip', 'navet', 'beet', 'betterave'
            ],
            'meat_fish' => [
                'poulet', 'boeuf', 'porc', 'saumon', 'thon', 'chicken', 'beef', 'pork',
                'fish', 'meat', 'viande', 'poisson', 'steak', 'bacon', 'ham', 'jambon',
                'turkey', 'dinde', 'lamb', 'agneau', 'shrimp', 'crevette', 'cod', 'morue',
                'trout', 'truite', 'sardine', 'mackerel', 'maquereau'
            ],
            'dairy' => [
                'lait', 'fromage', 'yaourt', 'beurre', 'milk', 'cheese', 'yogurt',
                'butter', 'cream', 'crème', 'dairy', 'laitier', 'mozzarella', 'cheddar',
                'goat cheese', 'fromage de chèvre', 'feta', 'parmesan'
            ],
            'grains_bread' => [
                'pain', 'pâtes', 'riz', 'bread', 'pasta', 'rice', 'cereal', 'céréales',
                'flour', 'farine', 'oats', 'avoine', 'quinoa', 'bagel', 'croissant',
                'noodles', 'nouilles', 'crackers', 'biscuits salés', 'tortilla'
            ],
            'beverages' => [
                'eau', 'jus', 'café', 'thé', 'water', 'juice', 'coffee', 'tea',
                'soda', 'beer', 'bière', 'vin', 'wine', 'beverage', 'boisson',
                'sprite', 'coca', 'pepsi', 'sparkling water', 'eau pétillante'
            ],
            'cleaning_products' => [
                'détergent', 'savon', 'shampoing', 'soap', 'detergent', 'shampoo',
                'cleaning', 'nettoyage', 'toilet paper', 'papier toilette', 'bleach',
                'javel', 'dishwasher', 'lave-vaisselle', 'sponge', 'éponge'
            ],
            'snacks_sweets' => [
                'chocolat', 'biscuit', 'chips', 'chocolate', 'cookie', 'candy',
                'bonbon', 'gâteau', 'cake', 'ice cream', 'glace', 'nuts', 'noix',
                'popcorn', 'maïs soufflé', 'pretzel', 'crackers'
            ],
            'household' => [
                'batteries', 'piles', 'aluminum foil', 'papier aluminium', 'plastic wrap',
                'pellicule plastique', 'napkins', 'serviettes', 'candles', 'bougies',
                'light bulb', 'ampoule', 'garbage bags', 'sacs poubelle'
            ],
            'health_beauty' => [
                'toothpaste', 'dentifrice', 'deodorant', 'déodorant', 'vitamins',
                'vitamines', 'band-aid', 'pansement', 'moisturizer', 'hydratant',
                'sunscreen', 'crème solaire', 'makeup', 'maquillage'
            ],
            'frozen' => [
                'frozen', 'surgelé', 'ice', 'glace', 'frozen pizza', 'pizza surgelée',
                'frozen vegetables', 'légumes surgelés', 'frozen fruits', 'fruits surgelés',
                'ice cream', 'crème glacée'
            ],
            'condiments_spices' => [
                'salt', 'sel', 'pepper', 'poivre', 'ketchup', 'mustard', 'moutarde',
                'mayonnaise', 'vinegar', 'vinaigre', 'spice', 'épice', 'garlic', 'ail',
                'onion powder', 'poudre d\'oignon', 'paprika', 'oregano', 'origan'
            ],
            'baby_products' => [
                'diapers', 'couches', 'baby food', 'nourriture bébé', 'formula',
                'lait maternisé', 'baby', 'bébé', 'baby wipes', 'lingettes bébé'
            ],
            'pet_supplies' => [
                'dog food', 'nourriture chien', 'cat food', 'nourriture chat',
                'pet', 'animal', 'litter', 'litière', 'dog treats', 'gâteries chien'
            ]
        ];

        foreach ($items as $item) {
            $productName = strtolower($item->product_name);
            $categorized = false;
            
            // Essayer de catégoriser
            foreach ($categoryKeywords as $categoryKey => $keywords) {
                foreach ($keywords as $keyword) {
                    if (strpos($productName, strtolower($keyword)) !== false) {
                        // ✅ Utiliser le nom traduit selon la langue
                        $categoryName = $translations[$categoryKey][$language];
                        
                        if (!isset($categories[$categoryName])) {
                            $categories[$categoryName] = [
                                'category_key' => $categoryKey, // ✅ Clé pour identification
                                'total_spent' => 0,
                                'total_items' => 0,
                                'unique_products' => 0,
                                'average_price' => 0,
                                'top_products' => []
                            ];
                        }
                        
                        $itemTotal = ($item->price ?? 0) * $item->quantity;
                        $categories[$categoryName]['total_spent'] += $itemTotal;
                        $categories[$categoryName]['total_items'] += $item->quantity;
                        
                        // Track top products
                        if (!isset($categories[$categoryName]['top_products'][$item->product_name])) {
                            $categories[$categoryName]['top_products'][$item->product_name] = 0;
                        }
                        $categories[$categoryName]['top_products'][$item->product_name] += $itemTotal;
                        
                        $categorized = true;
                        break 2;
                    }
                }
            }
            
            // Si pas catégorisé, mettre dans "Autres"
            if (!$categorized) {
                $otherCategoryName = $translations['other'][$language];
                
                if (!isset($categories[$otherCategoryName])) {
                    $categories[$otherCategoryName] = [
                        'category_key' => 'other',
                        'total_spent' => 0,
                        'total_items' => 0,
                        'unique_products' => 0,
                        'average_price' => 0,
                        'top_products' => []
                    ];
                }
                
                $itemTotal = ($item->price ?? 0) * $item->quantity;
                $categories[$otherCategoryName]['total_spent'] += $itemTotal;
                $categories[$otherCategoryName]['total_items'] += $item->quantity;
                
                if (!isset($categories[$otherCategoryName]['top_products'][$item->product_name])) {
                    $categories[$otherCategoryName]['top_products'][$item->product_name] = 0;
                }
                $categories[$otherCategoryName]['top_products'][$item->product_name] += $itemTotal;
            }
        }

        // Finaliser les calculs
        foreach ($categories as &$category) {
            $category['unique_products'] = count($category['top_products']);
            $category['average_price'] = $category['total_items'] > 0 ? 
                $category['total_spent'] / $category['total_items'] : 0;
            
            // Trier les top products
            arsort($category['top_products']);
            $category['top_products'] = array_keys($category['top_products']);
        }

        return $categories;
    }

    /**
     * ✅ HISTORIQUE DES DÉPENSES PAR JOUR (7-30 derniers jours)
     */
    public function dailySpendingHistory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            // Paramètres avec valeurs par défaut
            $days = min((int)($params['days'] ?? 30), 90); // Max 90 jours
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur avec sa devise
            $user = User::with('currency')->find($user_id);
            if (!$user) {
                throw new \Exception('User not found');
            }

            // Déterminer la devise cible
            if ($currency_code) {
                $targetCurrency = Currency::findByCode($currency_code);
                if (!$targetCurrency) {
                    throw new \Exception('Invalid currency code');
                }
            } else {
                $targetCurrency = $user->currency ?? Currency::getDefault();
            }

            // Calculer les dates
            $endDate = Carbon::now()->endOfDay();
            $startDate = Carbon::now()->subDays($days - 1)->startOfDay();

            // Query pour les items achetés avec prix
            $items = $this->getUserAccessibleItemsQuery($user_id)
                ->where('is_purchased', true)
                ->whereNotNull('price')
                ->whereBetween('updated_at', [$startDate, $endDate])
                ->get();

            // Créer les données par jour
            $dailyData = [];
            $currentDate = $startDate->copy();
            
            while ($currentDate->lte($endDate)) {
                $dateKey = $currentDate->format('Y-m-d');
                $dailyData[$dateKey] = [
                    'date' => $dateKey,
                    'day_name' => $currentDate->format('l'),
                    'day_short' => $currentDate->format('D'),
                    'day_number' => $currentDate->day,
                    'month_name' => $currentDate->format('F'),
                    'total_spent' => 0,
                    'total_items' => 0,
                    'shopping_sessions' => 0,
                    'average_item_price' => 0,
                    'currency' => $targetCurrency->code
                ];
                $currentDate->addDay();
            }

            // Calculer les totaux par jour
            $sessionsByDay = [];
            foreach ($items as $item) {
                $dateKey = $item->updated_at->format('Y-m-d');
                if (isset($dailyData[$dateKey])) {
                    $totalPrice = $item->price * $item->quantity;
                    $dailyData[$dateKey]['total_spent'] += $totalPrice;
                    $dailyData[$dateKey]['total_items'] += $item->quantity;
                    
                    // Compter les sessions (groupées par liste et heure)
                    $sessionKey = $dateKey . '-' . $item->list_id . '-' . $item->updated_at->format('H');
                    $sessionsByDay[$dateKey][$sessionKey] = true;
                }
            }

            // Finaliser les calculs et formater
            foreach ($dailyData as $dateKey => &$day) {
                $day['shopping_sessions'] = count($sessionsByDay[$dateKey] ?? []);
                if ($day['total_items'] > 0) {
                    $day['average_item_price'] = round($day['total_spent'] / $day['total_items'], 2);
                }
                $day['total_spent'] = round($day['total_spent'], 2);
                $day['formatted_total'] = $targetCurrency->formatAmountDisplay($day['total_spent']);
                $day['formatted_average'] = $targetCurrency->formatAmountDisplay($day['average_item_price']);
            }

            // Trier par date
            $sortedDailyData = array_values($dailyData);
            usort($sortedDailyData, function($a, $b) {
                return $a['date'] <=> $b['date'];
            });

            // Calculs de tendance
            $values = array_column($sortedDailyData, 'total_spent');
            $totalSpent = array_sum($values);
            $averageDaily = count($values) > 0 ? $totalSpent / count($values) : 0;
            
            // Tendance (comparaison des 7 derniers jours vs 7 précédents)
            $recentDays = array_slice($values, -7);
            $previousDays = array_slice($values, -14, 7);
            $recentAvg = count($recentDays) > 0 ? array_sum($recentDays) / count($recentDays) : 0;
            $previousAvg = count($previousDays) > 0 ? array_sum($previousDays) / count($previousDays) : 0;
            
            $trendPercentage = $previousAvg > 0 ? 
                round((($recentAvg - $previousAvg) / $previousAvg) * 100, 1) : 0;

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'daily_data' => $sortedDailyData,
                    'summary' => [
                        'total_spent' => round($totalSpent, 2),
                        'average_daily' => round($averageDaily, 2),
                        'currency' => $targetCurrency->code,
                        'period' => [
                            'start' => $startDate->toDateString(),
                            'end' => $endDate->toDateString(),
                            'days' => $days
                        ],
                        'trend' => [
                            'percentage' => $trendPercentage,
                            'direction' => $trendPercentage > 0 ? 'increasing' : ($trendPercentage < 0 ? 'decreasing' : 'stable'),
                            'recent_average' => round($recentAvg, 2),
                            'previous_average' => round($previousAvg, 2)
                        ],
                        'formatted_total' => $targetCurrency->formatAmountDisplay($totalSpent),
                        'formatted_average_daily' => $targetCurrency->formatAmountDisplay($averageDaily)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'DAILY_ANALYTICS_ERROR',
                    'message' => 'Error retrieving daily spending data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ HISTORIQUE DES DÉPENSES PAR SEMAINE (12-52 dernières semaines)
     */
    public function weeklySpendingHistory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            // Paramètres avec valeurs par défaut
            $weeks = min((int)($params['weeks'] ?? 12), 52); // Max 52 semaines
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur avec sa devise
            $user = User::with('currency')->find($user_id);
            if (!$user) {
                throw new \Exception('User not found');
            }

            // Déterminer la devise cible
            if ($currency_code) {
                $targetCurrency = Currency::findByCode($currency_code);
                if (!$targetCurrency) {
                    throw new \Exception('Invalid currency code');
                }
            } else {
                $targetCurrency = $user->currency ?? Currency::getDefault();
            }

            // Calculer les dates (commencer par le début de la semaine actuelle)
            $endDate = Carbon::now()->endOfWeek();
            $startDate = Carbon::now()->subWeeks($weeks - 1)->startOfWeek();

            // Query pour les items achetés avec prix
            $items = $this->getUserAccessibleItemsQuery($user_id)
                ->where('is_purchased', true)
                ->whereNotNull('price')
                ->whereBetween('updated_at', [$startDate, $endDate])
                ->get();

            // Créer les données par semaine
            $weeklyData = [];
            $currentDate = $startDate->copy();
            
            while ($currentDate->lte($endDate)) {
                $weekKey = $currentDate->format('Y-W');
                $weekStart = $currentDate->copy()->startOfWeek();
                $weekEnd = $currentDate->copy()->endOfWeek();
                
                $weeklyData[$weekKey] = [
                    'week' => $weekKey,
                    'week_number' => $currentDate->week,
                    'year' => $currentDate->year,
                    'week_start' => $weekStart->toDateString(),
                    'week_end' => $weekEnd->toDateString(),
                    'week_label' => $weekStart->format('M j') . ' - ' . $weekEnd->format('M j, Y'),
                    'total_spent' => 0,
                    'total_items' => 0,
                    'shopping_days' => 0,
                    'average_item_price' => 0,
                    'currency' => $targetCurrency->code
                ];
                $currentDate->addWeek();
            }

            // Calculer les totaux par semaine
            $daysByWeek = [];
            foreach ($items as $item) {
                $weekKey = $item->updated_at->format('Y-W');
                if (isset($weeklyData[$weekKey])) {
                    $totalPrice = $item->price * $item->quantity;
                    $weeklyData[$weekKey]['total_spent'] += $totalPrice;
                    $weeklyData[$weekKey]['total_items'] += $item->quantity;
                    
                    // Compter les jours de shopping uniques
                    $dayKey = $item->updated_at->format('Y-m-d');
                    $daysByWeek[$weekKey][$dayKey] = true;
                }
            }

            // Finaliser les calculs et formater
            foreach ($weeklyData as $weekKey => &$week) {
                $week['shopping_days'] = count($daysByWeek[$weekKey] ?? []);
                if ($week['total_items'] > 0) {
                    $week['average_item_price'] = round($week['total_spent'] / $week['total_items'], 2);
                }
                $week['total_spent'] = round($week['total_spent'], 2);
                $week['formatted_total'] = $targetCurrency->formatAmountDisplay($week['total_spent']);
                $week['formatted_average'] = $targetCurrency->formatAmountDisplay($week['average_item_price']);
            }

            // Trier par semaine
            $sortedWeeklyData = array_values($weeklyData);
            usort($sortedWeeklyData, function($a, $b) {
                if ($a['year'] !== $b['year']) {
                    return $a['year'] <=> $b['year'];
                }
                return $a['week_number'] <=> $b['week_number'];
            });

            // Calculs de tendance
            $values = array_column($sortedWeeklyData, 'total_spent');
            $totalSpent = array_sum($values);
            $averageWeekly = count($values) > 0 ? $totalSpent / count($values) : 0;
            
            // Tendance (comparaison des 4 dernières semaines vs 4 précédentes)
            $recentWeeks = array_slice($values, -4);
            $previousWeeks = array_slice($values, -8, 4);
            $recentAvg = count($recentWeeks) > 0 ? array_sum($recentWeeks) / count($recentWeeks) : 0;
            $previousAvg = count($previousWeeks) > 0 ? array_sum($previousWeeks) / count($previousWeeks) : 0;
            
            $trendPercentage = $previousAvg > 0 ? 
                round((($recentAvg - $previousAvg) / $previousAvg) * 100, 1) : 0;

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'weekly_data' => $sortedWeeklyData,
                    'summary' => [
                        'total_spent' => round($totalSpent, 2),
                        'average_weekly' => round($averageWeekly, 2),
                        'currency' => $targetCurrency->code,
                        'period' => [
                            'start' => $startDate->toDateString(),
                            'end' => $endDate->toDateString(),
                            'weeks' => $weeks
                        ],
                        'trend' => [
                            'percentage' => $trendPercentage,
                            'direction' => $trendPercentage > 0 ? 'increasing' : ($trendPercentage < 0 ? 'decreasing' : 'stable'),
                            'recent_average' => round($recentAvg, 2),
                            'previous_average' => round($previousAvg, 2)
                        ],
                        'formatted_total' => $targetCurrency->formatAmountDisplay($totalSpent),
                        'formatted_average_weekly' => $targetCurrency->formatAmountDisplay($averageWeekly)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'WEEKLY_ANALYTICS_ERROR',
                    'message' => 'Error retrieving weekly spending data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ HISTORIQUE DES DÉPENSES PAR ANNÉE (5-10 dernières années)
     */
    public function yearlySpendingHistory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            // Paramètres avec valeurs par défaut
            $years = min((int)($params['years'] ?? 5), 10); // Max 10 ans
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur avec sa devise
            $user = User::with('currency')->find($user_id);
            if (!$user) {
                throw new \Exception('User not found');
            }

            // Déterminer la devise cible
            if ($currency_code) {
                $targetCurrency = Currency::findByCode($currency_code);
                if (!$targetCurrency) {
                    throw new \Exception('Invalid currency code');
                }
            } else {
                $targetCurrency = $user->currency ?? Currency::getDefault();
            }

            // Calculer les dates
            $currentYear = Carbon::now()->year;
            $startYear = $currentYear - $years + 1;
            $endYear = $currentYear;

            $startDate = Carbon::create($startYear, 1, 1)->startOfYear();
            $endDate = Carbon::create($endYear, 12, 31)->endOfYear();

            // Query pour les items achetés avec prix
            $items = $this->getUserAccessibleItemsQuery($user_id)
                ->where('is_purchased', true)
                ->whereNotNull('price')
                ->whereBetween('updated_at', [$startDate, $endDate])
                ->get();

            // Créer les données par année
            $yearlyData = [];
            for ($year = $startYear; $year <= $endYear; $year++) {
                $yearlyData[$year] = [
                    'year' => $year,
                    'year_label' => (string)$year,
                    'is_current_year' => $year === $currentYear,
                    'total_spent' => 0,
                    'total_items' => 0,
                    'shopping_months' => 0,
                    'shopping_days' => 0,
                    'average_item_price' => 0,
                    'average_monthly' => 0,
                    'currency' => $targetCurrency->code
                ];
            }

            // Calculer les totaux par année
            $monthsByYear = [];
            $daysByYear = [];
            
            foreach ($items as $item) {
                $year = $item->updated_at->year;
                if (isset($yearlyData[$year])) {
                    $totalPrice = $item->price * $item->quantity;
                    $yearlyData[$year]['total_spent'] += $totalPrice;
                    $yearlyData[$year]['total_items'] += $item->quantity;
                    
                    // Compter les mois et jours de shopping uniques
                    $monthKey = $item->updated_at->format('Y-m');
                    $dayKey = $item->updated_at->format('Y-m-d');
                    $monthsByYear[$year][$monthKey] = true;
                    $daysByYear[$year][$dayKey] = true;
                }
            }

            // Finaliser les calculs et formater
            foreach ($yearlyData as $year => &$data) {
                $data['shopping_months'] = count($monthsByYear[$year] ?? []);
                $data['shopping_days'] = count($daysByYear[$year] ?? []);
                
                if ($data['total_items'] > 0) {
                    $data['average_item_price'] = round($data['total_spent'] / $data['total_items'], 2);
                }
                
                if ($data['shopping_months'] > 0) {
                    $data['average_monthly'] = round($data['total_spent'] / $data['shopping_months'], 2);
                }
                
                $data['total_spent'] = round($data['total_spent'], 2);
                $data['formatted_total'] = $targetCurrency->formatAmountDisplay($data['total_spent']);
                $data['formatted_average_item'] = $targetCurrency->formatAmountDisplay($data['average_item_price']);
                $data['formatted_average_monthly'] = $targetCurrency->formatAmountDisplay($data['average_monthly']);
            }

            // Trier par année
            $sortedYearlyData = array_values($yearlyData);
            usort($sortedYearlyData, function($a, $b) {
                return $a['year'] <=> $b['year'];
            });

            // Calculs de tendance
            $values = array_column($sortedYearlyData, 'total_spent');
            $totalSpent = array_sum($values);
            $averageYearly = count($values) > 0 ? $totalSpent / count($values) : 0;
            
            // Tendance (comparaison année actuelle vs précédente)
            $currentYearSpending = end($values);
            $previousYearSpending = count($values) > 1 ? $values[count($values) - 2] : 0;
            
            $trendPercentage = $previousYearSpending > 0 ? 
                round((($currentYearSpending - $previousYearSpending) / $previousYearSpending) * 100, 1) : 0;

            // Année avec le plus de dépenses
            $maxSpendingYear = null;
            $maxSpending = 0;
            foreach ($sortedYearlyData as $yearData) {
                if ($yearData['total_spent'] > $maxSpending) {
                    $maxSpending = $yearData['total_spent'];
                    $maxSpendingYear = $yearData['year'];
                }
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'yearly_data' => $sortedYearlyData,
                    'summary' => [
                        'total_spent' => round($totalSpent, 2),
                        'average_yearly' => round($averageYearly, 2),
                        'currency' => $targetCurrency->code,
                        'period' => [
                            'start_year' => $startYear,
                            'end_year' => $endYear,
                            'years' => $years
                        ],
                        'trend' => [
                            'percentage' => $trendPercentage,
                            'direction' => $trendPercentage > 0 ? 'increasing' : ($trendPercentage < 0 ? 'decreasing' : 'stable'),
                            'current_year_spending' => round($currentYearSpending, 2),
                            'previous_year_spending' => round($previousYearSpending, 2)
                        ],
                        'insights' => [
                            'highest_spending_year' => $maxSpendingYear,
                            'highest_spending_amount' => round($maxSpending, 2),
                            'formatted_highest' => $targetCurrency->formatAmountDisplay($maxSpending)
                        ],
                        'formatted_total' => $targetCurrency->formatAmountDisplay($totalSpent),
                        'formatted_average_yearly' => $targetCurrency->formatAmountDisplay($averageYearly)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'YEARLY_ANALYTICS_ERROR',
                    'message' => 'Error retrieving yearly spending data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ DÉPENSES PAR MAGASIN (AVEC FACTURES PRIORITAIRES)
     */
    public function spendingByStore(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period = $params['period'] ?? 'month';
            $currency_code = $params['currency'] ?? null;
            $limit = min((int)($params['limit'] ?? 20), 50);
            $language = $this->getUserLanguage($request);
            
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::findByCode($currency_code) : 
                ($user->currency ?? Currency::getDefault());

            // Définir la période
            $startDate = match($period) {
                'week' => Carbon::now()->subWeek(),
                'quarter' => Carbon::now()->subQuarter(),
                'year' => Carbon::now()->subYear(),
                'all' => Carbon::create(2020, 1, 1),
                default => Carbon::now()->subMonth()
            };

            $endDate = Carbon::now()->endOfDay();

            // Obtenir les données combinées
            $spendingData = $this->getCombinedSpendingData($user_id, $startDate, $endDate);

            // Grouper par magasin
            $storeStats = [];
            foreach ($spendingData as $spending) {
                $storeName = $spending['store_name'] ?? 'Non spécifié';
                
                if (!isset($storeStats[$storeName])) {
                    $storeStats[$storeName] = [
                        'store_name' => $storeName,
                        'total_spent' => 0,
                        'receipts_total' => 0,
                        'items_total' => 0,
                        'transactions_count' => 0,
                        'receipts_count' => 0,
                        'items_sessions' => 0,
                        'last_visit' => null,
                        'data_sources' => []
                    ];
                }
                
                $storeStats[$storeName]['total_spent'] += $spending['amount'];
                $storeStats[$storeName]['transactions_count']++;
                
                if ($spending['source'] === 'receipt') {
                    $storeStats[$storeName]['receipts_total'] += $spending['amount'];
                    $storeStats[$storeName]['receipts_count']++;
                } else {
                    $storeStats[$storeName]['items_total'] += $spending['amount'];
                    $storeStats[$storeName]['items_sessions']++;
                }
                
                if (!$storeStats[$storeName]['last_visit'] || 
                    $spending['date'] > $storeStats[$storeName]['last_visit']) {
                    $storeStats[$storeName]['last_visit'] = $spending['date'];
                }
                
                $storeStats[$storeName]['data_sources'][] = $spending['source'];
            }

            // Trier par montant total
            uasort($storeStats, function($a, $b) {
                return $b['total_spent'] <=> $a['total_spent'];
            });

            // Limiter et formater
            $storeStats = array_slice($storeStats, 0, $limit, true);
            $grandTotal = array_sum(array_column($storeStats, 'total_spent'));

            $formattedStores = [];
            foreach ($storeStats as $storeName => $data) {
                $percentage = $grandTotal > 0 ? round(($data['total_spent'] / $grandTotal) * 100, 1) : 0;
                $dataQuality = $data['receipts_total'] > 0 ? 'high' : ($data['items_total'] > 0 ? 'medium' : 'low');
                
                $formattedStores[] = [
                    'store_name' => $storeName,
                    'total_spent' => round($data['total_spent'], 2),
                    'receipts_total' => round($data['receipts_total'], 2),
                    'items_total' => round($data['items_total'], 2),
                    'transactions_count' => $data['transactions_count'],
                    'receipts_count' => $data['receipts_count'],
                    'items_sessions' => $data['items_sessions'],
                    'percentage_of_total' => $percentage,
                    'data_quality' => $dataQuality,
                    'primary_source' => $data['receipts_total'] > $data['items_total'] ? 'receipts' : 'items',
                    'last_visit' => $data['last_visit'] ? $data['last_visit']->toDateString() : null,
                    'formatted_total' => $targetCurrency->formatAmountDisplay($data['total_spent']),
                    'formatted_receipts' => $targetCurrency->formatAmountDisplay($data['receipts_total']),
                    'formatted_items' => $targetCurrency->formatAmountDisplay($data['items_total'])
                ];
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'period' => $period,
                    'language' => $language,
                    'currency' => $targetCurrency->code,
                    'stores' => $formattedStores,
                    'summary' => [
                        'total_spent' => round($grandTotal, 2),
                        'total_stores' => count($formattedStores),
                        'period_start' => $period !== 'all' ? $startDate->toDateString() : null,
                        'formatted_total' => $targetCurrency->formatAmountDisplay($grandTotal),
                        'data_quality_distribution' => [
                            'high' => count(array_filter($formattedStores, fn($s) => $s['data_quality'] === 'high')),
                            'medium' => count(array_filter($formattedStores, fn($s) => $s['data_quality'] === 'medium')),
                            'low' => count(array_filter($formattedStores, fn($s) => $s['data_quality'] === 'low'))
                        ]
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'STORE_ANALYTICS_ERROR',
                    'message' => 'Error retrieving store spending data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Rapport de qualité des données
     */
    public function dataQualityReport(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $language = $this->getUserLanguage($request);
            
            $accessibleListIds = $this->getUserAccessibleListIds($user_id);
            
            if (empty($accessibleListIds)) {
                $response->getBody()->write(json_encode([
                    'success' => true,
                    'data' => [
                        'language' => $language,
                        'total_lists' => 0,
                        'data_quality' => 'no_data'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            // Statistiques par liste
            $lists = ShoppingList::whereIn('id', $accessibleListIds)
                ->with(['receipts', 'items'])
                ->get();

            $report = [
                'total_lists' => $lists->count(),
                'lists_with_receipts' => 0,
                'lists_with_item_prices' => 0,
                'lists_with_both' => 0,
                'lists_with_no_pricing' => 0,
                'total_receipts' => 0,
                'total_items_with_prices' => 0,
                'recommendations' => []
            ];

            foreach ($lists as $list) {
                $hasReceipts = $list->receipts->isNotEmpty();
                $hasItemPrices = $list->items->where('is_purchased', true)->whereNotNull('price')->isNotEmpty();
                
                if ($hasReceipts) $report['lists_with_receipts']++;
                if ($hasItemPrices) $report['lists_with_item_prices']++;
                if ($hasReceipts && $hasItemPrices) $report['lists_with_both']++;
                if (!$hasReceipts && !$hasItemPrices) $report['lists_with_no_pricing']++;
                
                $report['total_receipts'] += $list->receipts->count();
                $report['total_items_with_prices'] += $list->items->where('is_purchased', true)->whereNotNull('price')->count();
            }

            // Générer des recommandations
            $noPricingPercentage = ($report['lists_with_no_pricing'] / $report['total_lists']) * 100;
            
            if ($noPricingPercentage > 50) {
                $report['recommendations'][] = [
                    'type' => 'critical',
                    'message' => 'More than half of your lists have no pricing data. Consider adding receipts.',
                    'action' => 'add_receipts'
                ];
            } elseif ($noPricingPercentage > 25) {
                $report['recommendations'][] = [
                    'type' => 'warning',
                    'message' => 'Some lists are missing pricing data. Adding receipts will improve analytics.',
                    'action' => 'improve_coverage'
                ];
            } else {
                $report['recommendations'][] = [
                    'type' => 'success',
                    'message' => 'Good pricing data coverage! Your analytics are reliable.',
                    'action' => 'maintain'
                ];
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'report' => $report,
                    'percentages' => [
                        'lists_with_receipts' => round(($report['lists_with_receipts'] / $report['total_lists']) * 100, 1),
                        'lists_with_item_prices' => round(($report['lists_with_item_prices'] / $report['total_lists']) * 100, 1),
                        'lists_with_no_pricing' => round($noPricingPercentage, 1)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'DATA_QUALITY_ERROR',
                    'message' => 'Error generating data quality report',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ HISTORIQUE DES DÉPENSES PAR MOIS (VERSION CORRIGÉE AVEC FACTURES)
     */
    public function monthlySpendingHistory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $months = min((int)($params['months'] ?? 12), 24);
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            
            $user = User::with('currency')->find($user_id);
            if (!$user) {
                throw new \Exception('User not found');
            }

            // Déterminer la devise cible
            if ($currency_code) {
                $targetCurrency = Currency::findByCode($currency_code);
                if (!$targetCurrency) {
                    throw new \Exception('Invalid currency code');
                }
            } else {
                $targetCurrency = $user->currency ?? Currency::getDefault();
            }

            // Calculer les dates
            $currentYear = Carbon::now()->year;
            
            if ($months == 12) {
                $startDate = Carbon::create($currentYear, 1, 1)->startOfMonth();
                $endDate = Carbon::create($currentYear, 12, 31)->endOfMonth();
            } else {
                $endDate = Carbon::now()->endOfMonth();
                $startDate = Carbon::now()->subMonths($months - 1)->startOfMonth();
            }

            // ✅ Obtenir les données combinées
            $spendingData = $this->getCombinedSpendingData($user_id, $startDate, $endDate);

            // Créer les mois dans l'ordre chronologique
            $monthlyData = [];
            $currentDate = $startDate->copy();
            
            while ($currentDate->lte($endDate)) {
                $monthKey = $currentDate->format('Y-m');
                $monthlyData[$monthKey] = [
                    'year' => $currentDate->year,
                    'month' => $currentDate->month,
                    'month_name' => $currentDate->translatedFormat('F Y'),
                    'month_short' => $currentDate->translatedFormat('M'),
                    'total_spent' => 0,
                    'total_transactions' => 0,
                    'receipts_total' => 0,
                    'items_total' => 0,
                    'receipts_count' => 0,
                    'items_sessions' => 0,
                    'currency' => $targetCurrency->code,
                    'sort_order' => $currentDate->month
                ];
                $currentDate->addMonth();
            }

            // Calculer les totaux
            foreach ($spendingData as $spending) {
                $monthKey = $spending['date']->format('Y-m');
                if (isset($monthlyData[$monthKey])) {
                    $monthlyData[$monthKey]['total_spent'] += $spending['amount'];
                    $monthlyData[$monthKey]['total_transactions']++;
                    
                    if ($spending['source'] === 'receipt') {
                        $monthlyData[$monthKey]['receipts_total'] += $spending['amount'];
                        $monthlyData[$monthKey]['receipts_count']++;
                    } else {
                        $monthlyData[$monthKey]['items_total'] += $spending['amount'];
                        $monthlyData[$monthKey]['items_sessions']++;
                    }
                }
            }

            // Formater les données
            foreach ($monthlyData as &$month) {
                $month['total_spent'] = round($month['total_spent'], 2);
                $month['receipts_total'] = round($month['receipts_total'], 2);
                $month['items_total'] = round($month['items_total'], 2);
                $month['formatted_total'] = $targetCurrency->formatAmountDisplay($month['total_spent']);
                $month['formatted_receipts'] = $targetCurrency->formatAmountDisplay($month['receipts_total']);
                $month['formatted_items'] = $targetCurrency->formatAmountDisplay($month['items_total']);
                $month['data_quality'] = $month['receipts_total'] > 0 ? 'high' : ($month['items_total'] > 0 ? 'medium' : 'none');
            }

            // Trier les données
            $sortedMonthlyData = array_values($monthlyData);
            usort($sortedMonthlyData, function($a, $b) {
                if ($a['year'] !== $b['year']) {
                    return $a['year'] <=> $b['year'];
                }
                return $a['month'] <=> $b['month'];
            });

            // Calculs de tendance
            $values = array_column($sortedMonthlyData, 'total_spent');
            $totalSpent = array_sum($values);
            $averageMonthly = count($values) > 0 ? $totalSpent / count($values) : 0;
            
            $recentMonths = array_slice($values, -3);
            $previousMonths = array_slice($values, -6, 3);
            $recentAvg = count($recentMonths) > 0 ? array_sum($recentMonths) / count($recentMonths) : 0;
            $previousAvg = count($previousMonths) > 0 ? array_sum($previousMonths) / count($previousMonths) : 0;
            
            $trendPercentage = $previousAvg > 0 ? 
                round((($recentAvg - $previousAvg) / $previousAvg) * 100, 1) : 0;

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'monthly_data' => $sortedMonthlyData,
                    'summary' => [
                        'total_spent' => round($totalSpent, 2),
                        'average_monthly' => round($averageMonthly, 2),
                        'currency' => $targetCurrency->code,
                        'period' => [
                            'start' => $startDate->toDateString(),
                            'end' => $endDate->toDateString(),
                            'months' => $months,
                            'year_based' => $months == 12
                        ],
                        'data_sources' => [
                            'receipts_total' => round(array_sum(array_column($sortedMonthlyData, 'receipts_total')), 2),
                            'items_total' => round(array_sum(array_column($sortedMonthlyData, 'items_total')), 2),
                            'receipts_months' => count(array_filter($sortedMonthlyData, fn($m) => $m['receipts_count'] > 0)),
                            'items_months' => count(array_filter($sortedMonthlyData, fn($m) => $m['items_sessions'] > 0))
                        ],
                        'trend' => [
                            'percentage' => $trendPercentage,
                            'direction' => $trendPercentage > 0 ? 'increasing' : ($trendPercentage < 0 ? 'decreasing' : 'stable'),
                            'recent_average' => round($recentAvg, 2),
                            'previous_average' => round($previousAvg, 2)
                        ],
                        'formatted_total' => $targetCurrency->formatAmountDisplay($totalSpent),
                        'formatted_average_monthly' => $targetCurrency->formatAmountDisplay($averageMonthly)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'ANALYTICS_ERROR',
                    'message' => 'Error retrieving monthly spending data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}