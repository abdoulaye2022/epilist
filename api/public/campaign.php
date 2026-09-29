<?php
// public/campaign.php - SYSTÈME DE CAMPAGNE EMAIL EPILIST (JSON Response)

require __DIR__ . '/../vendor/autoload.php';

use App\Config\Config;
use App\Models\User;
use App\Services\MailSender;
use Carbon\Carbon;
use Dotenv\Dotenv;

// Charger les variables d'environnement
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// 🔒 GARDE : ce script envoie la campagne email à TOUTE la base et liste les
// destinataires. Exécution autorisée uniquement en CLI, ou en HTTP avec le
// secret CRON_SECRET (?key=... ou header X-Cron-Key). Sans secret configuré,
// tout accès HTTP est refusé (fail closed).
if (php_sapi_name() !== 'cli') {
    $expectedKey = $_ENV['CRON_SECRET'] ?? '';
    $providedKey = $_GET['key'] ?? ($_SERVER['HTTP_X_CRON_KEY'] ?? '');
    if ($expectedKey === '' || !hash_equals($expectedKey, (string)$providedKey)) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Forbidden']);
        exit;
    }
}

// Configuration UTC globale
date_default_timezone_set('UTC');
Carbon::setLocale('fr');

// Initialiser la base de données
App\Config\Database::connect(
    $_ENV['DB_CONNECTION'],
    $_ENV['DB_HOST'],
    $_ENV['DB_PORT'],
    $_ENV['DB_DATABASE'],
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD']
);

// Headers pour réponse JSON
header('Content-Type: application/json; charset=utf-8');

// Variable pour collecter les résultats
$response = [
    'success' => false,
    'timestamp' => Carbon::now()->format('Y-m-d H:i:s') . ' UTC',
    'environment' => Config::get('APP_ENV'),
    'data' => [],
    'errors' => []
];

try {
    $env = Config::get('APP_ENV');

    // Récupérer les utilisateurs éligibles (les désabonnés sont exclus par
    // email_marketing_consent, basculé à false lors du désabonnement).
    $users = User::where('email_marketing_consent', true)
        ->where('email_verified_at', '!=', null)
        ->where('is_active', true)
        ->whereNull('deletion_requested_at')
        ->select(['id', 'email', 'first_name', 'language', 'unsubscribe_token'])
        ->get();

    $totalUsers = $users->count();

    $response['data']['total_eligible_users'] = $totalUsers;
    $response['data']['campaign'] = 'nouveautes-2026-09';
    $response['data']['subject_fr'] = 'Du nouveau dans EpiList : scanner de reçus, suggestions et plus';
    $response['data']['subject_en'] = "What's new in EpiList: receipt scanner, smart suggestions and more";

    if ($totalUsers === 0) {
        $response['success'] = false;
        $response['message'] = 'Aucun utilisateur éligible trouvé';
        echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        exit;
    }

    // MODE DEV: Un seul email
    if ($env === 'dev') {
        $response['data']['mode'] = 'development';
        $response['data']['warning'] = 'Mode DEV: Un seul email envoyé à m2atodev@gmail.com';

        $firstUser = $users->first();
        $unsubscribeUrl = $firstUser->getUnsubscribeUrl();

        // ?lang=en (HTTP) ou `php campaign.php en` (CLI) pour tester la
        // version anglaise du gabarit.
        $cliLang = (php_sapi_name() === 'cli' && isset($argv[1])) ? $argv[1] : null;
        $testLang = ($cliLang ?? $_GET['lang'] ?? $firstUser->language ?? 'fr') === 'en' ? 'en' : 'fr';

        $emailSent = MailSender::sendUpdateCampaign(
            'm2atodev@gmail.com',
            $firstUser->first_name ?? 'Utilisateur',
            $testLang,
            $unsubscribeUrl
        );

        if ($emailSent) {
            $response['success'] = true;
            $response['message'] = 'Email de test envoyé avec succès';
            $response['data']['email_sent_to'] = 'm2atodev@gmail.com';
            $response['data']['first_name_used'] = $firstUser->first_name ?? 'Utilisateur';
            $response['data']['lang_used'] = $testLang;
            $response['data']['unsubscribe_url_included'] = true;
            $response['data']['emails_sent'] = 1;
            $response['data']['emails_failed'] = 0;
            $response['data']['next_steps'] = [
                'Tester l\'autre langue : campaign.php?lang=en',
                'Pour envoyer en production: APP_ENV=production puis relancer campaign.php',
            ];
        } else {
            $response['success'] = false;
            $response['message'] = 'Échec de l\'envoi de l\'email de test';
            $response['data']['emails_sent'] = 0;
            $response['data']['emails_failed'] = 1;
            $response['errors'][] = 'Impossible d\'envoyer l\'email à m2atodev@gmail.com';
        }

    } else {
        // MODE PRODUCTION: Envoi à tous les utilisateurs
        $response['data']['mode'] = 'production';
        $response['data']['warning'] = "ATTENTION: {$totalUsers} emails vont être envoyés aux vrais utilisateurs";

        $emailsSent = 0;
        $emailsFailed = 0;
        $batchSize = 50;
        $startTime = time();
        $sentDetails = [];
        $failedDetails = [];

        foreach ($users->chunk($batchSize) as $batchIndex => $batch) {
            foreach ($batch as $user) {
                try {
                    $unsubscribeUrl = $user->getUnsubscribeUrl();

                    // Chaque utilisateur reçoit la campagne dans SA langue.
                    $lang = ($user->language ?? 'fr') === 'en' ? 'en' : 'fr';

                    $success = MailSender::sendUpdateCampaign(
                        $user->email,
                        $user->first_name ?? 'Utilisateur',
                        $lang,
                        $unsubscribeUrl
                    );

                    if ($success) {
                        $emailsSent++;
                        $sentDetails[] = $user->email;
                    } else {
                        $emailsFailed++;
                        $failedDetails[] = $user->email;
                    }

                    usleep(100000); // 0.1 seconde

                } catch (\Exception $e) {
                    $emailsFailed++;
                    $failedDetails[] = $user->email;
                    $response['errors'][] = "{$user->email}: " . $e->getMessage();
                }
            }

            // Pause entre les lots
            sleep(1);
        }

        $duration = time() - $startTime;
        $successRate = $totalUsers > 0 ? round(($emailsSent / $totalUsers) * 100, 2) : 0;

        $response['success'] = $emailsSent > 0;
        $response['message'] = "Campagne terminée: {$emailsSent}/{$totalUsers} emails envoyés";
        $response['data']['emails_sent'] = $emailsSent;
        $response['data']['emails_failed'] = $emailsFailed;
        $response['data']['success_rate'] = $successRate . '%';
        $response['data']['duration_seconds'] = $duration;
        $response['data']['batch_size'] = $batchSize;

        // Limiter les détails pour ne pas surcharger la réponse
        if (count($sentDetails) <= 20) {
            $response['data']['sent_to'] = $sentDetails;
        } else {
            $response['data']['sent_to_sample'] = array_slice($sentDetails, 0, 20);
            $response['data']['sent_to_note'] = 'Showing first 20 emails only';
        }

        if (count($failedDetails) > 0) {
            $response['data']['failed_emails'] = $failedDetails;
        }
    }

} catch (\Exception $e) {
    $response['success'] = false;
    $response['message'] = 'Erreur lors de l\'exécution de la campagne';
    $response['errors'][] = $e->getMessage();
    $response['data']['error_details'] = [
        'file' => $e->getFile(),
        'line' => $e->getLine(),
        'trace' => explode("\n", $e->getTraceAsString())
    ];
    error_log("Campaign error: " . $e->getMessage());
}

// Retourner la réponse JSON
echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
