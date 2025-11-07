<?php
// test_campaign_email.php - Test d'envoi de l'email de campagne

require_once __DIR__ . '/vendor/autoload.php';

use App\Config\Config;
use App\Models\User;
use App\Services\MailSender;
use Illuminate\Database\Capsule\Manager as Capsule;

// Charger les variables d'environnement
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

// Initialiser la base de données
$capsule = new Capsule;
$capsule->addConnection([
    'driver'    => 'mysql',
    'host'      => Config::get('DB_HOST'),
    'database'  => Config::get('DB_NAME'),
    'username'  => Config::get('DB_USER'),
    'password'  => Config::get('DB_PASS'),
    'charset'   => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix'    => '',
]);

$capsule->setAsGlobal();
$capsule->bootEloquent();

echo "🧪 TEST D'ENVOI DE L'EMAIL DE CAMPAGNE\n";
echo "==========================================\n\n";

// Vérifier l'environnement
$env = Config::get('APP_ENV');
echo "📌 Environnement: {$env}\n";

// Compter les utilisateurs éligibles
$eligibleUsers = User::where('email_marketing_consent', true)
                    ->where('email_verified_at', '!=', null)
                    ->where('is_active', true)
                    ->whereNull('deletion_requested_at')
                    ->count();

echo "👥 Utilisateurs éligibles: {$eligibleUsers}\n";

if ($eligibleUsers > 0) {
    // Prendre le premier utilisateur pour les données
    $firstUser = User::where('email_marketing_consent', true)
                    ->where('email_verified_at', '!=', null)
                    ->where('is_active', true)
                    ->whereNull('deletion_requested_at')
                    ->first();

    if ($firstUser) {
        $unsubscribeUrl = $firstUser->getUnsubscribeUrl();

        echo "\n📧 Tentative d'envoi de l'email...\n";

        if ($env == 'dev') {
            $emailTo = 'm2atodev@gmail.com';
            echo "   → Mode DEV: Email sera envoyé à: {$emailTo}\n";
        } else {
            $emailTo = $firstUser->email;
            echo "   → Mode PROD: Email sera envoyé à: {$emailTo}\n";
        }

        echo "   → Prénom utilisé: {$firstUser->first_name}\n";
        echo "   → URL de désabonnement: {$unsubscribeUrl}\n\n";

        // Envoyer l'email
        $success = MailSender::sendNewVersionCampaign(
            $emailTo,
            $firstUser->first_name ?? 'Utilisateur',
            $unsubscribeUrl
        );

        if ($success) {
            echo "✅ Email envoyé avec succès!\n";
            echo "   → Vérifiez votre boîte mail: {$emailTo}\n";
        } else {
            echo "❌ Échec de l'envoi de l'email\n";
        }
    }
} else {
    echo "❌ Aucun utilisateur éligible trouvé\n";
}

echo "\n==========================================\n";
echo "✨ Test terminé\n";
