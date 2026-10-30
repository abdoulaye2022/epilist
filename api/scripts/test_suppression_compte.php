<?php
// scripts/test_suppression_compte.php — « supprimer mon compte » doit
// supprimer le compte.
//
// Usage : php scripts/test_suppression_compte.php [base_url]
// Prerequis : API locale (defaut http://localhost:8001), migrations 015
//             et 016 jouees.
//
// Ce que ce test defend, et qui etait casse de bout en bout :
//
//   - la route de confirmation attendait « email » + « confirmation_code »
//     quand l'application envoie « deletion_code », et lisait deux
//     colonnes absentes de la base. Elle repondait TOUJOURS 400 :
//     personne ne pouvait supprimer son compte ;
//   - meme si elle avait abouti, elle n'aurait fait qu'un soft delete :
//     courriel, prenom, nom et empreinte du mot de passe restaient ;
//   - le jeton d'acces deja emis restait valable jusqu'a une heure
//     apres la suppression.
//
// Le test cree QUATRE comptes jetables. Les trois autres comptent autant
// que le partant : ce qui est difficile dans une suppression, ce n'est
// pas d'effacer, c'est de ne pas emporter le travail des autres.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

$base = $argv[1] ?? 'http://localhost:8001';
$mdp = getenv('SUPPR_E2E_PWD') ?: 'Essai1234!';

$partant  = 'suppr-partant@epilist.test';
$restant  = 'suppr-restant@epilist.test';
$tiers    = 'suppr-tiers@epilist.test';
$webPart  = 'suppr-web@epilist.test';

$suffixe = substr((string) time(), -5);

$reussis = 0;
$echoues = 0;

function req(string $methode, string $url, ?array $corps = null, ?string $jeton = null, array $entetesSup = []): array
{
    $ch = curl_init($url);
    $entetes = array_merge(['Content-Type: application/json', 'Accept: application/json'], $entetesSup);
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

/**
 * Efface toute trace d'un passage precedent pour ce courriel.
 *
 * Sans cela, la creation d'une liste du meme nom repond 409 et le test
 * echoue sur son propre decor.
 */
function remetAZero(PDO $pdo, string $courriel): void
{
    $pdo->prepare('DELETE FROM account_deletion_requests WHERE email = ?')->execute([$courriel]);

    $idQ = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $idQ->execute([$courriel]);
    $id = $idQ->fetchColumn();

    if (!$id) {
        return;
    }

    $listes = $pdo->prepare('SELECT id FROM shopping_lists WHERE user_id = ? OR created_by_user_id = ?');
    $listes->execute([$id, $id]);

    foreach ($listes->fetchAll(PDO::FETCH_COLUMN) as $listId) {
        foreach (['list_items', 'budgets', 'shared_list', 'list_messages', 'list_receipts'] as $table) {
            $pdo->prepare("DELETE FROM {$table} WHERE list_id = ?")->execute([$listId]);
        }
        $pdo->prepare('DELETE FROM shopping_lists WHERE id = ?')->execute([$listId]);
    }

    foreach (['purchase_history', 'user_devices', 'refresh_tokens', 'shared_list'] as $table) {
        $colonne = $table === 'shared_list' ? 'shared_with_user_id' : 'user_id';
        $pdo->prepare("DELETE FROM {$table} WHERE {$colonne} = ?")->execute([$id]);
    }
}

/** Le corps BRUT : pour verifier qu'un clic direct rend du HTML. */
function reqBrut(string $url, array $entetes = []): array
{
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => $entetes,
        CURLOPT_TIMEOUT => 25,
    ]);
    $brut = (string) curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $type = (string) curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    curl_close($ch);

    return [$code, $brut, $type];
}

/**
 * Un compte jetable, cree directement en base.
 *
 * Pas par /auth/register : le plafond anti-robot est de trois
 * inscriptions par heure et par IP, et ce test a besoin de quatre
 * comptes. L'inscription est testee une fois, la ou c'est le sujet —
 * la reinscription avec l'ancienne adresse.
 */
function compte(PDO $pdo, string $base, string $courriel, string $mdp, string $prenom): array
{
    $pdo->prepare('DELETE FROM users WHERE email = ?')->execute([$courriel]);

    $pdo->prepare(
        "INSERT INTO users (first_name, last_name, email, password_hash, terms_accepted, is_active,
                            email_verified, email_verified_at, role, currency_id, language,
                            created_at, updated_at)
         VALUES (?, 'Essai', ?, ?, 1, 1, 1, ?, 'user', 1, 'fr', ?, ?)"
    )->execute([
        $prenom,
        $courriel,
        password_hash($mdp, PASSWORD_BCRYPT),
        date('Y-m-d H:i:s'),
        date('Y-m-d H:i:s'),
        date('Y-m-d H:i:s'),
    ]);

    [$code, $rep] = req('POST', "$base/auth/login", ['email' => $courriel, 'password' => $mdp]);

    if ($code !== 200 || empty($rep['access_token'])) {
        fwrite(STDERR, "Connexion impossible pour $courriel ($code). L'API tourne-t-elle sur $base ?\n");
        exit(1);
    }

    $idQ = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $idQ->execute([$courriel]);

    return [(int) $idQ->fetchColumn(), $rep['access_token']];
}

echo "=== Suppression de compte ===\n\n";

// Les plafonds de cadence sont faits pour les robots, pas pour un test
// qui cree quatre comptes d'affilee depuis la meme IP (la limite est de
// trois inscriptions par heure). On repart d'une ardoise propre.
foreach (glob($racine . '/storage/rate_limits/*') ?: [] as $fichier) {
    if (is_file($fichier)) {
        unlink($fichier);
    }
}

// Les comptes « deleted_user_* » d'un passage precedent genent les
// comptages : on les sort du chemin.
$pdo->exec("DELETE FROM users WHERE email LIKE 'deleted_user_%@deleted.local' AND first_name = 'Utilisateur'");

foreach ([$partant, $restant, $tiers, $webPart] as $c) {
    remetAZero($pdo, $c);
}

[$idPartant, $jetonPartant] = compte($pdo, $base, $partant, $mdp, 'Partant');
[$idRestant, $jetonRestant] = compte($pdo, $base, $restant, $mdp, 'Restant');
[$idTiers, $jetonTiers] = compte($pdo, $base, $tiers, $mdp, 'Tiers');
[$idWeb, $jetonWeb] = compte($pdo, $base, $webPart, $mdp, 'Web');

echo "Partant #$idPartant, restant #$idRestant, tiers #$idTiers, web #$idWeb\n\n";

// ---------------------------------------------------------------------
// 0. Le socle : la migration 016
// ---------------------------------------------------------------------
echo "La migration 016\n";

$colonne = (int) $pdo->query(
    "SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'anonymized_at'"
)->fetchColumn();
verifie('users.anonymized_at existe', $colonne === 1, 'migration 016 non jouee ?');

$reserve = $pdo->query("SELECT id FROM users WHERE email = 'deleted@deleted.local'")->fetchColumn();
verifie('l utilisateur reserve existe', (bool) $reserve);
$idReserve = (int) $reserve;

$reserveMuet = (int) $pdo->query(
    "SELECT COUNT(*) FROM users WHERE email = 'deleted@deleted.local'
      AND password_hash IS NULL AND is_active = 0 AND deleted_at IS NULL"
)->fetchColumn();
verifie('l utilisateur reserve ne peut pas servir a se connecter', $reserveMuet === 1);

// ---------------------------------------------------------------------
// 1. Le decor : trois listes, un partage en ecriture, un en lecture
// ---------------------------------------------------------------------
echo "\nLe decor\n";

[$c, $r] = req('POST', "$base/shopping-lists", ['name' => "Liste du foyer $suffixe"], $jetonPartant);
$listePartagee = (int) ($r['data']['id'] ?? $r['id'] ?? 0);
verifie('liste partagee creee', $listePartagee > 0, "code $c");

[$c, $r] = req('POST', "$base/shopping-lists", ['name' => "Liste solo $suffixe"], $jetonPartant);
$listeSolo = (int) ($r['data']['id'] ?? $r['id'] ?? 0);
verifie('liste solo creee', $listeSolo > 0, "code $c");

[$c, $r] = req('POST', "$base/shopping-lists", ['name' => "Liste en lecture $suffixe"], $jetonPartant);
$listeLecture = (int) ($r['data']['id'] ?? $r['id'] ?? 0);
verifie('liste en lecture creee', $listeLecture > 0, "code $c");

if ($listePartagee === 0 || $listeSolo === 0 || $listeLecture === 0) {
    fwrite(STDERR, "\nLe decor n'a pas pu etre pose : la suite du test ne voudrait rien dire.\n");
    exit(1);
}

// Les partages : acceptes directement en base, le parcours d'invitation
// n'est pas l'objet du test.
$pdo->prepare(
    "INSERT INTO shared_list (list_id, owner_id, shared_with_user_id, permission, status,
                              is_active, accepted_at, created_at, updated_at)
     VALUES (?, ?, ?, 'edit', 'accepted', 1, NOW(), NOW(), NOW())"
)->execute([$listePartagee, $idPartant, $idRestant]);

$pdo->prepare(
    "INSERT INTO shared_list (list_id, owner_id, shared_with_user_id, permission, status,
                              is_active, accepted_at, created_at, updated_at)
     VALUES (?, ?, ?, 'readOnly', 'accepted', 1, NOW(), NOW(), NOW())"
)->execute([$listeLecture, $idPartant, $idTiers]);

// Des articles, un recu, un budget, un historique : de quoi voir ce qui
// part et ce qui reste.
req('POST', "$base/shopping-lists/$listePartagee/items", ['product_name' => 'Pain', 'quantity' => 1], $jetonPartant);
req('POST', "$base/shopping-lists/$listeSolo/items", ['product_name' => 'Lait', 'quantity' => 2], $jetonPartant);

$pdo->prepare(
    "INSERT INTO list_receipts (list_id, store_name, total_amount, purchase_date, created_at, updated_at)
     VALUES (?, 'Metro', 42.50, CURDATE(), NOW(), NOW())"
)->execute([$listeSolo]);

$pdo->prepare(
    "INSERT INTO budgets (user_id, created_by_user_id, list_id, name, budget_amount, period_type,
                          start_date, end_date, alert_threshold, is_active, created_at, updated_at)
     VALUES (?, ?, ?, 'Budget du foyer', 300, 'monthly', CURDATE(),
             DATE_ADD(CURDATE(), INTERVAL 30 DAY), 80, 1, NOW(), NOW())"
)->execute([$idPartant, $idPartant, $listePartagee]);

$pdo->prepare(
    "INSERT INTO purchase_history (user_id, list_id, product_name, normalized_name, quantity,
                                   source, purchased_at, created_at)
     VALUES (?, ?, 'Pain', 'pain', 1, 'test', NOW(), NOW())"
)->execute([$idPartant, $listePartagee]);

// Deux messages dans la conversation partagee, un de chacun.
[$c] = req('POST', "$base/lists/$listePartagee/messages", ['message' => 'Je prends le pain'], $jetonPartant);
verifie('message du partant poste', $c === 200 || $c === 201, "code $c");
req('POST', "$base/lists/$listePartagee/messages", ['message' => 'Parfait, merci'], $jetonRestant);

$nbMessagesAvant = (int) $pdo->query("SELECT COUNT(*) FROM list_messages WHERE list_id = $listePartagee")->fetchColumn();
verifie('deux messages dans la conversation', $nbMessagesAvant === 2, "trouve $nbMessagesAvant");

// Un appareil et un jeton de rafraichissement, comme apres une vraie
// connexion sur telephone.
$pdo->prepare(
    "INSERT INTO user_devices (user_id, device_id, platform, push_token, is_active, created_at, updated_at)
     VALUES (?, 'appareil-essai', 'android', 'jeton-push-essai', 1, NOW(), NOW())"
)->execute([$idPartant]);

$jetonsAvant = (int) $pdo->query("SELECT COUNT(*) FROM refresh_tokens WHERE user_id = $idPartant")->fetchColumn();
verifie('un jeton de rafraichissement existe', $jetonsAvant > 0, "trouve $jetonsAvant");

// ---------------------------------------------------------------------
// 2. La demande, puis le code
// ---------------------------------------------------------------------
echo "\nLa demande de suppression\n";

[$c, $r] = req('POST', "$base/auth/request-account-deletion", ['reason' => 'Essai automatise'], $jetonPartant);
verifie('la demande aboutit', $c === 200 && ($r['success'] ?? false), "code $c");

$codeQ = $pdo->prepare('SELECT account_deletion_code FROM users WHERE id = ?');
$codeQ->execute([$idPartant]);
$code = (string) $codeQ->fetchColumn();
verifie('un code a six chiffres est en base', preg_match('/^\d{6}$/', $code) === 1,
    'la demande ecrivait avant dans une colonne inexistante');

[$c, $r] = req('GET', "$base/auth/account-deletion-status", null, $jetonPartant);
verifie('le statut annonce une demande en attente',
    $c === 200 && ($r['data']['has_pending_deletion'] ?? false) === true, "code $c");

echo "\nLe mauvais code ne supprime rien\n";
$faux = $code === '000000' ? '111111' : '000000';
[$c, $r] = req('POST', "$base/auth/confirm-account-deletion", ['deletion_code' => $faux], $jetonPartant);
verifie('un code faux est refuse', $c === 400 && ($r['code'] ?? '') === 'INVALID_CONFIRMATION_CODE', "code $c");

$encoreLa = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE id = $idPartant AND anonymized_at IS NULL")->fetchColumn();
verifie('le compte est intact apres un code faux', $encoreLa === 1);

// ---------------------------------------------------------------------
// 3. La suppression
// ---------------------------------------------------------------------
echo "\nLa suppression\n";

[$c, $r] = req('POST', "$base/auth/confirm-account-deletion", ['deletion_code' => $code], $jetonPartant);
verifie('la confirmation aboutit', $c === 200 && ($r['success'] ?? false), "code $c " . json_encode($r));

$ligne = $pdo->query(
    "SELECT email, first_name, last_name, password_hash, avatar_url, unsubscribe_token,
            sso_provider, two_factor_enabled, deletion_reason, anonymized_at, deleted_at, is_active
       FROM users WHERE id = $idPartant"
)->fetch(PDO::FETCH_ASSOC);

verifie('la ligne existe encore (elle part a la purge)', $ligne !== false);
verifie('le courriel est remplace', ($ligne['email'] ?? '') === "deleted_user_{$idPartant}@deleted.local",
    (string) ($ligne['email'] ?? 'absente'));
verifie('plus d empreinte de mot de passe', $ligne['password_hash'] === null);
verifie('plus d avatar', $ligne['avatar_url'] === null);
verifie('plus de jeton de desabonnement', $ligne['unsubscribe_token'] === null);
verifie('la raison de depart est effacee', $ligne['deletion_reason'] === null,
    'texte libre ecrit par la personne, donc identifiant');
verifie('la date d anonymisation est posee', $ligne['anonymized_at'] !== null);
verifie('le compte est marque supprime', $ligne['deleted_at'] !== null);

$ancienCourriel = (int) $pdo->query(
    "SELECT COUNT(*) FROM users WHERE email = " . $pdo->quote($partant)
)->fetchColumn();
verifie('l ancien courriel n est plus nulle part dans users', $ancienCourriel === 0);

// ---------------------------------------------------------------------
// 4. Le jeton d'acces ne vaut plus rien
// ---------------------------------------------------------------------
echo "\nLe jeton deja emis\n";

[$c] = req('GET', "$base/shopping-lists", null, $jetonPartant);
verifie('l ancien jeton est refuse', $c === 401,
    "code $c — un jeton vit une heure, un compte supprime ne doit pas survivre autant");

$jetonsApres = (int) $pdo->query("SELECT COUNT(*) FROM refresh_tokens WHERE user_id = $idPartant")->fetchColumn();
verifie('les jetons de rafraichissement sont detruits', $jetonsApres === 0, "reste $jetonsApres");

$appareils = (int) $pdo->query("SELECT COUNT(*) FROM user_devices WHERE user_id = $idPartant")->fetchColumn();
verifie('les appareils et jetons push sont detruits', $appareils === 0, "reste $appareils");

[$c] = req('POST', "$base/auth/login", ['email' => $partant, 'password' => $mdp]);
verifie('l ancien mot de passe ne connecte plus', $c === 401, "code $c");

// ---------------------------------------------------------------------
// 5. Ce qui etait a lui est parti
// ---------------------------------------------------------------------
echo "\nSes donnees personnelles\n";

$solo = (int) $pdo->query("SELECT COUNT(*) FROM shopping_lists WHERE id = $listeSolo")->fetchColumn();
verifie('la liste solo est detruite', $solo === 0);

$articlesSolo = (int) $pdo->query("SELECT COUNT(*) FROM list_items WHERE list_id = $listeSolo")->fetchColumn();
verifie('ses articles sont detruits', $articlesSolo === 0, "reste $articlesSolo");

$recus = (int) $pdo->query("SELECT COUNT(*) FROM list_receipts WHERE list_id = $listeSolo")->fetchColumn();
verifie('ses recus sont detruits', $recus === 0, "reste $recus");

$historique = (int) $pdo->query("SELECT COUNT(*) FROM purchase_history WHERE user_id = $idPartant")->fetchColumn();
verifie('son historique d achats est detruit', $historique === 0, "reste $historique");

$lecture = (int) $pdo->query("SELECT COUNT(*) FROM shopping_lists WHERE id = $listeLecture")->fetchColumn();
verifie('la liste partagee en LECTURE SEULE est detruite', $lecture === 0,
    'choix assume : personne ne peut l entretenir');

[$c] = req('GET', "$base/shopping-lists/$listeLecture", null, $jetonTiers);
verifie('le lecteur ne la trouve plus', $c === 404 || $c === 403, "code $c");

// ---------------------------------------------------------------------
// 6. Ce qui etait au groupe reste au groupe
// ---------------------------------------------------------------------
echo "\nLa liste partagee en ecriture\n";

$proprio = (int) $pdo->query("SELECT user_id FROM shopping_lists WHERE id = $listePartagee")->fetchColumn();
verifie('la liste a change de main', $proprio === $idRestant, "proprietaire #$proprio");

[$c, $r] = req('GET', "$base/shopping-lists/$listePartagee", null, $jetonRestant);
verifie('le membre restant y accede toujours', $c === 200, "code $c");

[$c] = req('POST', "$base/shopping-lists/$listePartagee/items", ['product_name' => 'Beurre', 'quantity' => 1], $jetonRestant);
verifie('il peut encore y ajouter un article', $c === 200 || $c === 201, "code $c");

$budget = $pdo->query("SELECT user_id FROM budgets WHERE list_id = $listePartagee")->fetchColumn();
verifie('le budget de la liste suit la liste', (int) $budget === $idRestant, "porte par #$budget");

$partageMort = (int) $pdo->query(
    "SELECT COUNT(*) FROM shared_list WHERE list_id = $listePartagee AND shared_with_user_id = $idRestant"
)->fetchColumn();
verifie('son propre partage a disparu (il est chez lui)', $partageMort === 0);

// ---------------------------------------------------------------------
// 7. La conversation n'a pas de trou
// ---------------------------------------------------------------------
echo "\nLa conversation\n";

$nbMessagesApres = (int) $pdo->query("SELECT COUNT(*) FROM list_messages WHERE list_id = $listePartagee")->fetchColumn();
verifie('les deux messages sont toujours la', $nbMessagesApres === 2, "trouve $nbMessagesApres");

$auteur = (int) $pdo->query(
    "SELECT user_id FROM list_messages WHERE list_id = $listePartagee ORDER BY id ASC LIMIT 1"
)->fetchColumn();
verifie('son message est signe par l utilisateur reserve', $auteur === $idReserve, "signe par #$auteur");

[$c, $r] = req('GET', "$base/lists/$listePartagee/messages", null, $jetonRestant);
$noms = array_map(fn ($m) => $m['user']['name'] ?? '', $r['data']['messages'] ?? []);
$supprimes = array_filter($r['data']['messages'] ?? [], fn ($m) => ($m['user']['is_deleted'] ?? false) === true);
verifie('l API annonce « Utilisateur supprime »', in_array('Utilisateur supprimé', $noms, true),
    implode(' | ', $noms));
verifie('et le drapeau is_deleted suit', count($supprimes) === 1, count($supprimes) . ' message(s)');

$adresseFuite = array_filter($supprimes, fn ($m) => ($m['user']['email'] ?? '') !== '');
verifie('aucune adresse n est rendue pour un compte supprime', $adresseFuite === []);

// ---------------------------------------------------------------------
// 8. L'ancienne adresse est libre
// ---------------------------------------------------------------------
echo "\nLa reinscription\n";

[$c, $r] = req('POST', "$base/auth/register", [
    'first_name' => 'Retour',
    'last_name' => 'Essai',
    'email' => $partant,
    'password' => $mdp,
    'password_confirmation' => $mdp,
    'terms_accepted' => true,
]);
verifie('l ancienne adresse peut se reinscrire', in_array($c, [200, 201], true),
    "code $c " . json_encode($r['message'] ?? ''));

$nouvelId = (int) $pdo->query("SELECT id FROM users WHERE email = " . $pdo->quote($partant))->fetchColumn();
verifie('c est un compte NEUF, pas l ancien', $nouvelId > 0 && $nouvelId !== $idPartant, "id $nouvelId");

$listesHeritees = (int) $pdo->query("SELECT COUNT(*) FROM shopping_lists WHERE user_id = $nouvelId")->fetchColumn();
verifie('il n herite d aucune liste de l ancien compte', $listesHeritees === 0, "trouve $listesHeritees");

// ---------------------------------------------------------------------
// 9. Le parcours du site : demande par courriel, lien a jeton
// ---------------------------------------------------------------------
echo "\nLa porte publique (site web)\n";

[$c, $r] = req('POST', "$base/account-deletion/request", ['email' => $webPart, 'language' => 'fr']);
verifie('la demande par courriel aboutit', $c === 200 && ($r['success'] ?? false), "code $c");

$demande = (int) $pdo->query(
    "SELECT COUNT(*) FROM account_deletion_requests WHERE email = " . $pdo->quote($webPart)
)->fetchColumn();
verifie('une demande est enregistree', $demande === 1, "trouve $demande");

$clair = (int) $pdo->query(
    "SELECT COUNT(*) FROM account_deletion_requests
      WHERE email = " . $pdo->quote($webPart) . " AND LENGTH(token_hash) = 64"
)->fetchColumn();
verifie('la base ne garde que l empreinte du jeton', $clair === 1);

[$c, $r] = req('POST', "$base/account-deletion/request", ['email' => 'inconnu-total@epilist.test', 'language' => 'en']);
$demandeFantome = (int) $pdo->query(
    "SELECT COUNT(*) FROM account_deletion_requests WHERE email = 'inconnu-total@epilist.test'"
)->fetchColumn();
verifie('une adresse inconnue recoit la meme reponse', $c === 200 && ($r['success'] ?? false), "code $c");
verifie('et ne cree aucune demande', $demandeFantome === 0,
    'sinon la page devient un detecteur de comptes');

// Le jeton clair n'est jamais rendu : on en pose un connu pour tester la
// suite, exactement comme le fait le controleur.
$jetonWebClair = bin2hex(random_bytes(32));
// L'echeance est calculee par PHP, comme le fait le controleur : sur
// cette machine MySQL et PHP ne sont pas sur le meme fuseau, et une
// echeance posee par NOW() paraitrait deja passee.
$maj = $pdo->prepare(
    "UPDATE account_deletion_requests SET token_hash = ?, expires_at = ?
      WHERE email = ? AND confirmed_at IS NULL"
);
$maj->execute([
    hash('sha256', $jetonWebClair),
    date('Y-m-d H:i:s', time() + 3600),
    $webPart,
]);
verifie('le jeton d essai remplace celui du courriel', $maj->rowCount() === 1,
    'lignes touchees : ' . $maj->rowCount());

[$c, $r] = req('GET', "$base/account-deletion/confirm/$jetonWebClair");
verifie('le lien supprime le compte', $c === 200 && ($r['success'] ?? false), "code $c");

$webAnonyme = (int) $pdo->query(
    "SELECT COUNT(*) FROM users WHERE id = $idWeb AND anonymized_at IS NOT NULL"
)->fetchColumn();
verifie('le compte du site est anonymise', $webAnonyme === 1);

[$c, $r] = req('GET', "$base/account-deletion/confirm/$jetonWebClair");
verifie('le meme lien ne sert pas deux fois', $c === 400 && ($r['success'] ?? true) === false, "code $c");

[$c, $r] = req('GET', "$base/account-deletion/confirm/" . bin2hex(random_bytes(32)));
verifie('un jeton inconnu est refuse', $c === 400, "code $c");

[$c, $corps, $type] = reqBrut("$base/account-deletion/confirm/$jetonWebClair", ['Accept: text/html']);
verifie('un clic direct depuis le courriel rend une page HTML',
    str_contains($type, 'text/html') && str_contains($corps, '<!doctype html>'),
    "type $type");
verifie('et cette page est hors index', str_contains($corps, 'name="robots" content="noindex"'));

// ---------------------------------------------------------------------
// 10. Le rattrapage des comptes d'avant
// ---------------------------------------------------------------------
echo "\nLe rattrapage (comptes « supprimes » d avant)\n";

$legacy = 'suppr-legacy@epilist.test';
// La date de depart se calcule en PHP, pas avec NOW() de MySQL : les deux
// horloges ne sont pas dans le meme fuseau, et autour de minuit la
// verification « conservee » comparait deux jours differents.
$departLegacy = date('Y-m-d H:i:s', strtotime('-200 days'));
$pdo->prepare('DELETE FROM users WHERE email = ?')->execute([$legacy]);
$pdo->prepare(
    "INSERT INTO users (first_name, last_name, email, password_hash, terms_accepted, is_active,
                        email_verified, role, currency_id, language, deleted_at, created_at, updated_at)
     VALUES ('Ancien', 'Parti', ?, 'empreinte-bidon', 1, 0, 1, 'user', 1, 'fr', ?, NOW(), NOW())"
)->execute([$legacy, $departLegacy]);
$idLegacy = (int) $pdo->lastInsertId();

$pdo->prepare(
    "INSERT INTO shopping_lists (user_id, created_by_user_id, name, created_at, updated_at)
     VALUES (?, ?, 'Liste d un compte parti', NOW(), NOW())"
)->execute([$idLegacy, $idLegacy]);

$sortie = [];
exec('php ' . escapeshellarg(dirname(__DIR__) . '/scripts/backfill_deleted_accounts.php') . ' 2>&1', $sortie);
$constat = implode("\n", $sortie);
verifie('le constat voit le compte a rattraper', str_contains($constat, "#$idLegacy"), 'absent du constat');
verifie('le constat ne modifie rien',
    (int) $pdo->query("SELECT COUNT(*) FROM users WHERE id = $idLegacy AND anonymized_at IS NULL")->fetchColumn() === 1);

exec('php ' . escapeshellarg(dirname(__DIR__) . '/scripts/backfill_deleted_accounts.php') . ' --apply 2>&1', $sortie);
$apres = $pdo->query(
    "SELECT email, password_hash, anonymized_at, deleted_at FROM users WHERE id = $idLegacy"
)->fetch(PDO::FETCH_ASSOC);
verifie('--apply anonymise le compte', ($apres['anonymized_at'] ?? null) !== null);
verifie('et efface son empreinte de mot de passe', $apres['password_hash'] === null);
verifie('sa date de depart d origine est conservee',
    str_starts_with((string) ($apres['deleted_at'] ?? ''), date('Y-m-d', strtotime('-200 days'))),
    'un rattrapage ne relance pas le delai de trente jours');

// ---------------------------------------------------------------------
// 11. La purge definitive
// ---------------------------------------------------------------------
echo "\nLa purge des trente jours\n";

$pdo->exec("UPDATE users SET anonymized_at = DATE_SUB(NOW(), INTERVAL 31 DAY),
                              deleted_at = DATE_SUB(NOW(), INTERVAL 31 DAY)
             WHERE id IN ($idPartant, $idWeb, $idLegacy)");

exec('php ' . escapeshellarg(dirname(__DIR__) . '/public/cron.php') . ' --purge-now 2>&1', $sortie);
$encore = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE id = $idPartant")->fetchColumn();
verifie('le constat ne purge rien', $encore === 1, 'la purge doit etre explicite');

exec('php ' . escapeshellarg(dirname(__DIR__) . '/public/cron.php') . ' --purge-now --apply 2>&1', $sortie);
$parti = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE id = $idPartant")->fetchColumn();
verifie('--apply efface la ligne pour de bon', $parti === 0);

$surviteListe = (int) $pdo->query("SELECT COUNT(*) FROM shopping_lists WHERE id = $listePartagee")->fetchColumn();
verifie('la liste transferee survit a la purge', $surviteListe === 1,
    'si elle disparait, une cascade a emporte le travail des autres');

$messagesSurvivants = (int) $pdo->query("SELECT COUNT(*) FROM list_messages WHERE list_id = $listePartagee")->fetchColumn();
verifie('les messages survivent a la purge', $messagesSurvivants === 2, "trouve $messagesSurvivants");

$reserveIntact = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE email = 'deleted@deleted.local'")->fetchColumn();
verifie('l utilisateur reserve n est jamais purge', $reserveIntact === 1);

// ---------------------------------------------------------------------
// Menage
// ---------------------------------------------------------------------
echo "\nMenage\n";

$pdo->exec("DELETE FROM account_deletion_requests WHERE email LIKE 'suppr-%@epilist.test'
             OR email = 'inconnu-total@epilist.test'");

/** Une liste s'efface par le bas : list_items n'a aucune cascade. */
$effaceListe = function (int $listId) use ($pdo): void {
    foreach (['list_items', 'budgets', 'shared_list', 'list_messages', 'list_receipts', 'purchase_history'] as $table) {
        $pdo->prepare("DELETE FROM {$table} WHERE list_id = ?")->execute([$listId]);
    }
    $pdo->prepare('DELETE FROM shopping_lists WHERE id = ?')->execute([$listId]);
};

$effaceListe($listePartagee);

foreach ([$partant, $restant, $tiers, $webPart, $legacy] as $courriel) {
    $idQ = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $idQ->execute([$courriel]);
    $id = $idQ->fetchColumn();

    if (!$id) {
        continue;
    }

    $listes = $pdo->prepare('SELECT id FROM shopping_lists WHERE user_id = ? OR created_by_user_id = ?');
    $listes->execute([$id, $id]);
    foreach ($listes->fetchAll(PDO::FETCH_COLUMN) as $listId) {
        $effaceListe((int) $listId);
    }

    foreach (['purchase_history', 'user_devices', 'refresh_tokens', 'list_messages', 'message_read_status'] as $table) {
        $pdo->prepare("DELETE FROM {$table} WHERE user_id = ?")->execute([$id]);
    }
    $pdo->prepare('DELETE FROM shared_list WHERE shared_with_user_id = ? OR owner_id = ?')->execute([$id, $id]);
    $pdo->prepare('DELETE FROM users WHERE id = ?')->execute([$id]);
}

// Les comptes anonymises de ce passage portent desormais un courriel en
// deleted_user_*, que la boucle ci-dessus ne retrouve pas.
$pdo->exec("DELETE FROM list_messages WHERE user_id IN
             (SELECT id FROM users WHERE email LIKE 'deleted_user_%@deleted.local')");
$pdo->exec("DELETE FROM users WHERE email LIKE 'deleted_user_%@deleted.local'");

echo "  comptes jetables retires\n";

echo "\n=== $reussis reussis, $echoues echoues ===\n";
exit($echoues === 0 ? 0 : 1);
