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

echo "\nRésultat : $pass OK, $fail échec(s)\n";
exit($fail === 0 ? 0 : 1);
