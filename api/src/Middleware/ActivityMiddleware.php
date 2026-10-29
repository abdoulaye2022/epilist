<?php
// src/Middleware/ActivityMiddleware.php — « cette personne a utilise
// l'application aujourd'hui ».
//
// C'est tout ce qu'il enregistre : un identifiant de compte et une
// DATE. Pas d'heure, pas de route appelee, pas d'adresse IP, pas
// d'appareil. De quoi calculer une retention honnete — combien de gens
// reviennent a J1, J7, J30 — sans construire un journal de navigation.
//
// POURQUOI IL FALLAIT CA. Le seul indicateur d'activite existant,
// `user_devices.last_active_at`, n'est ecrit qu'a l'enregistrement d'un
// appareil et au rafraichissement du jeton push : il rate tous ceux qui
// refusent les notifications, ceux dont l'initialisation echoue, et
// tout usage hors ligne. Il sous-estime l'activite, et de combien,
// personne ne peut le dire.
//
// UNE ECRITURE PAR PERSONNE ET PAR JOUR, au plus. Un fichier temoin
// evite d'aller jusqu'a la base a chaque requete : sans lui, une
// session de courses ferait des centaines d'ecritures pour une seule
// ligne utile.
//
// Et il ne fait JAMAIS echouer une requete : si l'enregistrement
// echoue, la requete continue comme si de rien n'etait. Une mesure qui
// casse le produit qu'elle mesure ne vaut rien.

namespace App\Middleware;

use Illuminate\Database\Capsule\Manager as DB;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;

class ActivityMiddleware implements MiddlewareInterface
{
    /** Dossier des temoins « deja vu aujourd'hui ». */
    private const DOSSIER_TEMOINS = 'storage/activity_days';

    public function process(Request $request, RequestHandler $handler): Response
    {
        $userId = (int) ($request->getAttribute('auth_id') ?? 0);

        if ($userId > 0) {
            $this->noterLeJour($userId);
        }

        return $handler->handle($request);
    }

    /**
     * Note le jour, une seule fois.
     *
     * L'ordre compte : on ecrit le temoin APRES la base. L'inverse
     * perdrait la journee entiere si l'insertion echouait.
     */
    private function noterLeJour(int $userId): void
    {
        $jour = date('Y-m-d');
        $temoin = $this->cheminTemoin($userId, $jour);

        if ($temoin !== null && file_exists($temoin)) {
            return;
        }

        try {
            // INSERT IGNORE : la cle primaire (user_id, activity_date)
            // tranche. Deux requetes simultanees au premier appel de la
            // journee ne produisent pas deux lignes, et la seconde ne
            // leve pas.
            DB::connection()->statement(
                'INSERT IGNORE INTO user_activity_days (user_id, activity_date, created_at)
                 VALUES (?, ?, NOW())',
                [$userId, $jour]
            );

            if ($temoin !== null) {
                @touch($temoin);
                $this->nettoyerLesVieuxTemoins();
            }
        } catch (\Throwable $e) {
            // Table absente (migration 019 pas encore jouee), base
            // indisponible : la requete continue. On ne perd qu'une
            // ligne de mesure.
            error_log('[Activity] jour non enregistre : ' . $e->getMessage());
        }
    }

    private function cheminTemoin(int $userId, string $jour): ?string
    {
        $dossier = dirname(__DIR__, 2) . '/' . self::DOSSIER_TEMOINS;

        if (!is_dir($dossier) && !@mkdir($dossier, 0755, true) && !is_dir($dossier)) {
            return null;
        }

        return $dossier . '/' . $userId . '-' . $jour;
    }

    /**
     * Les temoins d'hier ne servent plus a rien.
     *
     * Une fois sur cent : balayer le dossier a chaque requete couterait
     * plus cher que l'ecriture qu'on evite.
     */
    private function nettoyerLesVieuxTemoins(): void
    {
        if (random_int(1, 100) !== 1) {
            return;
        }

        $dossier = dirname(__DIR__, 2) . '/' . self::DOSSIER_TEMOINS;
        $limite = time() - 86400;

        foreach (glob($dossier . '/*') ?: [] as $fichier) {
            if (is_file($fichier) && filemtime($fichier) < $limite) {
                @unlink($fichier);
            }
        }
    }
}
