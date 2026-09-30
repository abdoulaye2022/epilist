<?php
// public/community_refresh.php - RECALCUL DES PRIX COMMUNAUTAIRES (§33)
//
// Reconstruit les agrégats anonymisés community_prices (fenêtre 90 j,
// règles de qualité : contributeurs distincts, observations minimales,
// valeurs aberrantes écartées). À planifier en cron (1x/jour suffit).
//
// Usage :
//   CLI  : php public/community_refresh.php
//   HTTP : GET /community_refresh.php?key=CRON_SECRET
//          (ou en-tête X-Cron-Key)

require __DIR__ . '/../vendor/autoload.php';

use App\Services\CommunityPriceService;
use Dotenv\Dotenv;

$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// 🔒 GARDE : même politique que campaign.php — CLI libre, HTTP exige le
// secret CRON_SECRET. Sans secret configuré, tout accès HTTP est refusé.
if (php_sapi_name() !== 'cli') {
    $expectedKey = $_ENV['CRON_SECRET'] ?? '';
    $providedKey = $_GET['key'] ?? ($_SERVER['HTTP_X_CRON_KEY'] ?? '');
    if ($expectedKey === '' || !hash_equals($expectedKey, (string) $providedKey)) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Forbidden']);
        exit;
    }
}

date_default_timezone_set('UTC');

App\Config\Database::connect(
    $_ENV['DB_CONNECTION'],
    $_ENV['DB_HOST'],
    $_ENV['DB_PORT'],
    $_ENV['DB_DATABASE'],
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD']
);

header('Content-Type: application/json; charset=utf-8');

try {
    $stats = CommunityPriceService::refresh();
    echo json_encode([
        'success' => true,
        'mode' => $_ENV['APP_ENV'] ?? 'unknown',
        'stats' => $stats,
    ]);
} catch (\Throwable $e) {
    error_log('community_refresh: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur de recalcul']);
}
