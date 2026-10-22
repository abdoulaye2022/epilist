<?php
// src/Services/ProductImageSeeder.php — remonte les photos deja prises.
//
// `list_items.image_url` existe depuis longtemps : une photo prise sur
// un article d'une liste. Mais elle restait prisonniere de CET article,
// de CETTE liste. product_images (migration 012) la rattache au
// PRODUIT, pour que l'alerte de prix, la suggestion et l'historique
// puissent l'afficher a leur tour.
//
// La logique vit ici, et non dans le script, parce qu'elle a DEUX
// appelants : la ligne de commande (scripts/seed_product_images.php) et
// l'URL protegee (public/seed_product_images.php), pour les
// hebergements sans acces SSH — c'est le cas de la production.

namespace App\Services;

use App\Models\PurchaseHistory;
use PDO;

class ProductImageSeeder
{
    public function __construct(private PDO $pdo)
    {
    }

    /**
     * @return array{articles:int, posees:int, perimees:int, total:int, lignes:array<int,string>}
     */
    public function run(bool $dryRun = false): array
    {
        $lignes = [];

        // La photo la plus RECENTE gagne, par produit et par espace.
        $articles = $this->pdo->query("
            SELECT li.product_name,
                   li.image_url,
                   li.created_by_user_id,
                   sl.space_id
              FROM list_items li
              JOIN shopping_lists sl ON sl.id = li.list_id
             WHERE li.image_url IS NOT NULL
               AND li.image_url <> ''
               AND li.deleted_at IS NULL
               AND sl.deleted_at IS NULL
             ORDER BY li.updated_at ASC
        ")->fetchAll(PDO::FETCH_ASSOC);

        $insert = $this->pdo->prepare("
            INSERT INTO product_images
                (space_id, normalized_name, product_label, image_url, source, created_by_user_id)
            VALUES (:space_id, :normalized_name, :product_label, :image_url, 'user', :user_id)
            ON DUPLICATE KEY UPDATE
                image_url = VALUES(image_url),
                product_label = VALUES(product_label),
                updated_at = CURRENT_TIMESTAMP
        ");

        $posees = 0;
        foreach ($articles as $a) {
            $clef = PurchaseHistory::normalizeProductName((string) $a['product_name']);
            if ($clef === '') {
                continue;
            }
            $lignes[] = sprintf('%s -> %s', $a['product_name'], $clef);
            if ($dryRun) {
                continue;
            }
            $insert->execute([
                ':space_id'        => $a['space_id'],
                ':normalized_name' => $clef,
                ':product_label'   => $a['product_name'],
                ':image_url'       => $a['image_url'],
                ':user_id'         => $a['created_by_user_id'],
            ]);
            $posees++;
        }

        // Clefs perimees : la clef DOIT etre la normalisation de
        // l'etiquette. Le normaliseur a ete corrige le 2026-10-22 (les
        // ligatures œ et æ), et les lignes posees sous l'ancienne clef
        // resteraient invisibles, jamais retrouvees.
        $perimees = 0;
        $efface = $this->pdo->prepare('DELETE FROM product_images WHERE id = :id');
        $existantes = $this->pdo
            ->query('SELECT id, normalized_name, product_label FROM product_images')
            ->fetchAll(PDO::FETCH_ASSOC);
        foreach ($existantes as $l) {
            $attendue = PurchaseHistory::normalizeProductName((string) $l['product_label']);
            if ($attendue === $l['normalized_name']) {
                continue;
            }
            $lignes[] = sprintf(
                'clef perimee : "%s" devrait etre "%s"',
                $l['normalized_name'],
                $attendue
            );
            if ($dryRun) {
                continue;
            }
            $efface->execute([':id' => $l['id']]);
            $perimees++;
        }

        return [
            'articles' => count($articles),
            'posees' => $posees,
            'perimees' => $perimees,
            'total' => (int) $this->pdo->query('SELECT COUNT(*) FROM product_images')->fetchColumn(),
            'lignes' => $lignes,
        ];
    }
}
