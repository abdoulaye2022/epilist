<?php
// scripts/seed_product_images.php - Remonte les photos deja prises.
//
// La logique vit dans App\Services\ProductImageSeeder, partagee avec
// public/seed_product_images.php : la PRODUCTION s'administre par
// phpMyAdmin et FTP, sans acces SSH, donc le semis doit aussi pouvoir
// se declencher par URL.
//
// Usage : php scripts/seed_product_images.php [--dry]
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

use App\Services\ProductImageSeeder;

$sec = in_array('--dry', array_slice($argv, 1), true);

$pdo = new PDO(
    "mysql:host={$_ENV['DB_HOST']};port={$_ENV['DB_PORT']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD'],
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$resultat = (new ProductImageSeeder($pdo))->run($sec);

echo "Articles avec photo : {$resultat['articles']}\n";
foreach ($resultat['lignes'] as $l) {
    echo "  $l\n";
}
echo $sec
    ? "\n(--dry : rien n'a ete ecrit)\n"
    : "\n{$resultat['posees']} photos posees, {$resultat['perimees']} clefs perimees retirees."
      . " product_images contient {$resultat['total']} lignes.\n";
