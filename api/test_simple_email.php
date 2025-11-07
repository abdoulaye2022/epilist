<?php
// test_simple_email.php - Test simple d'envoi de l'email de campagne

require_once __DIR__ . '/vendor/autoload.php';

use App\Config\Config;
use App\Services\MailSender;

// Charger les variables d'environnement
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

echo "🧪 TEST SIMPLE D'ENVOI DE L'EMAIL DE CAMPAGNE\n";
echo "================================================\n\n";

// Vérifier l'environnement
$env = Config::get('APP_ENV');
echo "📌 Environnement: {$env}\n\n";

// Paramètres de test
$emailTo = 'm2atodev@gmail.com';
$firstName = 'Mohamed';
$unsubscribeUrl = 'https://m2atodev.com/api.epilist/public/unsubscribe/test-token-12345';

echo "📧 Tentative d'envoi de l'email...\n";
echo "   → Email destinataire: {$emailTo}\n";
echo "   → Prénom: {$firstName}\n";
echo "   → URL de désabonnement: {$unsubscribeUrl}\n\n";

// Envoyer l'email
try {
    $success = MailSender::sendNewVersionCampaign(
        $emailTo,
        $firstName,
        $unsubscribeUrl
    );

    if ($success) {
        echo "✅ Email envoyé avec succès!\n";
        echo "   → Vérifiez votre boîte mail: {$emailTo}\n";
        echo "   → Sujet: 🎉 EpiList 2.0.0 - 10 nouvelles fonctionnalités révolutionnaires !\n\n";
        echo "📝 L'email contient les nouvelles fonctionnalités suivantes:\n";
        echo "   1. 🎤 Ajout vocal intelligent\n";
        echo "   2. ✓✓ Détection des doublons\n";
        echo "   3. 💡 Suggestions d'habitudes d'achat\n";
        echo "   4. 📱 Scanner de code-barres\n";
        echo "   5. 💬 Messagerie de listes intégrée\n";
        echo "   6. 📶 Mode hors ligne avancé\n";
        echo "   7. 💰 Gestion complète des dépenses\n";
        echo "   8. 🎯 Budgets intelligents\n";
        echo "   9. 📊 Statistiques avancées\n";
        echo "  10. 🔔 Notifications temps réel\n";
    } else {
        echo "❌ Échec de l'envoi de l'email\n";
        echo "   → Vérifiez la configuration SMTP dans le fichier .env\n";
    }
} catch (Exception $e) {
    echo "❌ Erreur lors de l'envoi:\n";
    echo "   → " . $e->getMessage() . "\n";
}

echo "\n================================================\n";
echo "✨ Test terminé\n";
