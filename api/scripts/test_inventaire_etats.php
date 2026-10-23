<?php
// scripts/test_inventaire_etats.php — l'etat d'une provision se DEDUIT.
//
// Une capture montrait « Alerte rupture : il n'y en a plus a la
// maison » juste sous « Quantite restante : 2, pour un seuil de 1 ».
// L'etat venait d'un appui sur une pastille, la quantite d'un
// formulaire, et rien ne les reliait : les deux etaient vrais
// separement et faux ensemble.
//
// Ce fichier verrouille la regle qui les relie. Aucune base de donnees :
// la regle est une fonction pure, et c'est tout l'interet de l'avoir
// sortie du controleur.
//
// Usage : php scripts/test_inventaire_etats.php
declare(strict_types=1);

require dirname(__DIR__) . '/vendor/autoload.php';

use App\Models\HomeInventory;

$echecs = 0;
$total = 0;

/** @param string $attendu at_home | running_low | out */
function verifie(?float $quantite, ?float $seuil, string $manuel, string $attendu, string $pourquoi): void
{
    global $echecs, $total;
    $total++;
    $obtenu = HomeInventory::deduireStatut($quantite, $seuil, $manuel);
    $ok = $obtenu === $attendu;
    if (!$ok) {
        $echecs++;
    }
    printf(
        "%s  %-58s (q=%s, seuil=%s, manuel=%s) -> %s\n",
        $ok ? 'ok  ' : 'ECHEC',
        $pourquoi,
        $quantite === null ? 'null' : (string) $quantite,
        $seuil === null ? 'null' : (string) $seuil,
        $manuel,
        $obtenu
    );
}

echo "Etats d'inventaire deduits de la quantite\n";
echo str_repeat('-', 72) . "\n";

// Le cas de la capture, celui qui a declenche tout ceci.
verifie(2, 1, 'out', 'at_home', 'deux pour un seuil de un : disponible, pas une rupture');

// La rupture est un fait, pas une appreciation.
verifie(0, 1, 'at_home', 'out', 'zero : rupture, meme si on a coche « a la maison »');
verifie(0, null, 'at_home', 'out', 'zero sans seuil : rupture quand meme');
verifie(-1, null, 'at_home', 'out', 'une quantite negative ne devrait pas exister : rupture');

// Le seuil.
verifie(1, 1, 'at_home', 'running_low', 'pile au seuil : stock bas (« atteint ce nombre »)');
verifie(0.5, 1, 'at_home', 'running_low', 'sous le seuil : stock bas');
verifie(1.5, 1, 'out', 'at_home', 'au-dessus du seuil : disponible');
verifie(10, null, 'running_low', 'at_home', 'sans seuil, une quantite positive est disponible');

// Sans quantite, le choix manuel est rendu tel quel : c'est le cas des
// produits suivis au niveau (plein / a moitie / presque vide).
verifie(null, null, 'running_low', 'running_low', 'sans quantite : le choix manuel est garde');
verifie(null, 2, 'out', 'out', 'sans quantite, meme avec un seuil : choix manuel');
verifie(null, null, 'at_home', 'at_home', 'sans quantite : a la maison');

// Une valeur inventee ne doit pas se glisser en base.
verifie(null, null, 'peut-etre', 'at_home', 'un etat inconnu retombe sur « a la maison »');
verifie(null, null, '', 'at_home', 'un etat vide retombe sur « a la maison »');

echo str_repeat('-', 72) . "\n";
printf("%d verifications, %d echec(s).\n", $total, $echecs);
exit($echecs === 0 ? 0 : 1);
