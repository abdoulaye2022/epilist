<?php
// src/Controllers/CampaignController.php

namespace App\Controllers;

use App\Models\User;
use App\Services\MailSender;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;
use Exception;
use App\Config\Config;
use Carbon\Carbon;

class CampaignController
{
    /**
     *  Lancer la campagne de nouvelle version pour tous les utilisateurs actifs
     */
    public function sendNewVersionCampaign(Request $request, Response $response): Response
    {
        try {
            $data = $request->getParsedBody();
            
            // Validation des paramètres optionnels
            $validator = new Validator($data ?? []);
            $validator->rule('in', 'test_mode', ['true', 'false'])->message('Test mode must be true or false');
            $validator->rule('email', 'test_email')->message('Test email must be valid');
            $validator->rule('integer', 'batch_size')->message('Batch size must be an integer');
            $validator->rule('min', 'batch_size', 1)->message('Batch size must be at least 1');
            $validator->rule('max', 'batch_size', 100)->message('Batch size cannot exceed 100');

            if (!$validator->validate()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Invalid input parameters',
                        'validation_errors' => $validator->errors()
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            // Configuration
            $testMode = isset($data['test_mode']) && $data['test_mode'] === 'true';
            $testEmail = $data['test_email'] ?? null;
            $batchSize = isset($data['batch_size']) ? (int)$data['batch_size'] : 50;
            
            // Mode test : envoyer seulement à l'email de test
            if ($testMode) {
                if (!$testEmail) {
                    $response->getBody()->write(json_encode([
                        'success' => false,
                        'error' => [
                            'code' => 'MISSING_TEST_EMAIL',
                            'message' => 'Test email is required in test mode'
                        ]
                    ]));
                    return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
                }

                // In dev environment, override email for testing
                if(Config::get('APP_ENV') == 'dev') {
                    $testEmail = 'm2atodev@gmail.com';
                }

                $success = MailSender::sendNewVersionCampaign($testEmail, 'Utilisateur Test');
                
                $response->getBody()->write(json_encode([
                    'success' => true,
                    'data' => [
                        'mode' => 'test',
                        'emails_sent' => $success ? 1 : 0,
                        'test_email' => $testEmail,
                        'email_sent_successfully' => $success
                    ],
                    'message' => $success ? 'Test email sent successfully' : 'Test email failed to send'
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            //  CORRECTION: Mode production avec requête directe pour utilisateurs éligibles
            if (Config::get('APP_ENV') == 'dev') {
                //  EN DEV: Filtrer les utilisateurs éligibles et envoyer UN SEUL EMAIL
                $users = User::where('email_marketing_consent', true)
                            ->where('email_verified_at', '!=', null)
                            ->where('is_active', true)
                            ->whereNull('deletion_requested_at')
                            ->select(['id', 'email', 'first_name', 'unsubscribe_token'])
                            ->get();

                $totalUsersInDB = $users->count();

                if ($totalUsersInDB > 0) {
                    // Prendre le premier utilisateur pour les données, mais envoyer à l'email de dev
                    $firstUser = $users->first();
                    $unsubscribeUrl = $firstUser->getUnsubscribeUrl();
                    
                    //  ENVOI D'UN SEUL EMAIL à l'adresse de dev
                    $success = MailSender::sendNewVersionCampaign(
                        'm2atodev@gmail.com', // Email fixe en dev
                        $firstUser->first_name ?? 'Utilisateur Dev',
                        $unsubscribeUrl
                    );

                    $response->getBody()->write(json_encode([
                        'success' => true,
                        'data' => [
                            'mode' => 'production_dev',
                            'environment' => 'development',
                            'total_users_in_db' => $totalUsersInDB,
                            'emails_sent' => $success ? 1 : 0,
                            'actual_email_sent_to' => 'm2atodev@gmail.com',
                            'email_sent_successfully' => $success,
                            'note' => 'En mode DEV, un seul email est envoyé à l\'adresse de développement',
                            'eligibility_criteria' => [
                                'email_marketing_consent' => true,
                                'email_verified' => true,
                                'is_active' => true,
                                'not_deletion_requested' => true
                            ]
                        ],
                        'message' => $success 
                            ? "DEV MODE: 1 email sent to dev address (representing {$totalUsersInDB} users)" 
                            : "DEV MODE: Email failed to send"
                    ]));
                    return $response->withHeader('Content-Type', 'application/json');
                } else {
                    $response->getBody()->write(json_encode([
                        'success' => true,
                        'data' => [
                            'mode' => 'production_dev',
                            'environment' => 'development',
                            'total_users_in_db' => 0,
                            'emails_sent' => 0,
                            'message' => 'Aucun utilisateur éligible trouvé en base',
                            'eligibility_criteria' => [
                                'email_marketing_consent' => true,
                                'email_verified' => true,
                                'is_active' => true,
                                'not_deletion_requested' => true
                            ]
                        ]
                    ]));
                    return $response->withHeader('Content-Type', 'application/json');
                }
            }

            //  Mode production NORMAL (pas DEV) - Requête directe
            $users = User::where('email_marketing_consent', true)
                        ->where('email_verified_at', '!=', null)
                        ->where('is_active', true)
                        ->whereNull('deletion_requested_at')
                        ->select(['id', 'email', 'first_name', 'unsubscribe_token'])
                        ->get();

            $totalUsers = $users->count();
            $emailsSent = 0;
            $emailsFailed = 0;
            $errors = [];

            // Traitement par lots pour éviter la surcharge
            $batches = $users->chunk($batchSize);
            
            foreach ($batches as $batch) {
                foreach ($batch as $user) {
                    try {
                        // Générer l'URL de désabonnement pour chaque utilisateur
                        $unsubscribeUrl = $user->getUnsubscribeUrl();
                        
                        $success = MailSender::sendNewVersionCampaign(
                            $user->email, 
                            $user->first_name ?? 'Utilisateur',
                            $unsubscribeUrl
                        );
                        
                        if ($success) {
                            $emailsSent++;
                        } else {
                            $emailsFailed++;
                            $errors[] = "Failed to send to user ID {$user->id} ({$user->email})";
                        }
                        
                        // Petite pause entre les envois pour éviter la surcharge du serveur de mail
                        usleep(100000); // 0.1 seconde
                        
                    } catch (Exception $e) {
                        $emailsFailed++;
                        $errors[] = "Error sending to user ID {$user->id} ({$user->email}): " . $e->getMessage();
                        
                        // Log l'erreur
                        error_log("Campaign email error for user {$user->id}: " . $e->getMessage());
                    }
                }
                
                // Pause plus longue entre les lots
                if ($batches->count() > 1) {
                    sleep(1); // 1 seconde entre les lots
                }
            }

            $successRate = $totalUsers > 0 ? round(($emailsSent / $totalUsers) * 100, 2) : 0;

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'mode' => 'production',
                    'environment' => 'production',
                    'campaign_type' => 'new_version_2_0',
                    'total_users' => $totalUsers,
                    'emails_sent' => $emailsSent,
                    'emails_failed' => $emailsFailed,
                    'success_rate' => $successRate . '%',
                    'batch_size' => $batchSize,
                    'batches_processed' => $batches->count(),
                    'errors_sample' => array_slice($errors, 0, 5),
                    'unsubscribe_links_included' => true,
                    'eligibility_criteria' => [
                        'email_marketing_consent' => true,
                        'email_verified' => true,
                        'is_active' => true,
                        'not_deletion_requested' => true
                    ]
                ],
                'message' => "Campaign completed: {$emailsSent}/{$totalUsers} emails sent successfully"
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (Exception $e) {
            error_log("Campaign controller error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while sending the campaign',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     *  MISE À JOUR getCampaignStats avec stats de consentement
     */
    public function getCampaignStats(Request $request, Response $response): Response
    {
        try {
            //  NOUVELLES statistiques avec requête directe
            $totalUsers = User::count();
            $activeUsers = User::where('is_active', true)->count();
            $verifiedUsers = User::where('email_verified_at', '!=', null)->count();
            
            //  CORRECTION: Requête directe au lieu du scope
            $eligibleForCampaign = User::where('email_marketing_consent', true)
                                     ->where('email_verified_at', '!=', null)
                                     ->where('is_active', true)
                                     ->whereNull('deletion_requested_at')
                                     ->count();
            
            $unsubscribedUsers = User::where('email_marketing_consent', false)->count();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'environment' => Config::get('APP_ENV'),
                    'user_stats' => [
                        'total_users' => $totalUsers,
                        'active_users' => $activeUsers,
                        'verified_users' => $verifiedUsers,
                        'eligible_for_campaign' => $eligibleForCampaign,
                        'unsubscribed_from_marketing' => $unsubscribedUsers,
                        'marketing_consent_rate' => $totalUsers > 0 ? round((($eligibleForCampaign / $totalUsers) * 100), 2) . '%' : '0%',
                        'eligibility_rate' => $totalUsers > 0 ? round(($eligibleForCampaign / $totalUsers) * 100, 2) . '%' : '0%'
                    ],
                    'eligibility_criteria' => [
                        'email_marketing_consent' => 'true',
                        'email_verified_at' => 'not null',
                        'is_active' => 'true',
                        'deletion_requested_at' => 'null'
                    ],
                    'campaign_recommendations' => [
                        'recommended_batch_size' => min(50, max(10, intval($eligibleForCampaign / 10))),
                        'estimated_duration_minutes' => ceil($eligibleForCampaign / 60),
                        'best_sending_time' => 'Between 10:00-16:00 local time for better engagement',
                        'compliance_notes' => 'All emails include unsubscribe links for GDPR compliance',
                        'dev_mode_note' => Config::get('APP_ENV') == 'dev' ? 'DEV MODE: Only 1 email will be sent to m2atodev@gmail.com' : null
                    ]
                ],
                'message' => 'Campaign statistics retrieved successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving campaign stats',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     *  NOUVELLE MÉTHODE: Gérer le désabonnement via URL (retourne HTML ou JSON selon le header Accept)
     */
    public function handleUnsubscribe(Request $request, Response $response, array $args): Response
    {
        try {
            $token = $args['token'] ?? '';

            // Détecter si la requête attend du JSON (depuis Next.js) ou du HTML (clic direct)
            $acceptHeader = $request->getHeaderLine('Accept');
            $wantsJson = str_contains($acceptHeader, 'application/json');

            if (empty($token)) {
                if ($wantsJson) {
                    $response->getBody()->write(json_encode([
                        'success' => false,
                        'error' => [
                            'code' => 'MISSING_TOKEN',
                            'message' => 'Token de désabonnement manquant'
                        ]
                    ]));
                    return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
                } else {
                    $html = $this->generateUnsubscribeHtml(
                        'error',
                        'Token manquant',
                        'Le lien de désabonnement est invalide ou incomplet.',
                        null,
                        'fr'
                    );
                    $response->getBody()->write($html);
                    return $response->withHeader('Content-Type', 'text/html; charset=utf-8')->withStatus(400);
                }
            }

            // Trouver l'utilisateur par token
            $user = User::where('unsubscribe_token', $token)->first();

            if (!$user) {
                if ($wantsJson) {
                    $response->getBody()->write(json_encode([
                        'success' => false,
                        'error' => [
                            'code' => 'INVALID_TOKEN',
                            'message' => 'Token de désabonnement invalide'
                        ]
                    ]));
                    return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
                } else {
                    $html = $this->generateUnsubscribeHtml(
                        'error',
                        'Token invalide',
                        'Ce lien de désabonnement n\'est pas valide. Veuillez vérifier le lien dans votre email.',
                        null,
                        'fr'
                    );
                    $response->getBody()->write($html);
                    return $response->withHeader('Content-Type', 'text/html; charset=utf-8')->withStatus(404);
                }
            }

            // Déterminer la langue de l'utilisateur
            $lang = (isset($user->language) && in_array($user->language, ['fr', 'en'])) ? $user->language : 'fr';

            // Vérifier si déjà désabonné
            if (!$user->email_marketing_consent) {
                $title = $lang === 'en' ? 'Already Unsubscribed' : 'Déjà désabonné';
                $message = $lang === 'en'
                    ? 'You are already unsubscribed from our marketing emails.'
                    : 'Vous êtes déjà désabonné de nos emails marketing.';

                if ($wantsJson) {
                    $response->getBody()->write(json_encode([
                        'success' => true,
                        'message' => $message,
                        'data' => [
                            'already_unsubscribed' => true,
                            'unsubscribed_at' => $user->email_marketing_unsubscribed_at?->toISOString()
                        ]
                    ]));
                    return $response->withHeader('Content-Type', 'application/json');
                } else {
                    $html = $this->generateUnsubscribeHtml(
                        'info',
                        $title,
                        $message,
                        $user->first_name,
                        $lang
                    );
                    $response->getBody()->write($html);
                    return $response->withHeader('Content-Type', 'text/html; charset=utf-8');
                }
            }

            // Effectuer le désabonnement
            $unsubscribeSuccess = $user->update([
                'email_marketing_consent' => false,
                'email_marketing_unsubscribed_at' => Carbon::now()
            ]);

            if ($unsubscribeSuccess) {
                // Envoyer email de confirmation
                if(Config::get('APP_ENV') == 'dev') {
                    $emailToSend = 'm2atodev@gmail.com';
                } else {
                    $emailToSend = $user->email;
                }

                MailSender::sendUnsubscribeConfirmation($emailToSend, $user->first_name);

                $title = $lang === 'en' ? 'Unsubscribe Confirmed' : 'Désabonnement confirmé';
                $message = $lang === 'en'
                    ? 'You have been successfully unsubscribed from our marketing emails. You will no longer receive promotional emails from us.'
                    : 'Vous avez été désabonné avec succès de nos emails marketing. Vous ne recevrez plus d\'emails promotionnels de notre part.';

                if ($wantsJson) {
                    $response->getBody()->write(json_encode([
                        'success' => true,
                        'message' => $message,
                        'data' => [
                            'user_email' => $user->email,
                            'unsubscribed_at' => Carbon::now()->toISOString(),
                            'confirmation_email_sent' => true
                        ]
                    ]));
                    return $response->withHeader('Content-Type', 'application/json');
                } else {
                    $html = $this->generateUnsubscribeHtml(
                        'success',
                        $title,
                        $message,
                        $user->first_name,
                        $lang
                    );
                    $response->getBody()->write($html);
                    return $response->withHeader('Content-Type', 'text/html; charset=utf-8');
                }
            } else {
                $title = $lang === 'en' ? 'Unsubscribe Error' : 'Erreur de désabonnement';
                $message = $lang === 'en'
                    ? 'An error occurred while processing your request. Please try again later.'
                    : 'Une erreur s\'est produite lors du traitement de votre demande. Veuillez réessayer plus tard.';

                if ($wantsJson) {
                    $response->getBody()->write(json_encode([
                        'success' => false,
                        'error' => [
                            'code' => 'UNSUBSCRIBE_FAILED',
                            'message' => $message
                        ]
                    ]));
                    return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
                } else {
                    $html = $this->generateUnsubscribeHtml(
                        'error',
                        $title,
                        $message,
                        null,
                        $lang
                    );
                    $response->getBody()->write($html);
                    return $response->withHeader('Content-Type', 'text/html; charset=utf-8')->withStatus(500);
                }
            }

        } catch (Exception $e) {
            error_log("Unsubscribe error: " . $e->getMessage());

            // Détecter si la requête attend du JSON
            $acceptHeader = $request->getHeaderLine('Accept');
            $wantsJson = str_contains($acceptHeader, 'application/json');

            if ($wantsJson) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'INTERNAL_ERROR',
                        'message' => 'Erreur lors du traitement du désabonnement',
                        'details' => $e->getMessage()
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
            } else {
                $html = $this->generateUnsubscribeHtml(
                    'error',
                    'Erreur serveur',
                    'Une erreur technique s\'est produite. Veuillez réessayer plus tard ou nous contacter.',
                    null,
                    'fr'
                );
                $response->getBody()->write($html);
                return $response->withHeader('Content-Type', 'text/html; charset=utf-8')->withStatus(500);
            }
        }
    }

    /**
     * Générer une page HTML bilingue pour le désabonnement
     */
    private function generateUnsubscribeHtml(string $type, string $title, string $message, ?string $firstName = null, string $lang = 'fr'): string
    {
        // Définir les couleurs et icônes selon le type
        $config = [
            'success' => [
                'color' => '#059669',
                'bgColor' => '#d1fae5',
                'icon' => '✓'
            ],
            'error' => [
                'color' => '#dc2626',
                'bgColor' => '#fee2e2',
                'icon' => '✕'
            ],
            'info' => [
                'color' => '#2563eb',
                'bgColor' => '#dbeafe',
                'icon' => 'ℹ'
            ]
        ];

        $settings = $config[$type] ?? $config['info'];

        // Messages bilingues
        if ($lang === 'en') {
            $greeting = $firstName ? "Hello {$firstName}," : "Hello,";
            $footerText1 = "This page concerns your marketing email preferences.<br>You will continue to receive important emails about your account.";
            $footerText2 = "Questions? Contact us at <a href='mailto:support@epilist.com'>support@epilist.com</a>";
        } else {
            $greeting = $firstName ? "Bonjour {$firstName}," : "Bonjour,";
            $footerText1 = "Cette page concerne vos préférences d'emails marketing.<br>Vous continuerez à recevoir les emails importants concernant votre compte.";
            $footerText2 = "Des questions? Contactez-nous à <a href='mailto:support@epilist.com'>support@epilist.com</a>";
        }

        return "<!DOCTYPE html>
<html lang='{$lang}'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>{$title} - EpiList</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 500px;
            width: 100%;
            padding: 48px 32px;
            text-align: center;
        }
        .logo {
            font-size: 48px;
            font-weight: bold;
            background: linear-gradient(135deg, #059669 0%, #10b981 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 32px;
        }
        .icon-circle {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background: {$settings['bgColor']};
            color: {$settings['color']};
            font-size: 40px;
            font-weight: bold;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
        }
        h1 {
            color: #1f2937;
            font-size: 28px;
            margin-bottom: 16px;
            font-weight: 700;
        }
        .greeting {
            color: #4b5563;
            font-size: 16px;
            margin-bottom: 16px;
        }
        .message {
            color: #6b7280;
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 32px;
        }
        .footer {
            border-top: 1px solid #e5e7eb;
            padding-top: 24px;
            margin-top: 32px;
        }
        .footer p {
            color: #9ca3af;
            font-size: 14px;
            line-height: 1.5;
        }
        .footer a {
            color: #059669;
            text-decoration: none;
        }
        .footer a:hover {
            text-decoration: underline;
        }
        @media (max-width: 640px) {
            .container {
                padding: 32px 24px;
            }
            h1 {
                font-size: 24px;
            }
            .icon-circle {
                width: 64px;
                height: 64px;
                font-size: 32px;
            }
        }
    </style>
</head>
<body>
    <div class='container'>
        <div class='logo'>EpiList</div>

        <div class='icon-circle'>
            {$settings['icon']}
        </div>

        <h1>{$title}</h1>

        " . ($firstName ? "<p class='greeting'>{$greeting}</p>" : "") . "

        <p class='message'>{$message}</p>

        <div class='footer'>
            <p>
                {$footerText1}
            </p>
            <p style='margin-top: 16px;'>
                {$footerText2}
            </p>
        </div>
    </div>
</body>
</html>";
    }

    /**
     *  Envoyer un email de test à un utilisateur spécifique
     */
    public function sendTestEmail(Request $request, Response $response): Response
    {
        try {
            $data = $request->getParsedBody();
            
            // Validation
            $validator = new Validator($data);
            $validator->rule('required', 'email')->message('Email is required');
            $validator->rule('email', 'email')->message('Valid email is required');
            $validator->rule('required', 'first_name')->message('First name is required');
            $validator->rule('lengthMin', 'first_name', 1)->message('First name cannot be empty');

            if (!$validator->validate()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Invalid input data',
                        'validation_errors' => $validator->errors()
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $email = $data['email'];
            $firstName = $data['first_name'];

            // In dev environment, override email for testing
            if(Config::get('APP_ENV') == 'dev') {
                $email = 'm2atodev@gmail.com';
            }
            
            $success = MailSender::sendNewVersionCampaign($email, $firstName);
            
            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'original_email' => $data['email'],
                    'actual_email_sent_to' => $email,
                    'first_name' => $firstName,
                    'email_sent_successfully' => $success,
                    'sent_at' => date('Y-m-d H:i:s'),
                    'environment' => Config::get('APP_ENV')
                ],
                'message' => $success ? 'Test email sent successfully' : 'Test email failed to send'
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while sending test email',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     *  Obtenir un aperçu de l'email de campagne (sans l'envoyer)
     */
    public function previewCampaignEmail(Request $request, Response $response): Response
    {
        try {
            $params = $request->getQueryParams();
            $firstName = $params['first_name'] ?? 'Utilisateur';
            
            // Générer le contenu HTML de l'email
            $htmlContent = MailSender::newVersionCampaignEmail($firstName);
            
            $response->getBody()->write($htmlContent);
            return $response->withHeader('Content-Type', 'text/html; charset=utf-8');

        } catch (Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while generating email preview',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}