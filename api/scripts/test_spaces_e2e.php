<?php
// scripts/test_spaces_e2e.php — Tests de bout en bout des espaces
// (Phase 1) contre l'API locale. Usage :
//   php scripts/test_spaces_e2e.php [base_url]
// Prérequis : API locale démarrée, comptes de test locaux
//   ali@gmail.com et admin@gmail.com (mots de passe par defaut
//   Test1234! / Abc1234! ; surchargeables par E2E_PWD_A / E2E_PWD_B
//   quand ils ont ete changes en testant l'app)
//
// Couvre les exigences §49 du cahier des charges pour la Phase 1 :
// isolation inter-espaces, rôles, invitations (création / acceptation /
// refus / révocation / nominative), protections de l'espace personnel.

$base = $argv[1] ?? 'http://localhost:8001';
$pass = 0;
$fail = 0;

function req(string $method, string $url, ?array $body = null, ?string $token = null, ?int $spaceId = null): array
{
    $ch = curl_init($url);
    $headers = ['Content-Type: application/json'];
    if ($token) $headers[] = "Authorization: Bearer $token";
    if ($spaceId !== null) $headers[] = "X-Space-Id: $spaceId";
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_TIMEOUT => 20,
    ]);
    if ($body !== null) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    $raw = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return [$status, json_decode((string) $raw, true) ?? []];
}

function check(string $name, bool $ok, string $detail = ''): void
{
    global $pass, $fail;
    if ($ok) { $pass++; echo "  OK  $name\n"; }
    else { $fail++; echo "  FAIL $name" . ($detail ? " — $detail" : '') . "\n"; }
}

// Accès base : nécessaire dès le départ (jetons d'invitation, et code
// 2FA des comptes qui ont activé la vérification en deux étapes).
$envLines = file(__DIR__ . '/../.env');
$env = [];
foreach ($envLines as $l) if (preg_match('/^([A-Z_]+)=(.*)$/', trim($l), $m)) $env[$m[1]] = trim($m[2], '"\'');
$pdo = new PDO("mysql:host={$env['DB_HOST']};port={$env['DB_PORT']};dbname={$env['DB_DATABASE']};charset=utf8mb4", $env['DB_USERNAME'], $env['DB_PASSWORD']);

/** Pose un code 2FA connu pour un compte et retourne ce code. */
function seedTwoFactorCode(PDO $pdo, string $email, string $code = '123456'): string
{
    $st = $pdo->prepare('UPDATE users SET admin_otp_code = ?, admin_otp_expires_at = ? WHERE email = ?');
    $st->execute([password_hash($code, PASSWORD_DEFAULT), date('Y-m-d H:i:s', time() + 600), $email]);
    return $code;
}

/**
 * Connexion complète, 2FA comprise : si le compte a activé la
 * vérification en deux étapes, le code est posé en base puis échangé.
 */
function login(string $base, string $email, string $password): array
{
    global $pdo;
    [$s, $d] = req('POST', "$base/auth/login", ['email' => $email, 'password' => $password]);
    if ($s !== 200) { fwrite(STDERR, "Login $email impossible ($s)\n"); exit(1); }

    if (($d['code'] ?? '') === 'TWO_FACTOR_REQUIRED') {
        $code = seedTwoFactorCode($pdo, $email);
        [$s, $d] = req('POST', "$base/auth/2fa/verify", ['email' => $email, 'code' => $code]);
        if ($s !== 200) { fwrite(STDERR, "2FA $email impossible ($s)\n"); exit(1); }
    }

    return [$d['access_token'] ?? $d['data']['access_token'] ?? '', $d];
}

// Mots de passe des comptes de test : surchargeables par variables
// d'environnement, car ils changent dès qu'on teste l'app pour de vrai.
//   E2E_PWD_A=... E2E_PWD_B=... E2E_PWD_C=... php scripts/test_spaces_e2e.php
$pwdA = getenv('E2E_PWD_A') ?: 'Test1234!';
$pwdB = getenv('E2E_PWD_B') ?: 'Abc1234!';
$pwdC = getenv('E2E_PWD_C') ?: 'Test1234!';

echo "== Connexion des deux comptes de test\n";
[$tokenA] = login($base, 'ali@gmail.com', $pwdA);
[$tokenB] = login($base, 'admin@gmail.com', $pwdB);
check('tokens obtenus', $tokenA !== '' && $tokenB !== '');

echo "== Espace personnel\n";
[$s, $d] = req('GET', "$base/spaces", null, $tokenA);
$spacesA = $d['data']['spaces'] ?? [];
$personalA = null;
foreach ($spacesA as $sp) if ($sp['type'] === 'personal') $personalA = $sp;
check('GET /spaces répond', $s === 200, "status $s");
check('espace personnel présent et en premier', $personalA !== null && ($spacesA[0]['type'] ?? '') === 'personal');
check('rôle owner sur le personnel', ($personalA['my_role'] ?? '') === 'owner');

echo "== Création d'un foyer\n";
[$s, $d] = req('POST', "$base/spaces", ['type' => 'household', 'name' => 'Foyer Test E2E', 'city' => 'Moncton', 'country' => 'CA'], $tokenA);
$household = $d['data']['space'] ?? null;
check('création foyer 201', $s === 201 && $household, "status $s");
$hid = (int) ($household['id'] ?? 0);
[$s] = req('POST', "$base/spaces", ['type' => 'personal', 'name' => 'Interdit'], $tokenA);
check('création d\'un second personnel refusée', $s === 422, "status $s");
[$s] = req('POST', "$base/spaces", ['type' => 'household', 'name' => ''], $tokenA);
check('nom vide refusé', $s === 422, "status $s");

echo "== Isolation inter-espaces (règle critique §40)\n";
[$s] = req('GET', "$base/spaces/$hid", null, $tokenB);
check('B ne voit pas l\'espace de A (403)', $s === 403, "status $s");
[$s] = req('GET', "$base/spaces/$hid/members", null, $tokenB);
check('B ne liste pas les membres (403)', $s === 403, "status $s");
[$s] = req('PUT', "$base/spaces/$hid", ['name' => 'Piraté'], $tokenB);
check('B ne modifie pas l\'espace (403)', $s === 403, "status $s");
[$s] = req('GET', "$base/spaces/999999", null, $tokenA);
check('espace inexistant = même 403 (pas d\'énumération)', $s === 403, "status $s");

echo "== Invitations\n";
[$s, $d] = req('POST', "$base/spaces/$hid/invitations", ['email' => 'admin@gmail.com', 'role' => 'member'], $tokenA);
$inv = $d['data']['invitation'] ?? null;
check('invitation créée', $s === 201 && $inv, "status $s");
[$s] = req('POST', "$base/spaces/$hid/invitations", ['email' => 'admin@gmail.com', 'role' => 'member'], $tokenA);
check('doublon d\'invitation refusé', $s === 422, "status $s");
[$s, $d] = req('GET', "$base/space-invitations", null, $tokenB);
$received = $d['data']['invitations'] ?? [];
$mine = null;
foreach ($received as $i) if ((int) $i['space_id'] === $hid) $mine = $i;
check('B voit l\'invitation reçue', $mine !== null);

// Le jeton n'est pas exposé dans les listes : on le lit en base pour
// tester le mismatch d'email (un tiers qui intercepte le lien).
$token = $pdo->query("SELECT token FROM space_invitations WHERE space_id = $hid AND status='pending' ORDER BY id DESC LIMIT 1")->fetchColumn();
check('jeton retrouvé en base', is_string($token) && strlen($token) === 64);

[$s] = req('POST', "$base/space-invitations/$token/accept", null, $tokenA);
check('acceptation par le mauvais compte refusée (403)', $s === 403, "status $s");
[$s, $d] = req('POST', "$base/space-invitations/$token/accept", null, $tokenB);
check('acceptation par le bon compte', $s === 200, "status $s");
[$s] = req('POST', "$base/space-invitations/$token/accept", null, $tokenB);
check('jeton non réutilisable', $s === 404, "status $s");

echo "== Rôles et permissions\n";
[$s, $d] = req('GET', "$base/spaces/$hid/members", null, $tokenB);
check('B (membre) liste les membres', $s === 200 && count($d['data']['members'] ?? []) === 2, "status $s");
[$s] = req('POST', "$base/spaces/$hid/invitations", ['email' => 'fati@gmail.com', 'role' => 'member'], $tokenB);
check('member ne peut pas inviter (403)', $s === 403, "status $s");
// ID utilisateur de B
$bId = (int) $pdo->query("SELECT id FROM users WHERE email='admin@gmail.com'")->fetchColumn();
$aId = (int) $pdo->query("SELECT id FROM users WHERE email='ali@gmail.com'")->fetchColumn();
[$s] = req('PUT', "$base/spaces/$hid/members/$bId", ['role' => 'manager'], $tokenA);
check('owner promeut B manager', $s === 200, "status $s");
[$s] = req('PUT', "$base/spaces/$hid/members/$aId", ['role' => 'viewer'], $tokenB);
check('manager ne touche pas à l\'owner (422/403)', in_array($s, [403, 422], true), "status $s");
[$s] = req('PUT', "$base/spaces/$hid/members/$bId", ['permissions' => ['view_budgets' => false]], $tokenA);
check('surcharge fine de permission acceptée', $s === 200, "status $s");
[$s] = req('PUT', "$base/spaces/$hid/members/$bId", ['permissions' => ['inconnu' => true]], $tokenA);
check('permission inconnue refusée', $s === 422, "status $s");

echo "== Protections du personnel et sorties\n";
$pid = (int) ($personalA['id'] ?? 0);
[$s] = req('POST', "$base/spaces/$pid/invitations", ['email' => 'admin@gmail.com'], $tokenA);
check('le personnel ne s\'invite pas', $s === 422, "status $s");
[$s] = req('DELETE', "$base/spaces/$pid", null, $tokenA);
check('le personnel ne se supprime pas', $s === 422, "status $s");
[$s] = req('POST', "$base/spaces/$hid/leave", null, $tokenA);
check('l\'owner ne peut pas quitter', $s === 422, "status $s");
[$s] = req('POST', "$base/spaces/$hid/leave", null, $tokenB);
check('B quitte le foyer', $s === 200, "status $s");
[$s] = req('GET', "$base/spaces/$hid", null, $tokenB);
check('B n\'a plus accès après départ (403)', $s === 403, "status $s");

echo "== Résolution X-Space-Id\n";
[$s] = req('GET', "$base/spaces/$hid", null, $tokenA, $hid);
check('membre + en-tête espace : accès OK', $s === 200, "status $s");

echo "== Nettoyage\n";
[$s] = req('DELETE', "$base/spaces/$hid", null, $tokenA);
check('suppression du foyer par l\'owner', $s === 200, "status $s");

// ==================================================================
// PHASE 2 — données du foyer (listes, items, budgets, inventaire,
// activité, isolation hors ligne des périmètres)
// ==================================================================
echo "== PHASE 2 : foyer avec données\n";
[$s, $d] = req('POST', "$base/spaces", ['type' => 'household', 'name' => 'Foyer P2'], $tokenA);
$h2 = (int) ($d['data']['space']['id'] ?? 0);
check('foyer P2 créé', $s === 201 && $h2 > 0, "status $s");
[$s] = req('POST', "$base/spaces/$h2/invitations", ['email' => 'admin@gmail.com', 'role' => 'member'], $tokenA);
$token2 = $pdo->query("SELECT token FROM space_invitations WHERE space_id = $h2 AND status='pending' ORDER BY id DESC LIMIT 1")->fetchColumn();
[$s] = req('POST', "$base/space-invitations/$token2/accept", null, $tokenB);
check('B rejoint le foyer P2', $s === 200, "status $s");

echo "== Listes de l'espace\n";
[$s, $d] = req('POST', "$base/shopping-lists", ['name' => 'Courses du foyer'], $tokenA, $h2);
$hlist = (int) ($d['data']['id'] ?? 0);
check('liste créée DANS le foyer', $s === 201 && $hlist > 0, "status $s");
$spaceOfList = (int) $pdo->query("SELECT space_id FROM shopping_lists WHERE id = $hlist")->fetchColumn();
check('space_id posé sur la liste', $spaceOfList === $h2, "space_id=$spaceOfList");

[$s, $d] = req('GET', "$base/shopping-lists", null, $tokenB, $h2);
$namesB = array_column((array) ($d['data'] ?? []), 'name');
check('B voit la liste du foyer', in_array('Courses du foyer', $namesB, true));
[$s, $d] = req('GET', "$base/shopping-lists", null, $tokenA);
$namesPerso = array_column((array) ($d['data'] ?? []), 'name');
check('la liste du foyer N\'apparaît PAS dans le personnel de A', !in_array('Courses du foyer', $namesPerso, true));
[$s, $d] = req('GET', "$base/shopping-lists", null, $tokenB, $h2);
check('listing foyer de B : uniquement les listes du foyer', count($namesB) === 1, 'count=' . count($namesB));

echo "== Items : accès par appartenance + attribution\n";
[$s, $d] = req('POST', "$base/shopping-lists/$hlist/items", ['product_name' => 'Lait foyer', 'quantity' => 1], $tokenB);
check('B (membre) ajoute un article', in_array($s, [200, 201], true), "status $s");
$creator = $pdo->query("SELECT created_by_user_id FROM list_items WHERE list_id = $hlist ORDER BY id DESC LIMIT 1")->fetchColumn();
check('attribution created_by = B', (int) $creator === $bId, "creator=$creator");
$itemId = (int) $pdo->query("SELECT id FROM list_items WHERE list_id = $hlist ORDER BY id DESC LIMIT 1")->fetchColumn();
[$s] = req('PATCH', "$base/shopping-lists/$hlist/items/$itemId/toggle", ['is_purchased' => true], $tokenA);
check('A coche l\'article', $s === 200, "status $s");
$buyer = $pdo->query("SELECT purchased_by_user_id FROM list_items WHERE id = $itemId")->fetchColumn();
check('attribution purchased_by = A', (int) $buyer === $aId, "buyer=$buyer");

// Isolation : un NON-membre (fati) ne touche pas la liste du foyer.
[$tokenC] = login($base, 'fati@gmail.com', $pwdC);
if ($tokenC !== '') {
    [$s] = req('GET', "$base/shopping-lists/$hlist/items", null, $tokenC);
    check('non-membre : items refusés', in_array($s, [403, 404], true), "status $s");
} else {
    echo "  SKIP fati (mot de passe non posé)\n";
}

echo "== Permissions fines : viewer\n";
[$s] = req('PUT', "$base/spaces/$h2/members/$bId", ['role' => 'viewer'], $tokenA);
check('B rétrogradé viewer', $s === 200, "status $s");
[$s] = req('POST', "$base/shopping-lists/$hlist/items", ['product_name' => 'Interdit viewer'], $tokenB);
check('viewer ne peut pas ajouter d\'article', in_array($s, [403, 404], true), "status $s");
[$s] = req('PUT', "$base/spaces/$h2/members/$bId", ['role' => 'member'], $tokenA);

echo "== Budgets du foyer\n";
[$s, $d] = req('POST', "$base/budgets", [
    'name' => 'Budget foyer', 'budget_amount' => 900, 'period_type' => 'monthly',
    'start_date' => date('Y-m-01'), 'end_date' => date('Y-m-t'),
], $tokenA, $h2);
check('budget créé dans le foyer', in_array($s, [200, 201], true), "status $s");
[$s, $d] = req('GET', "$base/budgets", null, $tokenB, $h2);
$bNames = array_column((array) ($d['data'] ?? []), 'name');
check('B voit le budget du foyer', in_array('Budget foyer', $bNames, true));
[$s, $d] = req('GET', "$base/budgets", null, $tokenA);
$bPerso = array_column((array) ($d['data'] ?? []), 'name');
check('budget foyer absent du personnel de A', !in_array('Budget foyer', $bPerso, true));
[$s] = req('PUT', "$base/spaces/$h2/members/$bId", ['permissions' => ['manage_budgets' => false]], $tokenA);
[$s] = req('POST', "$base/budgets", [
    'name' => 'Interdit B', 'budget_amount' => 10, 'period_type' => 'monthly',
    'start_date' => date('Y-m-01'), 'end_date' => date('Y-m-t'),
], $tokenB, $h2);
check('sans manage_budgets : création refusée', $s === 403, "status $s");

echo "== Inventaire du foyer\n";
[$s] = req('POST', "$base/inventory/status", ['product_name' => 'Riz foyer', 'status' => 'out'], $tokenA, $h2);
check('A pose Riz foyer = terminé', $s === 200, "status $s");
[$s, $d] = req('GET', "$base/inventory", null, $tokenB, $h2);
$invNames = array_column((array) ($d['data']['items'] ?? []), 'product_name');
check('B voit l\'inventaire du foyer', in_array('Riz foyer', $invNames, true));
[$s, $d] = req('GET', "$base/inventory", null, $tokenA);
$invPerso = array_column((array) ($d['data']['items'] ?? []), 'product_name');
check('inventaire foyer absent du personnel', !in_array('Riz foyer', $invPerso, true));

echo "== Journal d'activité\n";
[$s, $d] = req('GET', "$base/spaces/$h2/activity", null, $tokenB);
$types = array_column((array) ($d['data']['activities'] ?? []), 'type');
check('activité lisible par un membre', $s === 200, "status $s");
check('événements attendus présents',
    in_array('member_joined', $types, true)
    && in_array('list_created', $types, true)
    && in_array('item_added', $types, true)
    && in_array('item_purchased', $types, true)
    && in_array('budget_created', $types, true)
    && in_array('inventory_out', $types, true),
    implode(',', array_unique($types)));
if ($tokenC !== '') {
    [$s] = req('GET', "$base/spaces/$h2/activity", null, $tokenC);
    check('activité refusée à un non-membre', $s === 403, "status $s");
}

echo "== Nettoyage P2\n";
[$s] = req('DELETE', "$base/spaces/$h2", null, $tokenA);
check('suppression du foyer P2', $s === 200, "status $s");

// ==================================================================
// PHASE 3 — restaurant : demandes d'achat, fournisseurs,
// inventaire quantitatif
// ==================================================================
echo "== PHASE 3 : restaurant\n";
[$s, $d] = req('POST', "$base/spaces", ['type' => 'restaurant', 'name' => 'Resto P3'], $tokenA);
$r3 = (int) ($d['data']['space']['id'] ?? 0);
check('restaurant créé', $s === 201 && $r3 > 0, "status $s");
[$s] = req('POST', "$base/spaces/$r3/invitations", ['email' => 'admin@gmail.com', 'role' => 'member'], $tokenA);
$token3 = $pdo->query("SELECT token FROM space_invitations WHERE space_id = $r3 AND status='pending' ORDER BY id DESC LIMIT 1")->fetchColumn();
[$s] = req('POST', "$base/space-invitations/$token3/accept", null, $tokenB);
check('employé B (member) rejoint', $s === 200, "status $s");

echo "== Demandes d'achat\n";
[$s, $d] = req('POST', "$base/purchase-requests", ['product_name' => 'Poulet', 'quantity' => 20, 'unit' => 'kg'], $tokenB, $r3);
$reqId = (int) ($d['data']['request']['id'] ?? 0);
check('employé crée une demande (pending)', $s === 201 && ($d['data']['request']['status'] ?? '') === 'pending', "status $s");
[$s] = req('POST', "$base/purchase-requests/$reqId/approve", null, $tokenB, $r3);
check('member ne peut PAS approuver (403)', $s === 403, "status $s");
[$s] = req('POST', "$base/purchase-requests/$reqId/reject", ['comment' => ''], $tokenA, $r3);
check('refus sans commentaire refusé (422)', $s === 422, "status $s");
[$s, $d] = req('POST', "$base/purchase-requests/$reqId/approve", null, $tokenA, $r3);
check('owner approuve', $s === 200 && ($d['data']['request']['status'] ?? '') === 'approved', "status $s");
check('approbateur tracé', ($d['data']['request']['approved_by'] ?? 0) == $aId);
[$s] = req('POST', "$base/purchase-requests/$reqId/approve", null, $tokenA, $r3);
check('transition invalide refusée (422)', $s === 422, "status $s");
[$s, $d] = req('POST', "$base/purchase-requests/$reqId/purchased", null, $tokenB, $r3);
check('employé marque acheté', $s === 200 && ($d['data']['request']['status'] ?? '') === 'purchased', "status $s");
[$s, $d] = req('GET', "$base/purchase-requests/$reqId", null, $tokenA, $r3);
$events = $d['data']['request']['events'] ?? [];
check('historique complet (3 transitions)', count($events) === 3, 'events=' . count($events));

// Rejet commenté + annulation par le demandeur
[$s, $d] = req('POST', "$base/purchase-requests", ['product_name' => 'Caviar', 'quantity' => 1], $tokenB, $r3);
$reqId2 = (int) ($d['data']['request']['id'] ?? 0);
[$s, $d] = req('POST', "$base/purchase-requests/$reqId2/reject", ['comment' => 'Trop cher'], $tokenA, $r3);
check('rejet avec commentaire', $s === 200 && ($d['data']['request']['decision_comment'] ?? '') === 'Trop cher', "status $s");
[$s, $d] = req('POST', "$base/purchase-requests", ['product_name' => 'Test annulation'], $tokenB, $r3);
$reqId3 = (int) ($d['data']['request']['id'] ?? 0);
[$s] = req('POST', "$base/purchase-requests/$reqId3/cancel", null, $tokenB, $r3);
check('le demandeur annule sa demande', $s === 200, "status $s");
// Isolation : C (non-membre) ne voit rien
if ($tokenC !== '') {
    [$s, $d] = req('GET', "$base/purchase-requests", null, $tokenC, $r3);
    check('non-membre : demandes refusées (403)', $s === 403, "status $s");
}
// Espace personnel : pas de demandes d'achat
[$s, $d] = req('GET', "$base/purchase-requests", null, $tokenA);
check('personnel : liste vide (pas d\'erreur)', $s === 200 && ($d['data']['requests'] ?? null) === []);

echo "== Fournisseurs\n";
[$s, $d] = req('POST', "$base/suppliers", ['name' => 'Fournisseur A', 'phone' => '506-555-0101'], $tokenA, $r3);
$supId = (int) ($d['data']['supplier']['id'] ?? 0);
check('création fournisseur (owner)', $s === 201 && $supId > 0, "status $s");
[$s] = req('POST', "$base/suppliers", ['name' => 'Interdit'], $tokenB, $r3);
check('member sans manage_suppliers refusé (403)', $s === 403, "status $s");
[$s, $d] = req('GET', "$base/suppliers", null, $tokenB, $r3);
check('member liste les fournisseurs', $s === 200 && count($d['data']['suppliers'] ?? []) === 1, "status $s");
[$s] = req('PUT', "$base/suppliers/$supId", ['is_active' => false], $tokenA, $r3);
check('désactivation fournisseur', $s === 200, "status $s");

echo "== Inventaire quantitatif\n";
[$s] = req('POST', "$base/inventory/status", [
    'product_name' => 'Riz resto', 'status' => 'at_home',
    'quantity' => 8, 'unit' => 'kg', 'min_quantity' => 10,
    'reorder_quantity' => 25, 'preferred_supplier_id' => $supId,
], $tokenA, $r3);
check('inventaire avec seuils', $s === 200, "status $s");
[$s, $d] = req('GET', "$base/inventory", null, $tokenB, $r3);
$riz = null;
foreach (($d['data']['items'] ?? []) as $i) if ($i['product_name'] === 'Riz resto') $riz = $i;
check('below_min détecté (8 <= 10)', $riz !== null && ($riz['below_min'] ?? false) === true);
check('seuils renvoyés', ($riz['min_quantity'] ?? null) == 10 && ($riz['reorder_quantity'] ?? null) == 25);

echo "== Activité restaurant\n";
[$s, $d] = req('GET', "$base/spaces/$r3/activity", null, $tokenA);
$types3 = array_column((array) ($d['data']['activities'] ?? []), 'type');
check('événements demandes présents',
    in_array('purchase_request_created', $types3, true)
    && in_array('purchase_request_approved', $types3, true)
    && in_array('purchase_request_rejected', $types3, true),
    implode(',', array_unique($types3)));

echo "== Nettoyage P3\n";
[$s] = req('DELETE', "$base/spaces/$r3", null, $tokenA);
check('suppression du restaurant', $s === 200, "status $s");

// ==================================================================
// PHASE 4 — intelligence prix : observations par espace, isolation,
// prix cible, alertes dédupliquées (§23-§27, §34)
// ==================================================================
echo "== PHASE 4 : foyer avec historique de prix\n";
[$s, $d] = req('POST', "$base/spaces", ['type' => 'household', 'name' => 'Foyer P4'], $tokenA);
$h4 = (int) ($d['data']['space']['id'] ?? 0);
check('foyer P4 créé', $s === 201 && $h4 > 0, "status $s");
[$s] = req('POST', "$base/spaces/$h4/invitations", ['email' => 'admin@gmail.com', 'role' => 'member'], $tokenA);
$token4 = $pdo->query("SELECT token FROM space_invitations WHERE space_id = $h4 AND status='pending' ORDER BY id DESC LIMIT 1")->fetchColumn();
[$s] = req('POST', "$base/space-invitations/$token4/accept", null, $tokenB);
check('B rejoint le foyer P4', $s === 200, "status $s");
[$s, $d] = req('POST', "$base/shopping-lists", ['name' => 'Courses P4'], $tokenA, $h4);
$l4 = (int) ($d['data']['id'] ?? 0);
check('liste du foyer créée', $s === 201 && $l4 > 0, "status $s");

// Observations : article coché AVEC prix -> purchase_history.space_id.
// L'anti-doublon fusionne un 2e « Lait P4 » : on RECYCLE le même
// article (nouveau prix, décoché, recoché = nouvelle observation).
$l4item = 0;
$mkObs = function (float $price) use ($base, $tokenA, $l4, $pdo, &$l4item) {
    if ($l4item === 0) {
        req('POST', "$base/shopping-lists/$l4/items",
            ['product_name' => 'Lait P4', 'quantity' => 1, 'price' => $price, 'store_name' => 'Metro P4'], $tokenA);
        $l4item = (int) $pdo->query("SELECT id FROM list_items WHERE list_id = $l4 ORDER BY id DESC LIMIT 1")->fetchColumn();
    } else {
        req('PUT', "$base/shopping-lists/$l4/items/$l4item", ['price' => $price], $tokenA);
        req('PATCH', "$base/shopping-lists/$l4/items/$l4item/toggle", ['is_purchased' => false], $tokenA);
    }
    [$s] = req('PATCH', "$base/shopping-lists/$l4/items/$l4item/toggle", ['is_purchased' => true], $tokenA);
    return $s;
};
check('achat coché avec prix', $mkObs(4.99) === 200);
$obsSpace = $pdo->query("SELECT space_id FROM purchase_history WHERE normalized_name='lait p4' ORDER BY id DESC LIMIT 1")->fetchColumn();
check('observation rattachée au foyer (space_id)', (int) $obsSpace === $h4, "space_id=$obsSpace");

echo "== Import de reçu dans l'espace du foyer\n";
$receiptPayload = [
    'store_name' => 'IGA P4', 'purchase_date' => date('Y-m-d'),
    'total_amount' => 3.99, 'receipt_number' => 'P4-001', 'source' => 'manual',
    'items' => [['raw_label' => 'LAIT NAT 2%', 'product_name' => 'Lait P4', 'quantity' => 1, 'line_price' => 3.99]],
];
[$s, $d] = req('POST', "$base/shopping-lists/$l4/receipts/import", $receiptPayload, $tokenA);
check('import de reçu accepté', $s === 201, "status $s");
$row = $pdo->query("SELECT space_id, store_name FROM purchase_history WHERE normalized_name='lait p4' AND source='manual' ORDER BY id DESC LIMIT 1")->fetch(PDO::FETCH_ASSOC);
check('observation du reçu dans le foyer', (int) ($row['space_id'] ?? 0) === $h4 && ($row['store_name'] ?? '') === 'IGA P4');
$aliasSpace = $pdo->query("SELECT space_id FROM product_aliases WHERE normalized_alias='lait nat 2' ORDER BY id DESC LIMIT 1")->fetchColumn();
check('alias appris rattaché au foyer', (int) $aliasSpace === $h4, "space_id=$aliasSpace");
// Signature par ESPACE : B (autre membre) ré-importe le même reçu -> doublon
[$s, $d] = req('POST', "$base/shopping-lists/$l4/receipts/import", $receiptPayload, $tokenB);
check('même reçu par un autre membre = doublon (409)', $s === 409 && ($d['code'] ?? '') === 'DUPLICATE_RECEIPT', "status $s");

echo "== Isolation des prix (§34)\n";
[$s, $d] = req('GET', "$base/price-history?product=Lait%20P4", null, $tokenA, $h4);
$obsCount = count($d['data']['observations'] ?? []);
check('membre + en-tête foyer : observations visibles', $s === 200 && $obsCount >= 2, "obs=$obsCount");
check('fraîcheur exposée', ($d['data']['observations'][0]['freshness'] ?? '') === 'fresh');
[$s, $d] = req('GET', "$base/price-history?product=Lait%20P4", null, $tokenA);
check('les prix du foyer ne fuient PAS dans le personnel', count($d['data']['observations'] ?? []) === 0);
if ($tokenC !== '') {
    [$s] = req('GET', "$base/price-history?product=Lait%20P4", null, $tokenC, $h4);
    check('non-membre : historique refusé (403)', $s === 403, "status $s");
}

echo "== Prix cible (§25-§26)\n";
check('3e observation posée', $mkObs(4.49) === 200);
[$s, $d] = req('GET', "$base/price-alerts/suggest?product=Lait%20P4", null, $tokenB, $h4);
$sug = $d['data'] ?? [];
check('suggestion de seuil calculée', $s === 200 && ($sug['observations'] ?? 0) >= 3
    && is_numeric($sug['usual_price'] ?? null) && is_numeric($sug['suggested_target'] ?? null),
    json_encode($sug));
[$s, $d] = req('POST', "$base/price-alerts", ['product_name' => 'Lait P4', 'target_price' => 4.50], $tokenB, $h4);
$alertId = (int) ($d['data']['alert']['id'] ?? 0);
check('membre crée une alerte dans le foyer', $s === 201 && $alertId > 0, "status $s");
[$s] = req('POST', "$base/price-alerts", ['product_name' => 'Lait P4', 'target_price' => 4.00], $tokenA, $h4);
check('alerte en double refusée (409)', $s === 409, "status $s");
if ($tokenC !== '') {
    [$s] = req('POST', "$base/price-alerts", ['product_name' => 'Pirate', 'target_price' => 1], $tokenC, $h4);
    check('non-membre : création refusée (403)', $s === 403, "status $s");
}
[$s] = req('POST', "$base/price-alerts", ['product_name' => 'Sans seuil'], $tokenA, $h4);
check('seuil manquant refusé (422)', $s === 422, "status $s");

echo "== Déclenchement et déduplication (§27)\n";
check('observation sous le seuil', $mkObs(4.25) === 200);
$al = $pdo->query("SELECT last_triggered_at, last_notified_price FROM price_alerts WHERE id = $alertId")->fetch(PDO::FETCH_ASSOC);
check('alerte déclenchée (4,25 <= 4,50)', $al['last_triggered_at'] !== null && (float) $al['last_notified_price'] === 4.25, json_encode($al));
check('observation sous le seuil mais PLUS CHÈRE', $mkObs(4.30) === 200);
$al = $pdo->query("SELECT last_notified_price FROM price_alerts WHERE id = $alertId")->fetch(PDO::FETCH_ASSOC);
check('anti-spam : pas de re-notification à 4,30', (float) $al['last_notified_price'] === 4.25, json_encode($al));
check('observation STRICTEMENT plus basse', $mkObs(3.50) === 200);
$al = $pdo->query("SELECT last_notified_price FROM price_alerts WHERE id = $alertId")->fetch(PDO::FETCH_ASSOC);
check('meilleure affaire re-notifiée (3,50)', (float) $al['last_notified_price'] === 3.50, json_encode($al));
[$s, $d] = req('GET', "$base/spaces/$h4/activity", null, $tokenA);
$types4 = array_column((array) ($d['data']['activities'] ?? []), 'type');
check('activité price_alert_triggered journalisée', in_array('price_alert_triggered', $types4, true), implode(',', array_unique($types4)));

echo "== Gestion des alertes\n";
[$s, $d] = req('GET', "$base/price-alerts", null, $tokenA, $h4);
$alerts4 = $d['data']['alerts'] ?? [];
check('l\'owner voit l\'alerte du membre', count($alerts4) === 1 && ($alerts4[0]['last_observed'] ?? null) !== null, 'count=' . count($alerts4));
[$s, $d] = req('POST', "$base/price-alerts", ['product_name' => 'Café P4', 'target_price' => 10], $tokenA);
$persoAlert = (int) ($d['data']['alert']['id'] ?? 0);
check('alerte personnelle créée (sans en-tête)', $s === 201 && $persoAlert > 0, "status $s");
[$s, $d] = req('GET', "$base/price-alerts", null, $tokenA, $h4);
check('l\'alerte personnelle n\'apparaît pas dans le foyer', count($d['data']['alerts'] ?? []) === 1);
if ($tokenC !== '') {
    [$s] = req('PUT', "$base/price-alerts/$alertId", ['is_active' => false], $tokenC);
    check('non-membre : modification refusée', in_array($s, [403, 404], true), "status $s");
}
[$s] = req('PUT', "$base/price-alerts/$alertId", ['is_active' => false], $tokenB);
check('le créateur désactive son alerte', $s === 200, "status $s");
[$s] = req('DELETE', "$base/price-alerts/$alertId", null, $tokenA);
check('l\'owner (manage_lists) supprime l\'alerte', $s === 200, "status $s");

echo "== Nettoyage P4\n";
[$s] = req('DELETE', "$base/price-alerts/$persoAlert", null, $tokenA);
check('suppression alerte personnelle', $s === 200, "status $s");
[$s] = req('DELETE', "$base/spaces/$h4", null, $tokenA);
check('suppression du foyer P4', $s === 200, "status $s");
$pdo->exec("DELETE FROM purchase_history WHERE normalized_name = 'lait p4'");
$pdo->exec("DELETE FROM product_aliases WHERE normalized_alias = 'lait nat 2'");
$pdo->exec("DELETE FROM stores WHERE name IN ('Metro P4', 'IGA P4')");

// ==================================================================
// PHASE 5 — assistant intelligent : prédictions par espace (§17),
// avant les courses (§28), bon prix (§29), économies documentées (§30)
// ==================================================================
echo "== PHASE 5 : foyer avec historique multi-dates\n";
[$s, $d] = req('POST', "$base/spaces", ['type' => 'household', 'name' => 'Foyer P5'], $tokenA);
$h5 = (int) ($d['data']['space']['id'] ?? 0);
check('foyer P5 créé', $s === 201 && $h5 > 0, "status $s");
[$s] = req('POST', "$base/spaces/$h5/invitations", ['email' => 'admin@gmail.com', 'role' => 'member'], $tokenA);
$token5 = $pdo->query("SELECT token FROM space_invitations WHERE space_id = $h5 AND status='pending' ORDER BY id DESC LIMIT 1")->fetchColumn();
[$s] = req('POST', "$base/space-invitations/$token5/accept", null, $tokenB);
check('B rejoint le foyer P5', $s === 200, "status $s");
[$s, $d] = req('POST', "$base/shopping-lists", ['name' => 'Courses P5'], $tokenA, $h5);
$l5 = (int) ($d['data']['id'] ?? 0);

// Trois reçus datés (le prix du lait BAISSE : 4,99 -> 4,49 -> 3,99)
$mkReceipt = function (string $token, int $list, string $date, array $items, string $num) use ($base) {
    $total = array_sum(array_column($items, 'line_price'));
    return req('POST', "$base/shopping-lists/$list/receipts/import", [
        'store_name' => 'IGA P5', 'purchase_date' => $date,
        'total_amount' => $total, 'receipt_number' => $num, 'source' => 'manual',
        'items' => array_map(fn($i) => $i + ['quantity' => 1], $items),
    ], $token);
};
[$s] = $mkReceipt($tokenA, $l5, date('Y-m-d', strtotime('-10 days')), [
    ['raw_label' => 'Lait P5', 'line_price' => 4.99],
    ['raw_label' => 'Pain P5', 'line_price' => 2.50],
], 'P5-R1');
check('reçu J-10 importé', $s === 201, "status $s");
[$s] = $mkReceipt($tokenA, $l5, date('Y-m-d', strtotime('-8 days')), [
    ['raw_label' => 'Lait P5', 'line_price' => 4.49],
    ['raw_label' => 'Pain P5', 'line_price' => 2.50],
], 'P5-R2');
check('reçu J-8 importé', $s === 201, "status $s");

// Alerte AVANT le 3e reçu : elle doit se déclencher à l'import
[$s, $d] = req('POST', "$base/price-alerts", ['product_name' => 'Lait P5', 'target_price' => 4.00], $tokenA, $h5);
$alert5 = (int) ($d['data']['alert']['id'] ?? 0);
[$s] = $mkReceipt($tokenA, $l5, date('Y-m-d', strtotime('-1 day')), [
    ['raw_label' => 'Lait P5', 'line_price' => 3.99],
], 'P5-R3');
check('reçu J-1 importé (3,99, sous la cible)', $s === 201, "status $s");
$al5 = $pdo->query("SELECT last_notified_price FROM price_alerts WHERE id = $alert5")->fetchColumn();
check('alerte déclenchée par l\'import', abs((float) $al5 - 3.99) < 0.01, "last=$al5");

echo "== Prédictions par espace (§17, §34)\n";
[$s, $d] = req('GET', "$base/predictions?all=1&limit=100", null, $tokenB, $h5);
$predNames = array_column((array) ($d['data']['predictions'] ?? []), 'product_name');
check('B voit les prédictions du foyer', $s === 200 && in_array('Pain P5', $predNames, true), implode(',', $predNames));
[$s, $d] = req('GET', "$base/predictions?all=1&limit=100", null, $tokenA);
$predPerso = array_column((array) ($d['data']['predictions'] ?? []), 'product_name');
check('prédictions du foyer absentes du personnel', !in_array('Pain P5', $predPerso, true));
[$s] = req('POST', "$base/predictions/feedback", ['product_name' => 'Pain P5', 'action' => 'still_have'], $tokenB, $h5);
check('feedback accepté dans le foyer', $s === 200, "status $s");
$fbSpace = $pdo->query("SELECT space_id FROM home_inventory WHERE normalized_name='pain p5' ORDER BY id DESC LIMIT 1")->fetchColumn();
check('« j\'en ai encore » écrit dans l\'inventaire DU FOYER', (int) $fbSpace === $h5, "space_id=$fbSpace");

echo "== Est-ce un bon prix ? (§29)\n";
[$s, $d] = req('GET', "$base/prices/check?product=Lait%20P5&price=3.79", null, $tokenA, $h5);
check('3,79 = bon prix', $s === 200 && ($d['data']['verdict'] ?? '') === 'good', json_encode($d['data'] ?? []));
[$s, $d] = req('GET', "$base/prices/check?product=Lait%20P5&price=5.50", null, $tokenA, $h5);
check('5,50 = au-dessus du prix habituel', ($d['data']['verdict'] ?? '') === 'high');
check('les chiffres accompagnent le verdict',
    is_numeric($d['data']['usual_price'] ?? null) && is_numeric($d['data']['good_price'] ?? null)
    && ($d['data']['observations'] ?? 0) >= 3);
[$s, $d] = req('GET', "$base/prices/check?product=Lait%20P5&price=3.79", null, $tokenA);
check('sans historique personnel : unknown (pas de fuite)', ($d['data']['verdict'] ?? '') === 'unknown');
[$s] = req('GET', "$base/prices/check?product=Lait%20P5", null, $tokenA, $h5);
check('prix manquant refusé (422)', $s === 422, "status $s");

echo "== Économies estimées documentées (§30)\n";
[$s, $d] = req('GET', "$base/assistant/savings?days=30", null, $tokenA, $h5);
$sv = $d['data'] ?? [];
check('économie du lait détectée (4,74 -> 3,99)', abs(($sv['total_saving'] ?? 0) - 0.75) < 0.01, json_encode($sv));
$item0 = $sv['items'][0] ?? [];
check('économie documentée (payé, habituel, repères, date)',
    ($item0['product_name'] ?? '') === 'Lait P5' && abs(($item0['usual_price'] ?? 0) - 4.74) < 0.01
    && ($item0['priors_count'] ?? 0) === 2 && !empty($item0['purchased_at']));
[$s, $d] = req('GET', "$base/assistant/savings?days=30", null, $tokenA);
check('aucune économie du foyer dans le personnel', (float) ($d['data']['total_saving'] ?? -1) === 0.0);

echo "== Avant les courses (§28)\n";
[$s] = req('POST', "$base/budgets", [
    'name' => 'Budget P5', 'budget_amount' => 500, 'period_type' => 'monthly',
    'start_date' => date('Y-m-01'), 'end_date' => date('Y-m-t'),
], $tokenA, $h5);
[$s, $d] = req('GET', "$base/assistant/pre-shopping", null, $tokenB, $h5);
$brief = $d['data'] ?? [];
check('brief du foyer composé', $s === 200 && ($brief['space_type'] ?? '') === 'household', "status $s");
check('budget présent dans le brief', ($brief['budget']['budget_amount'] ?? null) == 500);
check('alerte de prix récente dans le brief', count($brief['price_watch'] ?? []) === 1
    && ($brief['price_watch'][0]['product_name'] ?? '') === 'Lait P5');
check('pas de demandes d\'achat pour un foyer',
    array_key_exists('pending_requests', $brief) && $brief['pending_requests'] === null);
if ($tokenC !== '') {
    [$s] = req('GET', "$base/assistant/pre-shopping", null, $tokenC, $h5);
    check('non-membre : brief refusé (403)', $s === 403, "status $s");
}

echo "== Espace pro : le quantitatif prime (§17)\n";
[$s, $d] = req('POST', "$base/spaces", ['type' => 'restaurant', 'name' => 'Resto P5'], $tokenA);
$r5 = (int) ($d['data']['space']['id'] ?? 0);
[$s, $d] = req('POST', "$base/shopping-lists", ['name' => 'Achats resto P5'], $tokenA, $r5);
$lr5 = (int) ($d['data']['id'] ?? 0);
// Cycle LENT (écart 20 j, dernier achat J-2 : ratio 0,1 -> pas besoin)
[$s] = $mkReceipt($tokenA, $lr5, date('Y-m-d', strtotime('-22 days')),
    [['raw_label' => 'Farine P5', 'line_price' => 10.00]], 'P5-F1');
[$s] = $mkReceipt($tokenA, $lr5, date('Y-m-d', strtotime('-2 days')),
    [['raw_label' => 'Farine P5', 'line_price' => 10.00]], 'P5-F2');
check('historique farine posé', $s === 201, "status $s");
[$s] = req('POST', "$base/inventory/status", [
    'product_name' => 'Farine P5', 'status' => 'out',
    'quantity' => 0, 'unit' => 'kg', 'min_quantity' => 5,
], $tokenA, $r5);
[$s, $d] = req('GET', "$base/predictions?all=1&limit=100", null, $tokenA, $r5);
$farine = null;
foreach (($d['data']['predictions'] ?? []) as $p) if ($p['product_name'] === 'Farine P5') $farine = $p;
check('stock à zéro = « en retard » malgré le cycle lent',
    $farine !== null && ($farine['status'] ?? '') === 'overdue' && ($farine['below_min'] ?? false) === true,
    json_encode($farine));
[$s, $d] = req('POST', "$base/purchase-requests", ['product_name' => 'Farine P5', 'quantity' => 25], $tokenA, $r5);
[$s, $d] = req('GET', "$base/assistant/pre-shopping", null, $tokenA, $r5);
$briefR = $d['data'] ?? [];
check('brief resto : demande en attente comptée', ($briefR['pending_requests'] ?? 0) === 1);
check('brief resto : rupture dans l\'inventaire', count($briefR['inventory_alerts'] ?? []) >= 1
    && ($briefR['space_type'] ?? '') === 'restaurant');

echo "== Nettoyage P5\n";
[$s] = req('DELETE', "$base/spaces/$h5", null, $tokenA);
check('suppression du foyer P5', $s === 200, "status $s");
[$s] = req('DELETE', "$base/spaces/$r5", null, $tokenA);
check('suppression du resto P5', $s === 200, "status $s");
$pdo->exec("DELETE FROM purchase_history WHERE normalized_name IN ('lait p5','pain p5','farine p5')");
$pdo->exec("DELETE FROM home_inventory WHERE normalized_name IN ('pain p5','farine p5')");
$pdo->exec("DELETE FROM product_prediction_prefs WHERE normalized_name IN ('pain p5','farine p5')");
$pdo->exec("DELETE FROM stores WHERE name = 'IGA P5'");

// ==================================================================
// PHASE 6 — communauté de prix anonymisée (§33) : agrégats sans
// identité, règles de qualité, retrait du partage
// ==================================================================
if ($tokenC === '') {
    echo "== PHASE 6 : SKIP (compte fati indisponible, 3 contributeurs requis)\n";
} else {
    echo "== PHASE 6 : trois contributeurs\n";
    // Consentement activé pour les trois comptes
    foreach ([$tokenA, $tokenB, $tokenC] as $t) {
        req('PUT', "$base/community/settings", ['enabled' => true], $t);
    }
    [$s, $d] = req('GET', "$base/community/settings", null, $tokenB);
    check('consentement lisible', $s === 200 && ($d['data']['enabled'] ?? false) === true, "status $s");

    // Chaque compte importe ses reçus « Maxi P6 » sur SA liste personnelle.
    // A ajoute une valeur ABERRANTE (59,90) et un produit isolé (Thé P6).
    $p6Lists = [];
    $p6Import = function (string $token, string $date, array $items, string $num) use ($base, &$p6Lists) {
        if (!isset($p6Lists[$token])) {
            [, $d] = req('POST', "$base/shopping-lists", ['name' => "Perso P6 $num"], $token);
            $p6Lists[$token] = (int) ($d['data']['id'] ?? 0);
        }
        $total = array_sum(array_column($items, 'line_price'));
        return req('POST', "$base/shopping-lists/{$p6Lists[$token]}/receipts/import", [
            'store_name' => 'Maxi P6', 'purchase_date' => $date,
            'total_amount' => $total, 'receipt_number' => $num, 'source' => 'manual',
            'items' => array_map(fn($i) => $i + ['quantity' => 1], $items),
        ], $token);
    };
    [$s] = $p6Import($tokenA, date('Y-m-d', strtotime('-6 days')), [['raw_label' => 'Cafe P6', 'line_price' => 5.99]], 'P6-A1');
    [$s] = $p6Import($tokenA, date('Y-m-d', strtotime('-4 days')), [
        ['raw_label' => 'Cafe P6', 'line_price' => 5.49],
        ['raw_label' => 'The P6', 'line_price' => 4.00],
    ], 'P6-A2');
    [$s] = $p6Import($tokenA, date('Y-m-d', strtotime('-1 day')), [['raw_label' => 'Cafe P6', 'line_price' => 59.90]], 'P6-A3');
    [$s] = $p6Import($tokenB, date('Y-m-d', strtotime('-5 days')), [['raw_label' => 'Cafe P6', 'line_price' => 5.79]], 'P6-B1');
    [$s] = $p6Import($tokenB, date('Y-m-d', strtotime('-3 days')), [['raw_label' => 'Cafe P6', 'line_price' => 5.59]], 'P6-B2');
    [$s] = $p6Import($tokenC, date('Y-m-d', strtotime('-2 days')), [['raw_label' => 'Cafe P6', 'line_price' => 5.69]], 'P6-C1');
    check('6 observations importées (3 comptes)', $s === 201, "status $s");

    echo "== Recalcul des agrégats\n";
    $cronKey = urlencode($env['CRON_SECRET'] ?? '');
    [$s, $d] = req('GET', "$base/community_refresh.php?key=$cronKey");
    check('recalcul exécuté', $s === 200 && ($d['success'] ?? false) === true
        && ($d['stats']['published'] ?? 0) >= 1, json_encode($d));
    [$s] = req('GET', "$base/community_refresh.php?key=mauvaise-cle");
    check('recalcul refusé sans le bon secret (403)', $s === 403, "status $s");

    echo "== Agrégats anonymisés et règles de qualité\n";
    [$s, $d] = req('GET', "$base/community/prices?product=Cafe%20P6", null, $tokenB);
    $cStores = $d['data']['stores'] ?? [];
    check('agrégat publié pour Cafe P6', $s === 200 && count($cStores) === 1, 'stores=' . count($cStores));
    $agg = $cStores[0] ?? [];
    check('3 contributeurs, 5 observations (aberrante ÉCARTÉE)',
        ($agg['contributors'] ?? 0) === 3 && ($agg['observations'] ?? 0) === 5, json_encode($agg));
    check('médiane communautaire 5,69', abs(($agg['median_price'] ?? 0) - 5.69) < 0.01);
    check('aucune identité dans la réponse', strpos(json_encode($d), 'user') === false);
    [$s, $d] = req('GET', "$base/community/prices?product=The%20P6", null, $tokenB);
    check('1 seul contributeur : PAS publié (qualité §33)', count($d['data']['stores'] ?? []) === 0);

    echo "== Repère communautaire dans « bon prix »\n";
    [$s, $d] = req('GET', "$base/prices/check?product=Cafe%20P6&price=5.49", null, $tokenC);
    check('C (1 seul achat) : verdict unknown MAIS repère communautaire',
        ($d['data']['verdict'] ?? '') === 'unknown'
        && abs(($d['data']['community']['median_price'] ?? 0) - 5.69) < 0.01,
        json_encode($d['data'] ?? []));

    echo "== Retrait du partage (§33)\n";
    [$s] = req('PUT', "$base/community/settings", ['enabled' => false], $tokenB);
    check('B se retire', $s === 200, "status $s");
    [$s, $d] = req('GET', "$base/community_refresh.php?key=$cronKey");
    [$s, $d] = req('GET', "$base/community/prices?product=Cafe%20P6", null, $tokenA);
    check('plus que 2 contributeurs : agrégat retiré', count($d['data']['stores'] ?? []) === 0);
    [$s] = req('PUT', "$base/community/settings", ['enabled' => true], $tokenB);
    [$s, $d] = req('GET', "$base/community_refresh.php?key=$cronKey");
    [$s, $d] = req('GET', "$base/community/prices?product=Cafe%20P6", null, $tokenA);
    check('retour de B : agrégat republié', count($d['data']['stores'] ?? []) === 1);

    echo "== Nettoyage P6\n";
    foreach ($p6Lists as $t => $lid) {
        req('DELETE', "$base/shopping-lists/$lid", null, $t);
    }
    $pdo->exec("DELETE FROM purchase_history WHERE normalized_name IN ('cafe p6','the p6')");
    $pdo->exec("DELETE FROM community_prices");
    $pdo->exec("DELETE FROM stores WHERE name = 'Maxi P6'");
    check('nettoyage P6 fait', true);
}

// ==================================================================
// §45 — dashboard adaptatif : attribution visible sur les articles
// des espaces partagés (« ajouté par » / « acheté par »)
// ==================================================================
echo "== §45 : attribution visible\n";
[$s, $d] = req('POST', "$base/spaces", ['type' => 'household', 'name' => 'Foyer §45'], $tokenA);
$h45 = (int) ($d['data']['space']['id'] ?? 0);
[$s] = req('POST', "$base/spaces/$h45/invitations", ['email' => 'admin@gmail.com', 'role' => 'member'], $tokenA);
$token45 = $pdo->query("SELECT token FROM space_invitations WHERE space_id = $h45 AND status='pending' ORDER BY id DESC LIMIT 1")->fetchColumn();
req('POST', "$base/space-invitations/$token45/accept", null, $tokenB);
[$s, $d] = req('POST', "$base/shopping-lists", ['name' => 'Liste §45'], $tokenA, $h45);
$l45 = (int) ($d['data']['id'] ?? 0);
req('POST', "$base/shopping-lists/$l45/items", ['product_name' => 'Beurre §45', 'quantity' => 1], $tokenB);
$i45 = (int) $pdo->query("SELECT id FROM list_items WHERE list_id = $l45 ORDER BY id DESC LIMIT 1")->fetchColumn();
req('PATCH', "$base/shopping-lists/$l45/items/$i45/toggle", ['is_purchased' => true], $tokenA);
[$s, $d] = req('GET', "$base/shopping-lists/$l45/items", null, $tokenB);
$item45 = null;
foreach (($d['data'] ?? []) as $it) if (($it['id'] ?? 0) === $i45) $item45 = $it;
check('article du foyer : « ajouté par » présent',
    $item45 !== null && !empty($item45['added_by_name']), json_encode($item45['added_by_name'] ?? null));
check('« acheté par » = l\'autre membre',
    !empty($item45['purchased_by_name']) && $item45['purchased_by_name'] !== $item45['added_by_name'],
    json_encode([$item45['added_by_name'] ?? null, $item45['purchased_by_name'] ?? null]));
// Liste personnelle : pas d'attribution (aucun nom exposé inutilement)
[$s, $d] = req('POST', "$base/shopping-lists", ['name' => 'Perso §45'], $tokenA);
$lp45 = (int) ($d['data']['id'] ?? 0);
req('POST', "$base/shopping-lists/$lp45/items", ['product_name' => 'Solo §45'], $tokenA);
[$s, $d] = req('GET', "$base/shopping-lists/$lp45/items", null, $tokenA);
check('liste personnelle : pas de champ d\'attribution',
    !array_key_exists('added_by_name', $d['data'][0] ?? []));

echo "== §45 : un changement de statut n'efface plus les seuils\n";
req('POST', "$base/inventory/status", [
    'product_name' => 'Sel §45', 'status' => 'at_home',
    'quantity' => 2, 'unit' => 'kg', 'min_quantity' => 5, 'reorder_quantity' => 10,
], $tokenA, $h45);
req('POST', "$base/inventory/status", ['product_name' => 'Sel §45', 'status' => 'running_low'], $tokenA, $h45);
[$s, $d] = req('GET', "$base/inventory", null, $tokenA, $h45);
$sel = null;
foreach (($d['data']['items'] ?? []) as $i) if ($i['product_name'] === 'Sel §45') $sel = $i;
check('statut changé, seuils et quantité INTACTS',
    $sel !== null && ($sel['status'] ?? '') === 'running_low'
    && ($sel['min_quantity'] ?? null) == 5 && ($sel['reorder_quantity'] ?? null) == 10
    && ($sel['quantity'] ?? null) == 2 && ($sel['unit'] ?? '') === 'kg',
    json_encode($sel));

echo "== Nettoyage §45\n";
$pdo->exec("DELETE FROM home_inventory WHERE normalized_name = 'sel 45'");
req('DELETE', "$base/shopping-lists/$lp45", null, $tokenA);
[$s] = req('DELETE', "$base/spaces/$h45", null, $tokenA);
check('nettoyage §45 fait', $s === 200, "status $s");
$pdo->exec("DELETE FROM purchase_history WHERE normalized_name IN ('beurre 45','solo 45')");

// ==================================================================
// AUDIT FINAL — correctifs C1-C6 : stats par espace, budget général
// par espace, alias, suppression sans limbes
// ==================================================================
echo "== AUDIT : foyer à trois membres\n";
[$s, $d] = req('POST', "$base/spaces", ['type' => 'household', 'name' => 'Foyer audit'], $tokenA);
$h7 = (int) ($d['data']['space']['id'] ?? 0);
check('foyer audit créé', $s === 201 && $h7 > 0, "status $s");
foreach ([['admin@gmail.com', $tokenB], ['fati@gmail.com', $tokenC]] as [$mail, $tk]) {
    if ($tk === '') continue;
    req('POST', "$base/spaces/$h7/invitations", ['email' => $mail, 'role' => 'member'], $tokenA);
    $tok = $pdo->query("SELECT token FROM space_invitations WHERE space_id = $h7 AND status='pending' ORDER BY id DESC LIMIT 1")->fetchColumn();
    req('POST', "$base/space-invitations/$tok/accept", null, $tk);
}
[$s, $d] = req('POST', "$base/shopping-lists", ['name' => 'Courses audit'], $tokenA, $h7);
$l7 = (int) ($d['data']['id'] ?? 0);

// Référence : total personnel de A AVANT toute activité du foyer
// (un compte de dev a de vraies dépenses ; on vérifie un DELTA nul).
$personalMonth = function (string $token) use ($base) {
    [, $d] = req('GET', "$base/analytics/spending/monthly?months=1", null, $token);
    foreach (($d['data']['monthly_data'] ?? []) as $m) {
        if (is_array($m) && ($m['is_current_month'] ?? false)) return (float) ($m['total_spent'] ?? 0);
    }
    return 0.0;
};
$baselineA = $personalMonth($tokenA);
// Même principe pour les budgets personnels de C (comptes réels : delta)
$personalBudgetSpent = function (string $token) use ($base) {
    [, $d] = req('GET', "$base/budgets", null, $token);
    $sum = 0.0;
    foreach (($d['data'] ?? []) as $b) $sum += (float) ($b['spent_amount'] ?? 0);
    return $sum;
};
$baselineBudgetC = $tokenC !== '' ? $personalBudgetSpent($tokenC) : 0.0;

// Achats croisés : B 40 $, C 10 $ (sur la liste créée par A)
$buy = function (string $token, string $product, float $price) use ($base, $l7, $pdo) {
    req('POST', "$base/shopping-lists/$l7/items", ['product_name' => $product, 'quantity' => 1, 'price' => $price], $token);
    $iid = (int) $pdo->query("SELECT id FROM list_items WHERE list_id = $l7 ORDER BY id DESC LIMIT 1")->fetchColumn();
    [$s] = req('PATCH', "$base/shopping-lists/$l7/items/$iid/toggle", ['is_purchased' => true], $token);
    return $s;
};
check('B achète 40 $', $buy($tokenB, 'Riz audit', 40.00) === 200);
if ($tokenC !== '') check('C achète 10 $', $buy($tokenC, 'Huile audit', 10.00) === 200);
$expected = $tokenC !== '' ? 50.0 : 40.0;

echo "== C2 : budget général = périmètre de l'ESPACE\n";
[$s] = req('POST', "$base/budgets", [
    'name' => 'Budget audit', 'budget_amount' => 200, 'period_type' => 'monthly',
    'start_date' => date('Y-m-01'), 'end_date' => date('Y-m-t'),
], $tokenA, $h7);
check('budget général du foyer créé', in_array($s, [200, 201], true), "status $s");
[$s, $d] = req('GET', "$base/budgets", null, $tokenB, $h7);
$auditBudget = null;
foreach (($d['data'] ?? []) as $b) if (($b['name'] ?? '') === 'Budget audit') $auditBudget = $b;
$spent = (float) ($auditBudget['spent_amount'] ?? -1);
check("dépensé du foyer = $expected (achats de TOUS les membres)", abs($spent - $expected) < 0.01, "spent=$spent");
check('budget actif même son dernier jour (endOfDay)', ($d['meta']['active_budgets'] ?? 0) >= 1, json_encode($d['meta'] ?? []));
if ($tokenC !== '') {
    $afterBudgetC = $personalBudgetSpent($tokenC);
    check('budgets persos de C : les achats du foyer NE comptent PAS (delta 0)',
        abs($afterBudgetC - $baselineBudgetC) < 0.01,
        "avant=$baselineBudgetC après=$afterBudgetC");
}

echo "== C1 : statistiques par espace\n";
[$s, $d] = req('GET', "$base/analytics/spending/monthly?months=1", null, $tokenB, $h7);
$monthNow = null;
foreach (($d['data']['monthly_data'] ?? []) as $m) {
    if (is_array($m) && ($m['is_current_month'] ?? false)) $monthNow = $m;
}
check('stats du foyer : mois courant = ' . $expected,
    $s === 200 && $monthNow !== null && abs((float) ($monthNow['total_spent'] ?? -1) - $expected) < 0.01,
    json_encode($monthNow));
$afterA = $personalMonth($tokenA);
check('stats personnelles de A : les achats du foyer absents (delta 0)',
    abs($afterA - $baselineA) < 0.01, "avant=$baselineA après=$afterA");

echo "== C6 : alias du foyer invisibles au scan personnel\n";
[$s] = req('POST', "$base/shopping-lists/$l7/receipts/import", [
    'store_name' => 'IGA audit', 'purchase_date' => date('Y-m-d'),
    'total_amount' => 3.49, 'receipt_number' => 'AUD-1', 'source' => 'manual',
    'items' => [['raw_label' => 'JUS ORNG AUDIT', 'product_name' => 'Jus orange audit', 'quantity' => 1, 'line_price' => 3.49]],
], $tokenA);
check('reçu avec alias importé dans le foyer', $s === 201, "status $s");
[$s, $d] = req('POST', "$base/receipts/resolve-labels", ['labels' => ['JUS ORNG AUDIT']], $tokenA, $h7);
check('en-tête foyer : alias résolu', ($d['data'][0]['method'] ?? '') === 'alias', json_encode($d['data'][0] ?? []));
[$s, $d] = req('POST', "$base/receipts/resolve-labels", ['labels' => ['JUS ORNG AUDIT']], $tokenA);
check('personnel : alias du foyer NON utilisé', ($d['data'][0]['method'] ?? '') !== 'alias', json_encode($d['data'][0] ?? []));

echo "== C5 : suppression d'espace sans limbes\n";
req('POST', "$base/price-alerts", ['product_name' => 'Riz audit', 'target_price' => 30], $tokenA, $h7);
$auditAlert = (int) $pdo->query("SELECT id FROM price_alerts WHERE space_id = $h7 ORDER BY id DESC LIMIT 1")->fetchColumn();
req('POST', "$base/suppliers", ['name' => 'Fournisseur audit'], $tokenA, $h7);
if ($tokenC !== '') {
    req('POST', "$base/spaces/$h7/leave", null, $tokenC);
    [$s] = req('GET', "$base/analytics/spending/monthly?months=1", null, $tokenC, $h7);
    check('après départ : stats du foyer refusées (403)', $s === 403, "status $s");
}
[$s] = req('DELETE', "$base/spaces/$h7", null, $tokenA);
check('suppression du foyer audit', $s === 200, "status $s");
[$s] = req('GET', "$base/shopping-lists/$l7", null, $tokenA);
check('liste du foyer supprimé : inaccessible même au créateur', in_array($s, [403, 404], true), "status $s");
$aliveAlert = $pdo->query("SELECT is_active FROM price_alerts WHERE id = $auditAlert")->fetchColumn();
check('alerte de prix désactivée', (int) $aliveAlert === 0, "is_active=$aliveAlert");
$aliveBudget = (int) $pdo->query("SELECT COUNT(*) FROM budgets WHERE space_id = $h7 AND is_active = 1")->fetchColumn();
check('budget du foyer désactivé', $aliveBudget === 0, "actifs=$aliveBudget");
$aliveSup = (int) $pdo->query("SELECT COUNT(*) FROM suppliers WHERE space_id = $h7 AND deleted_at IS NULL")->fetchColumn();
check('fournisseur soft-supprimé', $aliveSup === 0, "vivants=$aliveSup");

echo "== Nettoyage audit\n";
$pdo->exec("DELETE FROM purchase_history WHERE normalized_name IN ('riz audit','huile audit','jus orange audit')");
$pdo->exec("DELETE FROM product_aliases WHERE normalized_alias = 'jus orng audit'");
$pdo->exec("DELETE FROM stores WHERE name = 'IGA audit'");
check('nettoyage audit fait', true);

// ==================================================================
// 2FA PAR EMAIL — OPTIONNELLE : désactivée par défaut, activable par
// l'utilisateur, exige le mot de passe pour changer de réglage
// ==================================================================
echo "== 2FA : réglage par utilisateur\n";
$t2fa = $pdo->prepare('UPDATE users SET two_factor_enabled = 0, admin_otp_code = NULL WHERE email = ?');
$t2fa->execute(['ali@gmail.com']);

[$tokenA] = login($base, 'ali@gmail.com', $pwdA);
[$s, $d] = req('GET', "$base/auth/2fa", null, $tokenA);
check('réglage lisible, désactivé par défaut',
    $s === 200 && ($d['data']['enabled'] ?? true) === false && ($d['data']['method'] ?? '') === 'email',
    json_encode($d['data'] ?? []));

[$s] = req('POST', "$base/auth/2fa", ['enabled' => true], $tokenA);
check('activation sans mot de passe refusée (401)', $s === 401, "status $s");
[$s] = req('POST', "$base/auth/2fa", ['enabled' => true, 'password' => 'mauvais'], $tokenA);
check('mot de passe erroné refusé (401)', $s === 401, "status $s");
[$s, $d] = req('POST', "$base/auth/2fa", ['enabled' => true, 'password' => $pwdA], $tokenA);
check('activation avec mot de passe', $s === 200 && ($d['data']['enabled'] ?? false) === true, "status $s");

echo "== 2FA : connexion en deux étapes\n";
[$s, $d] = req('POST', "$base/auth/login", ['email' => 'ali@gmail.com', 'password' => $pwdA]);
check('login challengé, AUCUN jeton délivré',
    $s === 200 && ($d['code'] ?? '') === 'TWO_FACTOR_REQUIRED' && empty($d['access_token']),
    json_encode(array_keys($d)));
check('le serveur annonce la méthode email', ($d['data']['method'] ?? '') === 'email');

$code2fa = seedTwoFactorCode($pdo, 'ali@gmail.com', '424242');
[$s] = req('POST', "$base/auth/2fa/verify", ['email' => 'ali@gmail.com', 'code' => '000000']);
check('mauvais code refusé (401)', $s === 401, "status $s");
[$s, $d] = req('POST', "$base/auth/2fa/verify", ['email' => 'ali@gmail.com', 'code' => $code2fa]);
$tokenA2 = $d['access_token'] ?? '';
check('bon code : jetons délivrés', $s === 200 && $tokenA2 !== '' && !empty($d['refresh_token']), "status $s");
[$s] = req('POST', "$base/auth/2fa/verify", ['email' => 'ali@gmail.com', 'code' => $code2fa]);
check('code à usage unique (rejeu refusé)', $s === 401, "status $s");

// Code expiré : on antidate l'échéance
$pdo->prepare('UPDATE users SET admin_otp_code = ?, admin_otp_expires_at = ? WHERE email = ?')
    ->execute([password_hash('777777', PASSWORD_DEFAULT), date('Y-m-d H:i:s', time() - 60), 'ali@gmail.com']);
[$s] = req('POST', "$base/auth/2fa/verify", ['email' => 'ali@gmail.com', 'code' => '777777']);
check('code expiré refusé (401)', $s === 401, "status $s");

echo "== 2FA : désactivation\n";
[$s] = req('POST', "$base/auth/2fa", ['enabled' => false, 'password' => $pwdA], $tokenA2);
check('désactivation acceptée', $s === 200, "status $s");
[$s, $d] = req('POST', "$base/auth/login", ['email' => 'ali@gmail.com', 'password' => $pwdA]);
check('login revenu en UNE étape', $s === 200 && !empty($d['access_token']), "status $s");

echo "== 2FA : administrateur (même règle)\n";
$pdo->prepare('UPDATE users SET two_factor_enabled = 0 WHERE email = ?')->execute(['admin@gmail.com']);
[$s, $d] = req('POST', "$base/auth/admin/otp", ['email' => 'admin@gmail.com', 'password' => $pwdB]);
check('admin sans 2FA : connexion directe',
    $s === 200 && !empty($d['access_token']) && ($d['data']['requires_2fa'] ?? null) === false, "status $s");
$pdo->prepare('UPDATE users SET two_factor_enabled = 1 WHERE email = ?')->execute(['admin@gmail.com']);
[$s, $d] = req('POST', "$base/auth/admin/otp", ['email' => 'admin@gmail.com', 'password' => $pwdB]);
check('admin avec 2FA : code exigé, aucun jeton',
    $s === 200 && empty($d['access_token']) && ($d['data']['requires_2fa'] ?? false) === true, "status $s");
[$s] = req('POST', "$base/auth/admin/otp", ['email' => 'ali@gmail.com', 'password' => $pwdA]);
check('non-admin refusé sur la route admin (401)', $s === 401, "status $s");

// ==================================================================
// INVENTAIRE : un achat remet le produit « à la maison »
// ==================================================================
echo "== Inventaire : réapprovisionnement par l'achat\n";
[$s, $d] = req('POST', "$base/shopping-lists", ['name' => 'Liste réappro'], $tokenA);
$lr = (int) ($d['data']['id'] ?? 0);

// Produit SUIVI et marqué terminé
req('POST', "$base/inventory/status",
    ['product_name' => 'Lait réappro', 'status' => 'out'], $tokenA);
req('POST', "$base/shopping-lists/$lr/items",
    ['product_name' => 'Lait réappro', 'quantity' => 1, 'price' => 3.99], $tokenA);
$ir = (int) $pdo->query("SELECT id FROM list_items WHERE list_id = $lr ORDER BY id DESC LIMIT 1")->fetchColumn();
[$s] = req('PATCH', "$base/shopping-lists/$lr/items/$ir/toggle", ['is_purchased' => true], $tokenA);
check('article coché', $s === 200, "status $s");
$inv = $pdo->query("SELECT status, source FROM home_inventory WHERE normalized_name = 'lait reappro'")->fetch(PDO::FETCH_ASSOC);
check('produit suivi : remis « à la maison » par l\'achat',
    ($inv['status'] ?? '') === 'at_home' && ($inv['source'] ?? '') === 'purchase',
    json_encode($inv));

// Produit NON suivi : l'inventaire ne doit pas se remplir tout seul
req('POST', "$base/shopping-lists/$lr/items",
    ['product_name' => 'Jamais suivi réappro', 'quantity' => 1], $tokenA);
$ir2 = (int) $pdo->query("SELECT id FROM list_items WHERE list_id = $lr ORDER BY id DESC LIMIT 1")->fetchColumn();
req('PATCH', "$base/shopping-lists/$lr/items/$ir2/toggle", ['is_purchased' => true], $tokenA);
$n = (int) $pdo->query("SELECT COUNT(*) FROM home_inventory WHERE normalized_name = 'jamais suivi reappro'")->fetchColumn();
check('produit non suivi : aucune entrée créée', $n === 0, "entrees=$n");

// Une action manuelle POSTÉRIEURE reste prioritaire
req('POST', "$base/inventory/status",
    ['product_name' => 'Lait réappro', 'status' => 'out'], $tokenA);
$inv2 = $pdo->query("SELECT status, source FROM home_inventory WHERE normalized_name = 'lait reappro'")->fetch(PDO::FETCH_ASSOC);
check('le choix manuel postérieur l\'emporte',
    ($inv2['status'] ?? '') === 'out' && ($inv2['source'] ?? '') === 'manual', json_encode($inv2));

req('DELETE', "$base/shopping-lists/$lr", null, $tokenA);
$pdo->exec("DELETE FROM home_inventory WHERE normalized_name = 'lait reappro'");
$pdo->exec("DELETE FROM purchase_history WHERE normalized_name IN ('lait reappro','jamais suivi reappro')");
check('nettoyage réappro fait', true);

echo "\nRésultat : $pass OK, $fail échec(s)\n";
exit($fail === 0 ? 0 : 1);
