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
     * ✅ Lancer la campagne de nouvelle version pour tous les utilisateurs actifs
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

            // ✅ CORRECTION: Mode production avec requête directe pour utilisateurs éligibles
            if (Config::get('APP_ENV') == 'dev') {
                // ✅ EN DEV: Filtrer les utilisateurs éligibles et envoyer UN SEUL EMAIL
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
                    
                    // ✅ ENVOI D'UN SEUL EMAIL à l'adresse de dev
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

            // ✅ Mode production NORMAL (pas DEV) - Requête directe
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
     * ✅ MISE À JOUR getCampaignStats avec stats de consentement
     */
    public function getCampaignStats(Request $request, Response $response): Response
    {
        try {
            // ✅ NOUVELLES statistiques avec requête directe
            $totalUsers = User::count();
            $activeUsers = User::where('is_active', true)->count();
            $verifiedUsers = User::where('email_verified_at', '!=', null)->count();
            
            // ✅ CORRECTION: Requête directe au lieu du scope
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
     * ✅ NOUVELLE MÉTHODE: Gérer le désabonnement via URL
     */
    public function handleUnsubscribe(Request $request, Response $response, array $args): Response
    {
        try {
            $token = $args['token'] ?? '';
            
            if (empty($token)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'MISSING_TOKEN',
                        'message' => 'Token de désabonnement manquant'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Trouver l'utilisateur par token
            $user = User::where('unsubscribe_token', $token)->first();
            
            if (!$user) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'INVALID_TOKEN',
                        'message' => 'Token de désabonnement invalide'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            // Vérifier si déjà désabonné
            if (!$user->email_marketing_consent) {
                $response->getBody()->write(json_encode([
                    'success' => true,
                    'message' => 'Vous êtes déjà désabonné des emails marketing',
                    'data' => [
                        'already_unsubscribed' => true,
                        'unsubscribed_at' => $user->email_marketing_unsubscribed_at?->toISOString()
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json');
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
                
                $response->getBody()->write(json_encode([
                    'success' => true,
                    'message' => 'Désabonnement effectué avec succès',
                    'data' => [
                        'user_email' => $user->email,
                        'unsubscribed_at' => Carbon::now()->toISOString(),
                        'confirmation_email_sent' => true
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            } else {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'UNSUBSCRIBE_FAILED',
                        'message' => 'Erreur lors du désabonnement'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
            }

        } catch (Exception $e) {
            error_log("Unsubscribe error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'Erreur lors du traitement du désabonnement',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Envoyer un email de test à un utilisateur spécifique
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
     * ✅ Obtenir un aperçu de l'email de campagne (sans l'envoyer)
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