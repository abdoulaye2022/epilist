<?php
// app/Services/BudgetAlertService.php - VERSION NETTOYÉE

namespace App\Services;

use App\Models\Budget;
use App\Models\User;
use App\Models\UserDevice;
use Carbon\Carbon;

class BudgetAlertService
{
    /**
     *  VÉRIFIER TOUS LES BUDGETS ET ENVOYER DES NOTIFICATIONS PUSH
     */
    public static function checkAndSendAlerts(): void
    {
        $budgets = Budget::active()
            ->current()
            ->with(['user.activeDevices', 'shoppingList'])
            ->get();

        foreach ($budgets as $budget) {
            if ($budget->shouldShowAlert()) {
                self::processAlert($budget);
            }
        }
    }

    /**
     *  TRAITER UNE ALERTE SPÉCIFIQUE
     */
    private static function processAlert(Budget $budget): void
    {
        $user = $budget->user;
        $status = $budget->getAlertStatus();

        $notificationService = new NotificationService();
        $alertType = $budget->isExceeded() ? 'exceeded' : 'warning';
        
        $success = $notificationService->sendBudgetAlert($user, $budget, $alertType);
        
        if ($success) {
            error_log("Budget notification sent successfully for budget {$budget->id}");
        } else {
            error_log("Failed to send budget notification for budget {$budget->id}");
        }
    }

    /**
     *  VÉRIFIER LES ALERTES LORS D'UN ACHAT/FACTURE
     */
    public static function checkPurchaseAlert(Budget $budget, float $purchaseAmount): ?array
    {
        if (!$budget->shouldShowAlert()) {
            return null;
        }

        $user = $budget->user;
        $notificationService = new NotificationService();
        
        // Envoyer notification immédiate
        $alertType = $budget->isExceeded() ? 'exceeded' : 'warning';
        $spentPercentage = round($budget->getSpentPercentage(), 1);
        
        $title = $alertType === 'exceeded' ? ' Budget Dépassé!' : ' Attention Budget';
        $body = $alertType === 'exceeded' 
            ? "Vous avez dépassé le budget \"{$budget->name}\"" 
            : "Vous avez utilisé {$spentPercentage}% du budget \"{$budget->name}\"";
            
        $result = $notificationService->sendToUser(
            $user->id,
            'budget_purchase_alert',
            $title,
            $body,
            [
                'budget_id' => (string) $budget->id,
                'budget_name' => $budget->name,
                'alert_type' => $alertType,
                'purchase_amount' => $purchaseAmount,
                'spent_percentage' => $spentPercentage,
                'action' => 'open_budget_details'
            ],
            $alertType === 'exceeded' ? 'high' : 'normal'
        );

        return [
            'budget_id' => $budget->id,
            'status' => $budget->getAlertStatus(),
            'message' => $budget->getAlertMessage(),
            'notification_sent' => $result['success'],
            'alert_type' => $alertType,
            'devices_notified' => $result['sent_count'] ?? 0
        ];
    }

    /**
     *  OBTENIR LES ALERTES POUR UN UTILISATEUR (POUR API)
     */
    public static function getUserAlerts(int $userId): array
    {
        $budgets = Budget::forUser($userId)
            ->active()
            ->current()
            ->with(['shoppingList'])
            ->get();

        $alerts = [];

        foreach ($budgets as $budget) {
            if ($budget->shouldShowAlert()) {
                $alerts[] = [
                    'id' => "budget_alert_{$budget->id}",
                    'type' => 'budget_alert',
                    'priority' => $budget->isExceeded() ? 'high' : 'medium',
                    'title' => $budget->isExceeded() ? ' Budget Dépassé' : ' Attention Budget',
                    'message' => $budget->getAlertMessage(),
                    'budget_id' => $budget->id,
                    'budget_name' => $budget->name,
                    'list_name' => $budget->shoppingList ? $budget->shoppingList->name : null,
                    'spent_percentage' => round($budget->getSpentPercentage(), 1),
                    'days_remaining' => $budget->getDaysRemaining(),
                    'is_exceeded' => $budget->isExceeded(),
                    'action_button' => [
                        'text' => 'Voir Budget',
                        'action' => 'open_budget_details',
                        'data' => ['budget_id' => $budget->id]
                    ],
                    'created_at' => Carbon::now()->toISOString()
                ];
            }
        }

        return $alerts;
    }

    /**
     *  PROGRAMMATEUR DE TÂCHES CRON
     */
    public static function runScheduledTasks(): void
    {
        $now = Carbon::now();
        
        // Vérification des alertes toutes les heures
        if ($now->minute === 0) {
            self::checkAndSendAlerts();
        }
        
        // Résumé quotidien à 9h du matin
        if ($now->hour === 9 && $now->minute === 0) {
            self::sendDailySummaries();
        }
        
        // Vérification des budgets expirant à 10h du matin
        if ($now->hour === 10 && $now->minute === 0) {
            self::checkExpiringBudgets();
        }
        
        // Nettoyage hebdomadaire le dimanche à 2h du matin
        if ($now->dayOfWeek === 0 && $now->hour === 2 && $now->minute === 0) {
            self::weeklyCleanup();
        }
    }

    /**
     *  RÉSUMÉ QUOTIDIEN POUR LES UTILISATEURS ACTIFS
     */
    private static function sendDailySummaries(): void
    {
        $users = User::active()
            ->whereHas('devices', function($query) {
                $query->active()->canReceiveNotifications();
            })
            ->get();

        $notificationService = new NotificationService();

        foreach ($users as $user) {
            // Récupérer les budgets actifs de l'utilisateur
            $budgets = Budget::forUser($user->id)
                ->active()
                ->current()
                ->get();

            $urgentBudgets = $budgets->filter(function($budget) {
                return $budget->shouldShowAlert();
            });

            if ($urgentBudgets->isNotEmpty()) {
                foreach ($urgentBudgets as $budget) {
                    $notificationService->sendBudgetAlert($user, $budget, 'daily_summary');
                }
            }
        }
    }

    /**
     *  VÉRIFIER LES BUDGETS EXPIRANT DANS 3 JOURS
     */
    private static function checkExpiringBudgets(): void
    {
        $threeDaysFromNow = Carbon::now()->addDays(3)->toDateString();
        
        $expiringBudgets = Budget::active()
            ->whereDate('end_date', $threeDaysFromNow)
            ->with(['user'])
            ->get();

        $notificationService = new NotificationService();

        foreach ($expiringBudgets as $budget) {
            $user = $budget->user;
            
            // Vérifier si l'utilisateur peut recevoir des notifications
            if (!$user->canReceiveNotifications()) {
                continue;
            }

            $daysLeft = $budget->getDaysRemaining();
            $spentPercentage = round($budget->getSpentPercentage(), 1);
            
            $notificationService->sendToUser(
                $user->id,
                'budget_expiring',
                ' Budget se termine bientôt',
                "Le budget \"{$budget->name}\" se termine dans {$daysLeft} jour(s). Vous avez utilisé {$spentPercentage}%",
                [
                    'budget_id' => (string) $budget->id,
                    'budget_name' => $budget->name,
                    'days_remaining' => $daysLeft,
                    'spent_percentage' => $spentPercentage,
                    'action' => 'renew_budget'
                ]
            );
        }
    }

    /**
     *  NETTOYAGE HEBDOMADAIRE
     */
    private static function weeklyCleanup(): void
    {
        // Nettoyer les anciens appareils inactifs
        $cleanedDevices = UserDevice::cleanupInactiveDevices();
        error_log("Weekly cleanup: Removed {$cleanedDevices} inactive devices");
        
        // Marquer les budgets expirés comme inactifs
        $expiredBudgets = Budget::where('end_date', '<', Carbon::now()->subDays(7))
            ->where('is_active', true)
            ->update(['is_active' => false]);
        
        error_log("Weekly cleanup: Deactivated {$expiredBudgets} expired budgets");
    }

    /**
     *  OBTENIR LES STATISTIQUES D'ALERTES
     */
    public static function getAlertStatistics(): array
    {
        $totalActiveBudgets = Budget::active()->current()->count();
        
        $exceededBudgets = Budget::active()
            ->current()
            ->get()
            ->filter(fn($budget) => $budget->isExceeded())
            ->count();
            
        $warningBudgets = Budget::active()
            ->current()
            ->get()
            ->filter(fn($budget) => $budget->isNearLimit() && !$budget->isExceeded())
            ->count();

        $usersWithAlerts = User::whereHas('budgets', function($query) {
            $query->active()
                  ->current()
                  ->whereRaw('
                      (SELECT COALESCE(SUM(lr.total_amount), 0) 
                       FROM list_receipts lr 
                       WHERE lr.list_id = budgets.list_id 
                       AND lr.purchase_date BETWEEN budgets.start_date AND budgets.end_date
                      ) >= budgets.budget_amount * (budgets.alert_threshold / 100)
                  ');
        })->count();

        return [
            'total_active_budgets' => $totalActiveBudgets,
            'exceeded_budgets' => $exceededBudgets,
            'warning_budgets' => $warningBudgets,
            'healthy_budgets' => $totalActiveBudgets - $exceededBudgets - $warningBudgets,
            'users_with_alerts' => $usersWithAlerts,
            'alert_rate' => $totalActiveBudgets > 0 ? 
                round((($exceededBudgets + $warningBudgets) / $totalActiveBudgets) * 100, 1) : 0
        ];
    }

    /**
     *  FORCER L'ENVOI D'UNE ALERTE POUR TESTS
     */
    public static function sendTestAlert(int $userId, int $budgetId): bool
    {
        $user = User::find($userId);
        $budget = Budget::find($budgetId);

        if (!$user || !$budget || $budget->user_id !== $userId) {
            return false;
        }

        $notificationService = new NotificationService();
        return $notificationService->sendBudgetAlert($user, $budget, 'warning');
    }

    /**
     *  OBTENIR LA PROCHAINE ALERTE PROGRAMMÉE POUR UN BUDGET
     */
    public static function getNextScheduledAlert(Budget $budget): ?Carbon
    {
        if (!$budget->isActive()) {
            return null;
        }

        $spentPercentage = $budget->getSpentPercentage();
        
        // Si déjà en alerte, la prochaine vérification est dans l'heure
        if ($spentPercentage >= $budget->alert_threshold) {
            return Carbon::now()->addHour();
        }
        
        // Sinon, estimation basée sur le rythme de dépense
        $daysElapsed = $budget->start_date->diffInDays(Carbon::now());
        $totalDays = $budget->start_date->diffInDays($budget->end_date);
        
        if ($daysElapsed > 0) {
            $dailySpendingRate = $spentPercentage / $daysElapsed;
            $daysToThreshold = ($budget->alert_threshold - $spentPercentage) / $dailySpendingRate;
            
            if ($daysToThreshold > 0 && $daysToThreshold <= 30) {
                return Carbon::now()->addDays(ceil($daysToThreshold));
            }
        }
        
        return null;
    }

    /**
     *  SUGGÉRER DES ACTIONS POUR UN BUDGET EN ALERTE
     */
    public static function suggestActions(Budget $budget): array
    {
        $suggestions = [];
        $spentPercentage = $budget->getSpentPercentage();
        $daysRemaining = $budget->getDaysRemaining();
        
        if ($budget->isExceeded()) {
            $suggestions[] = [
                'action' => 'review_spending',
                'title' => 'Examiner les dépenses récentes',
                'description' => 'Analysez vos achats récents pour identifier des économies possibles'
            ];
            
            $suggestions[] = [
                'action' => 'adjust_budget',
                'title' => 'Ajuster le budget',
                'description' => 'Augmenter le montant du budget si les dépenses sont justifiées'
            ];
        } elseif ($spentPercentage > 90) {
            $suggestions[] = [
                'action' => 'slow_spending',
                'title' => 'Ralentir les dépenses',
                'description' => "Il reste {$daysRemaining} jours - limitez les achats non essentiels"
            ];
        }
        
        if ($daysRemaining <= 3 && $spentPercentage < 70) {
            $suggestions[] = [
                'action' => 'use_remaining',
                'title' => 'Utiliser le budget restant',
                'description' => 'Votre budget se termine bientôt - profitez du montant restant'
            ];
        }
        
        return $suggestions;
    }

    /**
     *  ENVOYER NOTIFICATION IMMÉDIATE LORS D'UN ACHAT
     */
    public static function sendImmediatePurchaseAlert(User $user, Budget $budget, float $purchaseAmount): bool
    {
        if (!$budget->shouldShowAlert()) {
            return false;
        }

        $notificationService = new NotificationService();
        $alertType = $budget->isExceeded() ? 'exceeded' : 'warning';
        
        $title = $alertType === 'exceeded' ? ' Budget Dépassé!' : ' Attention Budget';
        $spentPercentage = round($budget->getSpentPercentage(), 1);
        $currency = $user->getPreferredCurrency();
        
        $body = $alertType === 'exceeded' 
            ? "Achat de {$currency->formatAmount($purchaseAmount)} - Budget \"{$budget->name}\" dépassé!"
            : "Achat de {$currency->formatAmount($purchaseAmount)} - {$spentPercentage}% du budget \"{$budget->name}\" utilisé";

        $result = $notificationService->sendToUser(
            $user->id,
            'purchase_budget_alert',
            $title,
            $body,
            [
                'budget_id' => (string) $budget->id,
                'budget_name' => $budget->name,
                'purchase_amount' => $purchaseAmount,
                'formatted_purchase_amount' => $currency->formatAmount($purchaseAmount),
                'spent_percentage' => $spentPercentage,
                'alert_type' => $alertType,
                'action' => 'open_budget_details'
            ],
            $alertType === 'exceeded' ? 'high' : 'normal'
        );

        return $result['success'];
    }
}