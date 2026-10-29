<?php
// scripts/test_recus_prives.php — la photo d'un recu n'appartient qu'a
// ceux qui ont acces a la liste.
//
// Usage : php scripts/test_recus_prives.php [base_url]
// Prerequis : API locale (defaut http://localhost:8001), migration 015
//             jouee.
//
// Ce que ce test defend, et qui etait casse : l'image d'un recu etait
// televersee en lecture publique, et son URL rangee en base. Quiconque
// connaissait l'URL lisait le recu — magasin, date, montants — sans
// compte. Desormais l'objet est prive et ne s'ouvre que par une URL
// signee de quinze minutes, delivree a qui a le droit de voir la liste.
//
// Le test cree DEUX comptes jetables : le proprietaire, et un intrus qui
// n'a rien demande. C'est l'intrus qui compte — sans lui, on ne teste
// qu'une porte ouverte.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

$base = $argv[1] ?? 'http://localhost:8001';
$motDePasse = getenv('RECUS_E2E_PWD') ?: 'Essai1234!';
$proprio = 'recus-prives-proprio@epilist.test';
$intrus = 'recus-prives-intrus@epilist.test';

$reussis = 0;
$echoues = 0;

function req(string $methode, string $url, ?array $corps = null, ?string $jeton = null): array
{
    $ch = curl_init($url);
    $entetes = ['Content-Type: application/json'];
    if ($jeton) {
        $entetes[] = "Authorization: Bearer $jeton";
    }
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $methode,
        CURLOPT_HTTPHEADER => $entetes,
        CURLOPT_TIMEOUT => 20,
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

/** Cree le compte s'il n'existe pas, le verifie, et rend son jeton. */
function compte(PDO $pdo, string $base, string $courriel, string $mdp, string $prenom): string
{
    $existe = $pdo->prepare('SELECT id FROM users WHERE email = ?');
    $existe->execute([$courriel]);
    if (!$existe->fetchColumn()) {
        req('POST', "$base/auth/register", [
            'first_name' => $prenom,
            'last_name' => 'Essai',
            'email' => $courriel,
            'password' => $mdp,
            'password_confirmation' => $mdp,
            'terms_accepted' => true,
        ]);
    }
    $pdo->prepare('UPDATE users SET email_verified = 1, email_verified_at = NOW() WHERE email = ?')
        ->execute([$courriel]);

    [$code, $rep] = req('POST', "$base/auth/login", ['email' => $courriel, 'password' => $mdp]);
    if ($code !== 200 || empty($rep['access_token'])) {
        fwrite(STDERR, "Connexion impossible pour $courriel ($code). L'API tourne-t-elle sur $base ?\n");
        exit(1);
    }
    return $rep['access_token'];
}

echo "=== Recus prives ===\n\n";

$jetonProprio = compte($pdo, $base, $proprio, $motDePasse, 'Proprio');
$jetonIntrus = compte($pdo, $base, $intrus, $motDePasse, 'Intrus');
echo "Proprietaire : $proprio\nIntrus       : $intrus\n\n";

// ---------------------------------------------------------------------
// 1. Le schema
// ---------------------------------------------------------------------
echo "La migration 015\n";
$colonne = $pdo->query(
    "SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'list_receipts'
        AND column_name = 'image_path'"
)->fetchColumn();
verifie('list_receipts.image_path existe', (int) $colonne === 1,
    'migration 015 non jouee ?');

$malFormees = $pdo->query(
    "SELECT COUNT(*) FROM list_receipts WHERE image_path LIKE '%://%'"
)->fetchColumn();
verifie('aucune cle ne contient d URL', (int) $malFormees === 0,
    "$malFormees ligne(s) mal converties");

// ---------------------------------------------------------------------
// 2. Une liste et un recu appartenant au proprietaire
// ---------------------------------------------------------------------
echo "\nPreparation\n";
$nomListe = 'Recus prives ' . bin2hex(random_bytes(3));
[$code, $rep] = req('POST', "$base/shopping-lists", ['name' => $nomListe], $jetonProprio);
$listId = $rep['data']['id'] ?? ($rep['id'] ?? null);
verifie('liste creee', $listId !== null, "code $code");
if ($listId === null) {
    echo "\nImpossible de continuer sans liste.\n";
    exit(1);
}

[$code, $rep] = req('POST', "$base/shopping-lists/$listId/receipts", [
    'store_name' => 'Metro Essai',
    'total_amount' => 42.5,
    'purchase_date' => date('Y-m-d'),
], $jetonProprio);
$receiptId = $rep['data']['id'] ?? null;
verifie('recu cree', $receiptId !== null, "code $code");
if ($receiptId === null) {
    echo "\nImpossible de continuer sans recu.\n";
    exit(1);
}

// ---------------------------------------------------------------------
// 3. Le contrat de la charge utile
// ---------------------------------------------------------------------
echo "\nCe que l API renvoie\n";
[$code, $rep] = req('GET', "$base/shopping-lists/$listId/receipts", null, $jetonProprio);
$liste = $rep['data'] ?? [];
$leRecu = null;
foreach ($liste as $r) {
    if ((int) ($r['id'] ?? 0) === (int) $receiptId) {
        $leRecu = $r;
        break;
    }
}
verifie('le recu est dans la liste', $leRecu !== null, "code $code");
verifie("le champ has_image est present",
    $leRecu !== null && array_key_exists('has_image', $leRecu),
    'les applications a jour s en servent pour savoir s il y a une photo');
verifie('has_image est faux sans photo',
    $leRecu !== null && ($leRecu['has_image'] ?? true) === false);

// ---------------------------------------------------------------------
// 4. Sans photo : 404, et surtout pas une URL
// ---------------------------------------------------------------------
echo "\nSans photo\n";
[$code, $rep] = req('GET', "$base/shopping-lists/$listId/receipts/$receiptId/image-url", null, $jetonProprio);
verifie('le proprietaire recoit 404', $code === 404, "code $code");
verifie('aucune URL n est renvoyee', empty($rep['data']['url'] ?? null));

// ---------------------------------------------------------------------
// 5. L intrus : 403 AVANT toute autre consideration
// ---------------------------------------------------------------------
echo "\nUn autre utilisateur\n";
[$code, $rep] = req('GET', "$base/shopping-lists/$listId/receipts/$receiptId/image-url", null, $jetonIntrus);
verifie('l intrus recoit 403', $code === 403, "code $code");
verifie('aucune URL ne fuit', empty($rep['data']['url'] ?? null));

// Le 403 doit tomber sur l ACCES, pas sur l existence : un intrus ne doit
// pas pouvoir distinguer « recu sans photo » de « recu avec photo » en
// comparant 404 et 403.
[$code404, $rep404] = req('GET', "$base/shopping-lists/$listId/receipts/999999/image-url", null, $jetonIntrus);
verifie('un recu inexistant donne AUSSI 403 a l intrus', $code404 === 403,
    "code $code404 — sinon l intrus apprend quels recus existent");

[$code, $rep] = req('GET', "$base/shopping-lists/$listId/receipts", null, $jetonIntrus);
verifie('l intrus ne lit pas les recus de la liste', in_array($code, [403, 404], true),
    "code $code");

// ---------------------------------------------------------------------
// 6. Sans jeton du tout
// ---------------------------------------------------------------------
echo "\nSans authentification\n";
[$code, $rep] = req('GET', "$base/shopping-lists/$listId/receipts/$receiptId/image-url");
verifie('un anonyme recoit 401', $code === 401, "code $code");

// ---------------------------------------------------------------------
// 7. Partage accepte : le lecteur voit
// ---------------------------------------------------------------------
echo "\nUn membre avec qui la liste est partagee\n";
$idIntrus = (int) $pdo->query("SELECT id FROM users WHERE email = " . $pdo->quote($intrus))->fetchColumn();
$pdo->prepare(
    "INSERT INTO shared_list (list_id, owner_id, shared_with_user_id, permission, status, is_active, share_token, shared_at, created_at, updated_at)
     SELECT ?, user_id, ?, 'readOnly', 'accepted', 1, ?, NOW(), NOW(), NOW() FROM shopping_lists WHERE id = ?"
)->execute([$listId, $idIntrus, bin2hex(random_bytes(16)), $listId]);

[$code, $rep] = req('GET', "$base/shopping-lists/$listId/receipts/$receiptId/image-url", null, $jetonIntrus);
verifie('en lecture seule, le refus n est plus 403 mais 404 (pas de photo)',
    $code === 404, "code $code — la lecture seule doit suffire a regarder un recu");

// ---------------------------------------------------------------------
// 8. Retrocompatibilite : un recu d AVANT la migration 015
// ---------------------------------------------------------------------
// Ces lignes-la ne portent qu une URL publique, jamais de cle. L API doit
// les reconnaitre comme « ayant une photo » — sinon le rattrapage du
// stockage ferait disparaitre les recus deja pris par les utilisateurs.
echo "\nUn recu d avant la migration (URL seule)\n";
$pdo->prepare(
    "UPDATE list_receipts
        SET image_url = ?, image_path = NULL
      WHERE id = ?"
)->execute([
    'https://storage.googleapis.com/epilist-storage/prod/receipts/ancien0000000000000000000000.jpg',
    $receiptId,
]);

[$code, $rep] = req('GET', "$base/shopping-lists/$listId/receipts", null, $jetonProprio);
$ancien = null;
foreach (($rep['data'] ?? []) as $r) {
    if ((int) ($r['id'] ?? 0) === (int) $receiptId) {
        $ancien = $r;
        break;
    }
}
verifie('une URL seule compte comme une photo',
    $ancien !== null && ($ancien['has_image'] ?? false) === true,
    'sinon les recus d avant disparaissent de l application');

// A ce stade l autre compte est un LECTEUR legitime (partage accepte a
// l etape 7). Il doit donc obtenir une URL — et c est ce cas qui prouve
// que la signature V4 fonctionne, y compris sur une ligne qui ne porte
// qu une vieille URL publique.
[$code, $rep] = req('GET', "$base/shopping-lists/$listId/receipts/$receiptId/image-url", null, $jetonIntrus);
$urlSignee = $rep['data']['url'] ?? '';
verifie('le lecteur autorise obtient une URL', $code === 200 && $urlSignee !== '',
    "code $code");
verifie('l URL est signee et limitee dans le temps',
    str_contains($urlSignee, 'X-Goog-Signature') && str_contains($urlSignee, 'X-Goog-Expires'),
    'une URL sans signature serait une URL publique deguisee');
verifie('l URL expire dans un quart d heure au plus',
    (int) (preg_match('/X-Goog-Expires=(\\d+)/', $urlSignee, $m) ? $m[1] : 99999) <= 900,
    'expiration annoncee : ' . ($m[1] ?? 'illisible') . ' s');
verifie('l expiration est annoncee a l application',
    !empty($rep['data']['expires_at'] ?? null));

// Partage revoque : la porte se referme immediatement.
$pdo->prepare('UPDATE shared_list SET status = ?, is_active = 0 WHERE list_id = ? AND shared_with_user_id = ?')
    ->execute(['revoked', $listId, $idIntrus]);
[$code, $rep] = req('GET', "$base/shopping-lists/$listId/receipts/$receiptId/image-url", null, $jetonIntrus);
verifie('partage revoque : retour a 403', $code === 403, "code $code");
verifie('et plus aucune URL', empty($rep['data']['url'] ?? null));

// ---------------------------------------------------------------------
// Menage : la liste d essai ne reste pas
// ---------------------------------------------------------------------
$pdo->prepare('DELETE FROM shared_list WHERE list_id = ?')->execute([$listId]);
req('DELETE', "$base/shopping-lists/$listId", null, $jetonProprio);

echo "\n=== $reussis reussis, $echoues echoues ===\n";
exit($echoues > 0 ? 1 : 0);
