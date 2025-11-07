<?php
// app/Services/UserHabitAnalysisService.php - SERVICE D'ANALYSE DES HABITUDES UTILISATEUR

namespace App\Services;

use App\Models\User;
use App\Models\ShoppingList;
use App\Services\NotificationService;
use Carbon\Carbon;

class UserHabitAnalysisService
{
    protected $notificationService;

    // Types de fréquence
    const FREQUENCY_DAILY = 'daily';
    const FREQUENCY_WEEKLY = 'weekly';
    const FREQUENCY_BIWEEKLY = 'biweekly';
    const FREQUENCY_IRREGULAR = 'irregular';
    const FREQUENCY_INACTIVE = 'inactive';

    // Jours préférés pour les rappels hebdomadaires
    const PREFERRED_DAYS = [
        Carbon::MONDAY => 'lundi',
        Carbon::TUESDAY => 'mardi',
        Carbon::WEDNESDAY => 'mercredi',
        Carbon::THURSDAY => 'jeudi',
        Carbon::FRIDAY => 'vendredi',
        Carbon::SATURDAY => 'samedi',
        Carbon::SUNDAY => 'dimanche'
    ];

    public function __construct()
    {
        $this->notificationService = new NotificationService();
    }

    /**
     * 🎯 ANALYSE PRINCIPALE: Détecter les habitudes de création de listes
     */
    public function analyzeUserHabits(User $user): array
    {
        error_log("📊 Analyzing habits for user {$user->id} ({$user->email})");

        try {
            // Récupérer les listes des 90 derniers jours
            $ninetyDaysAgo = Carbon::now()->subDays(90);
            $lists = ShoppingList::where('user_id', $user->id)
                ->where('created_at', '>=', $ninetyDaysAgo)
                ->orderBy('created_at', 'asc')
                ->get();

            $totalLists = $lists->count();
            error_log("  Found {$totalLists} lists in last 90 days");

            if ($totalLists === 0) {
                return [
                    'user_id' => $user->id,
                    'frequency' => self::FREQUENCY_INACTIVE,
                    'pattern' => 'no_lists',
                    'confidence' => 100,
                    'next_expected_date' => null,
                    'should_notify' => false
                ];
            }

            // Calculer les intervalles entre les listes
            $intervals = $this->calculateIntervals($lists);

            // Détecter la fréquence dominante
            $frequencyAnalysis = $this->detectFrequency($intervals, $totalLists);

            // Détecter le jour préféré (pour weekly/biweekly)
            $preferredDay = $this->detectPreferredDay($lists);

            // Calculer la date attendue de la prochaine liste
            $nextExpectedDate = $this->calculateNextExpectedDate(
                $lists->last(),
                $frequencyAnalysis['frequency'],
                $preferredDay
            );

            // Déterminer si on doit envoyer une notification
            $shouldNotify = $this->shouldSendReminder(
                $lists->last(),
                $nextExpectedDate,
                $frequencyAnalysis['frequency']
            );

            $analysis = [
                'user_id' => $user->id,
                'frequency' => $frequencyAnalysis['frequency'],
                'pattern' => $frequencyAnalysis['pattern'],
                'confidence' => $frequencyAnalysis['confidence'],
                'preferred_day' => $preferredDay,
                'average_interval_days' => $frequencyAnalysis['average_interval'],
                'last_list_date' => $lists->last()->created_at->toDateString(),
                'days_since_last_list' => $lists->last()->created_at->diffInDays(Carbon::now()),
                'next_expected_date' => $nextExpectedDate ? $nextExpectedDate->toDateString() : null,
                'should_notify' => $shouldNotify,
                'total_lists_90d' => $totalLists
            ];

            error_log("  Analysis result: " . json_encode($analysis));

            // Sauvegarder l'analyse
            $this->saveHabitAnalysis($user->id, $analysis);

            return $analysis;

        } catch (\Exception $e) {
            error_log("❌ Error analyzing habits for user {$user->id}: " . $e->getMessage());
            return [
                'user_id' => $user->id,
                'frequency' => self::FREQUENCY_IRREGULAR,
                'pattern' => 'error',
                'confidence' => 0,
                'should_notify' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * 📅 Calculer les intervalles entre les listes
     */
    private function calculateIntervals($lists): array
    {
        $intervals = [];
        $previousDate = null;

        foreach ($lists as $list) {
            if ($previousDate) {
                $daysBetween = $previousDate->diffInDays($list->created_at);
                $intervals[] = $daysBetween;
            }
            $previousDate = $list->created_at;
        }

        error_log("  Intervals: " . json_encode($intervals));
        return $intervals;
    }

    /**
     * 🔍 Détecter la fréquence dominante
     */
    private function detectFrequency(array $intervals, int $totalLists): array
    {
        if (empty($intervals)) {
            return [
                'frequency' => self::FREQUENCY_IRREGULAR,
                'pattern' => 'insufficient_data',
                'confidence' => 0,
                'average_interval' => 0
            ];
        }

        $avgInterval = array_sum($intervals) / count($intervals);
        $stdDev = $this->calculateStandardDeviation($intervals);

        // Calculer la variance (coefficient de variation)
        $variance = $avgInterval > 0 ? ($stdDev / $avgInterval) * 100 : 100;

        error_log("  Avg interval: {$avgInterval} days, StdDev: {$stdDev}, Variance: {$variance}%");

        // Déterminer la fréquence selon l'intervalle moyen
        if ($avgInterval <= 3 && $variance < 50) {
            // Listes quotidiennes ou tous les 2-3 jours
            $frequency = self::FREQUENCY_DAILY;
            $pattern = 'daily_shopper';
            $confidence = 100 - min($variance, 50);
        } elseif ($avgInterval >= 6 && $avgInterval <= 9 && $variance < 40) {
            // Listes hebdomadaires (une fois par semaine)
            $frequency = self::FREQUENCY_WEEKLY;
            $pattern = 'weekly_shopper';
            $confidence = 100 - min($variance, 40);
        } elseif ($avgInterval >= 10 && $avgInterval <= 18 && $variance < 40) {
            // Listes toutes les 2 semaines
            $frequency = self::FREQUENCY_BIWEEKLY;
            $pattern = 'biweekly_shopper';
            $confidence = 100 - min($variance, 40);
        } else {
            // Fréquence irrégulière
            $frequency = self::FREQUENCY_IRREGULAR;
            $pattern = 'irregular_shopper';
            $confidence = max(0, 50 - $variance);
        }

        return [
            'frequency' => $frequency,
            'pattern' => $pattern,
            'confidence' => round($confidence),
            'average_interval' => round($avgInterval, 1)
        ];
    }

    /**
     * 📊 Calculer l'écart-type
     */
    private function calculateStandardDeviation(array $values): float
    {
        if (count($values) < 2) {
            return 0;
        }

        $mean = array_sum($values) / count($values);
        $variance = array_sum(array_map(function($x) use ($mean) {
            return pow($x - $mean, 2);
        }, $values)) / count($values);

        return sqrt($variance);
    }

    /**
     * 📆 Détecter le jour préféré de la semaine
     */
    private function detectPreferredDay($lists): ?int
    {
        $dayCount = array_fill(0, 7, 0); // Lundi = 1, Dimanche = 0

        foreach ($lists as $list) {
            $dayOfWeek = $list->created_at->dayOfWeek;
            $dayCount[$dayOfWeek]++;
        }

        error_log("  Day distribution: " . json_encode($dayCount));

        // Trouver le jour avec le plus de listes
        $maxCount = max($dayCount);

        // Si au moins 30% des listes sont créées le même jour
        if ($maxCount >= count($lists) * 0.3) {
            $preferredDay = array_search($maxCount, $dayCount);
            error_log("  Preferred day: " . self::PREFERRED_DAYS[$preferredDay] . " ({$maxCount} lists)");
            return $preferredDay;
        }

        return null;
    }

    /**
     * 🎯 Calculer la date attendue de la prochaine liste
     */
    private function calculateNextExpectedDate($lastList, string $frequency, ?int $preferredDay): ?Carbon
    {
        if (!$lastList) {
            return null;
        }

        $lastDate = $lastList->created_at;
        $now = Carbon::now();

        switch ($frequency) {
            case self::FREQUENCY_DAILY:
                // Attendre 2-3 jours après la dernière liste
                $nextDate = $lastDate->copy()->addDays(2);
                break;

            case self::FREQUENCY_WEEKLY:
                // Attendre jusqu'au prochain jour préféré
                if ($preferredDay !== null) {
                    $nextDate = $now->copy()->next($preferredDay);

                    // Si le jour préféré de cette semaine est déjà passé, prendre la semaine prochaine
                    if ($nextDate->isBefore($now)) {
                        $nextDate->addWeek();
                    }
                } else {
                    // Par défaut, 7 jours après la dernière liste
                    $nextDate = $lastDate->copy()->addWeek();
                }
                break;

            case self::FREQUENCY_BIWEEKLY:
                // Attendre 2 semaines
                if ($preferredDay !== null) {
                    $nextDate = $now->copy()->next($preferredDay);

                    // Si moins de 2 semaines depuis la dernière liste, prendre le prochain cycle
                    if ($lastDate->diffInDays($nextDate) < 14) {
                        $nextDate->addWeek();
                    }
                } else {
                    $nextDate = $lastDate->copy()->addWeeks(2);
                }
                break;

            default:
                // Pour irregular, on ne peut pas prédire
                return null;
        }

        return $nextDate;
    }

    /**
     * ⏰ Déterminer si on doit envoyer un rappel
     */
    private function shouldSendReminder($lastList, ?Carbon $nextExpectedDate, string $frequency): bool
    {
        if (!$lastList || !$nextExpectedDate) {
            return false;
        }

        $now = Carbon::now();
        $daysSinceLastList = $lastList->created_at->diffInDays($now);
        $daysUntilExpected = $now->diffInDays($nextExpectedDate, false);

        error_log("  Days since last list: {$daysSinceLastList}, Days until expected: {$daysUntilExpected}");

        // Ne jamais envoyer si moins de 24h depuis la dernière liste
        if ($daysSinceLastList < 1) {
            return false;
        }

        switch ($frequency) {
            case self::FREQUENCY_DAILY:
                // Rappel si 2+ jours sans liste
                return $daysSinceLastList >= 2;

            case self::FREQUENCY_WEEKLY:
                // Rappel si on est le jour attendu OU 1 jour après
                return $daysUntilExpected <= 0 && $daysSinceLastList >= 6;

            case self::FREQUENCY_BIWEEKLY:
                // Rappel si on est proche de la date attendue
                return $daysUntilExpected <= 0 && $daysSinceLastList >= 13;

            default:
                // Pour irregular, pas de rappel automatique
                return false;
        }
    }

    /**
     * 💾 Sauvegarder l'analyse des habitudes
     */
    private function saveHabitAnalysis(int $userId, array $analysis): void
    {
        $cacheFile = $this->getStoragePath() . "/user_habit_{$userId}.json";

        try {
            $storageDir = dirname($cacheFile);
            if (!is_dir($storageDir)) {
                mkdir($storageDir, 0755, true);
            }

            $analysis['analyzed_at'] = Carbon::now()->toIso8601String();
            file_put_contents($cacheFile, json_encode($analysis, JSON_PRETTY_PRINT));

            error_log("  Saved habit analysis to {$cacheFile}");

        } catch (\Exception $e) {
            error_log("❌ Error saving habit analysis: " . $e->getMessage());
        }
    }

    /**
     * 📖 Récupérer l'analyse sauvegardée
     */
    public function getStoredHabitAnalysis(int $userId): ?array
    {
        $cacheFile = $this->getStoragePath() . "/user_habit_{$userId}.json";

        if (!file_exists($cacheFile)) {
            return null;
        }

        try {
            $content = file_get_contents($cacheFile);
            $analysis = json_decode($content, true);

            // Vérifier que l'analyse n'est pas trop ancienne (max 7 jours)
            if (isset($analysis['analyzed_at'])) {
                $analyzedAt = Carbon::parse($analysis['analyzed_at']);
                if ($analyzedAt->diffInDays(Carbon::now()) > 7) {
                    return null; // Analyse trop ancienne
                }
            }

            return $analysis;

        } catch (\Exception $e) {
            error_log("❌ Error reading habit analysis: " . $e->getMessage());
            return null;
        }
    }

    /**
     * 📬 Envoyer une notification personnalisée basée sur les habitudes
     */
    public function sendHabitBasedReminder(User $user, array $habitAnalysis): bool
    {
        try {
            $frequency = $habitAnalysis['frequency'];
            $daysSinceLastList = $habitAnalysis['days_since_last_list'];
            $preferredDay = $habitAnalysis['preferred_day'] ?? null;

            // Personnaliser le message selon la fréquence
            switch ($frequency) {
                case self::FREQUENCY_DAILY:
                    $title = "🛒 Votre liste quotidienne";
                    $body = "D'habitude, vous créez une liste tous les 2-3 jours. Cela fait {$daysSinceLastList} jour(s), prêt pour vos courses ?";
                    break;

                case self::FREQUENCY_WEEKLY:
                    $dayName = $preferredDay !== null ? self::PREFERRED_DAYS[$preferredDay] : '';
                    $title = "🛒 Votre liste de la semaine";

                    if ($dayName) {
                        $body = "C'est {$dayName} ! D'habitude, vous créez votre liste ce jour-là. Prêt pour vos courses hebdomadaires ?";
                    } else {
                        $body = "D'habitude, vous créez une liste chaque semaine. Cela fait {$daysSinceLastList} jour(s), c'est le moment !";
                    }
                    break;

                case self::FREQUENCY_BIWEEKLY:
                    $title = "🛒 Votre liste bi-hebdomadaire";
                    $body = "D'habitude, vous faites vos courses toutes les 2 semaines. C'est le moment de créer votre liste !";
                    break;

                default:
                    return false; // Pas de rappel pour les utilisateurs irréguliers
            }

            $data = [
                'reminder_type' => 'habit_based',
                'frequency' => $frequency,
                'days_since_last_list' => (string) $daysSinceLastList,
                'confidence' => (string) $habitAnalysis['confidence'],
                'action' => 'create_new_list'
            ];

            $result = $this->notificationService->sendToUser(
                $user->id,
                NotificationService::TYPE_WEEKLY_LIST_REMINDER,
                $title,
                $body,
                $data,
                'normal'
            );

            return $result['success'];

        } catch (\Exception $e) {
            error_log("❌ Error sending habit-based reminder: " . $e->getMessage());
            return false;
        }
    }

    /**
     * 🔄 Analyser et envoyer des rappels pour tous les utilisateurs actifs
     */
    public function analyzeAndNotifyAllUsers(): array
    {
        error_log("🚀 Starting habit analysis for all active users");

        $results = [
            'analyzed' => 0,
            'notifications_sent' => 0,
            'errors' => []
        ];

        try {
            // Récupérer tous les utilisateurs actifs avec des appareils
            $users = User::where('is_active', true)
                ->whereHas('devices', function($q) {
                    $q->where('is_active', true)->whereNotNull('push_token');
                })
                ->get();

            error_log("  Found {$users->count()} active users to analyze");

            foreach ($users as $user) {
                try {
                    $results['analyzed']++;

                    // Analyser les habitudes
                    $analysis = $this->analyzeUserHabits($user);

                    // Envoyer une notification si nécessaire
                    if ($analysis['should_notify']) {
                        $sent = $this->sendHabitBasedReminder($user, $analysis);

                        if ($sent) {
                            $results['notifications_sent']++;
                            error_log("  ✅ Sent reminder to user {$user->id} ({$analysis['frequency']})");
                        }
                    } else {
                        error_log("  ⏭️  Skipped user {$user->id} - no notification needed");
                    }

                } catch (\Exception $e) {
                    $error = "User {$user->id}: " . $e->getMessage();
                    $results['errors'][] = $error;
                    error_log("  ❌ Error for user {$user->id}: " . $e->getMessage());
                }
            }

            error_log("🏁 Habit analysis completed: " . json_encode($results));

        } catch (\Exception $e) {
            $error = "General error: " . $e->getMessage();
            $results['errors'][] = $error;
            error_log("❌ Critical error in analyzeAndNotifyAllUsers: " . $e->getMessage());
        }

        return $results;
    }

    /**
     * 🧹 Nettoyer les anciennes analyses
     */
    public function cleanupOldAnalyses(): int
    {
        $cleaned = 0;
        $storageDir = $this->getStoragePath();

        if (!is_dir($storageDir)) {
            return 0;
        }

        try {
            $files = glob($storageDir . "/user_habit_*.json");
            $now = time();

            foreach ($files as $file) {
                $lastModified = filemtime($file);

                // Supprimer les fichiers plus anciens que 30 jours
                if (($now - $lastModified) > (30 * 24 * 60 * 60)) {
                    unlink($file);
                    $cleaned++;
                }
            }

        } catch (\Exception $e) {
            error_log("Error cleaning habit analysis files: " . $e->getMessage());
        }

        return $cleaned;
    }

    /**
     * 📁 Obtenir le chemin du dossier storage
     */
    private function getStoragePath(): string
    {
        return dirname(__DIR__, 2) . '/storage';
    }
}
