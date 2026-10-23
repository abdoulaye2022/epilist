<?php
// scripts/test_budget_periodes.php — la periode qui suit.
//
// « Le budget se renouvelle-t-il automatiquement a la fin de la
// periode ? » Oui, quand auto_renew le dit — et c'est alors le cron qui
// cree la periode suivante, sans surveillance. La regle qu'il applique
// se verifie ici : sans trou entre deux periodes, sans chevauchement,
// et une periode personnalisee garde sa duree.
//
// Aucune base de donnees : la regle est une fonction pure.
//
// Usage : php scripts/test_budget_periodes.php
declare(strict_types=1);

require dirname(__DIR__) . '/vendor/autoload.php';

use App\Models\Budget;
use Carbon\Carbon;

$echecs = 0;
$total = 0;

function verifie(string $type, string $debut, string $fin, string $attDebut, string $attFin, string $pourquoi): void
{
    global $echecs, $total;
    $total++;
    [$d, $f] = Budget::prochainePeriode($type, Carbon::parse($debut), Carbon::parse($fin));
    $obtenu = $d->toDateString() . ' -> ' . $f->toDateString();
    $attendu = $attDebut . ' -> ' . $attFin;
    $ok = $obtenu === $attendu;
    if (!$ok) {
        $echecs++;
    }
    printf(
        "%s  %-46s %-10s %s au %s  =>  %s\n",
        $ok ? 'ok  ' : 'ECHEC',
        $pourquoi,
        $type,
        $debut,
        $fin,
        $ok ? $obtenu : "$obtenu (attendu $attendu)"
    );
}

echo "La periode qui suit\n";
echo str_repeat('-', 110) . "\n";

// Le lendemain, toujours : sans trou, sans chevauchement.
verifie('monthly', '2026-10-01', '2026-10-31', '2026-11-01', '2026-11-30', 'un mois civil enchaine sur le suivant');
verifie('monthly', '2026-01-01', '2026-01-31', '2026-02-01', '2026-02-28', 'fevrier compte 28 jours');
verifie('monthly', '2024-01-01', '2024-01-31', '2024-02-01', '2024-02-29', 'une annee bissextile en compte 29');

// Le cycle de paie : la raison d'etre de biweekly.
verifie('biweekly', '2026-10-05', '2026-10-18', '2026-10-19', '2026-11-01', 'aux deux semaines : quatorze jours');
verifie('weekly', '2026-10-05', '2026-10-11', '2026-10-12', '2026-10-18', 'une semaine : sept jours');
verifie('yearly', '2026-01-01', '2026-12-31', '2027-01-01', '2027-12-31', 'une annee');

// Une periode personnalisee garde sa DUREE.
verifie('custom', '2026-10-12', '2026-10-25', '2026-10-26', '2026-11-08', 'du 12 au 25 : quatorze jours de plus');
verifie('custom', '2026-10-01', '2026-10-02', '2026-10-03', '2026-10-04', 'deux jours restent deux jours');

// Un budget d'un seul jour ne doit pas donner une periode vide.
verifie('custom', '2026-10-01', '2026-10-01', '2026-10-02', '2026-10-03', 'un seul jour : la suivante dure au moins un jour');

echo str_repeat('-', 110) . "\n";

// Pas de trou, pas de chevauchement : la propriete qui compte vraiment.
$total++;
$sansTrou = true;
foreach (['weekly', 'biweekly', 'monthly', 'yearly', 'custom'] as $type) {
    $fin = Carbon::parse('2026-03-14');
    [$d] = Budget::prochainePeriode($type, Carbon::parse('2026-03-01'), $fin);
    if ($d->toDateString() !== $fin->copy()->addDay()->toDateString()) {
        $sansTrou = false;
        echo "ECHEC  {$type} : la periode suivante ne commence pas le lendemain\n";
    }
}
if ($sansTrou) {
    echo "ok    toutes les periodes commencent le lendemain de la precedente\n";
} else {
    $echecs++;
}

printf("%d verifications, %d echec(s).\n", $total, $echecs);
exit($echecs === 0 ? 0 : 1);
