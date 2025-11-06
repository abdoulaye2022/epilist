<?php
// Test du contrôleur

require_once __DIR__ . '/vendor/autoload.php';

use App\Config\Database;
use App\Controllers\CategoryController;
use Dotenv\Dotenv;
use Slim\Psr7\Factory\ServerRequestFactory;
use Slim\Psr7\Factory\ResponseFactory;

// Charger l'environnement
$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

// Activer tous les rapports d'erreurs
error_reporting(E_ALL);
ini_set('display_errors', 1);

try {
    echo "1. Configuration de la base de données...\n";

    // Connecter à la base de données
    Database::connect(
        $_ENV['DB_CONNECTION'],
        $_ENV['DB_HOST'],
        $_ENV['DB_PORT'],
        $_ENV['DB_DATABASE'],
        $_ENV['DB_USERNAME'],
        $_ENV['DB_PASSWORD']
    );

    echo "2. Création du contrôleur...\n";
    $controller = new CategoryController();

    echo "3. Création de la requête et réponse simulées...\n";

    // Créer une requête et réponse simulées
    $requestFactory = new ServerRequestFactory();
    $request = $requestFactory->createServerRequest('POST', '/categories/initialize-defaults');
    $request = $request->withAttribute('user_id', 1); // Simuler un user ID

    $responseFactory = new ResponseFactory();
    $response = $responseFactory->createResponse();

    echo "4. Appel de la méthode initializeDefaults...\n";

    // Appeler la méthode
    $result = $controller->initializeDefaults($request, $response);

    echo "5. Résultat obtenu avec statut: " . $result->getStatusCode() . "\n";

    $body = (string) $result->getBody();
    echo "6. Corps de la réponse:\n" . $body . "\n";

    echo "\n✅ TEST RÉUSSI!\n";

} catch (\Exception $e) {
    echo "\n❌ ERREUR CAPTURÉE:\n";
    echo "Message: " . $e->getMessage() . "\n";
    echo "Fichier: " . $e->getFile() . "\n";
    echo "Ligne: " . $e->getLine() . "\n";
    echo "\nTrace:\n" . $e->getTraceAsString() . "\n";
}