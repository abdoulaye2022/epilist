<?php
// scripts/test_analyse_endpoints.php — ce que l'analyse du 23 octobre a
// ouvert dans l'API.
//
// Usage : php scripts/test_analyse_endpoints.php [base_url]
// Prerequis : API locale demarree (par defaut http://localhost:8001)
//             et migration 013 jouee.
//
// Le script cree son PROPRE compte jetable, comme
// test_planche_endpoints.php, plutot que de dependre d'un compte dont
// le mot de passe change des qu'on teste l'application a la main.
//
// Couvre : l'etat d'inventaire DEDUIT de la quantite (le cas « 2 pour un
// seuil de 1 » annonce en rupture), la peremption, le niveau, les
// boutons - et +, le prix approximatif d'un article, le budget aux deux
// semaines et son renouvellement, la recette ecrite a la main et sa
// recherche par ingredient, deux repas le meme jour, le refus d'un nom
// de liste deja pris, et le resume hebdomadaire des baisses de prix.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

$base = $argv[1] ?? 'http://localhost:8001';
$courriel = 'analyse-e2e@epilist.test';
$motDePasse = getenv('ANALYSE_E2E_PWD') ?: 'Essai1234!';

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

/** L'article de l'inventaire portant ce nom, ou null. */
function provision(array $items, string $nom): ?array
{
    foreach ($items as $i) {
        if (($i['product_name'] ?? '') === $nom) {
            return $i;
        }
    }
    return null;
}

// ---------------------------------------------------------------------
// Compte jetable
// ---------------------------------------------------------------------
$pdo = new PDO(
    "mysql:host={$_ENV['DB_HOST']};port={$_ENV['DB_PORT']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD'],
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$existe = $pdo->prepare('SELECT id FROM users WHERE email = ?');
$existe->execute([$courriel]);
if (!$existe->fetchColumn()) {
    req('POST', "$base/auth/register", [
        'first_name' => 'Analyse',
        'last_name' => 'Essai',
        'email' => $courriel,
        'password' => $motDePasse,
        'password_confirmation' => $motDePasse,
        'terms_accepted' => true,
    ]);
}
$pdo->prepare('UPDATE users SET email_verified = 1, email_verified_at = NOW() WHERE email = ?')
    ->execute([$courriel]);

[$code, $rep] = req('POST', "$base/auth/login", ['email' => $courriel, 'password' => $motDePasse]);
if ($code !== 200 || empty($rep['access_token'])) {
    fwrite(STDERR, "Connexion impossible ($code). L'API locale tourne-t-elle sur $base ?\n");
    exit(1);
}
$jeton = $rep['access_token'];
echo "Compte d'essai : $courriel\n\n";

// ---------------------------------------------------------------------
// 1. A la maison : l'etat se deduit de la quantite
// ---------------------------------------------------------------------
echo "A la maison — l'etat suit la quantite\n";

$riz = 'Riz essai ' . substr((string) time(), -5);

// LE cas de la capture : deux en stock, seuil de un, etat « out » saisi.
[$code, $rep] = req('POST', "$base/inventory/status", [
    'product_name' => $riz,
    'status' => 'out',
    'quantity' => 2,
    'min_quantity' => 1,
    'unit' => 'sac',
], $jeton);
verifie('la provision s\'enregistre', $code === 200, "code $code");
verifie(
    '2 pour un seuil de 1 n\'est PAS une rupture',
    ($rep['data']['item']['status'] ?? null) === 'at_home',
    'status = ' . ($rep['data']['item']['status'] ?? 'nul')
);
$rizId = $rep['data']['item']['id'] ?? null;

// Le seuil atteint : stock bas.
[$code, $rep] = req('POST', "$base/inventory/$rizId/quantity", ['quantity' => 1], $jeton);
verifie('pile au seuil : stock bas', ($rep['data']['item']['status'] ?? null) === 'running_low',
    'status = ' . ($rep['data']['item']['status'] ?? 'nul'));

// Zero, et seulement zero : rupture.
[$code, $rep] = req('POST', "$base/inventory/$rizId/quantity", ['quantity' => 0], $jeton);
verifie('zero : rupture', ($rep['data']['item']['status'] ?? null) === 'out');

// On ne descend pas sous zero.
[$code, $rep] = req('POST', "$base/inventory/$rizId/quantity", ['quantity' => -5], $jeton);
verifie('une quantite negative est ramenee a zero',
    ((float) ($rep['data']['item']['quantity'] ?? -1)) === 0.0);

[$code, $rep] = req('POST', "$base/inventory/$rizId/quantity", ['quantity' => 'beaucoup'], $jeton);
verifie('une quantite qui n\'est pas un nombre est refusee', $code === 422, "code $code");

// Peremption et niveau.
$demain = (new DateTimeImmutable('+2 days'))->format('Y-m-d');
[$code, $rep] = req('POST', "$base/inventory/status", [
    'product_name' => $riz,
    'status' => 'at_home',
    'quantity' => 3,
    'expires_at' => $demain,
], $jeton);
verifie('la date de peremption s\'enregistre',
    ($rep['data']['item']['expires_at'] ?? null) !== null, "code $code");

[$code, $rep] = req('GET', "$base/inventory", null, $jeton);
$ligne = provision($rep['data']['items'] ?? [], $riz);
verifie('la peremption dans 2 jours est signalee', ($ligne['expiring_soon'] ?? false) === true);
verifie('les jours restants sont comptes', ($ligne['days_to_expiry'] ?? null) === 2,
    'jours = ' . var_export($ligne['days_to_expiry'] ?? null, true));

[$code, $rep] = req('POST', "$base/inventory/status", [
    'product_name' => $riz,
    'status' => 'at_home',
    'expires_at' => null,
    'level' => 'half',
], $jeton);
verifie(
    'la date de peremption s\'effface',
    array_key_exists('expires_at', $rep['data']['item'] ?? [])
        && $rep['data']['item']['expires_at'] === null
);
verifie('le niveau s\'enregistre', ($rep['data']['item']['level'] ?? null) === 'half');

[$code, $rep] = req('POST', "$base/inventory/status", [
    'product_name' => $riz,
    'status' => 'at_home',
    'level' => 'peut-etre',
], $jeton);
verifie(
    'un niveau invente n\'entre pas en base',
    array_key_exists('level', $rep['data']['item'] ?? [])
        && $rep['data']['item']['level'] === null
);

echo "\n";

// ---------------------------------------------------------------------
// 2. Le prix d'un article : exact ou approximatif
// ---------------------------------------------------------------------
echo "Liste — le prix exact ou approximatif\n";

$nomListe = 'Essai analyse ' . substr((string) time(), -6);
[$code, $rep] = req('POST', "$base/shopping-lists", ['name' => $nomListe], $jeton);
verifie('une liste se cree', $code === 201, "code $code");
$listeId = $rep['data']['id'] ?? null;

// Le nom deja pris, aux majuscules pres.
[$code, $rep] = req('POST', "$base/shopping-lists", ['name' => strtoupper($nomListe)], $jeton);
verifie('un nom deja pris est refuse, majuscules comprises', $code === 409, "code $code");
verifie('le refus porte un code lisible', ($rep['code'] ?? null) === 'DUPLICATE_LIST_NAME');

[$code, $rep] = req('POST', "$base/shopping-lists/$listeId/items", [
    'product_name' => 'Pommes Gala',
    'quantity' => 2,
], $jeton);
verifie('un article s\'ajoute', $code === 201 || $code === 200, "code $code");
$articleId = $rep['data']['id'] ?? ($rep['data']['item']['id'] ?? null);

[$code, $rep] = req('PUT', "$base/shopping-lists/$listeId/items/$articleId", [
    'product_name' => 'Pommes Gala',
    'quantity' => 2,
    'price' => 8.0,
    'price_is_estimate' => true,
], $jeton);
verifie('le prix approximatif s\'enregistre', $code === 200, "code $code");
verifie('et il se relit comme approximatif',
    !empty($rep['data']['price_is_estimate']), var_export($rep['data']['price_is_estimate'] ?? null, true));

[$code, $rep] = req('PUT', "$base/shopping-lists/$listeId/items/$articleId", [
    'product_name' => 'Pommes Gala',
    'quantity' => 2,
    'price' => 8.0,
    'price_is_estimate' => false,
], $jeton);
verifie('un prix peut REPASSER en exact', empty($rep['data']['price_is_estimate']));

echo "\n";

// ---------------------------------------------------------------------
// 3. Budget : aux deux semaines, et le renouvellement
// ---------------------------------------------------------------------
echo "Budget — periode de paie et renouvellement\n";

// Les budgets d'un passage precedent couvriraient la meme periode, et
// l'API refuse deux periodes qui se chevauchent (a juste titre). On
// repart donc d'un compte sans budget.
[$code, $rep] = req('GET', "$base/budgets", null, $jeton);
foreach (($rep['data']['budgets'] ?? $rep['data'] ?? []) as $b) {
    if (is_array($b) && isset($b['id'])) {
        req('DELETE', "$base/budgets/{$b['id']}", null, $jeton);
    }
}

$debut = (new DateTimeImmutable('monday this week'))->format('Y-m-d');
$fin = (new DateTimeImmutable('monday this week'))->modify('+13 days')->format('Y-m-d');
[$code, $rep] = req('POST', "$base/budgets", [
    'name' => 'Paie ' . substr((string) time(), -5),
    'budget_amount' => 400,
    'period_type' => 'biweekly',
    'start_date' => $debut,
    'end_date' => $fin,
    'alert_threshold' => 80,
    'auto_renew' => true,
], $jeton);
verifie('un budget aux deux semaines se cree', $code === 201 || $code === 200, "code $code");
verifie('la periode est bien biweekly', ($rep['data']['period_type'] ?? null) === 'biweekly');
verifie('le renouvellement automatique se garde', ($rep['data']['auto_renew'] ?? null) === true,
    var_export($rep['data']['auto_renew'] ?? null, true));

[$code, $rep] = req('POST', "$base/budgets", [
    'name' => 'Periode inventee',
    'budget_amount' => 100,
    'period_type' => 'tous-les-mardis',
    'start_date' => $debut,
    'end_date' => $fin,
], $jeton);
verifie('une periode inventee est refusee', $code === 422, "code $code");

echo "\n";

// ---------------------------------------------------------------------
// 4. Repas : ecrire sa recette, la retrouver, deux repas le meme jour
// ---------------------------------------------------------------------
echo "Repas — ecrire, chercher, placer\n";

$plat = 'Pate chinois ' . substr((string) time(), -5);
[$code, $rep] = req('POST', "$base/recipes", [
    'name' => $plat,
    'servings' => 4,
    'preparation_time' => 35,
    'ingredients' => [
        ['ingredient_name' => 'Boeuf hache', 'quantity' => 500, 'unit' => 'g'],
        ['ingredient_name' => 'Mais en creme', 'quantity' => 1, 'unit' => 'boîte'],
        'Pommes de terre',
    ],
], $jeton);
verifie('une recette ecrite a la main s\'enregistre', $code === 201, "code $code");
verifie('ses trois ingredients sont la', ($rep['data']['recipe']['ingredients_count'] ?? 0) === 3,
    'compte = ' . ($rep['data']['recipe']['ingredients_count'] ?? 'nul'));
verifie('elle est a moi', ($rep['data']['recipe']['is_mine'] ?? false) === true);
$recetteId = $rep['data']['recipe']['id'] ?? null;

[$code, $rep] = req('POST', "$base/recipes", ['name' => '  '], $jeton);
verifie('une recette sans nom est refusee', $code === 422, "code $code");

// Recherche par nom.
[$code, $rep] = req('GET', "$base/recipes?q=" . urlencode(substr($plat, 0, 12)), null, $jeton);
$trouvee = array_filter($rep['data']['recipes'] ?? [], fn($r) => ($r['id'] ?? 0) === $recetteId);
verifie('la recherche par nom la trouve', $trouvee !== []);

// Recherche par INGREDIENT : « qu'est-ce que je fais avec du boeuf ? »
[$code, $rep] = req('GET', "$base/recipes?q=boeuf", null, $jeton);
$trouvee = array_filter($rep['data']['recipes'] ?? [], fn($r) => ($r['id'] ?? 0) === $recetteId);
verifie('la recherche par ingredient la trouve', $trouvee !== []);

// Filtre de temps.
[$code, $rep] = req('GET', "$base/recipes?max_time=10", null, $jeton);
$trouvee = array_filter($rep['data']['recipes'] ?? [], fn($r) => ($r['id'] ?? 0) === $recetteId);
verifie('un plat de 35 minutes sort d\'un filtre a 10 minutes', $trouvee === []);

// Deux repas le MEME jour : midi et soir.
[$code, $rep] = req('POST', "$base/meal-plans/preview", [
    'recipe_ids' => [$recetteId],
    'people' => 4,
], $jeton);
verifie('l\'apercu des ingredients repond', $code === 200, "code $code");
$ingredients = $rep['data']['items'] ?? [];

[$code, $rep] = req('POST', "$base/meal-plans", [
    'name' => 'Semaine essai',
    'recipe_ids' => [$recetteId],
    'people' => 4,
    'assignments' => [
        ['recipe_id' => $recetteId, 'weekday' => 2, 'meal_slot' => 'lunch'],
        ['recipe_id' => $recetteId, 'weekday' => 2, 'meal_slot' => 'dinner'],
    ],
    'items' => $ingredients !== [] ? $ingredients : [['product_name' => 'Pommes de terre', 'quantity' => 1]],
], $jeton);
verifie('le plan se cree avec deux repas le meme jour', $code === 201, "code $code");
$planId = $rep['data']['meal_plan_id'] ?? null;
if ($planId !== null) {
    $n = (int) $pdo->query(
        'SELECT COUNT(*) FROM meal_plan_recipes WHERE meal_plan_id = ' . (int) $planId
    )->fetchColumn();
    verifie('les deux repas sont bien DEUX lignes', $n === 2, "lignes = $n");
    $slots = $pdo->query(
        'SELECT GROUP_CONCAT(meal_slot ORDER BY meal_slot) FROM meal_plan_recipes WHERE meal_plan_id = ' . (int) $planId
    )->fetchColumn();
    verifie('midi et soir sont distingues', $slots === 'dinner,lunch', "slots = $slots");
}

[$code, $rep] = req('POST', "$base/meal-plans", [
    'recipe_ids' => [$recetteId],
    'assignments' => [['recipe_id' => $recetteId, 'weekday' => 9]],
    'items' => [['product_name' => 'Pommes de terre', 'quantity' => 1]],
], $jeton);
verifie('un jour hors de la semaine est refuse', $code === 422, "code $code");

echo "\n";

// ---------------------------------------------------------------------
// 5. Le resume hebdomadaire des baisses de prix
// ---------------------------------------------------------------------
echo "Alertes de prix — le resume hebdomadaire\n";

[$code, $rep] = req('PUT', "$base/user/email-preferences", ['price_alert_digest' => true], $jeton);
verifie('le resume hebdomadaire s\'active', $code === 200, "code $code");
[$code, $rep] = req('GET', "$base/user/email-preferences", null, $jeton);
$valeur = $rep['data']['price_alert_digest'] ?? null;
verifie('et il se relit', $valeur === true || $valeur === 1, var_export($valeur, true));

echo "\n" . str_repeat('-', 60) . "\n";
printf("%d verification(s) reussie(s), %d echec(s).\n", $reussis, $echoues);
exit($echoues === 0 ? 0 : 1);
