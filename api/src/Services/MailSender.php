<?php
namespace App\Services;

use Brevo\Client\Configuration;
use Brevo\Client\Api\TransactionalEmailsApi;
use Brevo\Client\Model\SendSmtpEmail;
use Brevo\Client\Model\SendSmtpEmailAttachment;
use Brevo\Client\Model\SendSmtpEmailSender;
use Exception;
use InvalidArgumentException;
use App\Config\Config;
use GuzzleHttp\Client as GuzzleClient;
use App\Models\Ad;

class MailSender
{
    private const SENDER_NAME = 'EpiList';
    private const SENDER_EMAIL = 'noreply@m2atech.com';
    private const MAX_ATTACHMENT_SIZE = 25 * 1024 * 1024; // 25MB
    private const ALLOWED_ATTACHMENT_TYPES = [
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
        'jpg', 'jpeg', 'png', 'gif', 'txt', 'csv', 'zip'
    ];

    /**
     * Envoie un email via l'API Brevo
     */
    public static function sendMail(string $subject, array $recipients, string $htmlBody, array $attachments = []): bool
    {
        try {
            // Validation des paramètres
            self::validateEmailParameters($subject, $recipients, $htmlBody, $attachments);

            // Configuration de l'API Brevo avec gestion des warnings
            $config = self::createBrevoConfiguration();
            
            // Création de l'instance API avec suppression des warnings
            $apiInstance = self::createApiInstance($config);

            // Préparation de l'email
            $emailData = self::prepareEmailData($subject, $recipients, $htmlBody, $attachments);

            // Envoi de l'email
            $result = $apiInstance->sendTransacEmail($emailData);
            
            // Log du succès
            error_log("Email sent successfully. Message ID: " . ($result->getMessageId() ?? 'unknown'));
            
            return true;

        } catch (Exception $e) {
            // Log détaillé de l'erreur
            error_log("Email sending failed: " . $e->getMessage() . " | Trace: " . $e->getTraceAsString());
            return false;
        }
    }

    /**
     * Méthode legacy pour compatibilité
     */
    public static function send_mail(string $subject, array $to, string $body, array $attachments = []): bool
    {
        return self::sendMail($subject, $to, $body, $attachments);
    }

    /**
     * Valide les paramètres d'email
     */
    private static function validateEmailParameters(string $subject, array $recipients, string $htmlBody, array $attachments): void
    {
        if (empty($subject)) {
            throw new InvalidArgumentException('Email subject cannot be empty');
        }

        if (empty($recipients) || !is_array($recipients)) {
            throw new InvalidArgumentException('Recipients must be a non-empty array');
        }

        foreach ($recipients as $recipient) {
            if (!isset($recipient['email']) || !filter_var($recipient['email'], FILTER_VALIDATE_EMAIL)) {
                throw new InvalidArgumentException('Invalid recipient email format');
            }
        }

        if (empty($htmlBody)) {
            throw new InvalidArgumentException('Email body cannot be empty');
        }

        if (!empty($attachments)) {
            self::validateAttachments($attachments);
        }
    }

    /**
     * Valide les pièces jointes
     */
    private static function validateAttachments(array $attachments): void
    {
        foreach ($attachments as $attachment) {
            if (!isset($attachment['content'], $attachment['name'])) {
                throw new InvalidArgumentException('Attachment must have content and name');
            }

            // Vérification de la taille
            if (strlen($attachment['content']) > self::MAX_ATTACHMENT_SIZE) {
                throw new InvalidArgumentException('Attachment size exceeds maximum allowed (25MB)');
            }

            // Vérification du type de fichier
            $extension = strtolower(pathinfo($attachment['name'], PATHINFO_EXTENSION));
            if (!in_array($extension, self::ALLOWED_ATTACHMENT_TYPES)) {
                throw new InvalidArgumentException("Attachment type '{$extension}' is not allowed");
            }
        }
    }

    /**
     * Crée la configuration Brevo
     */
    private static function createBrevoConfiguration(): Configuration
    {
        $apiKey = Config::get('BREVO_API_KEY');
        if (empty($apiKey)) {
            throw new InvalidArgumentException('BREVO_API_KEY is not configured');
        }

        return Configuration::getDefaultConfiguration()->setApiKey('api-key', $apiKey);
    }

    /**
     * Crée l'instance API en supprimant les warnings
     */
    private static function createApiInstance(Configuration $config): TransactionalEmailsApi
    {
        // Suppression temporaire des warnings pour éviter les deprecated notices
        $originalErrorReporting = error_reporting();
        error_reporting($originalErrorReporting & ~E_DEPRECATED);

        try {
            // Création du client HTTP avec timeout
            $httpClient = new GuzzleClient([
                'timeout' => 30,
                'connect_timeout' => 10
            ]);

            $apiInstance = new TransactionalEmailsApi($httpClient, $config);
            
            return $apiInstance;
        } finally {
            // Restauration du niveau d'erreur original
            error_reporting($originalErrorReporting);
        }
    }

    /**
     * Prépare les données de l'email
     */
    private static function prepareEmailData(string $subject, array $recipients, string $htmlBody, array $attachments): SendSmtpEmail
    {
        // Suppression des warnings pour la création des modèles
        $originalErrorReporting = error_reporting();
        error_reporting($originalErrorReporting & ~E_DEPRECATED);

        try {
            // Préparation des pièces jointes
            $attachmentObjects = [];
            if (!empty($attachments)) {
                foreach ($attachments as $attachment) {
                    $attachmentObjects[] = new SendSmtpEmailAttachment([
                        'content' => base64_encode($attachment['content']),
                        'name' => $attachment['name']
                    ]);
                }
            }

            // Création de l'expéditeur
            $sender = new SendSmtpEmailSender([
                'name' => self::SENDER_NAME,
                'email' => self::SENDER_EMAIL
            ]);

            // Données de l'email
            $emailData = [
                'subject' => $subject,
                'sender' => $sender,
                'to' => $recipients,
                'htmlContent' => $htmlBody,
                'textContent' => self::generatePlainTextFromHtml($htmlBody),
                'tracking' => [
                    'opens' => false,
                    'clicks' => false,
                    'unsubscribe' => false,
                ]
            ];

            // Ajout des pièces jointes si présentes
            if (!empty($attachmentObjects)) {
                $emailData['attachment'] = $attachmentObjects;
            }

            return new SendSmtpEmail($emailData);

        } finally {
            error_reporting($originalErrorReporting);
        }
    }

    /**
     * Génère une version texte brut à partir du HTML
     */
    private static function generatePlainTextFromHtml(string $html): string
    {
        // Remplacement des balises de saut de ligne
        $text = str_replace(['<br>', '<br/>', '<br />'], "\n", $html);
        
        // Remplacement des paragraphes
        $text = preg_replace('/<\/p>/i', "\n\n", $text);
        
        // Suppression de toutes les balises HTML
        $text = strip_tags($text);
        
        // Décodage des entités HTML
        $text = html_entity_decode($text, ENT_QUOTES, 'UTF-8');
        
        // Nettoyage des espaces multiples et des sauts de ligne excessifs
        $text = preg_replace('/\n{3,}/', "\n\n", $text);
        $text = preg_replace('/[ \t]+/', ' ', $text);
        
        return trim($text);
    }

    public static function headerContent(string $title): string
    {
        return "
            <!DOCTYPE html>
            <html lang='fr'>
            <head>
                <meta charset='UTF-8'>
                <meta name='viewport' content='width=device-width, initial-scale=1.0'>
                <title>" . htmlspecialchars($title, ENT_QUOTES, 'UTF-8') . "</title>
                <style>
                    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
                    
                    /* Reset styles */
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    
                    /* Base styles */
                    body { 
                        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                        line-height: 1.6; 
                        color: #1a202c; 
                        background-color: #f7fafc; 
                    }
                    
                    /* Button styles */
                    .button { 
                        display: inline-block; 
                        background: linear-gradient(135deg, #059669 0%, #047857 100%);
                        color: #ffffff !important; 
                        padding: 16px 32px; 
                        text-decoration: none; 
                        font-weight: 600; 
                        border-radius: 12px; 
                        transition: all 0.3s ease;
                        box-shadow: 0 4px 12px rgba(5, 150, 105, 0.25);
                    }
                    
                    .button:hover {
                        transform: translateY(-2px);
                        box-shadow: 0 6px 20px rgba(5, 150, 105, 0.35);
                    }
                    
                    /* Code styles */
                    .verification-code {
                        background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
                        color: #166534;
                        font-size: 32px;
                        font-weight: bold;
                        padding: 20px;
                        text-align: center;
                        border: 2px solid #bbf7d0;
                        border-radius: 12px;
                        letter-spacing: 4px;
                        margin: 20px 0;
                    }
                    
                    /* Responsive */
                    @media (max-width: 600px) {
                        .email-container { width: 100% !important; }
                        .content { padding: 20px !important; }
                        .verification-code { font-size: 24px !important; padding: 16px !important; }
                    }
                </style>
            </head>
            <body style='margin: 0; padding: 0; font-family: Inter, Arial, sans-serif; background-color: #f7fafc; color: #1a202c;'>
                <table role='presentation' width='100%' cellspacing='0' cellpadding='0' border='0' style='background-color: #f7fafc;'>
                    <tr>
                        <td align='center' style='padding: 40px 20px;'>
                            <table class='email-container' role='presentation' width='600' cellspacing='0' cellpadding='0' border='0' style='max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 25px rgba(0, 0, 0, 0.08); overflow: hidden;'>
                                <tr>
                                    <td class='header' style='background: linear-gradient(135deg, #ffffff 0%, #f0fdf4 100%); padding: 40px 30px 30px; text-align: center; border-bottom: 1px solid #e5e7eb;'>
                                        <!-- Logo Epilist -->
                                        <div style='display: inline-block; width: 80px; height: 80px; background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%); border-radius: 20px; margin-bottom: 16px; position: relative;'>
                                            <div style='position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); color: #059669; font-size: 36px;'>🛒</div>
                                        </div>
                                        <h1 style='margin: 0 0 8px; font-size: 28px; font-weight: bold; color: #047857;'>EpiList</h1>
                                        <p style='margin: 0 0 16px; font-size: 16px; color: #6b7280; font-weight: 500;'>
                                            Gérez vos courses facilement
                                        </p>
                                        <div style='height: 3px; width: 60px; background: linear-gradient(90deg, #059669, #10b981); margin: 0 auto; border-radius: 2px;'></div>
                                    </td>
                                </tr>
        ";
    }

    /**
     * Template de pied de page pour Epilist
     */
    public static function footerContent(): string
    {
        $currentYear = date('Y');
        
        return "
                                <tr>
                                    <td class='footer' style='background: linear-gradient(135deg, #1f2937 0%, #374151 100%); color: #ffffff; text-align: center; padding: 40px 30px;'>
                                        <!-- Logo footer -->
                                        <div style='display: inline-block; width: 60px; height: 60px; background: linear-gradient(135deg, #10b981 0%, #059669 100%); border-radius: 16px; margin-bottom: 20px; position: relative;'>
                                            <div style='position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); color: #ffffff; font-size: 24px;'>🛒</div>
                                        </div>
                                        
                                        <h3 style='margin: 0 0 8px; font-size: 18px; font-weight: 600; color: #ffffff;'>EpiList</h3>
                                        <p style='margin: 0 0 25px; font-size: 15px; color: #d1d5db; font-weight: 500;'>
                                            Simplifiez vos courses. Maîtrisez votre budget.
                                        </p>
                                        
                                        <!-- Fonctionnalités clés -->
                                        <div style='margin: 25px 0 30px; text-align: left; max-width: 400px; margin-left: auto; margin-right: auto;'>
                                            <div style='display: flex; align-items: center; margin-bottom: 8px; color: #d1d5db; font-size: 14px;'>
                                                <span style='margin-right: 8px;'>✅</span>
                                                <span>Créez vos listes avant d'aller faire vos courses</span>
                                            </div>
                                            <div style='display: flex; align-items: center; margin-bottom: 8px; color: #d1d5db; font-size: 14px;'>
                                                <span style='margin-right: 8px;'>🛍️</span>
                                                <span>Cochez vos achats en temps réel</span>
                                            </div>
                                            <div style='display: flex; align-items: center; color: #d1d5db; font-size: 14px;'>
                                                <span style='margin-right: 8px;'>💰</span>
                                                <span>Suivez vos dépenses d'épicerie en CAD\$</span>
                                            </div>
                                        </div>
                                        
                                        <!-- Informations de contact -->
                                        <p style='margin: 20px 0; font-size: 12px; color: #6b7280; line-height: 1.5; text-align: center;'>
                                            © {$currentYear} EpiList - Application de gestion de courses<br>
                                            Nouveau-Brunswick, Canada
                                        </p>
                                        
                                        <!-- Contact -->
                                        <div style='margin: 20px 0; padding: 16px; background: rgba(16, 185, 129, 0.1); border-radius: 8px; border: 1px solid rgba(16, 185, 129, 0.2);'>
                                            <p style='margin: 0 0 8px; font-size: 14px; color: #047857; font-weight: 600; text-align: center;'>
                                                Une question ? Besoin d'aide ?
                                            </p>
                                            <p style='margin: 0; font-size: 13px; color: #059669; text-align: center;'>
                                                Contactez-nous : <a href='mailto:contact@m2atech.com' style='color: #047857; font-weight: 600; text-decoration: none;'>contact@m2atech.com</a>
                                            </p>
                                        </div>
                                        
                                        <!-- Message local -->
                                        <div style='margin-top: 20px; padding: 15px; background: rgba(16, 185, 129, 0.05); border-radius: 8px;'>
                                            <p style='margin: 0; font-size: 12px; color: #10b981; font-weight: 500; text-align: center;'>
                                                🍁 Développée avec ❤️ par M2atech Solutions Inc.<br>
                                                <span style='font-size: 11px; color: #6b7280;'>Fièrement canadienne depuis le Nouveau-Brunswick</span>
                                            </p>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </body>
            </html>
        ";
    }

    /**
     * Template complet pour email de vérification
     */
    public static function verificationEmail(string $prenom, string $code): string
    {
        $header = self::headerContent('Vérification de votre compte EpiList');
        $footer = self::footerContent();
        
        $content = "
                                <tr>
                                    <td class='content' style='padding: 40px 30px;'>
                                        <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                                            Vérification de votre compte
                                        </h2>
                                        
                                        <p style='margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;'>
                                            Bonjour <strong>{$prenom}</strong>,
                                        </p>
                                        
                                        <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                                            Bienvenue sur <strong>EpiList</strong> ! Pour finaliser la création de votre compte et commencer à gérer vos courses efficacement, veuillez utiliser le code de vérification ci-dessous :
                                        </p>
                                        
                                        <div class='verification-code'>
                                            {$code}
                                        </div>
                                        
                                        <p style='margin: 20px 0; font-size: 14px; color: #6b7280; text-align: center;'>
                                            <strong>Ce code expire dans 15 minutes</strong>
                                        </p>
                                        
                                        <div style='background: #fef3c7; border: 1px solid #fbbf24; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                                            <p style='margin: 0; font-size: 14px; color: #92400e;'>
                                                <strong>💡 Conseil :</strong> Gardez ce code à portée de main et retournez dans l'application EpiList pour terminer votre inscription.
                                            </p>
                                        </div>
                                        
                                        <p style='margin: 25px 0 0; font-size: 16px; color: #374151; line-height: 1.6;'>
                                            Une fois votre compte vérifié, vous pourrez :<br>
                                            • Créer des listes d'épicerie personnalisées<br>
                                            • Suivre vos dépenses en temps réel<br>
                                            • Comparer les prix entre magasins<br>
                                            • Synchroniser vos listes sur tous vos appareils
                                        </p>
                                    </td>
                                </tr>
        ";
        
        return $header . $content . $footer;
    }

    /**
     * Template pour email de bienvenue
     */
    public static function welcomeEmail(string $prenom): string
    {
        $header = self::headerContent('Bienvenue dans la communauté EpiList');
        $footer = self::footerContent();
        
        $content = "
                                <tr>
                                    <td class='content' style='padding: 40px 30px;'>
                                        <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                                            Bienvenue dans la communauté EpiList ! 🎉
                                        </h2>
                                        
                                        <p style='margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;'>
                                            Bonjour <strong>{$prenom}</strong>,
                                        </p>
                                        
                                        <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                                            Félicitations ! Votre compte EpiList est maintenant actif et vous pouvez commencer à transformer votre façon de faire les courses.
                                        </p>
                                        
                                        <div style='background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%); border: 1px solid #10b981; border-radius: 12px; padding: 24px; margin: 25px 0; text-align: center;'>
                                            <h3 style='margin: 0 0 16px; font-size: 18px; color: #047857;'>🚀 Prêt à commencer ?</h3>
                                            <p style='margin: 0; font-size: 14px; color: #059669;'>
                                                Ouvrez votre application EpiList et créez votre première liste d'épicerie pour découvrir la simplicité de notre solution
                                            </p>
                                        </div>
                                        
                                        <h3 style='margin: 30px 0 15px; font-size: 18px; color: #047857;'>🛒 Vos prochaines étapes :</h3>
                                        
                                        <div style='margin: 20px 0;'>
                                            <div style='display: flex; align-items: flex-start; margin-bottom: 16px;'>
                                                <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>1</div>
                                                <div>
                                                    <strong style='color: #047857;'>Créez votre première liste</strong><br>
                                                    <span style='color: #6b7280; font-size: 14px;'>Ajoutez les produits dont vous avez besoin pour cette semaine</span>
                                                </div>
                                            </div>
                                            
                                            <div style='display: flex; align-items: flex-start; margin-bottom: 16px;'>
                                                <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>2</div>
                                                <div>
                                                    <strong style='color: #047857;'>Ajoutez les prix</strong><br>
                                                    <span style='color: #6b7280; font-size: 14px;'>Suivez vos dépenses et comparez les prix entre magasins</span>
                                                </div>
                                            </div>
                                            
                                            <div style='display: flex; align-items: flex-start;'>
                                                <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>3</div>
                                                <div>
                                                    <strong style='color: #047857;'>Faites vos courses</strong><br>
                                                    <span style='color: #6b7280; font-size: 14px;'>Cochez vos articles au fur et à mesure de vos achats</span>
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <div style='background: #fef3c7; border: 1px solid #fbbf24; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                                            <p style='margin: 0; font-size: 14px; color: #92400e;'>
                                                <strong>💡 Astuce :</strong> Utilisez EpiList avant de partir faire vos courses pour une expérience optimale !
                                            </p>
                                        </div>
                                        
                                        <p style='margin: 25px 0 0; font-size: 16px; color: #374151; line-height: 1.6;'>
                                            Merci de faire confiance à EpiList pour simplifier vos courses !<br><br>
                                            L'équipe EpiList
                                        </p>
                                    </td>
                                </tr>
        ";
        
        return $header . $content . $footer;
    }

    /**
     * Template pour réinitialisation de mot de passe
     */
    public static function resetPasswordEmail(string $prenom, string $lienReset): string
    {
        $header = self::headerContent('Réinitialisation de votre mot de passe EpiList');
        $footer = self::footerContent();
        
        $content = "
                                <tr>
                                    <td class='content' style='padding: 40px 30px;'>
                                        <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                                            Réinitialisation de mot de passe
                                        </h2>
                                        
                                        <p style='margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;'>
                                            Bonjour <strong>{$prenom}</strong>,
                                        </p>
                                        
                                        <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                                            Vous avez demandé la réinitialisation de votre mot de passe EpiList. Cliquez sur le bouton ci-dessous pour créer un nouveau mot de passe :
                                        </p>
                                        
                                        <div style='text-align: center; margin: 30px 0;'>
                                            <p style='margin: 0 0 16px; font-size: 14px; color: #6b7280;'>
                                                Pour réinitialiser votre mot de passe, copiez et collez ce lien dans votre navigateur :
                                            </p>
                                            <div style='background: #f3f4f6; border: 1px solid #d1d5db; border-radius: 8px; padding: 12px; word-break: break-all;'>
                                                <a href='{$lienReset}' style='color: #10b981; font-size: 14px; text-decoration: none;'>{$lienReset}</a>
                                            </div>
                                        </div>
                                        
                                        <p style='margin: 20px 0; font-size: 14px; color: #6b7280; text-align: center;'>
                                            <strong>Ce lien expire dans 1 heure</strong>
                                        </p>
                                        
                                        <div style='background: #fef2f2; border: 1px solid #f87171; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                                            <p style='margin: 0; font-size: 14px; color: #dc2626;'>
                                                <strong>🔒 Sécurité :</strong> Si vous n'avez pas demandé cette réinitialisation, ignorez cet email. Votre mot de passe actuel reste inchangé.
                                            </p>
                                        </div>
                                        
                                        <p style='margin: 25px 0; font-size: 14px; color: #6b7280; line-height: 1.6;'>
                                            <strong>Remarque :</strong> Ce lien fonctionne uniquement si vous l'ouvrez depuis l'appareil où vous avez demandé la réinitialisation.
                                        </p>
                                        
                                        <p style='margin: 25px 0 0; font-size: 16px; color: #374151; line-height: 1.6;'>
                                            L'équipe EpiList
                                        </p>
                                    </td>
                                </tr>
        ";
        
        return $header . $content . $footer;
    }
    /**
     * Méthode pour envoyer un email de changement de mot de passe
     */
    public static function sendPasswordChangeCode(string $email, string $code): bool 
    {
        $subject = "Votre code de changement de mot de passe EpiList";
        
        // Construction du contenu HTML de l'email
        $htmlContent = self::headerContent("Code de changement de mot de passe") . "
            <tr>
                <td class='content' style='padding: 40px 30px;'>
                    <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                        🔐 Code de changement de mot de passe
                    </h2>
                    
                    <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        Vous avez demandé à changer votre mot de passe EpiList. Voici votre code de vérification :
                    </p>
                    
                    <div class='verification-code'>
                        {$code}
                    </div>
                    
                    <p style='margin: 20px 0; font-size: 14px; color: #6b7280; text-align: center;'>
                        <strong>Ce code expire dans 2 heures</strong>
                    </p>
                    
                    <div style='background: #fef2f2; border: 1px solid #f87171; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                        <p style='margin: 0; font-size: 14px; color: #dc2626;'>
                            <strong>⚠️ Important :</strong> Ce code expirera dans 2 heures. Ne le partagez avec personne pour votre sécurité.
                        </p>
                    </div>
                    
                    <div style='background: #f0fdf4; border: 1px solid #10b981; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                        <p style='margin: 0; font-size: 14px; color: #047857;'>
                            <strong>🛒 Conseil :</strong> Une fois votre mot de passe changé, vous pourrez continuer à gérer vos listes d'épicerie en toute sécurité.
                        </p>
                    </div>
                    
                    <p style='margin: 25px 0; color: #6b7280; font-size: 14px; line-height: 1.6;'>
                        Si vous n'avez pas demandé ce changement, veuillez ignorer cet email ou contacter notre support à 
                        <a href='mailto:contact@m2atech.com' style='color: #10b981;'>contact@m2atech.com</a>
                    </p>
                    
                    <div style='margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb;'>
                        <p style='margin: 0 0 8px; color: #374151; font-weight: 600; font-size: 15px;'>
                            Cordialement,
                        </p>
                        <p style='margin: 0; color: #047857; font-weight: 600; font-size: 15px;'>
                            L'équipe EpiList
                        </p>
                    </div>
                </td>
            </tr>
        " . self::footerContent();
        
        // Envoi de l'email
        return self::sendMail(
            $subject,
            [['email' => $email]],
            $htmlContent
        );
    }

    /**
     * Envoie un email de vérification avec code
     */
    public static function sendVerificationEmail(string $email, string $firstName, string $code): bool
    {
        $subject = "Vérifiez votre compte EpiList - Code de vérification";
        
        // Génération du contenu HTML avec le template existant
        $htmlContent = self::verificationEmail($firstName, $code);
        
        // Envoi de l'email
        return self::sendMail(
            $subject,
            [['email' => $email]],
            $htmlContent
        );
    }

    /**
     * Envoie un email de bienvenue après vérification réussie
     */
    public static function sendWelcomeEmail(string $email, string $firstName): bool
    {
        $subject = "Bienvenue dans la communauté EpiList ! 🎉";
        
        // Génération du contenu HTML avec le template existant
        $htmlContent = self::welcomeEmail($firstName);
        
        // Envoi de l'email
        return self::sendMail(
            $subject,
            [['email' => $email]],
            $htmlContent
        );
    }
}