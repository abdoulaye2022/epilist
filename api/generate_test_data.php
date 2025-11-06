<?php
/**
 * Script de génération de données de test pour les suggestions intelligentes
 * Usage: php generate_test_data.php [user_id]
 */

require 'vendor/autoload.php';

use Illuminate\Database\Capsule\Manager as Capsule;

// Configuration de la base de données
$capsule = new Capsule;
$capsule->addConnection([
    'driver' => 'mysql',
    'host' => 'localhost',
    'database' => 'epilist',
    'username' => 'root',
    'password' => '',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix' => '',
]);

$capsule->setAsGlobal();
$capsule->bootEloquent();

// Récupérer l'ID utilisateur depuis les arguments
$userId = isset($argv[1]) ? (int)$argv[1] : 1;

echo "🎯 Génération de données de test pour l'utilisateur #$userId\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

// Vérifier que l'utilisateur existe
$user = Capsule::table('users')->where('id', $userId)->first();
if (!$user) {
    echo "❌ Erreur: L'utilisateur #$userId n'existe pas!\n";
    echo "📋 Utilisateurs disponibles:\n";
    $users = Capsule::table('users')->select('id', 'first_name', 'last_name', 'email')->get();
    foreach ($users as $u) {
        echo "   - ID: {$u->id} | {$u->first_name} {$u->last_name} ({$u->email})\n";
    }
    exit(1);
}

echo "✅ Utilisateur trouvé: {$user->first_name} {$user->last_name}\n\n";

// Vérifier qu'il y a des listes
$lists = Capsule::table('shopping_lists')
    ->where('user_id', $userId)
    ->whereNull('deleted_at')
    ->get();

if ($lists->isEmpty()) {
    echo "⚠️  Aucune liste trouvée. Création d'une liste de test...\n";
    $listId = Capsule::table('shopping_lists')->insertGetId([
        'user_id' => $userId,
        'name' => 'Liste de Test pour Suggestions',
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    echo "✅ Liste créée (ID: $listId)\n\n";
} else {
    $listId = $lists->first()->id;
    echo "✅ Utilisation de la liste #{$listId}: {$lists->first()->name}\n\n";
}

// Produits de test avec variations
$products = [
    // Produits réguliers (achetés fréquemment)
    ['name' => 'Lait', 'category' => 16, 'price_range' => [1.20, 1.80], 'qty_range' => [1, 2], 'frequency' => 7], // Produits laitiers - tous les 7 jours
    ['name' => 'Pain', 'category' => 17, 'price_range' => [1.00, 1.50], 'qty_range' => [1, 2], 'frequency' => 3], // Boulangerie - tous les 3 jours
    ['name' => 'Oeufs', 'category' => 16, 'price_range' => [2.50, 3.50], 'qty_range' => [6, 12], 'frequency' => 10], // Produits laitiers
    ['name' => 'Poulet', 'category' => 15, 'price_range' => [5.00, 8.00], 'qty_range' => [1, 2], 'frequency' => 14], // Viandes & Poissons
    ['name' => 'Riz', 'category' => 25, 'price_range' => [2.00, 4.00], 'qty_range' => [1, 2], 'frequency' => 21], // Autre

    // Produits occasionnels
    ['name' => 'Fromage', 'category' => 16, 'price_range' => [3.00, 6.00], 'qty_range' => [1, 1], 'frequency' => 14], // Produits laitiers
    ['name' => 'Tomates', 'category' => 14, 'price_range' => [1.50, 3.00], 'qty_range' => [1, 2], 'frequency' => 7], // Fruits & Légumes
    ['name' => 'Bananes', 'category' => 14, 'price_range' => [1.00, 2.00], 'qty_range' => [1, 2], 'frequency' => 5], // Fruits & Légumes

    // Produits associés (souvent achetés ensemble)
    ['name' => 'Beurre', 'category' => 16, 'price_range' => [2.00, 3.50], 'qty_range' => [1, 1], 'frequency' => 3], // Produits laitiers - avec Pain
    ['name' => 'Confiture', 'category' => 19, 'price_range' => [2.50, 4.00], 'qty_range' => [1, 1], 'frequency' => 21], // Snacks & Sucreries - avec Pain
    ['name' => 'Chocolat', 'category' => 19, 'price_range' => [1.50, 3.00], 'qty_range' => [1, 2], 'frequency' => 7], // Snacks & Sucreries
];

echo "📦 Génération de l'historique d'achats (simulation sur 90 jours)...\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

$totalInserted = 0;
$startDate = new DateTime('-90 days');
$today = new DateTime();

foreach ($products as $product) {
    $purchaseCount = 0;
    $currentDate = clone $startDate;

    echo "\n📍 {$product['name']} (fréquence: tous les {$product['frequency']} jours)\n";

    while ($currentDate <= $today) {
        // Ajouter une variation aléatoire (+/- 2 jours)
        $variation = rand(-2, 2);
        $purchaseDate = clone $currentDate;
        $purchaseDate->modify("+$variation days");

        if ($purchaseDate > $today) {
            break;
        }

        // Prix et quantité aléatoires dans la plage
        $price = rand($product['price_range'][0] * 100, $product['price_range'][1] * 100) / 100;
        $quantity = rand($product['qty_range'][0], $product['qty_range'][1]);

        // Déterminer la saison
        $month = (int)$purchaseDate->format('n');
        $season = match(true) {
            $month >= 3 && $month <= 5 => 'spring',
            $month >= 6 && $month <= 8 => 'summer',
            $month >= 9 && $month <= 11 => 'fall',
            default => 'winter',
        };

        // Insérer dans purchase_history
        Capsule::table('purchase_history')->insert([
            'user_id' => $userId,
            'product_name' => $product['name'],
            'normalized_name' => strtolower(trim($product['name'])),
            'category_id' => $product['category'],
            'quantity' => $quantity,
            'price' => $price,
            'store_name' => ['Carrefour', 'Auchan', 'Leclerc'][rand(0, 2)],
            'list_id' => $listId,
            'purchased_at' => $purchaseDate->format('Y-m-d H:i:s'),
            'day_of_week' => $purchaseDate->format('N'),
            'month' => $month,
            'season' => $season,
        ]);

        $purchaseCount++;
        $totalInserted++;

        echo "   ✓ Achat #{$purchaseCount}: {$purchaseDate->format('Y-m-d')} - {$quantity}x à {$price}€\n";

        // Passer à la prochaine date d'achat
        $currentDate->modify("+{$product['frequency']} days");
    }
}

echo "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "✅ Total: $totalInserted achats insérés dans l'historique\n\n";

// Calculer les patterns
echo "🔄 Calcul des patterns d'achat...\n";
Capsule::statement("CALL calculate_purchase_patterns(?)", [$userId]);
echo "✅ Patterns calculés avec succès!\n\n";

// Afficher les statistiques
echo "📊 Statistiques des patterns:\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

$patterns = Capsule::table('user_purchase_patterns')
    ->where('user_id', $userId)
    ->orderBy('frequency_score', 'desc')
    ->get();

foreach ($patterns as $pattern) {
    $suggestionScore = ($pattern->frequency_score * 0.4) +
                       ($pattern->recency_score * 0.35) +
                       ($pattern->regularity_score * 0.25);

    $confidence = match(true) {
        $suggestionScore >= 70 => '🟢 Élevée',
        $suggestionScore >= 40 => '🟠 Moyenne',
        default => '⚫ Faible',
    };

    echo sprintf(
        "\n📦 %s\n   Score: %.1f%% %s\n   Achats: %d fois | Fréquence: %.1f jours | Dernière fois: %s\n   Prochaine suggestion: %s\n",
        $pattern->product_name,
        $suggestionScore,
        $confidence,
        $pattern->total_purchases,
        $pattern->avg_days_between ?? 0,
        $pattern->last_purchased_at,
        $pattern->next_suggested_date ?? 'N/A'
    );
}

echo "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "🎉 Génération terminée avec succès!\n\n";
echo "💡 Comment tester:\n";
echo "   1. Ouvrez l'application EpiList\n";
echo "   2. Créez une nouvelle liste ou ouvrez une liste existante\n";
echo "   3. Cliquez sur 'Ajouter un article'\n";
echo "   4. Vous verrez les suggestions intelligentes apparaître!\n\n";
