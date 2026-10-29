<?php
// scripts/test_onboarding_court.php — entrer dans l'application ne
// demande plus d'aller chercher un code dans sa boite de courriel.
//
// Usage : php scripts/test_onboarding_court.php [base_url]
// Prerequis : API locale (defaut http://localhost:8001), migration 018.
//
// CE QUI CHANGE, ET CE QUI NE DOIT PAS CHANGER.
//
// La verification du courriel bloquait la connexion : quatorze gestes
// separaient l'installation de la premiere liste, dont un aller-retour
// dans une boite de courriel. Beaucoup de gens ne revenaient pas.
//
// Elle ne bloque plus l'entree — mais elle doit tenir ailleurs, la ou
// une adresse non prouvee ferait des degats : activer la deuxieme
// etape de connexion, et faire PARTIR un courriel de notre part. Ce
// test verifie les deux moities : la porte ouverte, et les verrous qui
// restent.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

$base = $argv[1] ?? 'http://localhost:8001';
$mdp = getenv('ONBOARD_E2E_PWD') ?: 'Essai1234!';
$nouveau = 'onboard-nouveau@epilist.test';

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

    foreach (['refresh_tokens', 'space_members', 'user_devices'] as $table) {
        $pdo->prepare("DELETE FROM {$table} WHERE user_id = ?")->execute([$id]);
    }
    $pdo->prepare('DELETE FROM spaces WHERE owner_user_id = ?')->execute([$id]);
    $pdo->prepare('DELETE FROM users WHERE id = ?')->execute([$id]);
}

echo "=== Onboarding court ===\n\n";

foreach (glob($racine . '/storage/rate_limits/*') ?: [] as $fichier) {
    if (is_file($fichier)) {
        unlink($fichier);
    }
}

nettoie($pdo, $nouveau);

// ---------------------------------------------------------------------
// 1. Le schema
// ---------------------------------------------------------------------
echo "La migration 018\n";

$colonne = (int) $pdo->query(
    "SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'users'
        AND column_name = 'onboarding_done_at'"
)->fetchColumn();
verifie('users.onboarding_done_at existe', $colonne === 1, 'migration 018 non jouee ?');

$anciens = (int) $pdo->query(
    "SELECT COUNT(*) FROM users
      WHERE onboarding_done_at IS NULL AND created_at < DATE_SUB(NOW(), INTERVAL 1 HOUR)"
)->fetchColumn();
verifie('les comptes d avant sont exemptes du parcours', $anciens === 0,
    "$anciens compte(s) verraient « Creez votre premiere liste » alors qu ils ont deja des listes");

// ---------------------------------------------------------------------
// 2. L'inscription ouvre la porte
// ---------------------------------------------------------------------
echo "\nL inscription\n";

[$c, $r] = req('POST', "$base/auth/register", [
    'first_name' => 'Nouvelle',
    'email' => $nouveau,
    'password' => $mdp,
    'password_confirmation' => $mdp,
    'terms_accepted' => true,
    'language' => 'fr',
]);

verifie('le nom de famille n est plus exige', in_array($c, [200, 201], true),
    "code $c " . json_encode($r['errors'] ?? $r['message'] ?? ''));

$jeton = (string) ($r['access_token'] ?? '');
verifie('l inscription delivre un jeton d acces', $jeton !== '',
    'sans jeton, il faut se connecter — et la connexion etait refusee aux non verifies');
verifie('et un jeton de rafraichissement', ($r['refresh_token'] ?? '') !== '');
verifie('elle annonce la verification en attente',
    ($r['data']['verification_required'] ?? false) === true,
    'l application pose son bandeau de rappel la-dessus');
verifie('le compte n est PAS marque verifie pour autant',
    ($r['data']['email_verified'] ?? true) == false,
    'entrer sans verifier ne doit pas valoir verification');

if ($jeton === '') {
    fwrite(STDERR, "\nSans jeton, la suite du test ne veut rien dire.\n");
    exit(1);
}

// ---------------------------------------------------------------------
// 3. On entre, et on peut travailler
// ---------------------------------------------------------------------
echo "\nLa premiere liste, tout de suite\n";

[$c, $r] = req('POST', "$base/shopping-lists", ['name' => 'Épicerie de la semaine'], $jeton);
$listeId = (int) ($r['data']['id'] ?? $r['id'] ?? 0);
verifie('un compte non verifie peut creer sa liste', $listeId > 0, "code $c");

[$c] = req('POST', "$base/shopping-lists/$listeId/items", ['product_name' => 'Pain', 'quantity' => 1], $jeton);
verifie('et y ajouter un article', in_array($c, [200, 201], true), "code $c");

// ---------------------------------------------------------------------
// 4. La connexion ne refuse plus
// ---------------------------------------------------------------------
echo "\nLa connexion\n";

[$c, $r] = req('POST', "$base/auth/login", ['email' => $nouveau, 'password' => $mdp]);
verifie('un compte non verifie peut se connecter', $c === 200 && ($r['access_token'] ?? '') !== '',
    "code $c " . ($r['code'] ?? ''));
verifie('la reponse rappelle que la verification reste a faire',
    ($r['data']['verification_required'] ?? false) === true);

// ---------------------------------------------------------------------
// 5. Ce qui reste verrouille
// ---------------------------------------------------------------------
echo "\nCe qui reste verrouille sans verification\n";

[$c, $r] = req('POST', "$base/auth/2fa", ['enabled' => true, 'password' => $mdp], $jeton);
verifie('activer la deuxieme etape est refuse',
    $c === 403 && ($r['code'] ?? '') === 'EMAIL_NOT_VERIFIED',
    "code $c " . ($r['code'] ?? '') . " — l activer sur une adresse fausse enferme dehors");

[$c, $r] = req('POST', "$base/spaces", ['name' => 'Foyer essai', 'type' => 'household'], $jeton);
$espaceId = (int) ($r['data']['space']['id'] ?? $r['data']['id'] ?? 0);

if ($espaceId > 0) {
    [$c, $r] = req('POST', "$base/spaces/$espaceId/invitations", [
        'email' => 'quelqu-un@example.com',
        'role' => 'member',
    ], $jeton);
    verifie('inviter quelqu un par courriel est refuse',
        $c === 403 && ($r['code'] ?? '') === 'EMAIL_NOT_VERIFIED',
        "code $c " . ($r['code'] ?? '') . " — sinon le service devient un relais d envoi");
} else {
    verifie('inviter quelqu un par courriel est refuse', false,
        "espace non cree (code $c), verrou non verifie");
}

// ---------------------------------------------------------------------
// 6. Une fois le courriel verifie, tout s ouvre
// ---------------------------------------------------------------------
echo "\nUne fois verifie\n";

$pdo->prepare('UPDATE users SET email_verified = 1, email_verified_at = NOW() WHERE email = ?')
    ->execute([$nouveau]);

[$c, $r] = req('POST', "$base/auth/2fa", ['enabled' => true, 'password' => $mdp], $jeton);
verifie('la deuxieme etape s active', $c === 200 && ($r['success'] ?? false), "code $c");

// Et elle se desactive meme si le courriel redevenait non verifie :
// le verrou ne doit jamais enfermer quelqu un dehors.
$pdo->prepare('UPDATE users SET email_verified = 0, email_verified_at = NULL WHERE email = ?')
    ->execute([$nouveau]);

[$c, $r] = req('POST', "$base/auth/2fa", ['enabled' => false, 'password' => $mdp], $jeton);
verifie('et elle se desactive toujours, verifie ou non', $c === 200 && ($r['success'] ?? false),
    "code $c — un verrou qui empeche de revenir en arriere est un piege");

$pdo->prepare('UPDATE users SET email_verified = 1, email_verified_at = NOW() WHERE email = ?')
    ->execute([$nouveau]);

// ---------------------------------------------------------------------
// 7. Le parcours de depart, une seule fois
// ---------------------------------------------------------------------
echo "\nLe parcours de depart\n";

[$c, $r] = req('GET', "$base/auth/me", null, $jeton);
$donnees = $r['data'] ?? $r['user'] ?? [];
verifie('un compte neuf ne l a pas encore vu',
    ($donnees['onboarding_done'] ?? true) === false,
    json_encode($donnees['onboarding_done'] ?? null));

[$c, $r] = req('POST', "$base/user/onboarding-complete", [], $jeton);
verifie('le marquer comme vu fonctionne', $c === 200 && ($r['success'] ?? false), "code $c");

$date = $pdo->query(
    "SELECT onboarding_done_at FROM users WHERE email = " . $pdo->quote($nouveau)
)->fetchColumn();
verifie('la date est posee en base', $date !== null && $date !== false);

[$c, $r] = req('POST', "$base/user/onboarding-complete", [], $jeton);
$dateApres = $pdo->query(
    "SELECT onboarding_done_at FROM users WHERE email = " . $pdo->quote($nouveau)
)->fetchColumn();
verifie('un second appel ne change pas la date', $c === 200 && $dateApres === $date,
    'la premiere date est la bonne : c est elle qui mesure l effet du parcours');

[$c, $r] = req('GET', "$base/auth/me", null, $jeton);
$donnees = $r['data'] ?? $r['user'] ?? [];
verifie('et le compte ne le reverra pas', ($donnees['onboarding_done'] ?? false) === true);

// ---------------------------------------------------------------------
// 8. Le profil sans nom de famille
// ---------------------------------------------------------------------
echo "\nLe profil\n";

[$c, $r] = req('PUT', "$base/auth/me", ['first_name' => 'Nouvelle'], $jeton);
if ($c === 404 || $c === 405) {
    [$c, $r] = req('POST', "$base/auth/me", ['first_name' => 'Nouvelle'], $jeton);
}
verifie('le profil s enregistre sans nom de famille', in_array($c, [200, 201], true),
    "code $c " . json_encode($r['errors'] ?? $r['message'] ?? ''));

// ---------------------------------------------------------------------
// Menage
// ---------------------------------------------------------------------
echo "\nMenage\n";
nettoie($pdo, $nouveau);
echo "  compte jetable retire\n";

echo "\n=== $reussis reussis, $echoues echoues ===\n";
exit($echoues === 0 ? 0 : 1);
