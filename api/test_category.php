<?php
// Test script pour débugger l'erreur 500

require_once __DIR__ . '/vendor/autoload.php';

use App\Config\Database;
use App\Models\Category;
use Dotenv\Dotenv;

// Charger l'environnement
$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

// Activer tous les rapports d'erreurs
error_reporting(E_ALL);
ini_set('display_errors', 1);

try {
    echo "1. Chargement de la configuration...\n";

    // Connecter à la base de données
    Database::connect(
        $_ENV['DB_CONNECTION'],
        $_ENV['DB_HOST'],
        $_ENV['DB_PORT'],
        $_ENV['DB_DATABASE'],
        $_ENV['DB_USERNAME'],
        $_ENV['DB_PASSWORD']
    );

    echo "2. Base de données connectée.\n";

    // Tester si la classe Category existe
    if (!class_exists('App\Models\Category')) {
        throw new Exception("La classe Category n'existe pas!");
    }

    echo "3. Classe Category trouvée.\n";

    // Tester une requête simple
    $count = Category::count();
    echo "4. Nombre de catégories en base : $count\n";

    // Tester la création d'une catégorie
    $userId = 1; // ID de test

    echo "5. Test de création d'une catégorie...\n";

    $category = Category::create([
        'user_id' => $userId,
        'name' => 'Test Catégorie',
        'icon_code' => 'category',
        'color_hex' => '#4CAF50',
        'order_index' => 0
    ]);

    echo "6. Catégorie créée avec succès! ID: " . $category->id . "\n";

    // Supprimer la catégorie de test
    $category->delete();
    echo "7. Catégorie de test supprimée.\n";

    echo "\n✅ TOUT FONCTIONNE CORRECTEMENT!\n";

} catch (\Exception $e) {
    echo "\n❌ ERREUR DÉTECTÉE:\n";
    echo "Message: " . $e->getMessage() . "\n";
    echo "Fichier: " . $e->getFile() . "\n";
    echo "Ligne: " . $e->getLine() . "\n";
    echo "\nTrace complète:\n" . $e->getTraceAsString() . "\n";
}