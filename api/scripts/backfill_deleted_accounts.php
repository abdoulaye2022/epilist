<?php
// scripts/backfill_deleted_accounts.php — rattrape les comptes « deja
// supprimes » qui contiennent encore toutes leurs donnees.
//
// Pendant des mois, confirmer la suppression de son compte posait
// is_active = 0 et deleted_at, puis l'API repondait « Compte supprime
// avec succes ». La ligne users restait entiere : courriel, prenom, nom,
// empreinte du mot de passe, listes, recus, photos. Ces comptes-la sont
// encore en base aujourd'hui, et ce script les traite enfin.
//
//   php scripts/backfill_deleted_accounts.php             # constat (defaut)
//   php scripts/backfill_deleted_accounts.php --apply     # agit vraiment
//   php scripts/backfill_deleted_accounts.php --apply --limit=10
//
// Le mode par defaut n'ecrit RIEN. Il montre, compte par compte, ce qui
// serait detruit, transfere ou re-attribue. Rien ne part sans --apply.
//
// Chaque compte passe par AccountDeletionService — le MEME service que
// l'application et le site. Pas de seconde logique de suppression a
// maintenir, donc pas de seconde logique a se tromper.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';

use App\Models\User;
use App\Services\AccountDeletionService;
use Illuminate\Database\Capsule\Manager as DB;

\App\Config\Config::load();
\App\Config\Database::connect();

// ---------------------------------------------------------------- args
$appliquer = in_array('--apply', $argv, true);
$limite = 0;
foreach ($argv as $a) {
    if (str_starts_with($a, '--limit=')) {
        $limite = max(0, (int) substr($a, 8));
    }
}

$mode = $appliquer ? 'APPLY' : 'CONSTAT';
echo "=== Rattrapage des comptes supprimes — mode {$mode} ===\n\n";
if (!$appliquer) {
    echo "Rien ne sera modifie. Relancer avec --apply pour agir.\n\n";
}

// La ligne reservee « Utilisateur supprime » doit exister : c'est elle
// qui recueille les messages des comptes supprimes.
try {
    $reserve = User::reserve();
    echo "Utilisateur reserve : #{$reserve->id} ({$reserve->email})\n\n";
} catch (\RuntimeException $e) {
    echo "ARRET : " . $e->getMessage() . "\n";
    exit(1);
}

// -------------------------------------------------------------- cibles
// Deux populations, et la seconde surprend toujours : des comptes qui
// ont DEMANDE leur suppression, recu la reponse « supprime », et dont
// la ligne n'a meme pas de deleted_at parce que l'ecriture portait sur
// des colonnes inexistantes.
$query = User::withTrashed()
    ->whereNull('anonymized_at')
    ->where('email', '<>', User::EMAIL_RESERVE)
    ->where(function ($q) {
        $q->whereNotNull('deleted_at')
          ->orWhere(function ($q2) {
              $q2->where('is_deletion_requested', 1)->whereNotNull('deletion_requested_at');
          });
    })
    ->orderBy('id');

if ($limite > 0) {
    $query->limit($limite);
}

$comptes = $query->get();

if ($comptes->isEmpty()) {
    echo "Aucun compte a rattraper. Tout est en ordre.\n";
    exit(0);
}

echo "{$comptes->count()} compte(s) a rattraper :\n\n";

$totaux = ['listes' => 0, 'recus' => 0, 'messages' => 0, 'traites' => 0, 'echecs' => 0];

foreach ($comptes as $compte) {
    $listes = DB::table('shopping_lists')->where('user_id', $compte->id)->count();
    $recus = DB::table('list_receipts as r')
        ->join('shopping_lists as l', 'l.id', '=', 'r.list_id')
        ->where('l.user_id', $compte->id)->count();
    $messages = DB::table('list_messages')->where('user_id', $compte->id)->count();

    $totaux['listes'] += $listes;
    $totaux['recus'] += $recus;
    $totaux['messages'] += $messages;

    printf(
        "  #%-5d %-34s supprime le %-19s | %d liste(s), %d recu(s), %d message(s)\n",
        $compte->id,
        courrielMasque((string) $compte->email),
        $compte->deleted_at ? (string) $compte->deleted_at : 'jamais (incoherent)',
        $listes,
        $recus,
        $messages
    );

    if (!$appliquer) {
        continue;
    }

    try {
        $rapport = (new AccountDeletionService())->supprimer($compte, 'backfill');
        $totaux['traites']++;

        printf(
            "        -> %d liste(s) detruite(s), %d transferee(s), %d espace(s) transfere(s), " .
            "%d message(s) re-attribue(s), %d image(s) effacee(s)\n",
            $rapport['listes_supprimees'],
            $rapport['listes_transferees'],
            $rapport['espaces_transferes'],
            $rapport['messages_reattribues'],
            $rapport['images_supprimees']
        );

        if ($rapport['images_non_supprimees'] !== []) {
            printf(
                "        -> ATTENTION : %d image(s) non effacee(s) du stockage\n",
                count($rapport['images_non_supprimees'])
            );
        }
    } catch (\Throwable $e) {
        $totaux['echecs']++;
        echo "        -> ECHEC : " . $e->getMessage() . "\n";
    }
}

echo "\n";
echo "Total a traiter : {$comptes->count()} compte(s), {$totaux['listes']} liste(s), ";
echo "{$totaux['recus']} recu(s), {$totaux['messages']} message(s).\n";

if ($appliquer) {
    echo "Traites : {$totaux['traites']}, echecs : {$totaux['echecs']}.\n";
    echo "\nLes lignes anonymisees quitteront la base a la purge des trente jours\n";
    echo "(cron.php, tache 12 — elle aussi en mode constat par defaut).\n";
    exit($totaux['echecs'] > 0 ? 1 : 0);
}

echo "\nRelancer avec --apply pour agir.\n";
exit(0);

/** Un courriel reste identifiant : le journal n'en garde que la forme. */
function courrielMasque(string $email): string
{
    $parties = explode('@', $email, 2);
    $debut = mb_substr($parties[0], 0, 2);
    $domaine = $parties[1] ?? '?';

    return $debut . str_repeat('*', max(1, mb_strlen($parties[0]) - 2)) . '@' . $domaine;
}
