<?php
// app/Controllers/AnalyticsController.php - PARTIE 1: STRUCTURE ET UTILITAIRES

namespace App\Controllers;

use App\Models\ListItem;
use App\Models\ListReceipt;
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
     * ✅ RÉCUPÉRER LES IDS DES LISTES ACCESSIBLES
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
     * ✅ VÉRIFICATION D'ACCÈS À UNE LISTE
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
     * ✅ QUERY BUILDER POUR LES ITEMS ACCESSIBLES
     */
    private function getUserAccessibleItemsQuery(int $user_id): Builder
    {
        $accessibleListIds = $this->getUserAccessibleListIds($user_id);
        return ListItem::whereIn('list_id', $accessibleListIds);
    }

    /**
     * ✅ OBTENIR LES DONNÉES DE DÉPENSES COMBINÉES (FACTURES + ITEMS)
     */
    private function getCombinedSpendingDataSafe(int $user_id, Carbon $startDate, Carbon $endDate): array
    {
        try {
            error_log("🔍 getCombinedSpendingDataSafe START - User: $user_id");
            error_log("📅 Date range: {$startDate->toDateString()} to {$endDate->toDateString()}");
            
            $accessibleListIds = $this->getUserAccessibleListIds($user_id);
            
            if (empty($accessibleListIds)) {
                error_log("⚠️ No accessible lists found!");
                return [];
            }

            $spendingData = [];

            // ===== ÉTAPE 1: FACTURES (PRIORITAIRES) =====
            error_log("💳 === ANALYZING RECEIPTS ===");
            
            $receipts = ListReceipt::whereIn('list_id', $accessibleListIds)
                ->whereBetween('purchase_date', [$startDate, $endDate])
                ->orderBy('purchase_date', 'desc')
                ->get();
            
            error_log("💳 Found " . $receipts->count() . " receipts");
            
            $listsWithReceipts = [];
            
            foreach ($receipts as $receipt) {
                if (!$receipt->purchase_date || !is_numeric($receipt->total_amount) || $receipt->total_amount <= 0) {
                    error_log("💳 ❌ SKIPPED: Invalid receipt {$receipt->id}");
                    continue;
                }
                
                $key = 'receipt_' . $receipt->id;
                
                $spendingData[$key] = [
                    'date' => $receipt->purchase_date,
                    'amount' => (float)$receipt->total_amount,
                    'source' => 'receipt',
                    'store_name' => (string)($receipt->store_name ?? ''),
                    'list_id' => (int)$receipt->list_id,
                    'receipt_id' => (int)$receipt->id,
                    'details' => [
                        'receipt_id' => (int)$receipt->id,
                        'notes' => (string)($receipt->notes ?? '')
                    ]
                ];
                
                $listsWithReceipts[] = $receipt->list_id;
                error_log("💳 ✅ Receipt {$receipt->id}: {$receipt->total_amount}$ on {$receipt->purchase_date->toDateString()}");
            }
            
            $listsWithReceipts = array_unique($listsWithReceipts);
            error_log("📦 Lists with receipts: " . json_encode($listsWithReceipts));

            // ===== ÉTAPE 2: ITEMS (FALLBACK POUR LISTES SANS FACTURES) =====
            error_log("📦 === ANALYZING ITEMS ===");
            
            $listsForItemsAnalysis = array_diff($accessibleListIds, $listsWithReceipts);
            error_log("📦 Lists for items analysis: " . json_encode($listsForItemsAnalysis));
            
            if (!empty($listsForItemsAnalysis)) {
                $items = ListItem::whereIn('list_id', $listsForItemsAnalysis)
                    ->where('is_purchased', true)
                    ->whereNotNull('price')
                    ->where('price', '>', 0)
                    ->whereBetween('updated_at', [$startDate, $endDate])
                    ->get();

                error_log("📦 Found " . $items->count() . " items with prices");
                
                // Grouper les items par date et liste
                $itemGroups = [];
                foreach ($items as $item) {
                    if (!$item->updated_at || !is_numeric($item->price) || !is_numeric($item->quantity)) {
                        continue;
                    }
                    
                    $dateKey = $item->updated_at->toDateString();
                    $groupKey = $dateKey . '_list_' . $item->list_id;
                    
                    if (!isset($itemGroups[$groupKey])) {
                        $itemGroups[$groupKey] = [
                            'date' => $item->updated_at,
                            'amount' => 0.0,
                            'source' => 'items',
                            'store_name' => (string)($item->store_name ?? ''),
                            'list_id' => (int)$item->list_id,
                            'details' => [
                                'items_count' => 0,
                                'items' => []
                            ]
                        ];
                    }
                    
                    $itemTotal = (float)$item->price * (int)$item->quantity;
                    $itemGroups[$groupKey]['amount'] += $itemTotal;
                    $itemGroups[$groupKey]['details']['items_count']++;
                    $itemGroups[$groupKey]['details']['items'][] = [
                        'product_name' => (string)$item->product_name,
                        'quantity' => (int)$item->quantity,
                        'price' => (float)$item->price,
                        'total' => $itemTotal
                    ];
                    
                    error_log("📦 ✅ Item {$item->id}: {$item->product_name} = $itemTotal");
                }
                
                // Ajouter les groupes d'items aux données de dépenses
                foreach ($itemGroups as $groupKey => $group) {
                    $key = 'items_' . $groupKey;
                    $spendingData[$key] = $group;
                }
            }

            // ===== ÉTAPE 3: RÉSUMÉ FINAL =====
            $finalData = array_values($spendingData);
            $totalAmount = array_sum(array_column($finalData, 'amount'));
            $receiptCount = count(array_filter($finalData, fn($item) => $item['source'] === 'receipt'));
            $itemGroupCount = count(array_filter($finalData, fn($item) => $item['source'] === 'items'));
            
            error_log("💰 === FINAL SUMMARY ===");
            error_log("💰 Total spending entries: " . count($finalData));
            error_log("💰 Receipt entries: $receiptCount");
            error_log("💰 Item group entries: $itemGroupCount");
            error_log("💰 Grand total amount: $totalAmount");
            error_log("🔍 getCombinedSpendingDataSafe END");
            
            return $finalData;
            
        } catch (\Exception $e) {
            error_log("❌ Error in getCombinedSpendingDataSafe: " . $e->getMessage());
            error_log("❌ Stack trace: " . $e->getTraceAsString());
            return [];
        }
    }

    /**
     * ✅ OBTENIR LES DONNÉES AVEC SÉPARATION PROPRES/PARTAGÉES
     */
    private function getSpendingDataWithBreakdown(int $user_id, Carbon $startDate, Carbon $endDate): array
    {
        error_log("🔍 getSpendingDataWithBreakdown START");
        
        // Récupérer les IDs des listes propres et partagées
        $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
        $sharedListIds = SharedList::where('shared_with_user_id', $user_id)
                                ->where('status', 'accepted')
                                ->where('is_active', true)
                                ->pluck('list_id')->toArray();
        
        error_log("📊 Own lists: " . json_encode($ownListIds));
        error_log("📊 Shared lists: " . json_encode($sharedListIds));
        
        // Récupérer toutes les données de dépenses
        $allSpendingData = $this->getCombinedSpendingDataSafe($user_id, $startDate, $endDate);
        
        $breakdown = [
            'own_lists' => [],
            'shared_lists' => [],
            'totals' => [
                'own_lists_total' => 0.0,
                'shared_lists_total' => 0.0,
                'grand_total' => 0.0
            ]
        ];
        
        // Séparer les données selon le type de liste
        foreach ($allSpendingData as $spending) {
            $listId = $spending['list_id'];
            $amount = (float)$spending['amount'];
            
            if (in_array($listId, $ownListIds)) {
                // Liste propre
                $breakdown['own_lists'][] = $spending;
                $breakdown['totals']['own_lists_total'] += $amount;
                error_log("📊 Own list $listId: +$amount");
            } elseif (in_array($listId, $sharedListIds)) {
                // Liste partagée
                $breakdown['shared_lists'][] = $spending;
                $breakdown['totals']['shared_lists_total'] += $amount;
                error_log("📊 Shared list $listId: +$amount");
            } else {
                error_log("⚠️ Unknown list $listId for user $user_id");
            }
            
            $breakdown['totals']['grand_total'] += $amount;
        }
        
        error_log("📊 BREAKDOWN TOTALS:");
        error_log("📊 Own: {$breakdown['totals']['own_lists_total']}$");
        error_log("📊 Shared: {$breakdown['totals']['shared_lists_total']}$");
        error_log("📊 Grand: {$breakdown['totals']['grand_total']}$");
        
        return $breakdown;
    }

    /**
     * ✅ CATÉGORISER LES PRODUITS AVEC I18N
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
                        $categoryName = $translations[$categoryKey][$language];
                        
                        if (!isset($categories[$categoryName])) {
                            $categories[$categoryName] = [
                                'category_key' => $categoryKey,
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
     * ✅ DASHBOARD PRINCIPAL
     */
    public function dashboard(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            $includeShared = ($params['include_shared'] ?? 'true') !== 'false';
            
            error_log("🎯 Dashboard - User: $user_id, Include shared: " . ($includeShared ? 'YES' : 'NO'));
            
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

            if (!$targetCurrency) {
                $targetCurrency = (object)[
                    'code' => 'CAD',
                    'symbol' => '$',
                    'formatAmountDisplay' => function($amount) {
                        return '$' . number_format($amount, 2);
                    }
                ];
            }

            // ===== PÉRIODE ACTUELLE =====
            $currentMonthStart = Carbon::now()->startOfMonth();
            $currentMonthEnd = Carbon::now()->endOfMonth();

            // ===== OBTENIR LES LISTES ACCESSIBLES =====
            if ($includeShared) {
                $listIds = $this->getUserAccessibleListIds($user_id);
            } else {
                $listIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
            }

            if (empty($listIds)) {
                error_log("⚠️ No accessible lists found for user $user_id");
                
                $response->getBody()->write(json_encode([
                    'success' => true,
                    'data' => [
                        'language' => $language,
                        'currency' => $targetCurrency->code,
                        'include_shared' => $includeShared,
                        'current_month' => [
                            'total_spent' => 0,
                            'items_purchased' => 0,
                            'unique_products' => 0,
                            'shopping_sessions' => 0,
                            'formatted_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                                ? $targetCurrency->formatAmountDisplay(0)
                                : '$0.00'
                        ],
                        'last_7_days' => [],
                        'quick_stats' => [
                            'average_daily_spending' => 0,
                            'data_source' => $includeShared ? 'own_and_shared' : 'own_only'
                        ]
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            // ===== CALCULS POUR LE MOIS ACTUEL =====
            
            // 1. Total des dépenses via les données combinées
            $breakdown = $this->getSpendingDataWithBreakdown($user_id, $currentMonthStart, $currentMonthEnd);
            $currentTotal = $includeShared ? 
                $breakdown['totals']['grand_total'] : 
                $breakdown['totals']['own_lists_total'];

            // 2. Statistiques des items achetés pour le mois actuel
            $currentMonthItems = ListItem::whereIn('list_id', $listIds)
                ->where('is_purchased', true)
                ->whereBetween('updated_at', [$currentMonthStart, $currentMonthEnd])
                ->get();

            $itemsPurchased = $currentMonthItems->sum('quantity');
            $uniqueProducts = $currentMonthItems->unique('product_name')->count();

            error_log("📊 Current month items: " . $currentMonthItems->count());
            error_log("📊 Items purchased (quantity): $itemsPurchased");
            error_log("📊 Unique products: $uniqueProducts");

            // 3. Sessions de shopping (groupées par liste et jour)
            $shoppingSessions = 0;
            if ($currentMonthItems->isNotEmpty()) {
                $sessionGroups = $currentMonthItems->groupBy(function($item) {
                    return $item->list_id . '-' . $item->updated_at->format('Y-m-d');
                });
                $shoppingSessions = $sessionGroups->count();
            }

            error_log("📊 Shopping sessions: $shoppingSessions");

            // ===== STATS DES 7 DERNIERS JOURS =====
            $last7Days = [];
            for ($i = 6; $i >= 0; $i--) {
                $date = Carbon::now()->subDays($i);
                $dayStart = $date->copy()->startOfDay();
                $dayEnd = $date->copy()->endOfDay();
                
                // Récupérer les données de dépenses de ce jour
                $daySpendingData = $this->getCombinedSpendingDataSafe($user_id, $dayStart, $dayEnd);
                
                // Filtrer selon includeShared
                if (!$includeShared) {
                    $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
                    $daySpendingData = array_filter($daySpendingData, function($spending) use ($ownListIds) {
                        return in_array($spending['list_id'], $ownListIds);
                    });
                }
                
                $dayTotal = array_sum(array_column($daySpendingData, 'amount'));
                
                // Compter les items de ce jour
                $dayItems = ListItem::whereIn('list_id', $listIds)
                    ->where('is_purchased', true)
                    ->whereBetween('updated_at', [$dayStart, $dayEnd])
                    ->get();
                
                $dayItemsCount = $dayItems->sum('quantity');

                $last7Days[] = [
                    'date' => $date->toDateString(),
                    'day_name' => $date->format('l'),
                    'total_spent' => round($dayTotal, 2),
                    'items_count' => $dayItemsCount,
                    'formatted_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                        ? $targetCurrency->formatAmountDisplay($dayTotal)
                        : '$' . number_format($dayTotal, 2)
                ];
            }

            // ===== STATISTIQUES DES FACTURES POUR LE MOIS =====
            $receiptsCount = ListReceipt::whereIn('list_id', $listIds)
                ->whereBetween('purchase_date', [$currentMonthStart, $currentMonthEnd])
                ->count();

            $uniqueStores = ListReceipt::whereIn('list_id', $listIds)
                ->whereBetween('purchase_date', [$currentMonthStart, $currentMonthEnd])
                ->distinct('store_name')
                ->count('store_name');

            // Si pas de factures, compter les magasins des items
            if ($uniqueStores === 0) {
                $uniqueStores = $currentMonthItems->whereNotNull('store_name')
                    ->unique('store_name')
                    ->count();
            }

            error_log("📊 Receipts count: $receiptsCount");
            error_log("📊 Unique stores: $uniqueStores");

            // ===== COMPARAISON AVEC LE MOIS PRÉCÉDENT =====
            $previousMonthStart = Carbon::now()->subMonth()->startOfMonth();
            $previousMonthEnd = Carbon::now()->subMonth()->endOfMonth();

            error_log("📊 Previous month: {$previousMonthStart->toDateString()} to {$previousMonthEnd->toDateString()}");

            // Obtenir les données du mois précédent
            $previousBreakdown = $this->getSpendingDataWithBreakdown($user_id, $previousMonthStart, $previousMonthEnd);
            $previousTotal = $includeShared ? 
                $previousBreakdown['totals']['grand_total'] : 
                $previousBreakdown['totals']['own_lists_total'];

            // Calculer les changements
            $spendingChange = $currentTotal - $previousTotal;
            $spendingChangePercentage = $previousTotal > 0 ? 
                round((($spendingChange / $previousTotal) * 100), 1) : 0;

            $trend = 'stable';
            if ($spendingChangePercentage > 2) {
                $trend = 'increased';
            } elseif ($spendingChangePercentage < -2) {
                $trend = 'decreased';
            }

            // Statistiques des items du mois précédent pour comparaison
            $previousMonthItems = ListItem::whereIn('list_id', $listIds)
                ->where('is_purchased', true)
                ->whereBetween('updated_at', [$previousMonthStart, $previousMonthEnd])
                ->get();

            $previousItemsPurchased = $previousMonthItems->sum('quantity');
            $previousUniqueProducts = $previousMonthItems->unique('product_name')->count();

            error_log("📊 Previous month total: $previousTotal");
            error_log("📊 Spending change: $spendingChange ({$spendingChangePercentage}%)");
            error_log("📊 Trend: $trend");

            $comparisonData = [
                'current_period' => round($currentTotal, 2),
                'previous_period' => round($previousTotal, 2),
                'absolute_change' => round($spendingChange, 2),
                'spending_change_percentage' => $spendingChangePercentage,
                'spending_trend' => $trend,
                'items_change' => (int)$itemsPurchased - (int)$previousItemsPurchased,
                'products_change' => (int)$uniqueProducts - (int)$previousUniqueProducts,
                'period_type' => 'month',
                'current_period_name' => Carbon::now()->format('F Y'),
                'previous_period_name' => Carbon::now()->subMonth()->format('F Y')
            ];

            // ===== RÉPONSE FINALE =====
            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'currency' => $targetCurrency->code,
                    'include_shared' => $includeShared,
                    
                    'current_month' => [
                        'total_spent' => round($currentTotal, 2),
                        'items_purchased' => (int)$itemsPurchased,
                        'unique_products' => (int)$uniqueProducts,
                        'shopping_sessions' => (int)$shoppingSessions,
                        'receipts_count' => (int)$receiptsCount,
                        'unique_stores' => (int)$uniqueStores,
                        'formatted_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                            ? $targetCurrency->formatAmountDisplay($currentTotal)
                            : '$' . number_format($currentTotal, 2)
                    ],
                    
                    'last_7_days' => $last7Days,
                    
                    'comparison_with_last_month' => $comparisonData,
                    
                    'data_breakdown' => [
                        'own_lists_total' => round($breakdown['totals']['own_lists_total'], 2),
                        'shared_lists_total' => round($breakdown['totals']['shared_lists_total'], 2),
                        'own_lists_percentage' => $breakdown['totals']['grand_total'] > 0 ? 
                            round(($breakdown['totals']['own_lists_total'] / $breakdown['totals']['grand_total']) * 100, 1) : 0,
                        'shared_lists_percentage' => $breakdown['totals']['grand_total'] > 0 ? 
                            round(($breakdown['totals']['shared_lists_total'] / $breakdown['totals']['grand_total']) * 100, 1) : 0,
                        'formatted_own_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                            ? $targetCurrency->formatAmountDisplay($breakdown['totals']['own_lists_total'])
                            : '$' . number_format($breakdown['totals']['own_lists_total'], 2),
                        'formatted_shared_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                            ? $targetCurrency->formatAmountDisplay($breakdown['totals']['shared_lists_total'])
                            : '$' . number_format($breakdown['totals']['shared_lists_total'], 2)
                    ],
                    
                    'quick_stats' => [
                        'average_daily_spending' => round(array_sum(array_column($last7Days, 'total_spent')) / 7, 2),
                        'data_source' => $includeShared ? 'own_and_shared' : 'own_only',
                        'lists_count' => count($listIds),
                        'active_month' => $itemsPurchased > 0 || $currentTotal > 0
                    ],

                    // ===== DEBUGGING INFO (à retirer en production) =====
                    'debug_info' => [
                        'accessible_lists_count' => count($listIds),
                        'current_month_items_count' => $currentMonthItems->count(),
                        'items_with_quantity' => $currentMonthItems->where('quantity', '>', 0)->count(),
                        'receipts_this_month' => $receiptsCount,
                        'calculation_method' => 'direct_item_queries'
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("❌ Dashboard error: " . $e->getMessage());
            error_log("❌ Stack trace: " . $e->getTraceAsString());
            
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
     * ✅ TENDANCES DE DÉPENSES
     */
    public function spendingTrends(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period = $params['period'] ?? 'month'; // week, month, year
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            $includeShared = ($params['include_shared'] ?? 'true') !== 'false';
            
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

            // Récupérer les données de dépenses
            $spendingData = $this->getCombinedSpendingDataSafe($user_id, $startDate, $endDate);

            if (!$includeShared) {
                $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
                $spendingData = array_filter($spendingData, function($spending) use ($ownListIds) {
                    return in_array($spending['list_id'], $ownListIds);
                });
            }

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
                    'total_transactions' => 0,
                    'unique_stores' => 0
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
            $storesByPeriod = [];
            foreach ($spendingData as $spending) {
                $periodKey = $spending['date']->format($groupFormat);
                if (isset($trendData[$periodKey])) {
                    $trendData[$periodKey]['total_spent'] += $spending['amount'];
                    $trendData[$periodKey]['total_transactions']++;
                    
                    // Track unique stores
                    if (!isset($storesByPeriod[$periodKey])) {
                        $storesByPeriod[$periodKey] = [];
                    }
                    $storesByPeriod[$periodKey][$spending['store_name']] = true;
                }
            }

            // Finaliser les données
            foreach ($trendData as $periodKey => &$data) {
                $data['total_spent'] = round($data['total_spent'], 2);
                $data['unique_stores'] = count($storesByPeriod[$periodKey] ?? []);
                $data['formatted_total'] = $targetCurrency->formatAmountDisplay($data['total_spent']);
            }

            // Trier les données par ordre chronologique
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
                    ],
                    'include_shared' => $includeShared
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
     * ✅ DÉPENSES PAR CATÉGORIE
     */
    public function spendingByCategory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period = $params['period'] ?? 'month'; // week, month, quarter, year, all
            $currency_code = $params['currency'] ?? null;
            $limit = min((int)($params['limit'] ?? 20), 50);
            $includeShared = ($params['include_shared'] ?? 'true') !== 'false';
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

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

            if (!$includeShared) {
                $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
                $items = $items->filter(function($item) use ($ownListIds) {
                    return in_array($item->list_id, $ownListIds);
                });
            }

            // Catégoriser les produits
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
                    'category_key' => $data['category_key'],
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
                    'language' => $language,
                    'currency' => $targetCurrency->code,
                    'include_shared' => $includeShared,
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
     * ✅ DÉPENSES PAR MAGASIN
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
            $includeShared = ($params['include_shared'] ?? 'true') !== 'false';
            
            error_log("🏪 spendingByStore - User: $user_id, Period: $period, Include shared: " . ($includeShared ? 'YES' : 'NO'));
            
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

            if (!$targetCurrency) {
                $targetCurrency = (object)[
                    'code' => 'CAD',
                    'symbol' => '$',
                    'formatAmountDisplay' => function($amount) {
                        return '$' . number_format($amount, 2);
                    }
                ];
            }

            // Définir la période
            $startDate = match($period) {
                'week' => Carbon::now()->subWeek(),
                'quarter' => Carbon::now()->subQuarter(),
                'year' => Carbon::now()->subYear(),
                'all' => Carbon::create(2020, 1, 1),
                default => Carbon::now()->subMonth()
            };

            $endDate = Carbon::now()->endOfDay();

            // Obtenir les données
            $spendingData = $this->getCombinedSpendingDataSafe($user_id, $startDate, $endDate);
            
            // Filtrer selon includeShared
            if (!$includeShared) {
                $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
                $spendingData = array_filter($spendingData, function($spending) use ($ownListIds) {
                    return in_array($spending['list_id'], $ownListIds);
                });
                error_log("🏪 Filtered to own lists only: " . count($spendingData) . " entries");
            }

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
                        'last_visit' => null
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
                    'formatted_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                        ? $targetCurrency->formatAmountDisplay($data['total_spent'])
                        : '$' . number_format($data['total_spent'], 2)
                ];
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'period' => $period,
                    'language' => $language,
                    'currency' => $targetCurrency->code,
                    'include_shared' => $includeShared,
                    'stores' => $formattedStores,
                    'summary' => [
                        'total_spent' => round($grandTotal, 2),
                        'total_stores' => count($formattedStores),
                        'period_start' => $period !== 'all' ? $startDate->toDateString() : null,
                        'formatted_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                            ? $targetCurrency->formatAmountDisplay($grandTotal)
                            : '$' . number_format($grandTotal, 2)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("❌ Store analytics error: " . $e->getMessage());
            
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
     * ✅ HISTORIQUE MENSUEL
     */
    public function monthlySpendingHistory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $months = min((int)($params['months'] ?? 12), 24);
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            $includeShared = ($params['include_shared'] ?? 'true') !== 'false';
            
            error_log("📊 Monthly history - User: $user_id, Months: $months, Include shared: " . ($includeShared ? 'YES' : 'NO'));
            
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

            if (!$targetCurrency) {
                $targetCurrency = (object)[
                    'code' => 'CAD',
                    'symbol' => '$',
                    'formatAmountDisplay' => function($amount) {
                        return '$' . number_format($amount, 2);
                    }
                ];
            }

            // Calculer les dates
            $endDate = Carbon::now()->endOfMonth();
            $startDate = Carbon::now()->subMonths($months - 1)->startOfMonth();

            // Récupérer les données de dépenses
            $allSpendingData = $this->getCombinedSpendingDataSafe($user_id, $startDate, $endDate);
            
            // Filtrer selon includeShared
            if (!$includeShared) {
                $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
                $allSpendingData = array_filter($allSpendingData, function($spending) use ($ownListIds) {
                    return in_array($spending['list_id'], $ownListIds);
                });
            }

            // Noms des mois
            $monthNames = [
                1 => 'janvier', 2 => 'février', 3 => 'mars', 4 => 'avril',
                5 => 'mai', 6 => 'juin', 7 => 'juillet', 8 => 'août',
                9 => 'septembre', 10 => 'octobre', 11 => 'novembre', 12 => 'décembre'
            ];
            
            // Créer les données mensuelles
            $monthlyData = [];
            $currentDate = $startDate->copy();
            
            while ($currentDate->lte($endDate)) {
                $monthKey = $currentDate->format('Y-m');
                $monthName = $monthNames[$currentDate->month] ?? 'mois';
                
                $monthlyData[$monthKey] = [
                    'year' => (int)$currentDate->year,
                    'month' => (int)$currentDate->month,
                    'month_name' => $monthName . ' ' . $currentDate->year,
                    'month_short' => substr($monthName, 0, 4) . '.',
                    'total_spent' => 0.0,
                    'total_transactions' => 0,
                    'receipts_total' => 0.0,
                    'items_total' => 0.0,
                    'receipts_count' => 0,
                    'items_sessions' => 0,
                    'currency' => (string)$targetCurrency->code
                ];
                $currentDate->addMonth();
            }

            // Calculer les totaux par mois
            foreach ($allSpendingData as $spending) {
                $monthKey = $spending['date']->format('Y-m');
                
                if (isset($monthlyData[$monthKey])) {
                    $amount = (float)$spending['amount'];
                    $monthlyData[$monthKey]['total_spent'] += $amount;
                    $monthlyData[$monthKey]['total_transactions']++;
                    
                    $source = $spending['source'] ?? 'unknown';
                    if ($source === 'receipt') {
                        $monthlyData[$monthKey]['receipts_total'] += $amount;
                        $monthlyData[$monthKey]['receipts_count']++;
                    } else {
                        $monthlyData[$monthKey]['items_total'] += $amount;
                        $monthlyData[$monthKey]['items_sessions']++;
                    }
                }
            }

            // Formater les données finales
            foreach ($monthlyData as &$month) {
                $month['total_spent'] = round((float)$month['total_spent'], 2);
                $month['receipts_total'] = round((float)$month['receipts_total'], 2);
                $month['items_total'] = round((float)$month['items_total'], 2);
                
                $month['formatted_total'] = is_callable([$targetCurrency, 'formatAmountDisplay']) 
                    ? $targetCurrency->formatAmountDisplay($month['total_spent'])
                    : '$' . number_format($month['total_spent'], 2);
                
                $month['data_quality'] = $month['receipts_total'] > 0 ? 'high' : 
                    ($month['items_total'] > 0 ? 'medium' : 'none');
            }

            // Trier chronologiquement
            $sortedMonthlyData = array_values($monthlyData);
            usort($sortedMonthlyData, function($a, $b) {
                if ($a['year'] !== $b['year']) {
                    return $a['year'] <=> $b['year'];
                }
                return $a['month'] <=> $b['month'];
            });

            // Calculs de résumé
            $values = array_column($sortedMonthlyData, 'total_spent');
            $totalSpent = array_sum($values);
            $averageMonthly = count($values) > 0 ? $totalSpent / count($values) : 0;

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'include_shared' => $includeShared,
                    'monthly_data' => $sortedMonthlyData,
                    'summary' => [
                        'total_spent' => round($totalSpent, 2),
                        'average_monthly' => round($averageMonthly, 2),
                        'currency' => $targetCurrency->code,
                        'period' => [
                            'start' => $startDate->toDateString(),
                            'end' => $endDate->toDateString(),
                            'months' => $months
                        ],
                        'formatted_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                            ? $targetCurrency->formatAmountDisplay($totalSpent)
                            : '$' . number_format($totalSpent, 2)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("❌ Error in monthlySpendingHistory: " . $e->getMessage());
            
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
     * ✅ STATISTIQUES DE RÉPARTITION DES LISTES
     */
    public function getListsBreakdown(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period = $params['period'] ?? 'month';
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

            // Définir la période
            $startDate = match($period) {
                'week' => Carbon::now()->subWeek(),
                'quarter' => Carbon::now()->subQuarter(),
                'year' => Carbon::now()->subYear(),
                default => Carbon::now()->subMonth()
            };
            $endDate = Carbon::now()->endOfDay();

            $breakdown = $this->getSpendingDataWithBreakdown($user_id, $startDate, $endDate);
            
            // Statistiques des listes
            $ownListsCount = ShoppingList::where('user_id', $user_id)->count();
            $sharedListsCount = SharedList::where('shared_with_user_id', $user_id)
                                        ->where('status', 'accepted')
                                        ->where('is_active', true)
                                        ->count();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'period' => $period,
                    'currency' => $targetCurrency->code,
                    
                    'spending_breakdown' => [
                        'own_lists_total' => round($breakdown['totals']['own_lists_total'], 2),
                        'shared_lists_total' => round($breakdown['totals']['shared_lists_total'], 2),
                        'grand_total' => round($breakdown['totals']['grand_total'], 2),
                        'own_lists_percentage' => $breakdown['totals']['grand_total'] > 0 ? 
                            round(($breakdown['totals']['own_lists_total'] / $breakdown['totals']['grand_total']) * 100, 1) : 0,
                        'shared_lists_percentage' => $breakdown['totals']['grand_total'] > 0 ? 
                            round(($breakdown['totals']['shared_lists_total'] / $breakdown['totals']['grand_total']) * 100, 1) : 0
                    ],
                    
                    'lists_stats' => [
                        'own_lists_count' => $ownListsCount,
                        'shared_lists_count' => $sharedListsCount,
                        'total_accessible_lists' => $ownListsCount + $sharedListsCount,
                        'own_lists_transactions' => count($breakdown['own_lists']),
                        'shared_lists_transactions' => count($breakdown['shared_lists'])
                    ],
                    
                    'formatted_amounts' => [
                        'own_lists_total' => $targetCurrency->formatAmountDisplay($breakdown['totals']['own_lists_total']),
                        'shared_lists_total' => $targetCurrency->formatAmountDisplay($breakdown['totals']['shared_lists_total']),
                        'grand_total' => $targetCurrency->formatAmountDisplay($breakdown['totals']['grand_total'])
                    ],
                    
                    'period_info' => [
                        'start_date' => $startDate->toDateString(),
                        'end_date' => $endDate->toDateString()
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'BREAKDOWN_ERROR',
                    'message' => 'Error retrieving lists breakdown',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ TOP PRODUITS
     */
    public function topProducts(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();

            $includeShared = ($params['include_shared'] ?? 'true') !== 'false';
            $period = $params['period'] ?? 'month';
            $sort_by = $params['sort_by'] ?? 'total_spent'; // total_spent, quantity, frequency
            $currency_code = $params['currency'] ?? null;
            $limit = min((int)($params['limit'] ?? 10), 50);
            $language = $this->getUserLanguage($request);
            
            // Récupérer l'utilisateur
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

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

            if (!$includeShared) {
                $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
                $items = $items->filter(function($item) use ($ownListIds) {
                    return in_array($item->list_id, $ownListIds);
                });
            }

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
                    'include_shared' => $includeShared,
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
     * ✅ COMPARAISON ENTRE PÉRIODES
     */
    public function periodComparison(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $period_type = $params['period_type'] ?? 'month'; // month, quarter, year
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            $includeShared = ($params['include_shared'] ?? 'true') !== 'false';
            
            // Récupérer l'utilisateur
            $user = User::with('currency')->find($user_id);
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

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
            $calculatePeriodStats = function($startDate, $endDate) use ($user_id, $includeShared) {
                $spendingData = $this->getCombinedSpendingDataSafe($user_id, $startDate, $endDate);

                if (!$includeShared) {
                    $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
                    $spendingData = array_filter($spendingData, function($spending) use ($ownListIds) {
                        return in_array($spending['list_id'], $ownListIds);
                    });
                }

                $totalSpent = array_sum(array_column($spendingData, 'amount'));
                $totalTransactions = count($spendingData);
                $uniqueStores = count(array_unique(array_column($spendingData, 'store_name')));

                return [
                    'total_spent' => round($totalSpent, 2),
                    'total_transactions' => $totalTransactions,
                    'unique_stores' => $uniqueStores,
                    'average_transaction' => $totalTransactions > 0 ? round($totalSpent / $totalTransactions, 2) : 0
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
                    'include_shared' => $includeShared,
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
                        'efficiency_change' => $changes['average_transaction']['percentage']
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
     * ✅ HISTORIQUE DES DÉPENSES PAR JOUR
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
            $includeShared = ($params['include_shared'] ?? 'true') !== 'false';
            
            // Récupérer l'utilisateur avec sa devise
            $user = User::with('currency')->find($user_id);
            if (!$user) {
                throw new \Exception('User not found');
            }

            // Déterminer la devise cible
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

            if (!$targetCurrency) {
                $targetCurrency = (object)[
                    'code' => 'CAD',
                    'symbol' => '$',
                    'formatAmountDisplay' => function($amount) {
                        return '$' . number_format($amount, 2);
                    }
                ];
            }

            // Calculer les dates
            $endDate = Carbon::now()->endOfDay();
            $startDate = Carbon::now()->subDays($days - 1)->startOfDay();

            // Récupérer toutes les données de dépenses
            $allSpendingData = $this->getCombinedSpendingDataSafe($user_id, $startDate, $endDate);

            if (!$includeShared) {
                $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
                $allSpendingData = array_filter($allSpendingData, function($spending) use ($ownListIds) {
                    return in_array($spending['list_id'], $ownListIds);
                });
            }

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
                    'total_transactions' => 0,
                    'shopping_sessions' => 0,
                    'currency' => $targetCurrency->code
                ];
                $currentDate->addDay();
            }

            // Calculer les totaux par jour
            $sessionsByDay = [];
            foreach ($allSpendingData as $spending) {
                $dateKey = $spending['date']->format('Y-m-d');
                if (isset($dailyData[$dateKey])) {
                    $amount = (float)$spending['amount'];
                    $dailyData[$dateKey]['total_spent'] += $amount;
                    $dailyData[$dateKey]['total_transactions']++;
                    
                    // Compter les sessions (groupées par liste et heure)
                    $sessionKey = $dateKey . '-' . $spending['list_id'] . '-' . $spending['date']->format('H');
                    $sessionsByDay[$dateKey][$sessionKey] = true;
                }
            }

            // Finaliser les calculs et formater
            foreach ($dailyData as $dateKey => &$day) {
                $day['shopping_sessions'] = count($sessionsByDay[$dateKey] ?? []);
                $day['total_spent'] = round($day['total_spent'], 2);
                $day['formatted_total'] = is_callable([$targetCurrency, 'formatAmountDisplay']) 
                    ? $targetCurrency->formatAmountDisplay($day['total_spent'])
                    : '$' . number_format($day['total_spent'], 2);
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

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => $language,
                    'include_shared' => $includeShared,
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
                        'formatted_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                            ? $targetCurrency->formatAmountDisplay($totalSpent)
                            : '$' . number_format($totalSpent, 2)
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
     * ✅ HISTORIQUE DES DÉPENSES PAR ANNÉE
     */
    public function yearlySpendingHistory(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();
            
            $years = min((int)($params['years'] ?? 5), 10);
            $currency_code = $params['currency'] ?? null;
            $language = $this->getUserLanguage($request);
            $includeShared = ($params['include_shared'] ?? 'true') !== 'false';
            
            error_log("🔍 yearlySpendingHistory - User ID: $user_id, Years: $years");
            
            $user = User::with('currency')->find($user_id);
            if (!$user) {
                throw new \Exception('User not found');
            }

            // Déterminer la devise cible
            $targetCurrency = $currency_code ? 
                Currency::where('code', strtoupper($currency_code))->first() : 
                ($user->currency ?? Currency::where('code', 'CAD')->first());

            if (!$targetCurrency) {
                $targetCurrency = (object)[
                    'code' => 'CAD',
                    'symbol' => '$',
                    'formatAmountDisplay' => function($amount) {
                        return '$' . number_format($amount, 2);
                    }
                ];
            }

            // Calculer les dates
            $currentYear = Carbon::now()->year;
            $startYear = $currentYear - $years + 1;
            $endYear = $currentYear;

            $startDate = Carbon::create($startYear, 1, 1, 0, 0, 0);
            $endDate = Carbon::create($endYear, 12, 31, 23, 59, 59);

            // Récupérer les données de dépenses
            $spendingData = $this->getCombinedSpendingDataSafe($user_id, $startDate, $endDate);
            
            if (!$includeShared) {
                $ownListIds = ShoppingList::where('user_id', $user_id)->pluck('id')->toArray();
                $spendingData = array_filter($spendingData, function($spending) use ($ownListIds) {
                    return in_array($spending['list_id'], $ownListIds);
                });
            }

            // Créer les données par année
            $yearlyData = [];
            for ($year = $startYear; $year <= $endYear; $year++) {
                $yearlyData[$year] = [
                    'year' => $year,
                    'year_label' => (string)$year,
                    'is_current_year' => $year === $currentYear,
                    'total_spent' => 0.0,
                    'total_transactions' => 0,
                    'receipts_total' => 0.0,
                    'items_total' => 0.0,
                    'receipts_count' => 0,
                    'items_sessions' => 0,
                    'shopping_months' => 0,
                    'shopping_days' => 0,
                    'average_monthly' => 0.0,
                    'currency' => (string)$targetCurrency->code
                ];
            }

            // Calculer les totaux avec gestion d'erreur
            $monthsByYear = [];
            $daysByYear = [];
            
            foreach ($spendingData as $spending) {
                try {
                    if (!isset($spending['date']) || !isset($spending['amount'])) {
                        continue;
                    }
                    
                    $spendingYear = $spending['date']->year;
                    
                    if (!isset($yearlyData[$spendingYear])) {
                        continue;
                    }
                    
                    $amount = (float)$spending['amount'];
                    if ($amount <= 0) {
                        continue;
                    }
                    
                    // Ajouter aux totaux
                    $yearlyData[$spendingYear]['total_spent'] += $amount;
                    $yearlyData[$spendingYear]['total_transactions']++;
                    
                    $source = $spending['source'] ?? 'unknown';
                    if ($source === 'receipt') {
                        $yearlyData[$spendingYear]['receipts_total'] += $amount;
                        $yearlyData[$spendingYear]['receipts_count']++;
                    } else {
                        $yearlyData[$spendingYear]['items_total'] += $amount;
                        $yearlyData[$spendingYear]['items_sessions']++;
                    }
                    
                    // Compter les mois et jours uniques
                    $monthKey = $spending['date']->format('Y-m');
                    $dayKey = $spending['date']->format('Y-m-d');
                    $monthsByYear[$spendingYear][$monthKey] = true;
                    $daysByYear[$spendingYear][$dayKey] = true;
                    
                } catch (\Exception $e) {
                    error_log("⚠️ Error processing spending entry: " . $e->getMessage());
                    continue;
                }
            }

            // Finaliser les calculs
            foreach ($yearlyData as $year => &$data) {
                try {
                    $data['shopping_months'] = count($monthsByYear[$year] ?? []);
                    $data['shopping_days'] = count($daysByYear[$year] ?? []);
                    
                    if ($data['shopping_months'] > 0) {
                        $data['average_monthly'] = round($data['total_spent'] / $data['shopping_months'], 2);
                    } else {
                        $data['average_monthly'] = 0.0;
                    }
                    
                    // Arrondir les totaux
                    $data['total_spent'] = round($data['total_spent'], 2);
                    $data['receipts_total'] = round($data['receipts_total'], 2);
                    $data['items_total'] = round($data['items_total'], 2);
                    
                    // Formatage sécurisé
                    if (is_callable([$targetCurrency, 'formatAmountDisplay'])) {
                        $data['formatted_total'] = (string)$targetCurrency->formatAmountDisplay($data['total_spent']);
                        $data['formatted_average_monthly'] = (string)$targetCurrency->formatAmountDisplay($data['average_monthly']);
                    } else {
                        $symbol = $targetCurrency->symbol ?? '$';
                        $data['formatted_total'] = $symbol . number_format($data['total_spent'], 2);
                        $data['formatted_average_monthly'] = $symbol . number_format($data['average_monthly'], 2);
                    }
                    
                    // Qualité des données
                    if ($data['receipts_total'] > 0) {
                        $data['data_quality'] = 'high';
                    } elseif ($data['items_total'] > 0) {
                        $data['data_quality'] = 'medium';
                    } else {
                        $data['data_quality'] = 'none';
                    }
                    
                } catch (\Exception $e) {
                    error_log("⚠️ Error finalizing year $year data: " . $e->getMessage());
                    $data['data_quality'] = 'error';
                }
            }

            // Trier par année
            $sortedYearlyData = array_values($yearlyData);
            usort($sortedYearlyData, function($a, $b) {
                return $a['year'] <=> $b['year'];
            });

            // Calculs de tendance
            $values = array_column($sortedYearlyData, 'total_spent');
            $totalSpent = array_sum($values);
            $averageYearly = count(array_filter($values)) > 0 ? 
                $totalSpent / count(array_filter($values)) : 0;

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'language' => (string)$language,
                    'include_shared' => $includeShared,
                    'yearly_data' => $sortedYearlyData,
                    'summary' => [
                        'total_spent' => round($totalSpent, 2),
                        'average_yearly' => round($averageYearly, 2),
                        'currency' => (string)$targetCurrency->code,
                        'period' => [
                            'start_year' => (int)$startYear,
                            'end_year' => (int)$endYear,
                            'years_requested' => (int)$years
                        ],
                        'formatted_total' => is_callable([$targetCurrency, 'formatAmountDisplay']) 
                            ? $targetCurrency->formatAmountDisplay($totalSpent)
                            : ($targetCurrency->symbol ?? '$') . number_format($totalSpent, 2)
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("❌ Error in yearlySpendingHistory: " . $e->getMessage());
            
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
     * ✅ RAPPORT DE QUALITÉ DES DONNÉES
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

}