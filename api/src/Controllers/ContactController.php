<?php
// src/Controllers/ContactController.php

namespace App\Controllers;

use App\Models\User;
use App\Services\MailSender;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Psr7\Response as SlimResponse;
use Slim\Psr7\Factory\ResponseFactory;
use Slim\Psr7\Factory\StreamFactory;
use Slim\Psr7\Headers;
use Slim\Psr7\Response as JsonResponse;
use App\Config\Config;
use Carbon\Carbon;
use Valitron\Validator;

class ContactController
{
    /**
     * ✅ NOUVEAU: Détecter la langue de l'utilisateur
     */
    private function getUserLanguage(Request $request): string
    {
        // Essayer de récupérer la langue depuis les headers
        $acceptLanguage = $request->getHeaderLine('Accept-Language');
        
        // Ou depuis les paramètres de requête
        $params = $request->getQueryParams();
        $langParam = $params['lang'] ?? null;
        
        if ($langParam && in_array($langParam, ['en', 'fr'])) {
            return $langParam;
        }
        
        // Parser Accept-Language header
        if ($acceptLanguage) {
            if (strpos($acceptLanguage, 'fr') !== false) {
                return 'fr';
            }
            if (strpos($acceptLanguage, 'en') !== false) {
                return 'en';
            }
        }
        
        // Défaut : français
        return 'fr';
    }

    /**
     * ✅ NOUVEAU: Traductions des types de feedback
     */
    private function getFeedbackTypeTranslations(): array
    {
        return [
            'bug' => [
                'en' => [
                    'label' => 'Report a bug',
                    'description' => 'Technical issue or malfunction'
                ],
                'fr' => [
                    'label' => 'Signaler un bug',
                    'description' => 'Problème technique ou dysfonctionnement'
                ]
            ],
            'feature' => [
                'en' => [
                    'label' => 'New feature',
                    'description' => 'Improvement suggestion or new feature'
                ],
                'fr' => [
                    'label' => 'Nouvelle fonctionnalité',
                    'description' => 'Suggestion d\'amélioration ou nouvelle fonctionnalité'
                ]
            ],
            'improvement' => [
                'en' => [
                    'label' => 'Improvement',
                    'description' => 'Enhancement of existing feature'
                ],
                'fr' => [
                    'label' => 'Amélioration',
                    'description' => 'Amélioration d\'une fonctionnalité existante'
                ]
            ],
            'question' => [
                'en' => [
                    'label' => 'Question',
                    'description' => 'Help or usage question'
                ],
                'fr' => [
                    'label' => 'Question',
                    'description' => 'Aide ou question sur l\'utilisation'
                ]
            ],
            'other' => [
                'en' => [
                    'label' => 'Other',
                    'description' => 'Other type of feedback'
                ],
                'fr' => [
                    'label' => 'Autre',
                    'description' => 'Autre type de feedback'
                ]
            ]
        ];
    }

    /**
     * ✅ NOUVEAU: Traductions des niveaux de priorité
     */
    private function getPriorityTranslations(): array
    {
        return [
            'low' => [
                'en' => 'Low',
                'fr' => 'Faible'
            ],
            'normal' => [
                'en' => 'Normal',
                'fr' => 'Normal'
            ],
            'high' => [
                'en' => 'High',
                'fr' => 'Élevée'
            ],
            'urgent' => [
                'en' => 'Urgent',
                'fr' => 'Urgente'
            ]
        ];
    }

    /**
     * ✅ MÉTHODE DE TEST: Simple test pour vérifier que la classe fonctionne
     */
    public function test(Request $request, Response $response): Response
    {
        $response->getBody()->write(json_encode([
            'success' => true,
            'message' => 'ContactController fonctionne correctement',
            'timestamp' => time()
        ]));
        return $response->withHeader('Content-Type', 'application/json');
    }

    /**
     * ✅ MÉTHODE CORRIGÉE: Obtenir les types de feedback disponibles
     */
    public function getFeedbackTypes(Request $request, Response $response): Response
    {
        try {
            $language = $this->getUserLanguage($request);
            error_log("🌐 Feedback types requested in language: $language");
            
            // Récupérer les traductions
            $feedbackTypeTranslations = $this->getFeedbackTypeTranslations();
            $priorityTranslations = $this->getPriorityTranslations();
            
            // Icônes communes à toutes les langues
            $feedbackIcons = [
                'bug' => '🐛',
                'feature' => '💡',
                'improvement' => '🚀',
                'question' => '❓',
                'other' => '💬'
            ];
            
            // Construire les types de feedback traduits
            $feedbackTypes = [];
            foreach ($feedbackTypeTranslations as $key => $translations) {
                $feedbackTypes[] = [
                    'value' => $key,
                    'label' => $translations[$language]['label'],
                    'description' => $translations[$language]['description'],
                    'icon' => $feedbackIcons[$key]
                ];
            }
            
            // Construire les priorités traduites
            $priorities = [];
            foreach ($priorityTranslations as $key => $translations) {
                $priorities[] = [
                    'value' => $key,
                    'label' => $translations[$language]
                ];
            }
            
            error_log("✅ Returning " . count($feedbackTypes) . " feedback types and " . count($priorities) . " priorities in $language");
            
            return $this->createSuccessResponse([
                'language' => $language,
                'feedback_types' => $feedbackTypes,
                'priorities' => $priorities
            ], 'Types de feedback récupérés avec succès');

        } catch (\Exception $e) {
            error_log("❌ Erreur lors de la récupération des types de feedback: " . $e->getMessage());
            return $this->createErrorResponse(
                'Erreur lors du chargement des types de feedback',
                500,
                'FEEDBACK_TYPES_ERROR'
            );
        }
    }

    /**
     * ✅ ROUTE PRINCIPALE: Envoyer un feedback/contact
     */
    public function sendFeedback(Request $request, Response $response): Response
    {
        // Récupérer l'ID de l'utilisateur depuis le token JWT (peut être null pour les utilisateurs non connectés)
        $authId = $request->getAttribute('auth_id');
        
        $data = $request->getParsedBody();

        // Validation des données
        $validator = new Validator($data);
        
        // Validation des champs obligatoires
        $validator->rule('required', ['subject', 'message'])
            ->message('{field} est requis');
        
        $validator->rule('lengthMax', 'subject', 200)
            ->message('Le sujet ne peut pas dépasser 200 caractères');
        
        $validator->rule('lengthMax', 'message', 2000)
            ->message('Le message ne peut pas dépasser 2000 caractères');
        
        $validator->rule('lengthMin', 'message', 10)
            ->message('Le message doit contenir au moins 10 caractères');

        // Validation du type de feedback (optionnel)
        if (isset($data['feedback_type'])) {
            $validator->rule('in', 'feedback_type', ['bug', 'feature', 'improvement', 'question', 'other'])
                ->message('Type de feedback invalide');
        }

        // Si pas d'utilisateur connecté, on exige email et nom
        if (!$authId) {
            $validator->rule('required', ['email', 'name'])
                ->message('{field} est requis pour les utilisateurs non connectés');
            
            $validator->rule('email', 'email')
                ->message('Format d\'email invalide');
            
            $validator->rule('lengthMax', 'name', 100)
                ->message('Le nom ne peut pas dépasser 100 caractères');
        }

        // Validation de la priorité (optionnelle)
        if (isset($data['priority'])) {
            $validator->rule('in', 'priority', ['low', 'normal', 'high', 'urgent'])
                ->message('Priorité invalide');
        }

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'code' => 'VALIDATION_ERROR',
                'message' => 'Erreurs de validation',
                'errors' => $validator->errors()
            ]));
            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(400);
        }

        try {
            // Récupérer les informations utilisateur si connecté
            $user = null;
            $userName = '';
            $userEmail = '';
            
            if ($authId) {
                $user = User::find($authId);
                if ($user) {
                    $userName = trim($user->first_name . ' ' . $user->last_name);
                    $userEmail = $user->email;
                }
            } else {
                // Utilisateur non connecté
                $userName = trim($data['name']);
                $userEmail = $data['email'];
            }

            // Préparer les données du feedback
            $feedbackData = [
                'user_id' => $authId,
                'user_name' => $userName,
                'user_email' => $userEmail,
                'subject' => trim($data['subject']),
                'message' => trim($data['message']),
                'feedback_type' => $data['feedback_type'] ?? 'other',
                'priority' => $data['priority'] ?? 'normal',
                'user_agent' => $request->getHeaderLine('User-Agent'),
                'ip_address' => $this->getClientIpAddress($request),
                'submitted_at' => Carbon::now()->toISOString(),
                'app_version' => $data['app_version'] ?? null,
                'platform' => $data['platform'] ?? null,
                'device_info' => $data['device_info'] ?? null
            ];

            // Envoyer l'email de feedback
            $emailSent = $this->sendFeedbackEmail($feedbackData);

            if ($emailSent) {
                // Log du feedback envoyé
                error_log("✅ Feedback envoyé avec succès de: {$userEmail} - Sujet: {$feedbackData['subject']}");
                
                return $this->createSuccessResponse([
                    'feedback_id' => uniqid('feedback_', true),
                    'submitted_at' => $feedbackData['submitted_at']
                ], 'Votre message a été envoyé avec succès ! Nous vous répondrons dans les plus brefs délais.');
            } else {
                error_log("❌ Échec de l'envoi du feedback de: {$userEmail}");
                return $this->createErrorResponse(
                    'Erreur lors de l\'envoi du message. Veuillez réessayer plus tard.',
                    500,
                    'EMAIL_SEND_ERROR'
                );
            }

        } catch (\Exception $e) {
            error_log("❌ Erreur lors du traitement du feedback: " . $e->getMessage());
            return $this->createErrorResponse(
                'Une erreur inattendue s\'est produite. Veuillez réessayer plus tard.',
                500,
                'SERVER_ERROR'
            );
        }
    }

    /**
     * Crée une réponse d'erreur JSON.
     */
    private function createErrorResponse(string $message, int $statusCode, string $code = ''): JsonResponse
    {
        return new JsonResponse(
            $statusCode,
            new Headers(['Content-Type' => 'application/json']),
            (new StreamFactory())->createStream(json_encode([
                'success' => false,
                'code' => $code,
                'message' => $message,
            ]))
        );
    }

    /**
     * Crée une réponse de succès JSON.
     */
    private function createSuccessResponse(array $data = [], string $message = 'Success'): JsonResponse
    {
        return new JsonResponse(
            200,
            new Headers(['Content-Type' => 'application/json']),
            (new StreamFactory())->createStream(json_encode([
                'success' => true,
                'message' => $message,
                'data' => $data
            ]))
        );
    }

    /**
     * ✅ MÉTHODE UTILITAIRE: Envoyer l'email de feedback
     */
    private function sendFeedbackEmail(array $feedbackData): bool
    {
        try {
            $subject = "[EpiList Feedback] {$feedbackData['subject']}";
            
            // Déterminer l'icône selon le type
            $typeIcons = [
                'bug' => '🐛',
                'feature' => '💡',
                'improvement' => '🚀',
                'question' => '❓',
                'other' => '💬'
            ];
            
            $priorityColors = [
                'low' => '#10b981',
                'normal' => '#3b82f6',
                'high' => '#f59e0b',
                'urgent' => '#ef4444'
            ];
            
            $typeIcon = $typeIcons[$feedbackData['feedback_type']] ?? '💬';
            $priorityColor = $priorityColors[$feedbackData['priority']] ?? '#3b82f6';
            
            // Construire le contenu HTML
            $htmlContent = $this->buildFeedbackEmailContent($feedbackData, $typeIcon, $priorityColor);
            
            // Envoyer l'email
            return MailSender::sendMail(
                $subject,
                [['email' => 'contact@m2atech.com', 'name' => 'EpiList Support']],
                $htmlContent
            );
            
        } catch (\Exception $e) {
            error_log("❌ Erreur lors de la construction de l'email de feedback: " . $e->getMessage());
            return false;
        }
    }

    /**
     * ✅ MÉTHODE UTILITAIRE: Construire le contenu HTML de l'email
     */
    private function buildFeedbackEmailContent(array $data, string $typeIcon, string $priorityColor): string
    {
        $userStatus = $data['user_id'] ? 'Utilisateur connecté' : 'Utilisateur anonyme';
        $userInfo = $data['user_id'] ? "ID: {$data['user_id']}" : 'Non connecté';
        
        // En-tête personnalisé pour les emails internes
        $header = "
            <!DOCTYPE html>
            <html lang='fr'>
            <head>
                <meta charset='UTF-8'>
                <meta name='viewport' content='width=device-width, initial-scale=1.0'>
                <title>Nouveau feedback EpiList</title>
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #1a202c; background-color: #f7fafc; margin: 0; padding: 20px; }
                    .container { max-width: 800px; margin: 0 auto; background: #ffffff; border-radius: 12px; box-shadow: 0 4px 25px rgba(0, 0, 0, 0.08); overflow: hidden; }
                    .header { background: linear-gradient(135deg, #1f2937 0%, #374151 100%); color: #ffffff; padding: 30px; text-align: center; }
                    .content { padding: 30px; }
                    .feedback-type { display: inline-block; background: {$priorityColor}; color: white; padding: 6px 16px; border-radius: 20px; font-size: 12px; font-weight: bold; text-transform: uppercase; margin-bottom: 20px; }
                    .user-info { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; margin: 20px 0; }
                    .message-content { background: #f0fdf4; border: 1px solid #10b981; border-radius: 8px; padding: 20px; margin: 20px 0; }
                    .meta-info { background: #fafafa; border-radius: 8px; padding: 16px; margin: 20px 0; font-size: 14px; color: #6b7280; }
                    .priority-urgent { border-left: 4px solid #ef4444; }
                    .priority-high { border-left: 4px solid #f59e0b; }
                    .priority-normal { border-left: 4px solid #3b82f6; }
                    .priority-low { border-left: 4px solid #10b981; }
                </style>
            </head>
            <body>
                <div class='container'>
                    <div class='header'>
                        <h1 style='margin: 0; font-size: 24px;'>{$typeIcon} Nouveau feedback EpiList</h1>
                        <p style='margin: 8px 0 0; opacity: 0.9;'>Reçu le " . Carbon::now()->format('d/m/Y à H:i') . "</p>
                    </div>
        ";
        
        $content = "
                    <div class='content'>
                        <div class='feedback-type priority-{$data['priority']}'>
                            {$data['feedback_type']} - {$data['priority']}
                        </div>
                        
                        <h2 style='margin: 0 0 20px; color: #1f2937; font-size: 20px;'>{$data['subject']}</h2>
                        
                        <div class='user-info'>
                            <h3 style='margin: 0 0 12px; color: #374151; font-size: 16px;'>👤 Informations utilisateur</h3>
                            <p style='margin: 0 0 8px;'><strong>Nom:</strong> {$data['user_name']}</p>
                            <p style='margin: 0 0 8px;'><strong>Email:</strong> {$data['user_email']}</p>
                            <p style='margin: 0 0 8px;'><strong>Statut:</strong> {$userStatus}</p>
                            <p style='margin: 0;'><strong>Utilisateur:</strong> {$userInfo}</p>
                        </div>
                        
                        <div class='message-content'>
                            <h3 style='margin: 0 0 12px; color: #047857; font-size: 16px;'>💬 Message</h3>
                            <div style='white-space: pre-wrap; color: #374151;'>{$data['message']}</div>
                        </div>
        ";
        
        // Informations techniques si disponibles
        $technicalInfo = '';
        if ($data['app_version'] || $data['platform'] || $data['device_info']) {
            $technicalInfo = "
                        <div class='meta-info'>
                            <h3 style='margin: 0 0 12px; color: #6b7280; font-size: 14px;'>📱 Informations techniques</h3>
            ";
            
            if ($data['app_version']) {
                $technicalInfo .= "<p style='margin: 0 0 4px;'><strong>Version app:</strong> {$data['app_version']}</p>";
            }
            if ($data['platform']) {
                $technicalInfo .= "<p style='margin: 0 0 4px;'><strong>Plateforme:</strong> {$data['platform']}</p>";
            }
            if ($data['device_info']) {
                $technicalInfo .= "<p style='margin: 0 0 4px;'><strong>Appareil:</strong> {$data['device_info']}</p>";
            }
            
            $technicalInfo .= "
                            <p style='margin: 0 0 4px;'><strong>IP:</strong> {$data['ip_address']}</p>
                            <p style='margin: 0;'><strong>User Agent:</strong> " . substr($data['user_agent'], 0, 100) . "...</p>
                        </div>
            ";
        }
        
        $footer = "
                        <div style='margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; text-align: center;'>
                            <p style='margin: 0; color: #6b7280; font-size: 14px;'>
                                Email automatique - EpiList Support System<br>
                                Répondre directement à cet email pour contacter l'utilisateur
                            </p>
                        </div>
                    </div>
                </div>
            </body>
            </html>
        ";
        
        return $header . $content . $technicalInfo . $footer;
    }

    /**
     * ✅ MÉTHODE UTILITAIRE: Récupérer l'adresse IP du client
     */
    private function getClientIpAddress(Request $request): string
    {
        $serverParams = $request->getServerParams();
        
        // Vérifier les différents headers pour l'IP
        $ipHeaders = [
            'HTTP_CF_CONNECTING_IP',     // Cloudflare
            'HTTP_X_FORWARDED_FOR',      // Proxy
            'HTTP_X_FORWARDED',          // Proxy
            'HTTP_X_CLUSTER_CLIENT_IP',  // Cluster
            'HTTP_FORWARDED_FOR',        // Proxy
            'HTTP_FORWARDED',            // Proxy
            'REMOTE_ADDR'                // Standard
        ];
        
        foreach ($ipHeaders as $header) {
            if (!empty($serverParams[$header])) {
                $ip = $serverParams[$header];
                // Si plusieurs IPs, prendre la première
                if (strpos($ip, ',') !== false) {
                    $ip = trim(explode(',', $ip)[0]);
                }
                // Valider l'IP
                if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                    return $ip;
                }
            }
        }
        
        return $serverParams['REMOTE_ADDR'] ?? 'unknown';
    }
}