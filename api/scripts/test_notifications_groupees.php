<?php
// scripts/test_notifications_groupees.php — une notification dans la
// langue de celui qui la lit, et aucune notification perdue.
//
// Usage : php scripts/test_notifications_groupees.php
// (Aucun serveur requis : tout se passe dans le service.)
//
// Les deux defauts que ce test defend :
//
//   1. Le corps des notifications de liste etait ecrit en francais, en
//      dur, dans le controleur. Un membre anglophone d'un foyer
//      bilingue recevait tout en francais, alors que l'application et
//      les courriels, eux, sont traduits.
//
//   2. L'anti-spam JETAIT les notifications : une session de courses
//      produit des dizaines de coches, et tout ce qui tombait dans la
//      fenetre de trois minutes disparaissait sans laisser de trace.
//      Les autres membres n'apprenaient jamais que la liste avait
//      bouge. Elles sont maintenant accumulees et resumees.
//
// Aucun envoi reel : les comptes jetables n'ont pas d'appareil, donc
// sendToUser s'arrete avant le service d'envoi.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

\App\Config\Config::load();
\App\Config\Database::connect();

use App\Models\ShoppingList;
use App\Models\User;
use App\Services\NotificationService;
use App\Services\NotificationTexts;
use Illuminate\Database\Capsule\Manager as DB;

$reussis = 0;
$echoues = 0;

function verifie(string $nom, bool $ok, string $detail = ''): void
{
    global $reussis, $echoues;
    if ($ok) {
        $reussis++;
        echo "  OK  $nom\n";
    } else {
        $echoues++;
        echo "  NON $nom" . ($detail !== '' ? " — $detail" : '') . "\n";
    }
}

echo "=== Notifications : langue et regroupement ===\n\n";

// ---------------------------------------------------------------------
// 1. Les textes
// ---------------------------------------------------------------------
echo "Les textes\n";

verifie('un article ajoute, en francais',
    NotificationTexts::rendre('item_added', ['produit' => 'Pain'], 'fr')
        === '« Pain » a été ajouté à la liste');

verifie('le meme, en anglais',
    NotificationTexts::rendre('item_added', ['produit' => 'Bread'], 'en')
        === '“Bread” was added to the list');

verifie('un resume porte le prenom et le nombre',
    NotificationTexts::rendre('group_items_added', ['acteur' => 'Marie', 'nombre' => 4], 'fr')
        === 'Marie a ajouté 4 articles');

verifie('et sa version anglaise',
    NotificationTexts::rendre('group_items_added', ['acteur' => 'Marie', 'nombre' => 4], 'en')
        === 'Marie added 4 items');

verifie('une langue inconnue retombe sur le francais',
    NotificationTexts::rendre('all_purchased', [], 'de')
        === NotificationTexts::rendre('all_purchased', [], 'fr'));

verifie('une cle inconnue rend une chaine vide, sans exception',
    NotificationTexts::rendre('cle_qui_n_existe_pas') === '',
    'une notification ratee ne doit pas faire echouer l ajout d un article');

verifie('et elle se detecte avant la mise en attente',
    NotificationTexts::existe('item_added') && !NotificationTexts::existe('cle_qui_n_existe_pas'));

$sansParametre = NotificationTexts::rendre('item_added', [], 'fr');
verifie('un parametre manquant ne casse pas la phrase',
    str_contains($sansParametre, '{produit}') || $sansParametre !== '',
    'rendu : ' . $sansParametre);

// ---------------------------------------------------------------------
// 2. Le decor : deux membres, deux langues
// ---------------------------------------------------------------------
echo "\nLe decor\n";

$courriels = ['notif-fr@epilist.test', 'notif-en@epilist.test'];

foreach ($courriels as $courriel) {
    DB::table('shopping_lists')->whereIn('user_id', function ($q) use ($courriel) {
        $q->select('id')->from('users')->where('email', $courriel);
    })->delete();
    DB::table('users')->where('email', $courriel)->delete();
}

$idFr = DB::table('users')->insertGetId([
    'first_name' => 'Marie', 'last_name' => 'Essai', 'email' => $courriels[0],
    'password_hash' => null, 'terms_accepted' => 1, 'is_active' => 1,
    'email_verified' => 1, 'role' => 'user', 'currency_id' => 1, 'language' => 'fr',
    'created_at' => date('Y-m-d H:i:s'), 'updated_at' => date('Y-m-d H:i:s'),
]);

$idEn = DB::table('users')->insertGetId([
    'first_name' => 'John', 'last_name' => 'Essai', 'email' => $courriels[1],
    'password_hash' => null, 'terms_accepted' => 1, 'is_active' => 1,
    'email_verified' => 1, 'role' => 'user', 'currency_id' => 1, 'language' => 'en',
    'created_at' => date('Y-m-d H:i:s'), 'updated_at' => date('Y-m-d H:i:s'),
]);

$listeId = DB::table('shopping_lists')->insertGetId([
    'user_id' => $idFr, 'created_by_user_id' => $idFr,
    'name' => 'Liste notifications', 'created_at' => date('Y-m-d H:i:s'),
    'updated_at' => date('Y-m-d H:i:s'),
]);

$marie = User::find($idFr);
$john = User::find($idEn);
$liste = ShoppingList::find($listeId);
$service = new NotificationService();

verifie('les deux comptes et la liste existent',
    $marie !== null && $john !== null && $liste !== null);

// ---------------------------------------------------------------------
// 3. Chacun dans sa langue
// ---------------------------------------------------------------------
echo "\nChacun dans sa langue\n";

verifie('la francophone recoit du francais',
    $service->corpsPour($marie, 'item_added', ['produit' => 'Pain'])
        === '« Pain » a été ajouté à la liste');

verifie('l anglophone recoit de l anglais',
    $service->corpsPour($john, 'item_added', ['produit' => 'Pain'])
        === '“Pain” was added to the list',
    'c etait LE defaut : le corps partait en francais pour tout le monde');

// Un compte sans langue enregistree ne doit pas faire echouer l'envoi.
DB::table('users')->where('id', $idEn)->update(['language' => null]);
$sansLangue = User::find($idEn);
verifie('une langue absente retombe sur le francais',
    $service->corpsPour($sansLangue, 'all_purchased') !== '');
DB::table('users')->where('id', $idEn)->update(['language' => 'en']);

// ---------------------------------------------------------------------
// 4. Le regroupement : rien ne se perd
// ---------------------------------------------------------------------
echo "\nLe regroupement\n";

$fichierEtat = $racine . '/storage/list_update_cooldowns/list_' . $listeId . '.json';
@unlink($fichierEtat);
@unlink($racine . '/storage/list_update_cooldowns/list_' . $listeId . '.lock');

$destinataires = [$idFr, $idEn];

$premier = $service->sendListUpdateNotification($marie, $liste, 'item_added', ['produit' => 'Pain'], $destinataires);
verifie('le premier changement part tout de suite',
    !isset($premier['skipped']), json_encode($premier));

$etatApresPremier = json_decode((string) @file_get_contents($fichierEtat), true);
verifie('la fenetre est ouverte', ($etatApresPremier['derniere_notification'] ?? 0) > 0);

for ($i = 0; $i < 4; $i++) {
    $suivant = $service->sendListUpdateNotification(
        $marie, $liste, 'item_added', ['produit' => "Article $i"], $destinataires
    );
}

verifie('les suivants sont mis de cote, pas jetes',
    ($suivant['skipped'] ?? '') === 'regroupe',
    json_encode($suivant));

$etat = json_decode((string) @file_get_contents($fichierEtat), true);
verifie('quatre changements attendent', count($etat['en_attente'] ?? []) === 4,
    'trouve ' . count($etat['en_attente'] ?? []));

// Avant la fin de la fenetre, le cron ne doit rien envoyer.
verifie('le resume n est pas envoye avant la fin de la fenetre',
    $service->flushListUpdates() === 0);

$etatEncore = json_decode((string) @file_get_contents($fichierEtat), true);
verifie('et les changements attendent toujours', count($etatEncore['en_attente'] ?? []) === 4);

// La fenetre est passee : le cron envoie le resume.
$etatEncore['derniere_notification'] = time() - 200;
file_put_contents($fichierEtat, json_encode($etatEncore));

$envoyes = $service->flushListUpdates();
verifie('le cron envoie un resume une fois la fenetre passee', $envoyes === 1,
    "resumes envoyes : $envoyes");

$etatFinal = json_decode((string) @file_get_contents($fichierEtat), true);
verifie('l attente est videe', ($etatFinal['en_attente'] ?? ['x']) === []);
verifie('un second passage n envoie rien', $service->flushListUpdates() === 0,
    'sinon le meme resume partirait a chaque minute');

// ---------------------------------------------------------------------
// 5. La forme du resume
// ---------------------------------------------------------------------
echo "\nCe que dit le resume\n";

// Meme personne, meme genre de changement : on peut etre precis.
verifie('quatre ajouts par la meme personne',
    NotificationTexts::rendre('group_items_added', ['acteur' => 'Marie', 'nombre' => 4], 'fr')
        === 'Marie a ajouté 4 articles');

// Melange : un compte juste vaut mieux qu'une phrase fausse.
verifie('des changements de genres differents restent generaux',
    str_contains(
        NotificationTexts::rendre('group_changes_actor', ['acteur' => 'Marie', 'nombre' => 7], 'fr'),
        '7 changements'
    ));

verifie('plusieurs personnes : plus de prenom du tout',
    NotificationTexts::rendre('group_changes', ['nombre' => 9], 'fr') === '9 changements sur cette liste');

// ---------------------------------------------------------------------
// 6. L'ancien fichier temoin
// ---------------------------------------------------------------------
echo "\nLa bascule depuis l ancienne version\n";

@unlink($fichierEtat);
$ancien = $racine . '/storage/list_update_cooldowns/list_' . $listeId . '.lock';
touch($ancien);

$apresAncien = $service->sendListUpdateNotification(
    $marie, $liste, 'item_added', ['produit' => 'Lait'], $destinataires
);
verifie('un verrou de l ancienne version est respecte, puis converti',
    ($apresAncien['skipped'] ?? '') === 'regroupe' && !file_exists($ancien),
    'sinon la premiere notification apres mise a jour doublerait');

// ---------------------------------------------------------------------
// Menage
// ---------------------------------------------------------------------
echo "\nMenage\n";
@unlink($fichierEtat);
DB::table('shopping_lists')->where('id', $listeId)->delete();
DB::table('users')->whereIn('id', [$idFr, $idEn])->delete();
echo "  comptes et liste jetables retires\n";

echo "\n=== $reussis reussis, $echoues echoues ===\n";
exit($echoues === 0 ? 0 : 1);
