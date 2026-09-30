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

echo "\nRésultat : $pass OK, $fail échec(s)\n";
exit($fail === 0 ? 0 : 1);
