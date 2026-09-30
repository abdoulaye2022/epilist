<?php
// src/Services/PriceAlertService.php — déclenchement des alertes de
// baisse de prix (§27, Phase 4).
//
// Appelé APRÈS chaque nouvelle observation de prix (article coché avec
// prix, ligne de reçu importée). Jamais bloquant : une erreur ici ne
// doit jamais faire échouer l'achat ou l'import.
//
// Anti-spam (déduplication §27) :
//   - une alerte ne re-notifie pas avant RETRIGGER_HOURS (48 h)…
//   - …SAUF si le nouveau prix est strictement plus bas que le dernier
//     prix notifié (une vraie meilleure affaire mérite une notification).

namespace App\Services;

use App\Models\PriceAlert;
use App\Models\Space;
use App\Models\User;
use Carbon\Carbon;

class PriceAlertService
{
    public const RETRIGGER_HOURS = 48;

    /**
     * Une observation de prix vient d'être enregistrée dans un espace :
     * déclenche les alertes actives correspondantes.
     * $storeId null = magasin inconnu -> seules les alertes « tous
     * magasins » (store_id NULL) sont candidates.
     */
    public static function onObservation(
        ?int $spaceId,
        int $buyerUserId,
        string $productName,
        string $normalizedName,
        float $price,
        ?int $storeId = null,
        ?string $storeName = null
    ): void {
        if ($spaceId === null || $price <= 0 || $normalizedName === '') {
            return;
        }

        try {
            $alerts = PriceAlert::where('space_id', $spaceId)
                ->where('normalized_name', $normalizedName)
                ->where('is_active', true)
                ->where('target_price', '>=', $price)
                ->get();

            foreach ($alerts as $alert) {
                // Alerte liée à un magasin précis : l'observation doit venir
                // de CE magasin (une observation sans magasin ne compte pas).
                if ($alert->store_id !== null && $alert->store_id !== $storeId) {
                    continue;
                }

                // Déduplication : silence 48 h, sauf prix strictement plus bas.
                if ($alert->last_triggered_at !== null) {
                    $recent = Carbon::parse($alert->last_triggered_at)
                        ->gt(Carbon::now()->subHours(self::RETRIGGER_HOURS));
                    $lowerThanLast = $alert->last_notified_price !== null
                        && $price < (float) $alert->last_notified_price - 0.009;
                    if ($recent && !$lowerThanLast) {
                        continue;
                    }
                }

                $alert->update([
                    'last_triggered_at' => Carbon::now(),
                    'last_notified_price' => $price,
                ]);

                self::notify($alert, $price, $storeName);

                SpaceActivityService::log(
                    Space::find($spaceId),
                    $buyerUserId,
                    SpaceActivityService::PRICE_ALERT_TRIGGERED,
                    [
                        'product_name' => $alert->product_name,
                        'price' => round($price, 2),
                        'target_price' => (float) $alert->target_price,
                        'store_name' => $storeName,
                    ]
                );
            }
        } catch (\Throwable $e) {
            error_log('PriceAlertService::onObservation: ' . $e->getMessage());
        }
    }

    /** Push au créateur de l'alerte, dans sa langue. Best-effort. */
    private static function notify(PriceAlert $alert, float $price, ?string $storeName): void
    {
        try {
            $user = User::find($alert->created_by_user_id);
            if (!$user) {
                return;
            }
            $lang = in_array($user->language ?? null, ['fr', 'en']) ? $user->language : 'fr';
            $priceTxt = number_format($price, 2, $lang === 'fr' ? ',' : '.', ' ');
            $targetTxt = number_format((float) $alert->target_price, 2, $lang === 'fr' ? ',' : '.', ' ');

            if ($lang === 'en') {
                $title = "Price spotted: {$alert->product_name}";
                $body = $storeName
                    ? "{$alert->product_name} at \${$priceTxt} ({$storeName}) — at or below your target price (\${$targetTxt})."
                    : "{$alert->product_name} at \${$priceTxt} — at or below your target price (\${$targetTxt}).";
            } else {
                $title = "Prix repéré : {$alert->product_name}";
                $body = $storeName
                    ? "{$alert->product_name} à {$priceTxt} $ ({$storeName}) — sous votre prix cible ({$targetTxt} $)."
                    : "{$alert->product_name} à {$priceTxt} $ — sous votre prix cible ({$targetTxt} $).";
            }

            (new NotificationService())->sendToUser(
                (int) $user->id,
                'price_alert',
                $title,
                $body,
                [
                    'alert_id' => (string) $alert->id,
                    'product_name' => $alert->product_name,
                    'price' => (string) round($price, 2),
                ]
            );
        } catch (\Throwable $e) {
            error_log('PriceAlertService::notify: ' . $e->getMessage());
        }
    }
}
