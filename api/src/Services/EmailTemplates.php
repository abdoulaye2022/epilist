<?php
// src/Services/EmailTemplates.php - TEMPLATES D'EMAILS MULTILINGUES

namespace App\Services;

class EmailTemplates
{
    /**
     * Traductions pour le header et footer
     */
    private static function getCommonTranslations(): array
    {
        return [
            'fr' => [
                'tagline' => 'Gérez vos courses facilement',
                'footer_tagline' => 'Simplifiez vos courses. Maîtrisez votre budget.',
                'feature_1' => 'Créez vos listes avant d\'aller faire vos courses',
                'feature_2' => 'Cochez vos achats en temps réel',
                'feature_3' => 'Suivez vos dépenses dans votre devise préférée',
                'feature_4' => 'Partagez vos listes avec votre famille',
                'discover_features' => 'Découvrez toutes nos fonctionnalités',
                'visit_website' => 'Visitez epilist.app',
                'copyright' => 'Application de gestion de courses',
                'help_title' => 'Une question ? Besoin d\'aide ?',
                'help_text' => 'Rendez-vous sur notre site web pour nous contacter',
                'proudly_canadian' => 'Développée avec ❤ par M2atech Solutions Inc.',
                'local_tag' => 'Fièrement canadienne depuis le Nouveau-Brunswick',
            ],
            'en' => [
                'tagline' => 'Manage your shopping easily',
                'footer_tagline' => 'Simplify your shopping. Master your budget.',
                'feature_1' => 'Create your lists before going shopping',
                'feature_2' => 'Check off your purchases in real-time',
                'feature_3' => 'Track your expenses in your preferred currency',
                'feature_4' => 'Share your lists with your family',
                'discover_features' => 'Discover all our features',
                'visit_website' => 'Visit epilist.app',
                'copyright' => 'Shopping Management Application',
                'help_title' => 'Have a question? Need help?',
                'help_text' => 'Visit our website to contact us',
                'proudly_canadian' => 'Developed with ❤ by M2atech Solutions Inc.',
                'local_tag' => 'Proudly Canadian from New Brunswick',
            ],
        ];
    }

    /**
     * Obtenir les traductions pour un template donné
     */
    private static function getTranslations(string $template): array
    {
        $translations = [
            'verification' => [
                'fr' => [
                    'subject' => 'Vérifiez votre compte EpiList - Code de vérification',
                    'title' => 'Vérification de votre compte',
                    'greeting' => 'Bonjour',
                    'intro' => 'Bienvenue sur <strong>EpiList</strong> ! Pour finaliser la création de votre compte et commencer à gérer vos courses efficacement, veuillez utiliser le code de vérification ci-dessous :',
                    'code_expires' => 'Ce code expire dans 15 minutes',
                    'tip_title' => 'Conseil :',
                    'tip_text' => 'Gardez ce code à portée de main et retournez dans l\'application EpiList pour terminer votre inscription.',
                    'benefits_title' => 'Une fois votre compte vérifié, vous pourrez :',
                    'benefit_1' => 'Créer des listes d\'épicerie personnalisées',
                    'benefit_2' => 'Suivre vos dépenses en temps réel',
                    'benefit_3' => 'Comparer les prix entre magasins',
                    'benefit_4' => 'Synchroniser vos listes sur tous vos appareils',
                ],
                'en' => [
                    'subject' => 'Verify your Epi List account - Verification code',
                    'title' => 'Account Verification',
                    'greeting' => 'Hello',
                    'intro' => 'Welcome to <strong>EpiList</strong>! To complete your account creation and start managing your shopping efficiently, please use the verification code below:',
                    'code_expires' => 'This code expires in 15 minutes',
                    'tip_title' => 'Tip:',
                    'tip_text' => 'Keep this code handy and return to the EpiList app to complete your registration.',
                    'benefits_title' => 'Once your account is verified, you will be able to:',
                    'benefit_1' => 'Create personalized shopping lists',
                    'benefit_2' => 'Track your expenses in real-time',
                    'benefit_3' => 'Compare prices between stores',
                    'benefit_4' => 'Sync your lists across all your devices',
                ],
            ],
            'welcome' => [
                'fr' => [
                    'subject' => 'Bienvenue dans la communauté EpiList ! 🎉',
                    'title' => 'Bienvenue dans la communauté EpiList ! 🎉',
                    'greeting' => 'Bonjour',
                    'intro' => 'Félicitations ! Votre compte EpiList est maintenant actif et vous pouvez commencer à transformer votre façon de faire les courses.',
                    'cta_title' => '🚀 Prêt à commencer ?',
                    'cta_text' => 'Ouvrez votre application EpiList et créez votre première liste d\'épicerie pour découvrir la simplicité de notre solution',
                    'steps_title' => '✨ Vos prochaines étapes :',
                    'step_1_title' => 'Créez votre première liste',
                    'step_1_text' => 'Ajoutez les produits dont vous avez besoin pour cette semaine',
                    'step_2_title' => 'Ajoutez les prix',
                    'step_2_text' => 'Suivez vos dépenses et comparez les prix entre magasins',
                    'step_3_title' => 'Faites vos courses',
                    'step_3_text' => 'Cochez vos articles au fur et à mesure de vos achats',
                    'tip_title' => '💡 Astuce :',
                    'tip_text' => 'Utilisez EpiList avant de partir faire vos courses pour une expérience optimale !',
                    'closing' => 'Merci de faire confiance à EpiList pour simplifier vos courses !<br><br>L\'équipe EpiList',
                ],
                'en' => [
                    'subject' => 'Welcome to the EpiList community! 🎉',
                    'title' => 'Welcome to the EpiList community! 🎉',
                    'greeting' => 'Hello',
                    'intro' => 'Congratulations! Your EpiList account is now active and you can start transforming the way you shop.',
                    'cta_title' => '🚀 Ready to start?',
                    'cta_text' => 'Open your EpiList app and create your first shopping list to discover the simplicity of our solution',
                    'steps_title' => '✨ Your next steps:',
                    'step_1_title' => 'Create your first list',
                    'step_1_text' => 'Add the products you need for this week',
                    'step_2_title' => 'Add prices',
                    'step_2_text' => 'Track your spending and compare prices between stores',
                    'step_3_title' => 'Go shopping',
                    'step_3_text' => 'Check off your items as you shop',
                    'tip_title' => '💡 Tip:',
                    'tip_text' => 'Use EpiList before heading out shopping for the best experience!',
                    'closing' => 'Thank you for trusting EpiList to simplify your shopping!<br><br>The EpiList Team',
                ],
            ],
            'password_change' => [
                'fr' => [
                    'subject' => 'Votre code de changement de mot de passe EpiList',
                    'title' => '🔒 Code de changement de mot de passe',
                    'intro' => 'Vous avez demandé à changer votre mot de passe EpiList. Voici votre code de vérification :',
                    'code_expires' => 'Ce code expire dans 2 heures',
                    'important_title' => '⚠️ Important :',
                    'important_text' => 'Ce code expirera dans 2 heures. Ne le partagez avec personne pour votre sécurité.',
                    'tip_title' => '💡 Conseil :',
                    'tip_text' => 'Une fois votre mot de passe changé, vous pourrez continuer à gérer vos listes d\'épicerie en toute sécurité.',
                    'help_text' => 'Si vous n\'avez pas demandé ce changement, veuillez ignorer cet email ou contacter notre support.',
                    'closing' => 'Cordialement,<br>L\'équipe EpiList',
                ],
                'en' => [
                    'subject' => 'Your EpiList password change code',
                    'title' => '🔒 Password Change Code',
                    'intro' => 'You have requested to change your EpiList password. Here is your verification code:',
                    'code_expires' => 'This code expires in 2 hours',
                    'important_title' => '⚠️ Important:',
                    'important_text' => 'This code will expire in 2 hours. Do not share it with anyone for your security.',
                    'tip_title' => '💡 Tip:',
                    'tip_text' => 'Once your password is changed, you will be able to continue managing your shopping lists securely.',
                    'help_text' => 'If you did not request this change, please ignore this email or contact our support.',
                    'closing' => 'Best regards,<br>The EpiList Team',
                ],
            ],
            'password_changed' => [
                'fr' => [
                    'subject' => '✅ Votre mot de passe EpiList a été changé',
                    'title' => '✅ Mot de passe changé avec succès',
                    'greeting' => 'Bonjour',
                    'intro' => 'Votre mot de passe EpiList a été changé avec succès.',
                    'change_time' => 'Date et heure du changement :',
                    'security_title' => '🔐 Sécurité de votre compte',
                    'security_text' => 'Si vous n\'êtes pas à l\'origine de ce changement, veuillez nous contacter immédiatement.',
                    'tips_title' => '💡 Conseils de sécurité :',
                    'tip_1' => 'Utilisez un mot de passe unique pour EpiList',
                    'tip_2' => 'Ne partagez jamais votre mot de passe',
                    'tip_3' => 'Changez votre mot de passe régulièrement',
                    'tip_4' => 'Utilisez un gestionnaire de mots de passe sécurisé',
                    'action_required' => 'Action requise :',
                    'action_text' => 'Si ce n\'était pas vous, changez immédiatement votre mot de passe et contactez notre support.',
                    'closing' => 'Votre sécurité est notre priorité.<br><br>Cordialement,<br>L\'équipe EpiList',
                ],
                'en' => [
                    'subject' => '✅ Your EpiList password has been changed',
                    'title' => '✅ Password changed successfully',
                    'greeting' => 'Hello',
                    'intro' => 'Your EpiList password has been successfully changed.',
                    'change_time' => 'Date and time of change:',
                    'security_title' => '🔐 Account Security',
                    'security_text' => 'If you did not make this change, please contact us immediately.',
                    'tips_title' => '💡 Security Tips:',
                    'tip_1' => 'Use a unique password for EpiList',
                    'tip_2' => 'Never share your password',
                    'tip_3' => 'Change your password regularly',
                    'tip_4' => 'Use a secure password manager',
                    'action_required' => 'Action Required:',
                    'action_text' => 'If this wasn\'t you, change your password immediately and contact our support.',
                    'closing' => 'Your security is our priority.<br><br>Best regards,<br>The EpiList Team',
                ],
            ],
            'list_shared' => [
                'fr' => [
                    'subject' => '📋 {sharer_name} a partagé une liste avec vous',
                    'title' => '📋 Nouvelle liste partagée',
                    'greeting' => 'Bonjour',
                    'intro' => '{sharer_name} a partagé la liste "<strong>{list_name}</strong>" avec vous.',
                    'list_info_title' => 'Informations sur la liste :',
                    'list_name_label' => 'Nom :',
                    'shared_by_label' => 'Partagée par :',
                    'shared_at_label' => 'Date de partage :',
                    'permission_label' => 'Vos permissions :',
                    'permission_edit' => 'Vous pouvez modifier cette liste',
                    'permission_view' => 'Vous pouvez seulement consulter cette liste',
                    'cta_title' => '🚀 Commencez à collaborer',
                    'cta_text' => 'Ouvrez EpiList pour voir la liste et commencer à collaborer avec {sharer_name}.',
                    'features_title' => '✨ Avec les listes partagées, vous pouvez :',
                    'feature_1' => 'Voir les modifications en temps réel',
                    'feature_2' => 'Ajouter et cocher des articles ensemble',
                    'feature_3' => 'Suivre les dépenses en commun',
                    'feature_4' => 'Communiquer via le chat intégré',
                    'closing' => 'Bonne collaboration !<br><br>L\'équipe EpiList',
                ],
                'en' => [
                    'subject' => '📋 {sharer_name} shared a list with you',
                    'title' => '📋 New shared list',
                    'greeting' => 'Hello',
                    'intro' => '{sharer_name} has shared the list "<strong>{list_name}</strong>" with you.',
                    'list_info_title' => 'List information:',
                    'list_name_label' => 'Name:',
                    'shared_by_label' => 'Shared by:',
                    'shared_at_label' => 'Shared on:',
                    'permission_label' => 'Your permissions:',
                    'permission_edit' => 'You can edit this list',
                    'permission_view' => 'You can only view this list',
                    'cta_title' => '🚀 Start collaborating',
                    'cta_text' => 'Open EpiList to view the list and start collaborating with {sharer_name}.',
                    'features_title' => '✨ With shared lists, you can:',
                    'feature_1' => 'See real-time updates',
                    'feature_2' => 'Add and check off items together',
                    'feature_3' => 'Track expenses together',
                    'feature_4' => 'Communicate via integrated chat',
                    'closing' => 'Happy collaborating!<br><br>The EpiList Team',
                ],
            ],
            'list_completed' => [
                'fr' => [
                    'subject' => '🎉 Liste "{list_name}" complétée !',
                    'title' => '🎉 Liste complétée !',
                    'greeting' => 'Bonjour',
                    'intro' => 'Bonne nouvelle ! La liste "<strong>{list_name}</strong>" a été complétée.',
                    'completed_by' => 'Complétée par : {completed_by}',
                    'stats_title' => '📊 Statistiques de la liste :',
                    'total_items' => 'Articles au total',
                    'total_amount' => 'Montant total',
                    'shared_with' => 'Partagée avec',
                    'cta_title' => '📈 Voir les détails',
                    'cta_text' => 'Ouvrez EpiList pour voir tous les détails et l\'historique de cette liste.',
                    'closing' => 'Félicitations pour cette liste complétée !<br><br>L\'équipe EpiList',
                ],
                'en' => [
                    'subject' => '🎉 List "{list_name}" completed!',
                    'title' => '🎉 List completed!',
                    'greeting' => 'Hello',
                    'intro' => 'Great news! The list "<strong>{list_name}</strong>" has been completed.',
                    'completed_by' => 'Completed by: {completed_by}',
                    'stats_title' => '📊 List statistics:',
                    'total_items' => 'Total items',
                    'total_amount' => 'Total amount',
                    'shared_with' => 'Shared with',
                    'cta_title' => '📈 View details',
                    'cta_text' => 'Open EpiList to see all details and history of this list.',
                    'closing' => 'Congratulations on completing this list!<br><br>The EpiList Team',
                ],
            ],
        ];

        return $translations[$template] ?? [];
    }

    /**
     * Générer le template de vérification d'email
     */
    public static function verificationEmail(string $firstName, string $code, string $lang = 'fr'): string
    {
        $t = self::getTranslations('verification')[$lang] ?? self::getTranslations('verification')['fr'];

        $header = self::headerContent($t['title'], $lang);
        $footer = self::footerContent($lang);

        $content = "
            <tr>
                <td class='content' style='padding: 40px 30px;'>
                    <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                        {$t['title']}
                    </h2>

                    <p style='margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['greeting']} <strong>{$firstName}</strong>,
                    </p>

                    <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['intro']}
                    </p>

                    <div class='verification-code'>
                        {$code}
                    </div>

                    <p style='margin: 20px 0; font-size: 14px; color: #6b7280; text-align: center;'>
                        <strong>{$t['code_expires']}</strong>
                    </p>

                    <div style='background: #fef3c7; border: 1px solid #fbbf24; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                        <p style='margin: 0; font-size: 14px; color: #92400e;'>
                            <strong>{$t['tip_title']}</strong> {$t['tip_text']}
                        </p>
                    </div>

                    <p style='margin: 25px 0 0; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['benefits_title']}<br>
                        • {$t['benefit_1']}<br>
                        • {$t['benefit_2']}<br>
                        • {$t['benefit_3']}<br>
                        • {$t['benefit_4']}
                    </p>
                </td>
            </tr>
        ";

        return $header . $content . $footer;
    }

    /**
     * Générer le template de bienvenue
     */
    public static function welcomeEmail(string $firstName, string $lang = 'fr'): string
    {
        $t = self::getTranslations('welcome')[$lang] ?? self::getTranslations('welcome')['fr'];

        $header = self::headerContent($t['title'], $lang);
        $footer = self::footerContent($lang);

        $content = "
            <tr>
                <td class='content' style='padding: 40px 30px;'>
                    <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                        {$t['title']}
                    </h2>

                    <p style='margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['greeting']} <strong>{$firstName}</strong>,
                    </p>

                    <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['intro']}
                    </p>

                    <div style='background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%); border: 1px solid #10b981; border-radius: 12px; padding: 24px; margin: 25px 0; text-align: center;'>
                        <h3 style='margin: 0 0 16px; font-size: 18px; color: #047857;'>{$t['cta_title']}</h3>
                        <p style='margin: 0; font-size: 14px; color: #059669;'>
                            {$t['cta_text']}
                        </p>
                    </div>

                    <h3 style='margin: 30px 0 15px; font-size: 18px; color: #047857;'>{$t['steps_title']}</h3>

                    <div style='margin: 20px 0;'>
                        <div style='display: flex; align-items: flex-start; margin-bottom: 16px;'>
                            <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>1</div>
                            <div>
                                <strong style='color: #047857;'>{$t['step_1_title']}</strong><br>
                                <span style='color: #6b7280; font-size: 14px;'>{$t['step_1_text']}</span>
                            </div>
                        </div>

                        <div style='display: flex; align-items: flex-start; margin-bottom: 16px;'>
                            <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>2</div>
                            <div>
                                <strong style='color: #047857;'>{$t['step_2_title']}</strong><br>
                                <span style='color: #6b7280; font-size: 14px;'>{$t['step_2_text']}</span>
                            </div>
                        </div>

                        <div style='display: flex; align-items: flex-start;'>
                            <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>3</div>
                            <div>
                                <strong style='color: #047857;'>{$t['step_3_title']}</strong><br>
                                <span style='color: #6b7280; font-size: 14px;'>{$t['step_3_text']}</span>
                            </div>
                        </div>
                    </div>

                    <div style='background: #fef3c7; border: 1px solid #fbbf24; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                        <p style='margin: 0; font-size: 14px; color: #92400e;'>
                            <strong>{$t['tip_title']}</strong> {$t['tip_text']}
                        </p>
                    </div>

                    <p style='margin: 25px 0 0; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['closing']}
                    </p>
                </td>
            </tr>
        ";

        return $header . $content . $footer;
    }

    /**
     * Générer le template de changement de mot de passe
     */
    public static function passwordChangeEmail(string $code, string $lang = 'fr'): string
    {
        $t = self::getTranslations('password_change')[$lang] ?? self::getTranslations('password_change')['fr'];

        $header = self::headerContent($t['title'], $lang);
        $footer = self::footerContent($lang);

        $content = "
            <tr>
                <td class='content' style='padding: 40px 30px;'>
                    <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                        {$t['title']}
                    </h2>

                    <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['intro']}
                    </p>

                    <div class='verification-code'>
                        {$code}
                    </div>

                    <p style='margin: 20px 0; font-size: 14px; color: #6b7280; text-align: center;'>
                        <strong>{$t['code_expires']}</strong>
                    </p>

                    <div style='background: #fef2f2; border: 1px solid #f87171; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                        <p style='margin: 0; font-size: 14px; color: #dc2626;'>
                            <strong>{$t['important_title']}</strong> {$t['important_text']}
                        </p>
                    </div>

                    <div style='background: #f0fdf4; border: 1px solid #10b981; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                        <p style='margin: 0; font-size: 14px; color: #047857;'>
                            <strong>{$t['tip_title']}</strong> {$t['tip_text']}
                        </p>
                    </div>

                    <p style='margin: 25px 0; color: #6b7280; font-size: 14px; line-height: 1.6;'>
                        {$t['help_text']}
                    </p>

                    <div style='margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb;'>
                        <p style='margin: 0; color: #047857; font-weight: 600; font-size: 15px;'>
                            {$t['closing']}
                        </p>
                    </div>
                </td>
            </tr>
        ";

        return $header . $content . $footer;
    }

    /**
     * Générer le template de confirmation de changement de mot de passe
     */
    public static function passwordChangedEmail(string $firstName, string $changeDateTime, string $lang = 'fr'): string
    {
        $t = self::getTranslations('password_changed')[$lang] ?? self::getTranslations('password_changed')['fr'];

        $header = self::headerContent($t['title'], $lang);
        $footer = self::footerContent($lang);

        $content = "
            <tr>
                <td class='content' style='padding: 40px 30px;'>
                    <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                        {$t['title']}
                    </h2>

                    <p style='margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['greeting']} <strong>{$firstName}</strong>,
                    </p>

                    <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['intro']}
                    </p>

                    <div style='background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border: 2px solid #10b981; border-radius: 12px; padding: 20px; margin: 25px 0; text-align: center;'>
                        <p style='margin: 0 0 8px; font-size: 14px; color: #047857; font-weight: 600;'>
                            {$t['change_time']}
                        </p>
                        <p style='margin: 0; font-size: 18px; color: #059669; font-weight: bold;'>
                            {$changeDateTime}
                        </p>
                    </div>

                    <div style='background: #fef2f2; border: 2px solid #f87171; border-radius: 12px; padding: 20px; margin: 25px 0;'>
                        <h3 style='margin: 0 0 12px; font-size: 16px; color: #dc2626;'>{$t['security_title']}</h3>
                        <p style='margin: 0; font-size: 14px; color: #991b1b; line-height: 1.6;'>
                            {$t['security_text']}
                        </p>
                    </div>

                    <h3 style='margin: 30px 0 15px; font-size: 18px; color: #047857;'>{$t['tips_title']}</h3>

                    <div style='margin: 20px 0;'>
                        <div style='display: flex; align-items: flex-start; margin-bottom: 12px;'>
                            <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>✓</div>
                            <div style='color: #374151; font-size: 14px; line-height: 1.6;'>{$t['tip_1']}</div>
                        </div>

                        <div style='display: flex; align-items: flex-start; margin-bottom: 12px;'>
                            <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>✓</div>
                            <div style='color: #374151; font-size: 14px; line-height: 1.6;'>{$t['tip_2']}</div>
                        </div>

                        <div style='display: flex; align-items: flex-start; margin-bottom: 12px;'>
                            <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>✓</div>
                            <div style='color: #374151; font-size: 14px; line-height: 1.6;'>{$t['tip_3']}</div>
                        </div>

                        <div style='display: flex; align-items: flex-start;'>
                            <div style='background: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px; margin-right: 12px; flex-shrink: 0;'>✓</div>
                            <div style='color: #374151; font-size: 14px; line-height: 1.6;'>{$t['tip_4']}</div>
                        </div>
                    </div>

                    <div style='background: #fef3c7; border: 1px solid #fbbf24; border-radius: 8px; padding: 16px; margin: 25px 0;'>
                        <p style='margin: 0 0 8px; font-size: 14px; color: #92400e; font-weight: 600;'>
                            {$t['action_required']}
                        </p>
                        <p style='margin: 0; font-size: 13px; color: #92400e; line-height: 1.6;'>
                            {$t['action_text']}
                        </p>
                    </div>

                    <div style='margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb;'>
                        <p style='margin: 0; color: #047857; font-size: 15px; line-height: 1.6;'>
                            {$t['closing']}
                        </p>
                    </div>
                </td>
            </tr>
        ";

        return $header . $content . $footer;
    }

    /**
     * Générer le template pour notification de liste partagée
     */
    public static function listSharedEmail(string $recipientName, string $sharerName, string $listName, string $sharedAt, bool $canEdit, string $lang = 'fr'): string
    {
        $t = self::getTranslations('list_shared')[$lang] ?? self::getTranslations('list_shared')['fr'];

        // Remplacer les placeholders
        $subject = str_replace('{sharer_name}', $sharerName, $t['subject']);
        $intro = str_replace(['{sharer_name}', '{list_name}'], [$sharerName, $listName], $t['intro']);
        $ctaText = str_replace('{sharer_name}', $sharerName, $t['cta_text']);

        $header = self::headerContent($t['title'], $lang);
        $footer = self::footerContent($lang);

        $permissionText = $canEdit ? $t['permission_edit'] : $t['permission_view'];

        $content = "
            <tr>
                <td class='content' style='padding: 40px 30px;'>
                    <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                        {$t['title']}
                    </h2>

                    <p style='margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['greeting']} <strong>{$recipientName}</strong>,
                    </p>

                    <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$intro}
                    </p>

                    <div style='background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border: 2px solid #10b981; border-radius: 12px; padding: 20px; margin: 25px 0;'>
                        <h3 style='margin: 0 0 16px; font-size: 16px; color: #047857;'>{$t['list_info_title']}</h3>

                        <div style='margin-bottom: 12px;'>
                            <strong style='color: #059669;'>{$t['list_name_label']}</strong>
                            <span style='color: #374151;'>{$listName}</span>
                        </div>

                        <div style='margin-bottom: 12px;'>
                            <strong style='color: #059669;'>{$t['shared_by_label']}</strong>
                            <span style='color: #374151;'>{$sharerName}</span>
                        </div>

                        <div style='margin-bottom: 12px;'>
                            <strong style='color: #059669;'>{$t['shared_at_label']}</strong>
                            <span style='color: #374151;'>{$sharedAt}</span>
                        </div>

                        <div>
                            <strong style='color: #059669;'>{$t['permission_label']}</strong>
                            <span style='color: #374151;'>{$permissionText}</span>
                        </div>
                    </div>

                    <div style='background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%); border: 1px solid #10b981; border-radius: 12px; padding: 24px; margin: 25px 0; text-align: center;'>
                        <h3 style='margin: 0 0 16px; font-size: 18px; color: #047857;'>{$t['cta_title']}</h3>
                        <p style='margin: 0; font-size: 14px; color: #059669;'>
                            {$ctaText}
                        </p>
                    </div>

                    <h3 style='margin: 30px 0 15px; font-size: 18px; color: #047857;'>{$t['features_title']}</h3>

                    <div style='margin: 20px 0;'>
                        <div style='display: flex; align-items: flex-start; margin-bottom: 12px;'>
                            <span style='margin-right: 8px; font-size: 18px;'>🔄</span>
                            <div style='color: #374151; font-size: 14px; line-height: 1.6;'>{$t['feature_1']}</div>
                        </div>

                        <div style='display: flex; align-items: flex-start; margin-bottom: 12px;'>
                            <span style='margin-right: 8px; font-size: 18px;'>✅</span>
                            <div style='color: #374151; font-size: 14px; line-height: 1.6;'>{$t['feature_2']}</div>
                        </div>

                        <div style='display: flex; align-items: flex-start; margin-bottom: 12px;'>
                            <span style='margin-right: 8px; font-size: 18px;'>💰</span>
                            <div style='color: #374151; font-size: 14px; line-height: 1.6;'>{$t['feature_3']}</div>
                        </div>

                        <div style='display: flex; align-items: flex-start;'>
                            <span style='margin-right: 8px; font-size: 18px;'>💬</span>
                            <div style='color: #374151; font-size: 14px; line-height: 1.6;'>{$t['feature_4']}</div>
                        </div>
                    </div>

                    <div style='margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb;'>
                        <p style='margin: 0; color: #047857; font-size: 15px; line-height: 1.6;'>
                            {$t['closing']}
                        </p>
                    </div>
                </td>
            </tr>
        ";

        return $header . $content . $footer;
    }

    /**
     * Générer le template pour notification de liste complétée
     */
    public static function listCompletedEmail(string $recipientName, string $listName, string $completedBy, int $totalItems, string $totalAmount, int $sharedWithCount, string $lang = 'fr'): string
    {
        $t = self::getTranslations('list_completed')[$lang] ?? self::getTranslations('list_completed')['fr'];

        // Remplacer les placeholders
        $subject = str_replace('{list_name}', $listName, $t['subject']);
        $intro = str_replace('{list_name}', $listName, $t['intro']);
        $completedByText = str_replace('{completed_by}', $completedBy, $t['completed_by']);

        $header = self::headerContent($t['title'], $lang);
        $footer = self::footerContent($lang);

        $content = "
            <tr>
                <td class='content' style='padding: 40px 30px;'>
                    <h2 style='margin: 0 0 20px; font-size: 24px; font-weight: 600; color: #047857;'>
                        {$t['title']}
                    </h2>

                    <p style='margin: 0 0 20px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$t['greeting']} <strong>{$recipientName}</strong>,
                    </p>

                    <p style='margin: 0 0 25px; font-size: 16px; color: #374151; line-height: 1.6;'>
                        {$intro}
                    </p>

                    <div style='background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border: 2px solid #10b981; border-radius: 12px; padding: 20px; margin: 25px 0; text-align: center;'>
                        <p style='margin: 0; font-size: 16px; color: #059669; font-weight: 600;'>
                            {$completedByText}
                        </p>
                    </div>

                    <h3 style='margin: 30px 0 15px; font-size: 18px; color: #047857;'>{$t['stats_title']}</h3>

                    <div style='display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin: 20px 0;'>
                        <div style='background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; text-align: center;'>
                            <div style='font-size: 32px; font-weight: bold; color: #047857;'>{$totalItems}</div>
                            <div style='font-size: 12px; color: #6b7280; margin-top: 4px;'>{$t['total_items']}</div>
                        </div>

                        <div style='background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; text-align: center;'>
                            <div style='font-size: 24px; font-weight: bold; color: #047857;'>{$totalAmount}</div>
                            <div style='font-size: 12px; color: #6b7280; margin-top: 4px;'>{$t['total_amount']}</div>
                        </div>

                        <div style='background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; text-align: center;'>
                            <div style='font-size: 32px; font-weight: bold; color: #047857;'>{$sharedWithCount}</div>
                            <div style='font-size: 12px; color: #6b7280; margin-top: 4px;'>{$t['shared_with']}</div>
                        </div>
                    </div>

                    <div style='background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%); border: 1px solid #10b981; border-radius: 12px; padding: 24px; margin: 25px 0; text-align: center;'>
                        <h3 style='margin: 0 0 16px; font-size: 18px; color: #047857;'>{$t['cta_title']}</h3>
                        <p style='margin: 0; font-size: 14px; color: #059669;'>
                            {$t['cta_text']}
                        </p>
                    </div>

                    <div style='margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb;'>
                        <p style='margin: 0; color: #047857; font-size: 15px; line-height: 1.6;'>
                            {$t['closing']}
                        </p>
                    </div>
                </td>
            </tr>
        ";

        return $header . $content . $footer;
    }

    /**
     * Obtenir le sujet d'un email selon la langue
     */
    public static function getSubject(string $template, string $lang = 'fr'): string
    {
        $translations = self::getTranslations($template);
        return $translations[$lang]['subject'] ?? $translations['fr']['subject'] ?? '';
    }

    /**
     * Générer le header multilingue
     */
    public static function headerContent(string $title, string $lang = 'fr'): string
    {
        $common = self::getCommonTranslations()[$lang] ?? self::getCommonTranslations()['fr'];

        return "
            <!DOCTYPE html>
            <html lang='{$lang}'>
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
                                        <!-- Logo EpiList depuis votre serveur -->
                                        <div style='margin-bottom: 16px;'>
                                            <img src='https://m2atodev.com/api.epilist/public/app_logo.png'
                                                 alt='EpiList Logo'
                                                 style='width: 80px; height: 80px; border-radius: 20px; border: none; display: block; margin: 0 auto;'
                                                 onerror=\"this.style.display='none'; this.nextElementSibling.style.display='inline-block';\">
                                            <!-- Fallback si l'image ne charge pas -->
                                            <div style='display: none; width: 80px; height: 80px; background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%); border-radius: 20px; margin: 0 auto; position: relative;'>
                                                <div style='position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); color: #059669; font-size: 36px;'>🛒</div>
                                            </div>
                                        </div>
                                        <h1 style='margin: 0 0 8px; font-size: 28px; font-weight: bold; color: #047857;'>EpiList</h1>
                                        <p style='margin: 0 0 16px; font-size: 16px; color: #6b7280; font-weight: 500;'>
                                            {$common['tagline']}
                                        </p>
                                        <div style='height: 3px; width: 60px; background: linear-gradient(90deg, #059669, #10b981); margin: 0 auto; border-radius: 2px;'></div>
                                    </td>
                                </tr>
        ";
    }

    /**
     * Générer le footer multilingue
     */
    public static function footerContent(string $lang = 'fr', string $unsubscribeUrl = null): string
    {
        $common = self::getCommonTranslations()[$lang] ?? self::getCommonTranslations()['fr'];
        $currentYear = date('Y');

        // Lien de désabonnement conditionnel
        $unsubscribeSection = '';
        if ($unsubscribeUrl) {
            $unsubscribeText = $lang === 'fr'
                ? "Vous recevez cet email car vous êtes inscrit à EpiList.<br><a href='{$unsubscribeUrl}' style='color: #6b7280; text-decoration: underline;'>Se désabonner des emails marketing</a> | <a href='https://epilist.app' style='color: #6b7280; text-decoration: underline;'>Préférences email</a>"
                : "You are receiving this email because you are registered with EpiList.<br><a href='{$unsubscribeUrl}' style='color: #6b7280; text-decoration: underline;'>Unsubscribe from marketing emails</a> | <a href='https://epilist.app' style='color: #6b7280; text-decoration: underline;'>Email preferences</a>";

            $unsubscribeSection = "
                <!-- Section de désabonnement -->
                <div style='margin-top: 20px; padding: 15px; background: rgba(107, 114, 128, 0.05); border-radius: 8px; border-top: 1px solid #e5e7eb;'>
                    <p style='margin: 0; font-size: 11px; color: #6b7280; text-align: center; line-height: 1.4;'>
                        {$unsubscribeText}
                    </p>
                </div>
            ";
        }

        return "
                                    <tr>
                                        <td class='footer' style='background: linear-gradient(135deg, #1f2937 0%, #374151 100%); color: #ffffff; text-align: center; padding: 40px 30px;'>
                                            <!-- Logo footer -->
                                            <div style='margin-bottom: 20px;'>
                                                <img src='https://m2atodev.com/api.epilist/public/app_logo.png'
                                                    alt='EpiList Logo'
                                                    style='width: 60px; height: 60px; border-radius: 16px; border: none; display: block; margin: 0 auto;'
                                                    onerror=\"this.style.display='none'; this.nextElementSibling.style.display='inline-block';\">
                                                <!-- Fallback si l'image ne charge pas -->
                                                <div style='display: none; width: 60px; height: 60px; background: linear-gradient(135deg, #10b981 0%, #059669 100%); border-radius: 16px; margin: 0 auto; position: relative;'>
                                                    <div style='position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); color: #ffffff; font-size: 24px;'>🛒</div>
                                                </div>
                                            </div>

                                            <h3 style='margin: 0 0 8px; font-size: 18px; font-weight: 600; color: #ffffff;'>EpiList</h3>
                                            <p style='margin: 0 0 25px; font-size: 15px; color: #d1d5db; font-weight: 500;'>
                                                {$common['footer_tagline']}
                                            </p>

                                            <!-- Fonctionnalités clés -->
                                            <div style='margin: 25px 0 30px; text-align: left; max-width: 400px; margin-left: auto; margin-right: auto;'>
                                                <div style='display: flex; align-items: center; margin-bottom: 8px; color: #d1d5db; font-size: 14px;'>
                                                    <span style='margin-right: 8px;'>📝</span>
                                                    <span>{$common['feature_1']}</span>
                                                </div>
                                                <div style='display: flex; align-items: center; margin-bottom: 8px; color: #d1d5db; font-size: 14px;'>
                                                    <span style='margin-right: 8px;'>✅</span>
                                                    <span>{$common['feature_2']}</span>
                                                </div>
                                                <div style='display: flex; align-items: center; margin-bottom: 8px; color: #d1d5db; font-size: 14px;'>
                                                    <span style='margin-right: 8px;'>💰</span>
                                                    <span>{$common['feature_3']}</span>
                                                </div>
                                                <div style='display: flex; align-items: center; color: #d1d5db; font-size: 14px;'>
                                                    <span style='margin-right: 8px;'>👨‍👩‍👧‍👦</span>
                                                    <span>{$common['feature_4']}</span>
                                                </div>
                                            </div>

                                            <!-- Bouton vers le site web -->
                                            <div style='margin: 25px 0; padding: 20px; background: rgba(16, 185, 129, 0.1); border-radius: 12px; border: 1px solid rgba(16, 185, 129, 0.2);'>
                                                <p style='margin: 0 0 12px; font-size: 15px; color: #10b981; font-weight: 600; text-align: center;'>
                                                    ✨ {$common['discover_features']}
                                                </p>
                                                <a href='https://epilist.app'
                                                   style='display: inline-block; background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: #ffffff; padding: 12px 24px; text-decoration: none; font-weight: 600; border-radius: 8px; font-size: 14px;'>
                                                    {$common['visit_website']}
                                                </a>
                                            </div>

                                            <!-- Informations de contact -->
                                            <p style='margin: 20px 0; font-size: 12px; color: #6b7280; line-height: 1.5; text-align: center;'>
                                                © {$currentYear} EpiList - {$common['copyright']}<br>
                                                Nouveau-Brunswick, Canada
                                            </p>

                                            <!-- Une question ou besoin d'aide -->
                                            <div style='margin: 20px 0; padding: 16px; background: rgba(16, 185, 129, 0.08); border-radius: 8px; border: 1px solid rgba(16, 185, 129, 0.15);'>
                                                <p style='margin: 0 0 8px; font-size: 14px; color: #047857; font-weight: 600; text-align: center;'>
                                                    {$common['help_title']}
                                                </p>
                                                <p style='margin: 0; font-size: 13px; color: #059669; text-align: center;'>
                                                    {$common['help_text']}
                                                </p>
                                            </div>

                                            <!-- Message local -->
                                            <div style='margin-top: 20px; padding: 15px; background: rgba(16, 185, 129, 0.05); border-radius: 8px;'>
                                                <p style='margin: 0; font-size: 12px; color: #10b981; font-weight: 500; text-align: center;'>
                                                    {$common['proudly_canadian']}<br>
                                                    <span style='font-size: 11px; color: #6b7280;'>{$common['local_tag']}</span>
                                                </p>
                                            </div>

                                            {$unsubscribeSection}
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
}
