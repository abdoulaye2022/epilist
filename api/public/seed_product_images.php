<?php
// public/seed_product_images.php - SEMIS DES PHOTOS DE PRODUITS (migration 012)
//
// Remonte les photos deja prises sur les articles de liste vers la table
// partagee product_images, pour que l'alerte de prix et les suggestions
// puissent les afficher a leur tour.
//
// Cette porte HTTP existe parce que la PRODUCTION s'administre par
// phpMyAdmin et FTP, sans acces SSH : sans elle, le semis serait
// injouable la ou il sert.
//
// Usage :
//   CLI  : php public/seed_product_images.php
//   HTTP : GET /seed_product_images.php?key=CRON_SECRET
//          (ou en-tete X-Cron-Key)
//   Ajouter &dry=1 pour voir sans rien ecrire.
//
// Idempotent : rejouable, il ne duplique rien.

require __DIR__ . '/../vendor/autoload.php';

use App\Services\ProductImageSeeder;
use Dotenv\Dotenv;

$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// 🔒 GARDE : meme politique que community_refresh.php — CLI libre, HTTP
// exige le secret CRON_SECRET. Sans secret configure, tout acces HTTP
// est refuse, plutot que laisse ouvert.
if (php_sapi_name() !== 'cli') {
    $attendu = $_ENV['CRON_SECRET'] ?? '';
    $fourni = $_GET['key'] ?? ($_SERVER['HTTP_X_CRON_KEY'] ?? '');
    if ($attendu === '' || !hash_equals($attendu, (string) $fourni)) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Forbidden']);
        exit;
    }
}

$sec = php_sapi_name() === 'cli'
    ? in_array('--dry', array_slice($argv, 1), true)
    : isset($_GET['dry']);

try {
    $pdo = new PDO(
        "mysql:host={$_ENV['DB_HOST']};port={$_ENV['DB_PORT']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
        $_ENV['DB_USERNAME'],
        $_ENV['DB_PASSWORD'],
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    $resultat = (new ProductImageSeeder($pdo))->run($sec);
} catch (Throwable $e) {
    // La table product_images vient de la migration 012 : si elle
    // n'existe pas, c'est que la migration n'a pas ete jouee, et le
    // dire vaut mieux qu'une trace de pile.
    $message = str_contains($e->getMessage(), 'product_images')
        ? "La table product_images n'existe pas : jouer d'abord migrations/012_planche_version_b.sql."
        : $e->getMessage();
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['success' => false, 'message' => $message], JSON_UNESCAPED_UNICODE);
    exit(1);
}

if (php_sapi_name() === 'cli') {
    echo "Articles avec photo : {$resultat['articles']}\n";
    foreach ($resultat['lignes'] as $l) {
        echo "  $l\n";
    }
    echo $sec
        ? "\n(--dry : rien n'a ete ecrit)\n"
        : "\n{$resultat['posees']} photos posees, {$resultat['perimees']} clefs perimees retirees."
          . " product_images contient {$resultat['total']} lignes.\n";
    exit(0);
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'success' => true,
    'dry_run' => $sec,
    'data' => $resultat,
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
