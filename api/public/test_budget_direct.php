<?php
// test_budget_direct.php - Test direct de votre budget

require __DIR__ . '/../vendor/autoload.php';

use App\Models\Budget;
use Carbon\Carbon;
use Dotenv\Dotenv;

$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

date_default_timezone_set('UTC');

App\Config\Database::connect(
    $_ENV['DB_CONNECTION'],
    $_ENV['DB_HOST'],
    $_ENV['DB_PORT'],
    $_ENV['DB_DATABASE'],
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD']
);

$budget = Budget::find(1);
$now = Carbon::now();

echo "=== VÉRIFICATION DES DATES ===\n";
echo "📅 Date/heure actuelle: " . $now->toDateTimeString() . " (UTC)\n";
echo "📅 Début du budget: " . $budget->start_date->toDateTimeString() . "\n";
echo "📅 Fin du budget: " . $budget->end_date->toDateTimeString() . "\n";

echo "\n🔍 COMPARAISONS:\n";
echo "- Budget commencé: " . ($budget->start_date->lte($now) ? 'OUI' : 'NON') . "\n";
echo "- Budget pas encore fini: " . ($budget->end_date->gte($now) ? 'OUI' : 'NON') . "\n";
echo "- Budget actuel (current): " . ($budget->start_date->lte($now) && $budget->end_date->gte($now) ? 'OUI' : 'NON') . "\n";

if ($budget->end_date->lt($now)) {
    $hoursAgo = $now->diffInHours($budget->end_date);
    echo "❌ BUDGET EXPIRÉ il y a {$hoursAgo} heures!\n";
} elseif ($budget->start_date->gt($now)) {
    $hoursUntil = $now->diffInHours($budget->start_date);
    echo "⏳ Budget commence dans {$hoursUntil} heures\n";
} else {
    $hoursLeft = $budget->end_date->diffInHours($now);
    echo "✅ Budget actif, reste {$hoursLeft} heures\n";
}

echo "\n💡 SOLUTION - Étendre la période du budget:\n";
echo "UPDATE budgets SET end_date = '" . $now->addDays(7)->format('Y-m-d') . "' WHERE id = 1;\n";

echo "\n🔄 TEST APRÈS EXTENSION (simulation):\n";
$budget->end_date = $now->copy()->addDays(7);
echo "- Nouvelle fin: " . $budget->end_date->toDateString() . "\n";
echo "- Serait actuel: " . ($budget->start_date->lte($now) && $budget->end_date->gte($now) ? 'OUI' : 'NON') . "\n";
echo "- Déclencherait alerte: " . ($budget->shouldShowAlert() ? 'OUI' : 'NON') . "\n";