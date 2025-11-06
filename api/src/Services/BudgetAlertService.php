<?php
// app/Services/BudgetAlertService.php

namespace App\Services;

use App\Models\Budget;
use App\Models\User;
use App\Services\MailSender;
use Carbon\Carbon;

class BudgetAlertService
{
    /**
     * ✅ Vérifier et envoyer les alertes pour tous les budgets
     */
    public static function checkAndSendAlerts(): array
    {
        $results = [
            'checked' => 0,
            'alerts_sent' => 0,
            'errors' => 0,
            'details' => []
        ];

        try {
            // Récupérer tous les budgets actifs
            $budgets = Budget::active()
                ->current()
                ->with(['user', 'shoppingList'])
                ->get();

            $results['checked'] = $budgets->count();
            error_log("🔍 [BudgetAlertService] Checking {$budgets->count()} active budgets...");

            foreach ($budgets as $budget) {
                try {
                    $alertSent = self::checkBudgetAlert($budget);

                    if ($alertSent) {
                        $results['alerts_sent']++;
                        $results['details'][] = [
                            'budget_id' => $budget->id,
                            'budget_name' => $budget->name,
                            'user_id' => $budget->user_id,
                            'alert_type' => $budget->isExceeded() ? 'exceeded' : 'warning',
                            'status' => 'sent'
                        ];
                    }
                } catch (\Exception $e) {
                    $results['errors']++;
                    $results['details'][] = [
                        'budget_id' => $budget->id,
                        'error' => $e->getMessage()
                    ];
                    error_log("❌ [BudgetAlertService] Error for budget {$budget->id}: " . $e->getMessage());
                }
            }

            error_log("✅ [BudgetAlertService] Alerts sent: {$results['alerts_sent']}/{$results['checked']}");

        } catch (\Exception $e) {
            error_log("❌ [BudgetAlertService] Fatal error: " . $e->getMessage());
            $results['fatal_error'] = $e->getMessage();
        }

        return $results;
    }

    /**
     * ✅ Vérifier et envoyer une alerte pour un budget spécifique
     */
    private static function checkBudgetAlert(Budget $budget): bool
    {
        // Vérifier si le budget nécessite une alerte
        if (!$budget->shouldShowAlert()) {
            return false;
        }

        $user = $budget->user;
        if (!$user) {
            return false;
        }

        // Vérifier les préférences email de l'utilisateur
        if (!MailSender::canSendEmail($user->id, 'budget_alert')) {
            error_log("📧 [BudgetAlertService] Budget alert email disabled for user {$user->id}");
            return false;
        }

        // Vérifier si une alerte a déjà été envoyée récemment (éviter spam)
        if (self::wasAlertRecentlySent($budget)) {
            error_log("⏰ [BudgetAlertService] Alert already sent recently for budget {$budget->id}");
            return false;
        }

        // Envoyer l'alerte appropriée
        if ($budget->isExceeded()) {
            return self::sendExceededAlert($budget, $user);
        } elseif ($budget->isNearLimit()) {
            return self::sendWarningAlert($budget, $user);
        }

        return false;
    }

    /**
     * ✅ Envoyer une alerte de dépassement
     */
    private static function sendExceededAlert(Budget $budget, User $user): bool
    {
        $language = $user->preferred_language ?? 'fr';
        $currency = $user->getPreferredCurrency();

        $exceededAmount = $budget->getSpentAmount() - $budget->budget_amount;
        $exceededPercentage = $budget->getSpentPercentage();

        // Préparer les traductions
        $translations = [
            'fr' => [
                'subject' => '🚨 Budget dépassé : ' . $budget->name,
                'title' => 'Budget Dépassé',
                'intro' => 'Votre budget <strong>' . htmlspecialchars($budget->name) . '</strong> a été dépassé.',
                'spent' => 'Dépensé',
                'budget' => 'Budget',
                'exceeded' => 'Dépassement',
                'percentage' => 'Pourcentage',
                'action' => 'Voir le budget',
                'tip' => 'Conseil : Analysez vos dépenses pour identifier les postes à optimiser.'
            ],
            'en' => [
                'subject' => '🚨 Budget Exceeded: ' . $budget->name,
                'title' => 'Budget Exceeded',
                'intro' => 'Your budget <strong>' . htmlspecialchars($budget->name) . '</strong> has been exceeded.',
                'spent' => 'Spent',
                'budget' => 'Budget',
                'exceeded' => 'Exceeded',
                'percentage' => 'Percentage',
                'action' => 'View Budget',
                'tip' => 'Tip: Analyze your spending to identify areas for optimization.'
            ]
        ];

        $t = $translations[$language] ?? $translations['fr'];

        $htmlContent = self::getEmailTemplate($budget, $user, [
            'title' => $t['title'],
            'intro' => $t['intro'],
            'color' => '#dc2626',
            'icon' => '🚨',
            'stats' => [
                ['label' => $t['spent'], 'value' => $currency->formatAmount($budget->getSpentAmount())],
                ['label' => $t['budget'], 'value' => $currency->formatAmount($budget->budget_amount)],
                ['label' => $t['exceeded'], 'value' => $currency->formatAmount($exceededAmount), 'color' => '#dc2626'],
                ['label' => $t['percentage'], 'value' => number_format($exceededPercentage, 1) . '%', 'color' => '#dc2626']
            ],
            'action_text' => $t['action'],
            'tip' => $t['tip'],
            'language' => $language
        ]);

        $sent = MailSender::sendMailWithPreferences(
            $user->id,
            'budget_alert',
            $t['subject'],
            [['email' => $user->email, 'name' => $user->name]],
            $htmlContent
        );

        if ($sent) {
            self::recordAlertSent($budget, 'exceeded');
            error_log("✅ [BudgetAlertService] Exceeded alert sent for budget {$budget->id}");
        }

        return $sent;
    }

    /**
     * ✅ Envoyer une alerte d'avertissement
     */
    private static function sendWarningAlert(Budget $budget, User $user): bool
    {
        $language = $user->preferred_language ?? 'fr';
        $currency = $user->getPreferredCurrency();

        $remainingAmount = $budget->getRemainingAmount();
        $spentPercentage = $budget->getSpentPercentage();

        $translations = [
            'fr' => [
                'subject' => '⚠️ Alerte budget : ' . $budget->name,
                'title' => 'Attention à Votre Budget',
                'intro' => 'Votre budget <strong>' . htmlspecialchars($budget->name) . '</strong> approche de sa limite.',
                'spent' => 'Dépensé',
                'budget' => 'Budget',
                'remaining' => 'Restant',
                'percentage' => 'Pourcentage',
                'action' => 'Voir le budget',
                'tip' => 'Conseil : Surveillez vos dépenses pour rester dans votre budget.'
            ],
            'en' => [
                'subject' => '⚠️ Budget Alert: ' . $budget->name,
                'title' => 'Watch Your Budget',
                'intro' => 'Your budget <strong>' . htmlspecialchars($budget->name) . '</strong> is approaching its limit.',
                'spent' => 'Spent',
                'budget' => 'Budget',
                'remaining' => 'Remaining',
                'percentage' => 'Percentage',
                'action' => 'View Budget',
                'tip' => 'Tip: Monitor your spending to stay within your budget.'
            ]
        ];

        $t = $translations[$language] ?? $translations['fr'];

        $htmlContent = self::getEmailTemplate($budget, $user, [
            'title' => $t['title'],
            'intro' => $t['intro'],
            'color' => '#ea580c',
            'icon' => '⚠️',
            'stats' => [
                ['label' => $t['spent'], 'value' => $currency->formatAmount($budget->getSpentAmount())],
                ['label' => $t['budget'], 'value' => $currency->formatAmount($budget->budget_amount)],
                ['label' => $t['remaining'], 'value' => $currency->formatAmount($remainingAmount), 'color' => '#ea580c'],
                ['label' => $t['percentage'], 'value' => number_format($spentPercentage, 1) . '%', 'color' => '#ea580c']
            ],
            'action_text' => $t['action'],
            'tip' => $t['tip'],
            'language' => $language
        ]);

        $sent = MailSender::sendMailWithPreferences(
            $user->id,
            'budget_alert',
            $t['subject'],
            [['email' => $user->email, 'name' => $user->name]],
            $htmlContent
        );

        if ($sent) {
            self::recordAlertSent($budget, 'warning');
            error_log("✅ [BudgetAlertService] Warning alert sent for budget {$budget->id}");
        }

        return $sent;
    }

    /**
     * ✅ Template HTML pour les emails d'alerte
     */
    private static function getEmailTemplate(Budget $budget, User $user, array $data): string
    {
        $stats_html = '';
        foreach ($data['stats'] as $stat) {
            $color = $stat['color'] ?? '#374151';
            $stats_html .= "
            <tr>
                <td style='padding: 12px 0; border-bottom: 1px solid #e5e7eb;'>
                    <span style='color: #6b7280; font-size: 14px;'>{$stat['label']}</span>
                </td>
                <td style='padding: 12px 0; border-bottom: 1px solid #e5e7eb; text-align: right;'>
                    <strong style='color: {$color}; font-size: 16px;'>{$stat['value']}</strong>
                </td>
            </tr>";
        }

        return "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        </head>
        <body style='margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif; background-color: #f3f4f6;'>
            <table width='100%' cellpadding='0' cellspacing='0' style='background-color: #f3f4f6; padding: 40px 20px;'>
                <tr>
                    <td align='center'>
                        <table width='600' cellpadding='0' cellspacing='0' style='background-color: white; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);'>
                            <tr>
                                <td style='background-color: {$data['color']}; padding: 30px; text-align: center; border-radius: 12px 12px 0 0;'>
                                    <div style='font-size: 48px; margin-bottom: 10px;'>{$data['icon']}</div>
                                    <h1 style='color: white; margin: 0; font-size: 24px; font-weight: 600;'>{$data['title']}</h1>
                                </td>
                            </tr>
                            <tr>
                                <td style='padding: 40px 30px;'>
                                    <p style='color: #374151; font-size: 16px; line-height: 1.6; margin: 0 0 24px 0;'>
                                        {$data['intro']}
                                    </p>
                                    <table width='100%' cellpadding='0' cellspacing='0' style='margin: 24px 0;'>
                                        {$stats_html}
                                    </table>
                                    <div style='background-color: #f0f9ff; border-left: 4px solid #3b82f6; padding: 16px; margin: 24px 0; border-radius: 4px;'>
                                        <p style='color: #1e40af; margin: 0; font-size: 14px;'>
                                            💡 <strong>{$data['tip']}</strong>
                                        </p>
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td style='padding: 30px; background-color: #f9fafb; border-radius: 0 0 12px 12px; text-align: center;'>
                                    <p style='color: #6b7280; font-size: 12px; margin: 0;'>
                                        EpiList - Smart Shopping Budget Management
                                    </p>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </body>
        </html>";
    }

    /**
     * ✅ Vérifier si une alerte a été envoyée récemment (dans les 24h)
     */
    private static function wasAlertRecentlySent(Budget $budget): bool
    {
        return $budget->updated_at &&
               $budget->updated_at->gt(Carbon::now()->subHours(24)) &&
               $budget->isExceeded();
    }

    /**
     * ✅ Enregistrer qu'une alerte a été envoyée
     */
    private static function recordAlertSent(Budget $budget, string $type): void
    {
        error_log("📝 [BudgetAlertService] Alert recorded: budget={$budget->id}, type={$type}");
    }
}
