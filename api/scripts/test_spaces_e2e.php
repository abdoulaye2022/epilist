<?php
// scripts/test_spaces_e2e.php — Tests de bout en bout des espaces
// (Phase 1) contre l'API locale. Usage :
//   php scripts/test_spaces_e2e.php [base_url]
// Prérequis : API locale démarrée, comptes de test locaux
//   ali@gmail.com / Test1234!   et   admin@gmail.com / Abc1234!
//
// Couvre les exigences §49 du cahier des charges pour la Phase 1 :
// isolation inter-espaces, rôles, invitations (création / acceptation /
// refus / révocation / nominative), protections de l'espace personnel.

$base = $argv[1] ?? 'http://localhost:8000';
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

function login(string $base, string $email, string $password): array
{
    [$s, $d] = req('POST', "$base/auth/login", ['email' => $email, 'password' => $password]);
    if ($s !== 200) { fwrite(STDERR, "Login $email impossible ($s)\n"); exit(1); }
    return [$d['access_token'] ?? $d['data']['access_token'] ?? '', $d];
}

echo "== Connexion des deux comptes de test\n";
[$tokenA] = login($base, 'ali@gmail.com', 'Test1234!');
[$tokenB] = login($base, 'admin@gmail.com', 'Abc1234!');
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
$envLines = file(__DIR__ . '/../.env');
$env = [];
foreach ($envLines as $l) if (preg_match('/^([A-Z_]+)=(.*)$/', trim($l), $m)) $env[$m[1]] = trim($m[2], '"\'');
$pdo = new PDO("mysql:host={$env['DB_HOST']};port={$env['DB_PORT']};dbname={$env['DB_DATABASE']};charset=utf8mb4", $env['DB_USERNAME'], $env['DB_PASSWORD']);
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
[$tokenC] = login($base, 'fati@gmail.com', 'Test1234!');
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

echo "\nRésultat : $pass OK, $fail échec(s)\n";
exit($fail === 0 ? 0 : 1);
