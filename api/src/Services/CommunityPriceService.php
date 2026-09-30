<?php
// src/Services/CommunityPriceService.php — communauté de prix
// anonymisée (§33, Phase 6).
//
// RÈGLE ABSOLUE : jamais d'identité. Les agrégats (community_prices)
// ne contiennent aucun user_id ; ils ne sont PUBLIÉS que si les règles
// de qualité sont réunies :
//   - au moins MIN_CONTRIBUTORS utilisateurs DISTINCTS (un petit
//     groupe ré-identifierait son unique contributeur) ;
//   - au moins MIN_OBSERVATIONS observations dans la fenêtre ;
//   - valeurs aberrantes écartées ([médiane/4, médiane x4]) AVANT le
//     calcul des statistiques publiées.
// Les utilisateurs retirés (community_prices_enabled = 0) sont exclus
// à la source, dès le recalcul suivant.
//
// Le recalcul est un REBUILD complet (fenêtre 90 j), déclenché par
// public/community_refresh.php (cron) — jamais pendant une requête
// utilisateur.

namespace App\Services;

use App\Models\Store;
use Carbon\Carbon;
use Illuminate\Database\Capsule\Manager as DB;

class CommunityPriceService
{
    public const WINDOW_DAYS = 90;
    public const MIN_CONTRIBUTORS = 3;
    public const MIN_OBSERVATIONS = 5;
    private const OUTLIER_LOW = 0.25;
    private const OUTLIER_HIGH = 4.0;

    /**
     * Reconstruit tous les agrégats. Retourne des statistiques
     * d'exécution (aucune donnée personnelle).
     */
    public static function refresh(): array
    {
        $since = Carbon::now()->subDays(self::WINDOW_DAYS);

        $rows = DB::connection()->table('purchase_history as ph')
            ->join('users as u', 'u.id', '=', 'ph.user_id')
            ->leftJoin('spaces as sp', 'sp.id', '=', 'ph.space_id')
            ->where('u.community_prices_enabled', 1)
            ->where('ph.purchased_at', '>=', $since)
            ->whereNotNull('ph.price')
            ->where('ph.price', '>', 0)
            ->whereNotNull('ph.store_name')
            ->get([
                'ph.normalized_name', 'ph.product_name', 'ph.store_name',
                'ph.price', 'ph.purchased_at', 'ph.user_id',
                'sp.city', 'sp.country',
            ]);

        // Groupes (produit x magasin x région) — l'identité ne sert
        // qu'à compter les contributeurs distincts, puis disparaît.
        $groups = [];
        foreach ($rows as $r) {
            $storeKey = Store::slugify((string) $r->store_name);
            if ($storeKey === '') {
                continue;
            }
            $region = mb_strtolower(trim((string) ($r->city ?? '')), 'UTF-8');
            $country = strtoupper(substr(trim((string) ($r->country ?? '')), 0, 2));
            $key = $r->normalized_name . '|' . $storeKey . '|' . $region . '|' . $country;

            $groups[$key] ??= [
                'normalized_name' => $r->normalized_name,
                'store_key' => $storeKey,
                'region' => $region,
                'country' => $country,
                'labels' => [],
                'store_labels' => [],
                'obs' => [],
            ];
            $groups[$key]['labels'][$r->product_name] = ($groups[$key]['labels'][$r->product_name] ?? 0) + 1;
            $groups[$key]['store_labels'][$r->store_name] = ($groups[$key]['store_labels'][$r->store_name] ?? 0) + 1;
            $groups[$key]['obs'][] = [
                'price' => (float) $r->price,
                'user' => (int) $r->user_id,
                'at' => Carbon::parse($r->purchased_at),
            ];
        }

        $published = 0;
        $rejected = 0;
        $now = Carbon::now();

        DB::connection()->transaction(function () use ($groups, $now, &$published, &$rejected) {
            DB::connection()->table('community_prices')->delete();

            foreach ($groups as $g) {
                // Filtre des valeurs aberrantes autour de la médiane brute
                $prices = array_column($g['obs'], 'price');
                $median = self::median($prices);
                $kept = array_values(array_filter($g['obs'], fn($o) =>
                    $median <= 0
                    || ($o['price'] >= $median * self::OUTLIER_LOW
                        && $o['price'] <= $median * self::OUTLIER_HIGH)));

                $contributors = count(array_unique(array_column($kept, 'user')));
                if (count($kept) < self::MIN_OBSERVATIONS || $contributors < self::MIN_CONTRIBUTORS) {
                    $rejected++;
                    continue; // règles de qualité §33 : on ne publie pas
                }

                $keptPrices = array_column($kept, 'price');
                arsort($g['labels']);
                arsort($g['store_labels']);
                $lastAt = null;
                foreach ($kept as $o) {
                    if ($lastAt === null || $o['at']->gt($lastAt)) {
                        $lastAt = $o['at'];
                    }
                }

                DB::connection()->table('community_prices')->insert([
                    'normalized_name' => $g['normalized_name'],
                    'product_label' => (string) array_key_first($g['labels']),
                    'store_key' => $g['store_key'],
                    'store_label' => (string) array_key_first($g['store_labels']),
                    'region' => $g['region'],
                    'country' => $g['country'],
                    'observations' => count($kept),
                    'contributors' => $contributors,
                    'min_price' => round(min($keptPrices), 2),
                    'median_price' => round(self::median($keptPrices), 2),
                    'avg_price' => round(array_sum($keptPrices) / count($keptPrices), 2),
                    'last_observed_at' => $lastAt->toDateString(),
                    'computed_at' => $now->toDateTimeString(),
                ]);
                $published++;
            }
        });

        return [
            'source_rows' => count($rows),
            'groups' => count($groups),
            'published' => $published,
            'rejected_quality' => $rejected,
            'window_days' => self::WINDOW_DAYS,
            'min_contributors' => self::MIN_CONTRIBUTORS,
            'min_observations' => self::MIN_OBSERVATIONS,
        ];
    }

    /**
     * Meilleur agrégat communautaire pour un produit (médiane la plus
     * basse), ou null. Prêt à afficher : aucun identifiant.
     */
    public static function bestFor(string $normalizedName): ?array
    {
        $row = DB::connection()->table('community_prices')
            ->where('normalized_name', $normalizedName)
            ->orderBy('median_price')
            ->first();
        return $row === null ? null : self::format($row);
    }

    /** Une ligne d'agrégat, formatée pour l'API (jamais d'identité). */
    public static function format(object $row): array
    {
        $age = (int) floor(Carbon::parse($row->last_observed_at)->diffInDays(Carbon::now()));
        return [
            'product_label' => $row->product_label,
            'store_label' => $row->store_label,
            'region' => $row->region !== '' ? $row->region : null,
            'country' => $row->country !== '' ? $row->country : null,
            'median_price' => (float) $row->median_price,
            'min_price' => (float) $row->min_price,
            'avg_price' => (float) $row->avg_price,
            'observations' => (int) $row->observations,
            'contributors' => (int) $row->contributors,
            'last_observed_at' => $row->last_observed_at,
            'freshness' => match (true) {
                $age <= 14 => 'fresh',
                $age <= 30 => 'acceptable',
                $age <= 90 => 'old',
                default => 'stale',
            },
        ];
    }

    private static function median(array $values): float
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
}
