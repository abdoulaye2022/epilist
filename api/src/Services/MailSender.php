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
    private const SENDER_NAME = 'Kiloshare';
    private const SENDER_EMAIL = 'noreply@kiloshare.com';
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

    /**
     * Template d'en-tête d'email en français
     */
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
                        background: linear-gradient(135deg, #4096FF 0%, #1E90FF 100%);
                        color: #ffffff !important; 
                        padding: 16px 32px; 
                        text-decoration: none; 
                        font-weight: 600; 
                        border-radius: 8px; 
                        transition: all 0.3s ease;
                        box-shadow: 0 4px 12px rgba(64, 150, 255, 0.25);
                    }
                    
                    .button:hover {
                        transform: translateY(-2px);
                        box-shadow: 0 6px 20px rgba(64, 150, 255, 0.35);
                    }
                    
                    /* Responsive */
                    @media (max-width: 600px) {
                        .email-container { width: 100% !important; }
                        .content { padding: 20px !important; }
                    }
                </style>
            </head>
            <body style='margin: 0; padding: 0; font-family: Inter, Arial, sans-serif; background-color: #f7fafc; color: #1a202c;'>
                <table role='presentation' width='100%' cellspacing='0' cellpadding='0' border='0' style='background-color: #f7fafc;'>
                    <tr>
                        <td align='center' style='padding: 40px 20px;'>
                            <table class='email-container' role='presentation' width='600' cellspacing='0' cellpadding='0' border='0' style='max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 25px rgba(0, 0, 0, 0.08); overflow: hidden;'>
                                <tr>
                                    <td class='header' style='background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%); padding: 40px 30px 30px; text-align: center; border-bottom: 1px solid #e2e8f0;'>
                                        <img src='https://m2acode.com/api.kiloshare/public/logo_bleu.png' alt='Logo Kiloshare' style='max-width: 180px; height: auto; display: block; margin: 0 auto;'>
                                        <div style='margin-top: 15px; height: 3px; width: 60px; background: linear-gradient(90deg, #4096FF, #1E90FF); margin-left: auto; margin-right: auto; border-radius: 2px;'></div>
                                    </td>
                                </tr>
        ";
    }

    /**
     * Template de pied de page en français
     */
    public static function footerContent(): string
    {
        $baseUrl = Config::get('BASE_URL');
        $currentYear = date('Y');
        
        return "
                                <tr>
                                    <td class='footer' style='background: linear-gradient(135deg, #1a202c 0%, #2d3748 100%); color: #ffffff; text-align: center; padding: 40px 30px;'>
                                        <img src='https://m2acode.com/api.kiloshare/public/logo.png' alt='Kiloshare' style='max-width: 140px; height: auto; margin-bottom: 20px; opacity: 0.95;'>
                                        
                                        <h3 style='margin: 0 0 8px; font-size: 18px; font-weight: 600; color: #ffffff;'>Kiloshare</h3>
                                        <p style='margin: 0 0 25px; font-size: 15px; color: #cbd5e0; font-weight: 500;'>
                                            Partagez. Transportez. Économisez.
                                        </p>
                                        
                                        <div style='margin: 25px 0 30px;'>
                                            <a href='https://www.linkedin.com/company/m2atech-solutions-inc' style='display: inline-block; margin: 0 10px; text-decoration: none;'>
                                                <img src='https://m2acode.com/api.kiloshare/public/linkedin.png' alt='LinkedIn' style='width: 36px; height: 36px; border-radius: 8px; transition: opacity 0.3s ease;'>
                                            </a>
                                            <a href='https://youtube.com' style='display: inline-block; margin: 0 10px; text-decoration: none;'>
                                                <img src='https://m2acode.com/api.kiloshare/public/youtube.png' alt='YouTube' style='width: 36px; height: 36px; border-radius: 8px; transition: opacity 0.3s ease;'>
                                            </a>
                                            <a href='https://www.instagram.com/m2atech.solutions' style='display: inline-block; margin: 0 10px; text-decoration: none;'>
                                                <img src='https://m2acode.com/api.kiloshare/public/instagram.png' alt='Instagram' style='width: 36px; height: 36px; border-radius: 8px; transition: opacity 0.3s ease;'>
                                            </a>
                                        </div>
                                        
                                        <div style='margin: 25px 0; padding: 20px 0; border-top: 1px solid #4a5568; border-bottom: 1px solid #4a5568;'>
                                            <p style='margin: 0; font-size: 13px; color: #a0aec0;'>
                                                <a href='{$baseUrl}' style='color: #63b3ed; text-decoration: none; margin: 0 12px; transition: color 0.3s ease;'>Accueil</a>
                                                <span style='color: #718096;'>|</span>
                                                <a href='{$baseUrl}/contact' style='color: #63b3ed; text-decoration: none; margin: 0 12px; transition: color 0.3s ease;'>Contact</a>
                                                <span style='color: #718096;'>|</span>
                                                <a href='{$baseUrl}/confidentialite' style='color: #63b3ed; text-decoration: none; margin: 0 12px; transition: color 0.3s ease;'>Confidentialité</a>
                                                <span style='color: #718096;'>|</span>
                                                <a href='{$baseUrl}/conditions' style='color: #63b3ed; text-decoration: none; margin: 0 12px; transition: color 0.3s ease;'>Conditions</a>
                                            </p>
                                        </div>
                                        
                                        <p style='margin: 20px 0 0; font-size: 12px; color: #718096; line-height: 1.5;'>
                                            © {$currentYear} Kiloshare par M2atech Solutions Inc. Tous droits réservés.<br>
                                            Montréal, Québec, Canada<br><br>
                                            <a href='mailto:support@kiloshare.com' style='color: #63b3ed; text-decoration: none;'>support@kiloshare.com</a>
                                            <span style='margin: 0 8px; color: #4a5568;'>•</span>
                                            <a href='#' style='color: #63b3ed; text-decoration: none;'>Se désabonner</a>
                                        </p>
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
     * Template pour email de confirmation en français
     */
    public static function getConfirmationEmailTemplate(string $firstName, string $lastName, string $confirmationLink): string
    {
        return self::headerContent("Confirmation d'email | Kiloshare") . "
            <tr>
                <td class='content' style='padding: 50px 40px; line-height: 1.7;'>
                    <h1 style='color: #1a202c; font-size: 26px; font-weight: 700; margin: 0 0 25px; text-align: center;'>
                        Confirmez votre adresse email
                    </h1>
                    
                    <h2 style='color: #4096FF; font-size: 20px; font-weight: 600; margin: 0 0 25px;'>
                        Bonjour {$firstName} {$lastName},
                    </h2>
                    
                    <p style='margin: 0 0 25px; color: #4a5568; font-size: 16px; line-height: 1.8;'>
                        Bienvenue dans la communauté Kiloshare ! Nous sommes ravis de vous accueillir parmi nous.
                    </p>
                    
                    <p style='margin: 0 0 35px; color: #4a5568; font-size: 16px; line-height: 1.8;'>
                        Pour finaliser votre inscription et accéder à toutes les fonctionnalités de notre plateforme, 
                        nous avons besoin que vous confirmiez votre adresse email en cliquant sur le bouton ci-dessous :
                    </p>
                    
                    <div style='text-align: center; margin: 40px 0 50px;'>
                        <a href='{$confirmationLink}' class='button' style='display: inline-block; background: linear-gradient(135deg, #4096FF 0%, #1E90FF 100%); color: #ffffff !important; padding: 18px 40px; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px; box-shadow: 0 4px 15px rgba(64, 150, 255, 0.3);'>
                            ✓ Confirmer mon email
                        </a>
                    </div>
                    
                    <div style='background-color: #f8fafc; padding: 25px; margin: 35px 0; border-radius: 10px; border-left: 4px solid #4096FF;'>
                        <p style='margin: 0 0 15px; color: #4a5568; font-weight: 600; font-size: 15px;'>
                            💡 Vous ne pouvez pas cliquer sur le bouton ?
                        </p>
                        <p style='margin: 0; color: #4a5568; font-size: 14px; line-height: 1.6;'>
                            Copiez et collez ce lien dans votre navigateur :<br>
                            <span style='word-break: break-all; color: #4096FF; font-family: monospace; background: #edf2f7; padding: 4px 8px; border-radius: 4px; margin-top: 8px; display: inline-block;'>{$confirmationLink}</span>
                        </p>
                    </div>
                    
                    <div style='background-color: #fff5f5; border-left: 4px solid #fed7d7; padding: 20px; margin: 30px 0; border-radius: 6px;'>
                        <p style='margin: 0; color: #744210; font-size: 14px;'>
                            <strong>⏰ Important :</strong> Ce lien de confirmation expirera dans 24 heures pour des raisons de sécurité.
                        </p>
                    </div>
                    
                    <p style='margin: 35px 0 25px; color: #718096; font-size: 14px; line-height: 1.6;'>
                        Si vous n'avez pas créé de compte sur Kiloshare, vous pouvez ignorer cet email en toute sécurité. 
                        Aucune action ne sera effectuée sur votre adresse email.
                    </p>
                    
                    <div style='margin-top: 40px; padding-top: 25px; border-top: 1px solid #e2e8f0;'>
                        <p style='margin: 0 0 8px; color: #4a5568; font-weight: 600; font-size: 15px;'>
                            Cordialement,
                        </p>
                        <p style='margin: 0; color: #4096FF; font-weight: 600; font-size: 15px;'>
                            L'équipe Kiloshare
                        </p>
                    </div>
                </td>
            </tr>
        " . self::footerContent();
    }

    /**
     * Template pour email de réinitialisation de mot de passe en français
     */
    public static function getPasswordResetEmailTemplate(string $firstName, string $lastName, string $resetLink): string
    {
        return self::headerContent("Réinitialisation de mot de passe | Kiloshare") . "     
            <tr>
                <td class='content' style='padding: 50px 40px; line-height: 1.7;'>
                    <h1 style='color: #1a202c; font-size: 26px; font-weight: 700; margin: 0 0 25px; text-align: center;'>
                        Réinitialisation de votre mot de passe
                    </h1>
                    
                    <h2 style='color: #4096FF; font-size: 20px; font-weight: 600; margin: 0 0 25px;'>
                        Bonjour {$firstName} {$lastName},
                    </h2>
                    
                    <p style='margin: 0 0 25px; color: #4a5568; font-size: 16px; line-height: 1.8;'>
                        Nous avons reçu une demande de réinitialisation de mot de passe pour votre compte Kiloshare.
                    </p>
                    
                    <p style='margin: 0 0 35px; color: #4a5568; font-size: 16px; line-height: 1.8;'>
                        Si vous êtes à l'origine de cette demande, cliquez sur le bouton ci-dessous pour créer un nouveau mot de passe :
                    </p>
                    
                    <div style='text-align: center; margin: 40px 0 50px;'>
                        <a href='{$resetLink}' class='button' style='display: inline-block; background: linear-gradient(135deg, #4096FF 0%, #1E90FF 100%); color: #ffffff !important; padding: 18px 40px; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px; box-shadow: 0 4px 15px rgba(64, 150, 255, 0.3);'>
                            🔒 Réinitialiser mon mot de passe
                        </a>
                    </div>
                    
                    <div style='background-color: #fff5f5; border-left: 4px solid #f56565; padding: 20px; margin: 35px 0; border-radius: 6px;'>
                        <p style='margin: 0; color: #c53030; font-size: 15px; line-height: 1.6;'>
                            <strong>⚠️ Important :</strong> Ce lien expirera dans 1 heure pour votre sécurité. 
                            Si vous n'avez pas demandé cette réinitialisation, ignorez cet email ou 
                            <a href='mailto:support@kiloshare.com' style='color: #c53030; text-decoration: underline;'>contactez-nous immédiatement</a>.
                        </p>
                    </div>
                    
                    <div style='background-color: #f8fafc; padding: 25px; margin: 35px 0; border-radius: 10px; border-left: 4px solid #4096FF;'>
                        <p style='margin: 0 0 15px; color: #4a5568; font-weight: 600; font-size: 15px;'>
                            💡 Vous ne pouvez pas cliquer sur le bouton ?
                        </p>
                        <p style='margin: 0; color: #4a5568; font-size: 14px; line-height: 1.6;'>
                            Copiez et collez ce lien dans votre navigateur :<br>
                            <span style='word-break: break-all; color: #4096FF; font-family: monospace; background: #edf2f7; padding: 4px 8px; border-radius: 4px; margin-top: 8px; display: inline-block;'>{$resetLink}</span>
                        </p>
                    </div>
                    
                    <p style='margin: 35px 0 25px; color: #718096; font-size: 14px; line-height: 1.6;'>
                        Pour votre sécurité, nous vous recommandons de choisir un mot de passe fort contenant au moins 8 caractères, 
                        avec des majuscules, minuscules, chiffres et caractères spéciaux.
                    </p>
                    
                    <div style='margin-top: 40px; padding-top: 25px; border-top: 1px solid #e2e8f0;'>
                        <p style='margin: 0 0 8px; color: #4a5568; font-weight: 600; font-size: 15px;'>
                            Cordialement,
                        </p>
                        <p style='margin: 0; color: #4096FF; font-weight: 600; font-size: 15px;'>
                            L'équipe Kiloshare
                        </p>
                    </div>
                </td>
            </tr>
        " . self::footerContent();
    }

    public static function creationConfirmationEmailTemplate(Ad $ad): string
    {
         return self::headerContent("Merci pour votre annonce ! (Validation en cours)") . "
            <tr>
                <td class='content' style='padding: 30px 40px; line-height: 1.6;'>
                    <h1 style='color: #1A202C; font-size: 22px; font-weight: 600; margin-top: 0; margin-bottom: 20px;'>Validation de votre annonce</h1>
                    
                    <h2 style='color: #4096FF; font-size: 18px; font-weight: 600; margin-bottom: 15px;'>Bonjour {$ad->user->first_name} {$ad->user->last_name},</h2>
                    
                    <p style='margin: 0 0 20px; color: #4A5568;'>
                        Nous vous remercions d'avoir créé une annonce sur Kiloshare ! Votre annonce <strong>{$ad->title}</strong> est en cours de validation et sera approuvée d'ici peu, généralement dans un délai de <strong>24 heures</strong>.
                    </p>
                    
                    <p style='margin: 0 0 20px; color: #4A5568;'>
                        Une fois validée, vous recevrez une notification et votre annonce sera visible par tous les utilisateurs de la plateforme.
                    </p>
                    
                    <div style='background-color: #F8FAFC; border-left: 4px solid #4096FF; padding: 15px; margin: 25px 0; border-radius: 0 4px 4px 0;'>
                        <p style='margin: 0; color: #4A5568; font-size: 15px;'>
                            Nous vous remercions pour la confiance que vous accordez à Kiloshare. Pour toute question, contactez-nous à <a href='mailto:contact@kiloshare.com' style='color: #4096FF; text-decoration: none; font-weight: 600;'>contact@kiloshare.com</a>.
                        </p>
                    </div>
                    
                    <p style='margin: 25px 0 15px; color: #4A5568;'>
                        À très bientôt sur Kiloshare !
                    </p>
                    
                    <p style='margin: 30px 0 10px; color: #4A5568; font-weight: 600;'>
                        L'équipe Kiloshare
                    </p>
                </td>
            </tr> 
        " . self::footerContent();
    }
}