<?php
// app/Controllers/AnalyticsController.php - VERSION COMPLÈTE CORRIGÉE

namespace App\Controllers;

use App\Models\ListItem;
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
     * ✅ HISTORIQUE MENSUEL DES DÉPENSES (CORRIGÉ POUR L'ORDRE)
     */
    public function monthlySpendingHistory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            // Paramètres avec valeurs par défaut
            $months = min((int)($params['months'] ?? 12), 24); // Max 24 mois
            $currency_code = $params['currency'] ?? null;
            
            // Récupérer l'utilisateur avec sa devise
            $user = User::with('currency')->find($user_id);
            if (!$user) {
                throw new \Exception('User not found');
            }

            // Déterminer la devise cible (AFFICHAGE SEULEMENT)
            if ($currency_code) {
                $targetCurrency = Currency::findByCode($currency_code);
                if (!$targetCurrency) {
                    throw new \Exception('Invalid currency code');
                }
            } else {
                $targetCurrency = $user->currency ?? Currency::getDefault();
            }

            if (!$targetCurrency) {
                throw new \Exception('Currency not found');
            }

            // ✅ CORRECTION: Calculer les dates pour commencer par janvier
            $currentYear = Carbon::now()->year;
            $currentMonth = Carbon::now()->month;
            
            // Si on demande 12 mois, commencer par janvier de l'année actuelle
            // Sinon, prendre les X derniers mois complets
            if ($months == 12) {
                $startDate = Carbon::create($currentYear, 1, 1)->startOfMonth();
                $endDate = Carbon::create($currentYear, 12, 31)->endOfMonth();
            } else {
                $endDate = Carbon::now()->endOfMonth();
                $startDate = Carbon::now()->subMonths($months - 1)->startOfMonth();
            }

            // Query pour les items achetés avec prix
            $items = $this->getUserAccessibleItemsQuery($user_id)
                ->where('is_purchased', true)
                ->whereNotNull('price')
                ->whereBetween('updated_at', [$startDate, $endDate])
                ->get();

            // ✅ CORRECTION: Créer les mois dans l'ordre chronologique
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
                    'total_items' => 0,
                    'average_item_price' => 0,
                    'currency' => $targetCurrency->code,
                    'sort_order' => $currentDate->month // ✅ Ajout pour le tri côté client
                ];
                $currentDate->addMonth();
            }

            // Calculer les totaux
            foreach ($items as $item) {
                $monthKey = $item->updated_at->format('Y-m');
                if (isset($monthlyData[$monthKey])) {
                    $totalPrice = $item->price * $item->quantity;
                    $monthlyData[$monthKey]['total_spent'] += $totalPrice;
                    $monthlyData[$monthKey]['total_items'] += $item->quantity;
                }
            }

            // Calculer les moyennes et formater
            foreach ($monthlyData as &$month) {
                if ($month['total_items'] > 0) {
                    $month['average_item_price'] = round($month['total_spent'] / $month['total_items'], 2);
                }
                $month['total_spent'] = round($month['total_spent'], 2);
                $month['formatted_total'] = $targetCurrency->formatAmountDisplay($month['total_spent']);
                $month['formatted_average'] = $targetCurrency->formatAmountDisplay($month['average_item_price']);
            }

            // ✅ CORRECTION: Trier les données par année puis par mois
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
            
            // Tendance (comparaison des 3 derniers mois vs 3 précédents)
            $recentMonths = array_slice($values, -3);
            $previousMonths = array_slice($values, -6, 3);
            $recentAvg = count($recentMonths) > 0 ? array_sum($recentMonths) / count($recentMonths) : 0;
            $previousAvg = count($previousMonths) > 0 ? array_sum($previousMonths) / count($previousMonths) : 0;
            
            $trendPercentage = $previousAvg > 0 ? 
                round((($recentAvg - $previousAvg) / $previousAvg) * 100, 1) : 0;

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'monthly_data' => $sortedMonthlyData, // ✅ Données triées
                    'summary' => [
                        'total_spent' => round($totalSpent, 2),
                        'average_monthly' => round($averageMonthly, 2),
                        'currency' => $targetCurrency->code,
                        'period' => [
                            'start' => $startDate->toDateString(),
                            'end' => $endDate->toDateString(),
                            'months' => $months,
                            'year_based' => $months == 12 // ✅ Indicateur pour le client
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
     * ✅ DÉPENSES PAR CATÉGORIE (SIMPLIFIÉ)
     */
    public function spendingByCategory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period = $params['period'] ?? 'month'; // week, month, quarter, year, all
            $currency_code = $params['currency'] ?? null;
            $limit = min((int)($params['limit'] ?? 20), 50);
            
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

            // Catégoriser les produits
            $categories = $this->categorizeProducts($items);

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
     * ✅ TOP PRODUITS (SIMPLIFIÉ)
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
     * ✅ MÉTHODE PRIVÉE POUR CATÉGORISER LES PRODUITS
     */
    private function categorizeProducts($items): array
    {
        $categories = [];
        
        // Définition des catégories avec mots-clés (en français et anglais)
        $categoryKeywords = [
            'Fruits & Légumes' => [
                'pomme', 'banana', 'orange', 'tomate', 'carotte', 'oignon', 'pommes de terre',
                'apple', 'tomato', 'potato', 'onion', 'carrot', 'lettuce', 'spinach',
                'fruit', 'légume', 'vegetable', 'avocado', 'avocat'
            ],
            'Viandes & Poissons' => [
                'poulet', 'boeuf', 'porc', 'saumon', 'thon', 'chicken', 'beef', 'pork',
                'fish', 'meat', 'viande', 'poisson', 'steak', 'bacon', 'ham', 'jambon'
            ],
            'Produits Laitiers' => [
                'lait', 'fromage', 'yaourt', 'beurre', 'milk', 'cheese', 'yogurt',
                'butter', 'cream', 'crème', 'dairy', 'laitier'
            ],
            'Céréales & Pain' => [
                'pain', 'pâtes', 'riz', 'bread', 'pasta', 'rice', 'cereal', 'céréales',
                'flour', 'farine', 'oats', 'avoine', 'quinoa'
            ],
            'Boissons' => [
                'eau', 'jus', 'café', 'thé', 'water', 'juice', 'coffee', 'tea',
                'soda', 'beer', 'bière', 'vin', 'wine', 'beverage', 'boisson'
            ],
            'Produits d\'entretien' => [
                'détergent', 'savon', 'shampoing', 'soap', 'detergent', 'shampoo',
                'cleaning', 'nettoyage', 'toilet paper', 'papier toilette'
            ],
            'Snacks & Sucreries' => [
                'chocolat', 'biscuit', 'chips', 'chocolate', 'cookie', 'candy',
                'bonbon', 'gâteau', 'cake', 'ice cream', 'glace'
            ]
        ];

        foreach ($items as $item) {
            $productName = strtolower($item->product_name);
            $categorized = false;
            
            // Essayer de catégoriser
            foreach ($categoryKeywords as $categoryName => $keywords) {
                foreach ($keywords as $keyword) {
                    if (strpos($productName, strtolower($keyword)) !== false) {
                        if (!isset($categories[$categoryName])) {
                            $categories[$categoryName] = [
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
                if (!isset($categories['Autres'])) {
                    $categories['Autres'] = [
                        'total_spent' => 0,
                        'total_items' => 0,
                        'unique_products' => 0,
                        'average_price' => 0,
                        'top_products' => []
                    ];
                }
                
                $itemTotal = ($item->price ?? 0) * $item->quantity;
                $categories['Autres']['total_spent'] += $itemTotal;
                $categories['Autres']['total_items'] += $item->quantity;
                
                if (!isset($categories['Autres']['top_products'][$item->product_name])) {
                    $categories['Autres']['top_products'][$item->product_name] = 0;
                }
                $categories['Autres']['top_products'][$item->product_name] += $itemTotal;
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
}