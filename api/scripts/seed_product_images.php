<?php
// scripts/seed_product_images.php - Remonte les photos deja prises.
//
// `list_items.image_url` existe depuis longtemps : une photo prise sur
// un article d'une liste. Mais elle restait prisonniere de CET article,
// de CETTE liste. La table product_images (migration 012) la rattache au
// PRODUIT, pour que l'alerte de prix, la suggestion et l'historique
// puissent l'afficher a leur tour.
//
// Ce remplissage est idempotent : rejouable, il ne duplique rien et
// n'ecrase pas une photo plus recente.
//
// La normalisation passe par PurchaseHistory::normalizeProductName, et
// non par une expression SQL : c'est la meme clef que purchase_history,
// product_aliases et community_prices. Deux implementations des memes
// regles finiraient par diverger, et les photos cesseraient de se
// retrouver.
//
// Usage : php scripts/seed_product_images.php [--dry]
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

use App\Models\PurchaseHistory;

$sec = in_array('--dry', array_slice($argv, 1), true);

$pdo = new PDO(
    "mysql:host={$_ENV['DB_HOST']};port={$_ENV['DB_PORT']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD'],
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

// La photo la plus RECENTE gagne, par produit et par espace.
$articles = $pdo->query("
    SELECT li.product_name,
           li.image_url,
           li.created_by_user_id,
           sl.space_id,
           li.updated_at
      FROM list_items li
      JOIN shopping_lists sl ON sl.id = li.list_id
     WHERE li.image_url IS NOT NULL
       AND li.image_url <> ''
       AND li.deleted_at IS NULL
       AND sl.deleted_at IS NULL
     ORDER BY li.updated_at ASC
")->fetchAll(PDO::FETCH_ASSOC);

echo "Articles avec photo : " . count($articles) . "\n";

$insert = $pdo->prepare("
    INSERT INTO product_images
        (space_id, normalized_name, product_label, image_url, source, created_by_user_id)
    VALUES (:space_id, :normalized_name, :product_label, :image_url, 'user', :user_id)
    ON DUPLICATE KEY UPDATE
        image_url = VALUES(image_url),
        product_label = VALUES(product_label),
        updated_at = CURRENT_TIMESTAMP
");

$poses = 0;
foreach ($articles as $a) {
    $clef = PurchaseHistory::normalizeProductName((string) $a['product_name']);
    if ($clef === '') {
        continue;
    }
    printf("  %-40s -> %s\n", substr((string) $a['product_name'], 0, 40), $clef);
    if ($sec) {
        continue;
    }
    $insert->execute([
        ':space_id'        => $a['space_id'],
        ':normalized_name' => $clef,
        ':product_label'   => $a['product_name'],
        ':image_url'       => $a['image_url'],
        ':user_id'         => $a['created_by_user_id'],
    ]);
    $poses++;
}

// Clefs perimees : la clef DOIT etre la normalisation de l'etiquette.
// Si le normaliseur est corrige — il l'a ete le 2026-10-22, pour les
// ligatures œ et æ — les lignes posees sous l'ancienne clef restent,
// invisibles et jamais retrouvees. On les retire ici plutot que de les
// laisser pourrir.
$perimees = 0;
$lignes = $pdo->query('SELECT id, normalized_name, product_label FROM product_images')
              ->fetchAll(PDO::FETCH_ASSOC);
$efface = $pdo->prepare('DELETE FROM product_images WHERE id = :id');
foreach ($lignes as $l) {
    $attendue = PurchaseHistory::normalizeProductName((string) $l['product_label']);
    if ($attendue === $l['normalized_name']) {
        continue;
    }
    printf("  clef perimee : \"%s\" devrait etre \"%s\"\n", $l['normalized_name'], $attendue);
    if (!$sec) {
        $efface->execute([':id' => $l['id']]);
        $perimees++;
    }
}

$total = $pdo->query('SELECT COUNT(*) FROM product_images')->fetchColumn();
echo $sec
    ? "\n(--dry : rien n'a ete ecrit)\n"
    : "\n$poses photos posees, $perimees clefs perimees retirees."
      . " product_images contient $total lignes.\n";
