<?php
// run_migration_language.php - Exécuter la migration pour ajouter le champ language

require __DIR__ . '/vendor/autoload.php';

use Dotenv\Dotenv;

// Charger les variables d'environnement
$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

echo "=== MIGRATION: Ajout du champ 'language' à la table users ===\n\n";

try {
    // Connexion directe à la base de données
    $dsn = sprintf(
        '%s:host=%s;port=%s;dbname=%s;charset=utf8mb4',
        $_ENV['DB_CONNECTION'],
        $_ENV['DB_HOST'],
        $_ENV['DB_PORT'],
        $_ENV['DB_DATABASE']
    );

    $pdo = new PDO(
        $dsn,
        $_ENV['DB_USERNAME'],
        $_ENV['DB_PASSWORD'],
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]
    );

    echo "✅ Connexion à la base de données réussie\n\n";

    // Vérifier si la colonne existe déjà
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'language'");
    $columnExists = $stmt->rowCount() > 0;

    if ($columnExists) {
        echo "⚠️  La colonne 'language' existe déjà dans la table users\n";
        echo "Migration déjà appliquée!\n";
        exit(0);
    }

    echo "1. Ajout de la colonne 'language' à la table users...\n";
    $pdo->exec("ALTER TABLE users ADD COLUMN language VARCHAR(2) DEFAULT 'fr' AFTER currency_id");
    echo "   ✅ Colonne ajoutée avec succès\n\n";

    echo "2. Création de l'index sur la colonne language...\n";
    $pdo->exec("CREATE INDEX idx_users_language ON users(language)");
    echo "   ✅ Index créé avec succès\n\n";

    echo "3. Mise à jour des utilisateurs existants...\n";
    $stmt = $pdo->exec("UPDATE users SET language = 'fr' WHERE language IS NULL");
    echo "   ✅ {$stmt} utilisateurs mis à jour avec la langue française par défaut\n\n";

    echo "4. Ajout du commentaire à la colonne...\n";
    $pdo->exec("ALTER TABLE users MODIFY COLUMN language VARCHAR(2) DEFAULT 'fr' COMMENT 'Langue préférée de l\'utilisateur (fr, en)'");
    echo "   ✅ Commentaire ajouté\n\n";

    // Vérifier le résultat
    echo "5. Vérification de la colonne créée...\n";
    $stmt = $pdo->query("SHOW FULL COLUMNS FROM users WHERE Field = 'language'");
    $column = $stmt->fetch();
    if ($column) {
        echo "   ✅ Colonne 'language' configurée:\n";
        echo "      - Type: {$column['Type']}\n";
        echo "      - Default: {$column['Default']}\n";
        echo "      - Commentaire: {$column['Comment']}\n\n";
    }

    echo "=== MIGRATION TERMINÉE AVEC SUCCÈS ===\n";
    echo "Le champ 'language' a été ajouté à la table users!\n";

} catch (\Exception $e) {
    echo "❌ ERREUR lors de la migration: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}
