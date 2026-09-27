<?php
// src/Services/PurchasePredictionService.php
//
// Moteur de prédiction « Il te manque probablement… ».
// Statistiques simples et robustes sur purchase_history, à la volée
// (pas de procédure stockée, pas de trigger, pas de ML) :
//  - intervalles entre achats (dates distinctes) sur 12 mois ;
//  - médiane comme référence, écart des anomalies (> 3x médiane) ;
//  - confiance : none (1 achat) / low (2) / medium (3+) /
//    high (5+ réguliers, coefficient de variation < 0.35) ;
//  - statut : not_needed / soon / likely_needed / overdue, avec un
//    seuil « soon » élargi pour les produits irréguliers ;
//  - priorité des sources (§37 du cahier des charges) :
//    action manuelle récente (inventaire) > achat récent > historique.
//
// Les préférences (désactivé / snooze / fréquence personnalisée) et
// l'inventaire manuel sont appliqués ici, pas dans les contrôleurs.

namespace App\Services;

use App\Models\HomeInventory;
use App\Models\ProductPredictionPref;
use App\Models\PurchaseHistory;
use Carbon\Carbon;

class PurchasePredictionService
{
    /** Fenêtre d'historique analysée. */
    private const WINDOW_MONTHS = 12;

    /** Seuils de confiance (configurables ici, cf. §4). */
    private const MIN_PURCHASES_FOR_PREDICTION = 3;
    private const MIN_PURCHASES_PRELIMINARY = 2;
    private const HIGH_CONFIDENCE_PURCHASES = 5;
    private const HIGH_CONFIDENCE_MAX_CV = 0.35;

    /** Un intervalle > 3x la médiane est une anomalie (vacances…). */
    private const OUTLIER_FACTOR = 3.0;

    public const STATUS_NOT_NEEDED = 'not_needed';
    public const STATUS_SOON = 'soon';
    public const STATUS_LIKELY = 'likely_needed';
    public const STATUS_OVERDUE = 'overdue';

    /**
     * Prédictions pour un utilisateur, triées par urgence.
     *
     * @param bool $includeAll true = aussi les produits not_needed
     *                         (écran « toutes les suggestions »)
     * @return array[] chacune : product_name, normalized_name,
     *   frequency_days, last_purchased_at, days_since_last, status,
     *   confidence (low|medium|high), purchases_count, avg_quantity,
     *   usual_store, inventory_status (si connu), urgency (tri)
     */
    public function getPredictions(int $userId, bool $includeAll = false, int $limit = 50): array
    {
        $since = Carbon::now()->subMonths(self::WINDOW_MONTHS);

        $rows = PurchaseHistory::where('user_id', $userId)
            ->where('purchased_at', '>=', $since)
            ->orderBy('purchased_at')
            ->get(['product_name', 'normalized_name', 'quantity', 'store_name', 'purchased_at']);

        if ($rows->isEmpty()) {
            return [];
        }

        $prefs = ProductPredictionPref::where('user_id', $userId)->get()
            ->keyBy('normalized_name');
        $inventory = HomeInventory::where('user_id', $userId)->get()
            ->keyBy('normalized_name');

        $now = Carbon::now();
        $predictions = [];

        foreach ($rows->groupBy('normalized_name') as $normalized => $group) {
            $pref = $prefs->get($normalized);
            if ($pref !== null && !$pref->enabled) {
                continue; // « Ne plus suggérer ce produit »
            }
            if ($pref !== null && $pref->snoozed_until !== null &&
                $pref->snoozed_until->isFuture()) {
                continue; // « Pas maintenant » / « J'en ai encore »
            }

            $stats = $this->computeStats($group, $now);
            if ($stats === null) {
                continue; // un seul achat : pas de prédiction (§4)
            }

            $frequency = $pref?->custom_frequency_days ?: $stats['frequency_days'];
            if ($frequency < 1) {
                continue;
            }

            $daysSince = $stats['days_since_last'];
            $inv = $inventory->get($normalized);

            // Priorité des sources (§37) : un état manuel récent domine.
            $manualFresh = $inv !== null && $inv->source === 'manual' &&
                $inv->updated_at !== null &&
                $inv->updated_at->diffInDays($now) < max(2, $frequency * 0.6);

            if ($manualFresh && $inv->status === HomeInventory::STATUS_AT_HOME) {
                $status = self::STATUS_NOT_NEEDED;
            } elseif ($manualFresh && $inv->status === HomeInventory::STATUS_OUT) {
                $status = self::STATUS_OVERDUE;
            } elseif ($manualFresh && $inv->status === HomeInventory::STATUS_RUNNING_LOW) {
                $status = self::STATUS_SOON;
            } else {
                $status = $this->statusFor($daysSince, $frequency, $stats['cv']);
            }

            if (!$includeAll && $status === self::STATUS_NOT_NEEDED) {
                continue;
            }

            $predictions[] = [
                'product_name' => $group->last()->product_name,
                'normalized_name' => $normalized,
                'frequency_days' => (int) round($frequency),
                'last_purchased_at' => $stats['last_purchased_at']->toDateString(),
                'days_since_last' => $daysSince,
                'status' => $status,
                'confidence' => $stats['confidence'],
                'purchases_count' => $stats['purchases_count'],
                'avg_quantity' => $stats['avg_quantity'],
                'usual_store' => $stats['usual_store'],
                'inventory_status' => $inv?->status,
                'urgency' => $frequency > 0 ? round($daysSince / $frequency, 3) : 0,
            ];
        }

        // Urgence décroissante ; confiance haute d'abord à urgence égale
        usort($predictions, function ($a, $b) {
            if ($a['urgency'] !== $b['urgency']) {
                return $b['urgency'] <=> $a['urgency'];
            }
            $rank = ['high' => 0, 'medium' => 1, 'low' => 2];
            return ($rank[$a['confidence']] ?? 3) <=> ($rank[$b['confidence']] ?? 3);
        });

        return array_slice($predictions, 0, $limit);
    }

    /**
     * Statistiques d'un produit : fréquence robuste + confiance.
     * Retourne null si moins de 2 achats à des dates distinctes.
     */
    private function computeStats($purchases, Carbon $now): ?array
    {
        // Dates d'achat distinctes (2 lignes le même jour = 1 achat)
        $dates = [];
        $quantities = [];
        $stores = [];
        foreach ($purchases as $p) {
            $d = Carbon::parse($p->purchased_at)->startOfDay();
            $dates[$d->toDateString()] = $d;
            $quantities[] = (float) ($p->quantity ?: 1);
            if ($p->store_name) {
                $stores[$p->store_name] = ($stores[$p->store_name] ?? 0) + 1;
            }
        }
        $dates = array_values($dates);
        if (count($dates) < self::MIN_PURCHASES_PRELIMINARY) {
            return null;
        }

        $intervals = [];
        for ($i = 1; $i < count($dates); $i++) {
            $intervals[] = $dates[$i - 1]->diffInDays($dates[$i]);
        }

        // Référence : médiane, puis écart des anomalies (> 3x médiane).
        // Une absence de 40 jours ne casse pas un cycle hebdomadaire (§5).
        $median = $this->median($intervals);
        $kept = array_values(array_filter(
            $intervals,
            fn($i) => $median <= 0 || $i <= $median * self::OUTLIER_FACTOR
        ));
        if ($kept === []) {
            $kept = $intervals;
        }
        $mean = array_sum($kept) / count($kept);
        $cv = $mean > 0 ? $this->stdDev($kept) / $mean : 1.0;

        $count = count($dates);
        if ($count >= self::HIGH_CONFIDENCE_PURCHASES && $cv < self::HIGH_CONFIDENCE_MAX_CV) {
            $confidence = 'high';
        } elseif ($count >= self::MIN_PURCHASES_FOR_PREDICTION) {
            $confidence = 'medium';
        } else {
            $confidence = 'low';
        }

        arsort($stores);
        $last = end($dates);

        return [
            'frequency_days' => $mean,
            'cv' => $cv,
            'confidence' => $confidence,
            'purchases_count' => $count,
            'last_purchased_at' => $last,
            'days_since_last' => (int) floor($last->diffInDays($now)),
            'avg_quantity' => round(array_sum($quantities) / count($quantities), 1),
            'usual_store' => $stores === [] ? null : array_key_first($stores),
        ];
    }

    /**
     * Statut selon le ratio jours écoulés / fréquence. La fenêtre « soon »
     * s'élargit pour les produits irréguliers (cv élevé) : on prévient
     * plus tôt quand le cycle est flou (§6).
     */
    private function statusFor(int $daysSince, float $frequency, float $cv): string
    {
        $ratio = $daysSince / $frequency;
        $soonStart = 1.0 - min(0.35, max(0.15, $cv * 0.5));

        if ($ratio < $soonStart) {
            return self::STATUS_NOT_NEEDED;
        }
        if ($ratio < 1.0) {
            return self::STATUS_SOON;
        }
        if ($ratio <= 1.25) {
            return self::STATUS_LIKELY;
        }
        return self::STATUS_OVERDUE;
    }

    /**
     * Enregistre le feedback utilisateur et adapte le comportement (§8, §38).
     * Actions : added | not_now | still_have | never.
     */
    public function recordFeedback(int $userId, string $productName, string $action): void
    {
        $normalized = PurchaseHistory::normalizeProductName($productName);

        // Snooze proportionnel au cycle du produit pour éviter les
        // boucles absurdes (re-suggérer 5 minutes après « J'en ai encore »)
        $frequency = null;
        foreach ($this->getPredictions($userId, true, 200) as $p) {
            if ($p['normalized_name'] === $normalized) {
                $frequency = $p['frequency_days'];
                break;
            }
        }

        $values = ['last_feedback' => $action, 'product_name' => $productName];
        switch ($action) {
            case 'never':
                $values['enabled'] = 0;
                break;
            case 'still_have':
                $days = max(3, (int) round(($frequency ?? 7) * 0.4));
                $values['snoozed_until'] = Carbon::now()->addDays($days);
                break;
            case 'not_now':
            case 'added':
                $values['snoozed_until'] = Carbon::now()->addDays(2);
                break;
        }

        ProductPredictionPref::updateOrCreate(
            ['user_id' => $userId, 'normalized_name' => $normalized],
            $values
        );

        // « J'en ai encore » vaut aussi mise à jour d'inventaire estimée
        if ($action === 'still_have') {
            HomeInventory::updateOrCreate(
                ['user_id' => $userId, 'normalized_name' => $normalized],
                [
                    'product_name' => $productName,
                    'status' => HomeInventory::STATUS_AT_HOME,
                    'source' => 'manual',
                ]
            );
        }
    }

    private function median(array $values): float
    {
        if ($values === []) {
            return 0;
        }
        sort($values);
        $mid = intdiv(count($values), 2);
        return count($values) % 2 === 1
            ? (float) $values[$mid]
            : ($values[$mid - 1] + $values[$mid]) / 2;
    }

    private function stdDev(array $values): float
    {
        $n = count($values);
        if ($n < 2) {
            return 0;
        }
        $mean = array_sum($values) / $n;
        $sum = 0;
        foreach ($values as $v) {
            $sum += ($v - $mean) ** 2;
        }
        return sqrt($sum / ($n - 1));
    }
}
