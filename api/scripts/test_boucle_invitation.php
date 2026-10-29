<?php
// scripts/test_boucle_invitation.php — une invitation doit ramener
// quelqu'un, pas se perdre en chemin.
//
// Usage : php scripts/test_boucle_invitation.php [base_url]
// Prerequis : API locale (defaut http://localhost:8001), migration 017.
//
// Ce que ce test defend :
//
//   - un lien de partage ne survit pas au passage par le magasin
//     d'applications. Le CODE court, lui, survit : la personne le lit
//     sur l'ecran et le tape apres l'installation. S'il ne se resout
//     pas, l'invitation est perdue et la boucle est cassee ;
//   - le lien Google Play doit porter le jeton dans « referrer », sinon
//     Android n'a rien a rendre a l'application au premier lancement ;
//   - savoir d'ou vient un compte n'est pas un detail de confort :
//     sans users.signup_source, « combien d'inscriptions cette
//     invitation a-t-elle produites » n'a aucune reponse.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

// Eloquent sert a verifier la generation des codes (SharedList) ; sans
// cette connexion, les modeles n'ont pas de base ou aller.
\App\Config\Config::load();
\App\Config\Database::connect();

$base = $argv[1] ?? 'http://localhost:8001';
$mdp = getenv('INVIT_E2E_PWD') ?: 'Essai1234!';

$invitant = 'invit-hote@epilist.test';
$invite = 'invit-arrivant@epilist.test';

$reussis = 0;
$echoues = 0;

function req(string $methode, string $url, ?array $corps = null, ?string $jeton = null): array
{
    $ch = curl_init($url);
    $entetes = ['Content-Type: application/json', 'Accept: application/json'];
    if ($jeton) {
        $entetes[] = "Authorization: Bearer $jeton";
    }
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $methode,
        CURLOPT_HTTPHEADER => $entetes,
        CURLOPT_TIMEOUT => 25,
    ]);
    if ($corps !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($corps));
    }
    $brut = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return [$code, json_decode((string) $brut, true) ?? []];
}

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

$pdo = new PDO(
    "mysql:host={$_ENV['DB_HOST']};port={$_ENV['DB_PORT']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD'],
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

/** Un compte jetable, cree en base : /auth/register est plafonne. */
function compte(PDO $pdo, string $base, string $courriel, string $mdp, string $prenom): array
{
    nettoie($pdo, $courriel);

    $pdo->prepare(
        "INSERT INTO users (first_name, last_name, email, password_hash, terms_accepted, is_active,
                            email_verified, email_verified_at, role, currency_id, language,
                            created_at, updated_at)
         VALUES (?, 'Essai', ?, ?, 1, 1, 1, NOW(), 'user', 1, 'fr', NOW(), NOW())"
    )->execute([$prenom, $courriel, password_hash($mdp, PASSWORD_BCRYPT)]);

    [$code, $rep] = req('POST', "$base/auth/login", ['email' => $courriel, 'password' => $mdp]);

    if ($code !== 200 || empty($rep['access_token'])) {
        fwrite(STDERR, "Connexion impossible pour $courriel ($code). L'API tourne-t-elle sur $base ?\n");
        exit(1);
    }

    $idQ = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $idQ->execute([$courriel]);

    return [(int) $idQ->fetchColumn(), $rep['access_token']];
}

function nettoie(PDO $pdo, string $courriel): void
{
    $idQ = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $idQ->execute([$courriel]);
    $id = $idQ->fetchColumn();

    if (!$id) {
        return;
    }

    $listes = $pdo->prepare('SELECT id FROM shopping_lists WHERE user_id = ? OR created_by_user_id = ?');
    $listes->execute([$id, $id]);

    foreach ($listes->fetchAll(PDO::FETCH_COLUMN) as $listId) {
        foreach (['list_items', 'budgets', 'shared_list', 'list_messages', 'list_receipts', 'purchase_history'] as $table) {
            $pdo->prepare("DELETE FROM {$table} WHERE list_id = ?")->execute([$listId]);
        }
        $pdo->prepare('DELETE FROM shopping_lists WHERE id = ?')->execute([$listId]);
    }

    $pdo->prepare('DELETE FROM shared_list WHERE owner_id = ? OR shared_with_user_id = ?')->execute([$id, $id]);
    $pdo->prepare('DELETE FROM refresh_tokens WHERE user_id = ?')->execute([$id]);
    $pdo->prepare('DELETE FROM users WHERE id = ?')->execute([$id]);
}

echo "=== Boucle d'invitation ===\n\n";

// Les plafonds anti-robot ne doivent pas faire echouer un test qui
// cree des comptes et tape des codes en rafale.
foreach (glob($racine . '/storage/rate_limits/*') ?: [] as $fichier) {
    if (is_file($fichier)) {
        unlink($fichier);
    }
}

nettoie($pdo, $invite);
[$idInvitant, $jetonInvitant] = compte($pdo, $base, $invitant, $mdp, 'Hote');

echo "Invitant #$idInvitant\n\n";

// ---------------------------------------------------------------------
// 1. Le schema
// ---------------------------------------------------------------------
echo "La migration 017\n";

$colonne = (int) $pdo->query(
    "SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'shared_list' AND column_name = 'invite_code'"
)->fetchColumn();
verifie('shared_list.invite_code existe', $colonne === 1, 'migration 017 non jouee ?');

$unique = (int) $pdo->query(
    "SELECT COUNT(*) FROM information_schema.statistics
      WHERE table_schema = DATABASE() AND table_name = 'shared_list'
        AND index_name = 'uq_shared_list_invite_code'"
)->fetchColumn();
verifie('le code est unique au niveau de la base', $unique === 1,
    'sans index unique, deux partages peuvent porter le meme code');

$provenance = (int) $pdo->query(
    "SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'users'
        AND column_name IN ('signup_source', 'signup_share_id')"
)->fetchColumn();
verifie('users sait d ou vient un compte', $provenance === 2);

// ---------------------------------------------------------------------
// 2. Le lien de partage et son code
// ---------------------------------------------------------------------
echo "\nLe partage\n";

[$c, $r] = req('POST', "$base/shopping-lists", ['name' => 'Liste invitation ' . substr((string) time(), -5)], $jetonInvitant);
$listeId = (int) ($r['data']['id'] ?? $r['id'] ?? 0);
verifie('liste creee', $listeId > 0, "code $c");

if ($listeId === 0) {
    fwrite(STDERR, "\nSans liste, le reste du test ne veut rien dire.\n");
    exit(1);
}

[$c, $r] = req('POST', "$base/shopping-lists/$listeId/share", ['permission' => 'edit'], $jetonInvitant);
$donnees = $r['data'] ?? [];
$jetonPartage = (string) ($donnees['share_token'] ?? '');
$codeInvitation = (string) ($donnees['invite_code'] ?? '');

verifie('le lien de partage est cree', $c === 201 && $jetonPartage !== '', "code $c");
verifie('il porte un code d invitation', strlen($codeInvitation) === 6,
    'code rendu : ' . var_export($codeInvitation, true));

$alphabet = \App\Models\SharedList::ALPHABET_CODE;
$horsAlphabet = array_filter(str_split($codeInvitation), fn ($c) => !str_contains($alphabet, $c));
verifie('le code evite les caracteres ambigus (0 O 1 I L)', $horsAlphabet === [],
    'caracteres fautifs : ' . implode('', $horsAlphabet));

$urlPlay = (string) ($donnees['store_urls']['android'] ?? '');
verifie('le lien Play transporte le jeton dans referrer',
    str_contains($urlPlay, 'referrer=') && str_contains(urldecode($urlPlay), "share_token={$jetonPartage}"),
    $urlPlay);
verifie('et marque la provenance en utm_source',
    str_contains(urldecode($urlPlay), 'utm_source=share'));

$message = (string) ($donnees['share_message'] ?? '');
verifie('le message de partage contient le code', str_contains($message, $codeInvitation),
    'sans lui, la personne n a rien en main apres l installation');

// ---------------------------------------------------------------------
// 3. Ce que la page web peut lire
// ---------------------------------------------------------------------
echo "\nLa page de partage (publique)\n";

[$c, $r] = req('GET', "$base/share/public/$jetonPartage");
verifie('le jeton rend ses informations publiques', $c === 200 && ($r['success'] ?? false), "code $c");
verifie('dont le code a afficher', ($r['data']['invite_code'] ?? '') === $codeInvitation);
verifie('et le prenom de l invitant', ($r['data']['owner_first_name'] ?? '') === 'Hote');

$brut = json_encode($r);
verifie('aucune adresse courriel ne sort', !str_contains($brut, '@epilist.test'),
    'la page est publique : elle ne doit pas rendre de courriel');
verifie('aucun identifiant d utilisateur ne sort', !str_contains($brut, '"owner_id"'));

[$c] = req('GET', "$base/share/public/" . str_repeat('f', 32));
verifie('un jeton inconnu est refuse', $c === 404, "code $c");

// ---------------------------------------------------------------------
// 4. Le code, c'est-a-dire le vrai chemin de retour
// ---------------------------------------------------------------------
echo "\nLa resolution du code\n";

[$c, $r] = req('GET', "$base/share/code/$codeInvitation");
verifie('le code rend son jeton', $c === 200 && ($r['data']['share_token'] ?? '') === $jetonPartage, "code $c");

[$c, $r] = req('GET', "$base/share/code/" . strtolower($codeInvitation));
verifie('en minuscules aussi', $c === 200 && ($r['data']['share_token'] ?? '') === $jetonPartage);

$espace = substr($codeInvitation, 0, 3) . ' - ' . substr($codeInvitation, 3);
[$c, $r] = req('GET', '' . "$base/share/code/" . rawurlencode($espace));
verifie('avec des espaces et un tiret aussi', $c === 200 && ($r['data']['share_token'] ?? '') === $jetonPartage,
    "code $c — une personne recopie ce qu elle voit, pas ce qu on attend");

[$c, $r] = req('GET', "$base/share/code/ZZZZZZ");
verifie('un code inconnu est refuse', $c === 404 && ($r['code'] ?? '') === 'CODE_NOT_FOUND', "code $c");

[$c, $r] = req('GET', "$base/share/code/ABC");
verifie('un code trop court est refuse avant toute recherche', $c === 400, "code $c");

// Expire : meme reponse qu'inexistant, pour ne pas dire ce qui a existe.
$pdo->prepare("UPDATE shared_list SET expires_at = DATE_SUB(NOW(), INTERVAL 1 DAY) WHERE share_token = ?")
    ->execute([$jetonPartage]);

[$cExpire, $rExpire] = req('GET', "$base/share/code/$codeInvitation");
verifie('un code expire est refuse', $cExpire === 404, "code $cExpire");
verifie('et sa reponse est la meme qu un code inconnu',
    ($rExpire['code'] ?? '') === 'CODE_NOT_FOUND',
    'distinguer les deux dirait quels codes ont existe');

$pdo->prepare("UPDATE shared_list SET expires_at = DATE_ADD(NOW(), INTERVAL 30 DAY) WHERE share_token = ?")
    ->execute([$jetonPartage]);

// ---------------------------------------------------------------------
// 5. Le plafond de cadence
// ---------------------------------------------------------------------
echo "\nLa porte publique est gardee\n";

$code429 = 0;
for ($i = 0; $i < 25; $i++) {
    [$c] = req('GET', "$base/share/code/ZZZZZ" . chr(65 + ($i % 20)));
    if ($c === 429) {
        $code429++;
    }
}
verifie('les essais en rafale finissent par etre refuses', $code429 > 0,
    'une porte publique qui repond sans compter finit par etre essayee');

foreach (glob($racine . '/storage/rate_limits/*') ?: [] as $fichier) {
    if (is_file($fichier)) {
        unlink($fichier);
    }
}

// ---------------------------------------------------------------------
// 6. La provenance d'une inscription
// ---------------------------------------------------------------------
echo "\nD ou vient le nouveau compte\n";

[$c, $r] = req('POST', "$base/auth/register", [
    'first_name' => 'Arrivant',
    'last_name' => 'Essai',
    'email' => $invite,
    'password' => $mdp,
    'password_confirmation' => $mdp,
    'terms_accepted' => true,
    'signup_source' => 'invite_code',
    'share_token' => $jetonPartage,
]);
verifie('inscription avec le jeton de partage', in_array($c, [200, 201], true), "code $c");

$ligne = $pdo->query(
    "SELECT signup_source, signup_share_id FROM users WHERE email = " . $pdo->quote($invite)
)->fetch(PDO::FETCH_ASSOC);

$idPartage = (int) $pdo->query(
    "SELECT id FROM shared_list WHERE share_token = " . $pdo->quote($jetonPartage)
)->fetchColumn();

verifie('la source est enregistree', ($ligne['signup_source'] ?? '') === 'invite_code',
    var_export($ligne['signup_source'] ?? null, true));
verifie('et elle pointe sur LE partage qui a amene ce compte',
    (int) ($ligne['signup_share_id'] ?? 0) === $idPartage,
    'attendu ' . $idPartage . ', trouve ' . var_export($ligne['signup_share_id'] ?? null, true));

// Un jeton invente ne doit laisser aucune trace.
$imposteur = 'invit-imposteur@epilist.test';
nettoie($pdo, $imposteur);

[$c] = req('POST', "$base/auth/register", [
    'first_name' => 'Imposteur',
    'last_name' => 'Essai',
    'email' => $imposteur,
    'password' => $mdp,
    'password_confirmation' => $mdp,
    'terms_accepted' => true,
    'signup_source' => 'share_link',
    'share_token' => str_repeat('a', 32),
]);

$ligneImposteur = $pdo->query(
    "SELECT signup_source, signup_share_id FROM users WHERE email = " . $pdo->quote($imposteur)
)->fetch(PDO::FETCH_ASSOC);

verifie('un jeton invente ne cree aucun lien',
    $ligneImposteur !== false && $ligneImposteur['signup_share_id'] === null,
    'sinon les chiffres de la boucle seraient faux');

// Une source inconnue retombe sur « direct » plutot que d'entrer telle quelle.
$bidon = 'invit-source-bidon@epilist.test';
nettoie($pdo, $bidon);

req('POST', "$base/auth/register", [
    'first_name' => 'Bidon',
    'last_name' => 'Essai',
    'email' => $bidon,
    'password' => $mdp,
    'password_confirmation' => $mdp,
    'terms_accepted' => true,
    'signup_source' => '<script>alert(1)</script>',
]);

$sourceBidon = $pdo->query(
    "SELECT signup_source FROM users WHERE email = " . $pdo->quote($bidon)
)->fetchColumn();
verifie('une source inconnue retombe sur « direct »', $sourceBidon === 'direct',
    var_export($sourceBidon, true));

// ---------------------------------------------------------------------
// 7. Les codes ne se repetent pas
// ---------------------------------------------------------------------
echo "\nLes codes\n";

$codes = [];
for ($i = 0; $i < 200; $i++) {
    $codes[] = \App\Models\SharedList::genererCodeInvitation();
}
verifie('200 codes tires, 200 codes differents', count(array_unique($codes)) === 200);
verifie('tous dans l alphabet, tous de six caracteres',
    count(array_filter($codes, fn ($c) => strlen($c) === 6 && strspn($c, $alphabet) === 6)) === 200);

verifie('la normalisation enleve espaces, tirets et casse',
    \App\Models\SharedList::normaliserCode(' a3-fk 7m ') === 'A3FK7M');

// ---------------------------------------------------------------------
// Menage
// ---------------------------------------------------------------------
echo "\nMenage\n";
foreach ([$invite, $imposteur, $bidon, $invitant] as $courriel) {
    nettoie($pdo, $courriel);
}
echo "  comptes jetables retires\n";

echo "\n=== $reussis reussis, $echoues echoues ===\n";
exit($echoues === 0 ? 0 : 1);
