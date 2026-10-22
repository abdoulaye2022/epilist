<?php
// scripts/test_planche_endpoints.php — ce que la migration 012 a ouvert.
//
// Usage : php scripts/test_planche_endpoints.php [base_url]
// Prerequis : API locale demarree (par defaut http://localhost:8001).
//
// Le script cree son PROPRE compte local jetable et le verifie en base,
// plutot que de dependre de ali@gmail.com / admin@gmail.com dont les
// mots de passe changent des qu'on teste l'application a la main. Le
// mot de passe est surchargeable par PLANCHE_E2E_PWD.
//
// Couvre : adresse et heures d'ouverture d'un magasin, refus d'horaires
// mal formes, etoile « Favori » (idempotente, et remontant le magasin
// en tete de liste), recettes favorites, plat assigne a un jour, photo
// partagee d'un produit.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

$base = $argv[1] ?? 'http://localhost:8001';
$courriel = 'planche-e2e@epilist.test';
$motDePasse = getenv('PLANCHE_E2E_PWD') ?: 'Essai1234!';

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
        'first_name' => 'Planche',
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
$moi = (int) $rep['data']['id'];
echo "Compte d'essai : $courriel (id $moi)\n\n";

// ---------------------------------------------------------------------
// 1. Magasin : adresse, coordonnees, heures d'ouverture
// ---------------------------------------------------------------------
echo "Magasin — adresse et heures d'ouverture\n";

[$code, $rep] = req('POST', "$base/stores", ['name' => 'Essai Planche ' . substr((string) time(), -5)], $jeton);
verifie('un magasin se cree', $code === 201 || $code === 200, "code $code");
$magasinId = $rep['data']['id'] ?? null;
if (!$magasinId) {
    fwrite(STDERR, "Pas d'identifiant de magasin, on s'arrete.\n");
    exit(1);
}

$heures = [
    'mon' => ['08:00', '21:00'],
    'sat' => ['09:00', '20:00'],
    'sun' => null,
];
[$code, $rep] = req('PUT', "$base/stores/$magasinId", [
    'name' => $rep['data']['name'],
    'address' => '1200 rue Sainte-Catherine Ouest',
    'city' => 'Montréal',
    'postal_code' => 'H3B 1A1',
    'latitude' => 45.5017,
    'longitude' => -73.5673,
    'opening_hours' => $heures,
], $jeton);
verifie("l'adresse et les heures s'enregistrent", $code === 200, "code $code");
verifie("l'adresse revient telle quelle",
    ($rep['data']['address'] ?? null) === '1200 rue Sainte-Catherine Ouest');
verifie('les heures reviennent en JSON lisible',
    ($rep['data']['opening_hours']['mon'] ?? null) === ['08:00', '21:00']);
verifie('le dimanche ferme reste nul',
    array_key_exists('sun', $rep['data']['opening_hours'] ?? []) && $rep['data']['opening_hours']['sun'] === null);
verifie('la latitude est un nombre, pas une chaine',
    is_float($rep['data']['latitude'] ?? null) || is_int($rep['data']['latitude'] ?? null));

// Horaires mal formes : refuses, pas ecrits en silence.
foreach ([
    'une plage qui ferme avant d\'ouvrir' => ['mon' => ['21:00', '08:00']],
    'un jour inconnu' => ['lundi' => ['08:00', '21:00']],
    'une heure impossible' => ['mon' => ['25:00', '26:00']],
    'une plage a une seule heure' => ['mon' => ['08:00']],
] as $quoi => $mauvais) {
    [$code] = req('PUT', "$base/stores/$magasinId", [
        'name' => 'Essai Planche',
        'opening_hours' => $mauvais,
    ], $jeton);
    verifie("refus : $quoi", $code === 422, "code $code");
}

// ---------------------------------------------------------------------
// 2. Favori : porte par le membre, idempotent, et remonte la liste
// ---------------------------------------------------------------------
echo "\nMagasin — l'etoile Favori\n";

[$code, $rep] = req('PUT', "$base/stores/$magasinId/favorite", null, $jeton);
verifie("l'etoile s'allume", $code === 200 && ($rep['data']['is_favorite'] ?? false) === true, "code $code");

[$code] = req('PUT', "$base/stores/$magasinId/favorite", null, $jeton);
verifie('appuyer deux fois ne casse rien', $code === 200, "code $code");

$doublons = $pdo->prepare('SELECT COUNT(*) FROM store_favorites WHERE store_id = ? AND user_id = ?');
$doublons->execute([$magasinId, $moi]);
verifie('une seule ligne en base, pas deux', (int) $doublons->fetchColumn() === 1);

[$code, $rep] = req('GET', "$base/stores", null, $jeton);
$liste = $rep['data'] ?? [];
verifie('le favori est marque dans la liste',
    collect_premier($liste, $magasinId)['is_favorite'] ?? false);
verifie('les favoris remontent en tete',
    ($liste[0]['id'] ?? null) === $magasinId, 'le premier est ' . ($liste[0]['name'] ?? '?'));

[$code, $rep] = req('DELETE', "$base/stores/$magasinId/favorite", null, $jeton);
verifie("l'etoile s'eteint", $code === 200 && ($rep['data']['is_favorite'] ?? true) === false, "code $code");


// ---------------------------------------------------------------------
// 3. Recettes : la photo, et le favori porte par le membre
// ---------------------------------------------------------------------
echo "\nRecettes — photo du plat et favori\n";

[$code, $rep] = req('GET', "$base/recipes", null, $jeton);
$recettes = $rep['data']['recipes'] ?? [];
verifie('les recettes se chargent', $code === 200 && $recettes !== [], "code $code");

if ($recettes !== []) {
    verifie("la photo du plat sort enfin de la base",
        array_key_exists('image_url', $recettes[0]),
        'recipes.image_url existait depuis le debut, mais la reponse ne la transmettait pas');
    verifie("le favori est dans la reponse", array_key_exists('is_favorite', $recettes[0]));

    $recetteId = (int) $recettes[0]['id'];
    [$code, $rep] = req('PUT', "$base/recipes/$recetteId/favorite", null, $jeton);
    verifie('une recette se met en favori',
        $code === 200 && ($rep['data']['is_favorite'] ?? false) === true, "code $code");

    [$code] = req('PUT', "$base/recipes/$recetteId/favorite", null, $jeton);
    verifie('appuyer deux fois ne casse rien', $code === 200, "code $code");

    [$code, $rep] = req('GET', "$base/recipes", null, $jeton);
    $apres = $rep['data']['recipes'] ?? [];
    verifie('les favorites remontent en tete',
        ($apres[0]['id'] ?? null) === $recetteId, 'la premiere est ' . ($apres[0]['name'] ?? '?'));

    // Le favori appartient au MEMBRE : les recettes livrees ont
    // user_id NULL, donc une colonne sur recipes aurait valu pour tous.
    $partage = $pdo->prepare('SELECT COUNT(*) FROM recipe_favorites WHERE recipe_id = ? AND user_id <> ?');
    $partage->execute([$recetteId, $moi]);
    verifie("le favori d'un membre ne deborde pas sur les autres",
        (int) $partage->fetchColumn() === 0);

    [$code, $rep] = req('DELETE', "$base/recipes/$recetteId/favorite", null, $jeton);
    verifie('le favori se retire',
        $code === 200 && ($rep['data']['is_favorite'] ?? true) === false, "code $code");
}

// ---------------------------------------------------------------------
// 4. Repas : le plat trouve son jour
// ---------------------------------------------------------------------
echo "\nRepas — un plat, un jour\n";

if (count($recettes) >= 2) {
    $r1 = (int) $recettes[0]['id'];
    $r2 = (int) $recettes[1]['id'];

    [$code, $rep] = req('POST', "$base/meal-plans", [
        'name' => 'Semaine d\'essai',
        'people' => 4,
        'recipe_ids' => [$r1, $r2],
        'assignments' => [
            ['recipe_id' => $r1, 'weekday' => 1, 'meal_slot' => 'dinner'],
            ['recipe_id' => $r2, 'weekday' => 3],
        ],
        'items' => [['product_name' => 'Tomates', 'quantity' => 2]],
    ], $jeton);
    verifie('un plan avec des jours se cree', $code === 200 || $code === 201, "code $code");

    $planId = $rep['data']['meal_plan_id'] ?? ($rep['data']['id'] ?? null);
    if ($planId) {
        $jours = $pdo->prepare('SELECT recipe_id, weekday, meal_slot FROM meal_plan_recipes WHERE meal_plan_id = ?');
        $jours->execute([$planId]);
        $poses = [];
        foreach ($jours->fetchAll(PDO::FETCH_ASSOC) as $l) {
            $poses[(int) $l['recipe_id']] = $l;
        }
        verifie('le lundi est enregistre', (int) ($poses[$r1]['weekday'] ?? 0) === 1);
        verifie('le soir est enregistre', ($poses[$r1]['meal_slot'] ?? null) === 'dinner');
        verifie('le mercredi sans moment reste sans moment',
            (int) ($poses[$r2]['weekday'] ?? 0) === 3 && ($poses[$r2]['meal_slot'] ?? null) === null);
    }

    // Un jour impossible est refuse, pas ecrit en silence.
    [$code] = req('POST', "$base/meal-plans", [
        'recipe_ids' => [$r1],
        'assignments' => [['recipe_id' => $r1, 'weekday' => 9]],
        'items' => [['product_name' => 'Tomates']],
    ], $jeton);
    verifie('refus : un huitieme jour de la semaine', $code === 422, "code $code");
}

// ---------------------------------------------------------------------
// 5. Photo partagee d'un produit, sur l'alerte de prix
// ---------------------------------------------------------------------
echo "\nAlertes de prix — le visuel du produit\n";

// Repartir de zero : une photo laissee par le passage precedent
// fausserait l'assertion « sans photo connue, le champ est nul ».
$pdo->prepare('DELETE FROM product_images WHERE normalized_name = ?')
    ->execute([App\Models\PurchaseHistory::normalizeProductName('Pâtes Barilla essai')]);

[$code, $rep] = req('POST', "$base/price-alerts", [
    'product_name' => 'Pâtes Barilla essai',
    'target_price' => 2.49,
], $jeton);
verifie('une alerte se cree', $code === 200 || $code === 201, "code $code");
$alerteId = $rep['data']['alert']['id'] ?? ($rep['data']['id'] ?? null);

[$code, $rep] = req('GET', "$base/price-alerts", null, $jeton);
$alertes = $rep['data']['alerts'] ?? [];
$mienne = collect_premier($alertes, (int) $alerteId);
verifie("l'alerte porte un champ image", array_key_exists('image_url', $mienne));
// Surtout pas `?? 'x'` : l'operateur ecrase null par la valeur par
// defaut, et l'assertion ne pourrait JAMAIS voir le null qu'elle
// cherche. Elle a echoue ainsi pendant deux passages.
verifie('sans photo connue, le champ est nul',
    array_key_exists('image_url', $mienne) && $mienne['image_url'] === null,
    'valeur recue : ' . var_export($mienne['image_url'] ?? '(absent)', true));

// On pose la photo du PRODUIT, pas de l'alerte : elle doit remonter
// toute seule sur l'alerte, sans que rien ne la lui donne.
$espaceId = $mienne['space_id'] ?? null;
if ($espaceId !== null) {
    $pdo->prepare("
        INSERT INTO product_images (space_id, normalized_name, product_label, image_url, source, created_by_user_id)
        VALUES (?, ?, ?, ?, 'user', ?)
        ON DUPLICATE KEY UPDATE image_url = VALUES(image_url)
    ")->execute([
        $espaceId,
        App\Models\PurchaseHistory::normalizeProductName('Pâtes Barilla essai'),
        'Pâtes Barilla essai',
        'https://exemple.test/pates.jpg',
        $moi,
    ]);

    [$code, $rep] = req('GET', "$base/price-alerts", null, $jeton);
    $mienne = collect_premier($rep['data']['alerts'] ?? [], (int) $alerteId);
    verifie("la photo du produit remonte sur l'alerte",
        ($mienne['image_url'] ?? null) === 'https://exemple.test/pates.jpg');
}

if ($alerteId) {
    req('DELETE', "$base/price-alerts/$alerteId", null, $jeton);
}
$pdo->prepare('DELETE FROM product_images WHERE normalized_name = ?')
    ->execute([App\Models\PurchaseHistory::normalizeProductName('Pâtes Barilla essai')]);

// ---------------------------------------------------------------------
// 6. Invitation : le nom, et le telephone
// ---------------------------------------------------------------------
echo "\nInvitation — nom et telephone\n";

[$code, $rep] = req('POST', "$base/spaces", [
    'name' => 'Foyer d\'essai',
    'type' => 'household',
], $jeton);
$espace = $rep['data']['space']['id'] ?? ($rep['data']['id'] ?? null);
verifie('un foyer se cree', ($code === 200 || $code === 201) && $espace !== null, "code $code");

if ($espace) {
    // Une invitation en attente par courriel et par espace : on part
    // d'une adresse neuve a chaque passage, sinon le second echoue avec
    // INVITATION_ALREADY_PENDING et le test accuse le code a tort.
    $invitee = 'sara-' . substr((string) time(), -6) . '@epilist.test';
    [$code, $rep] = req('POST', "$base/spaces/$espace/invitations", [
        'email' => $invitee,
        'invitee_name' => 'Sara',
        'invitee_phone' => '+1 514 555 0199',
        'role' => 'member',
    ], $jeton);
    verifie("l'invitation part avec un nom", $code === 201 || $code === 200, "code $code");
    verifie('le nom revient dans la reponse',
        ($rep['data']['invitation']['invitee_name'] ?? null) === 'Sara');
    verifie('le telephone revient dans la reponse',
        ($rep['data']['invitation']['invitee_phone'] ?? null) === '+1 514 555 0199');

    [$code] = req('POST', "$base/spaces/$espace/invitations", [
        'email' => 'autre-' . substr((string) time(), -6) . '@epilist.test',
        'invitee_phone' => 'pas un numero du tout !!',
    ], $jeton);
    verifie('refus : un telephone qui n\'en est pas un', $code === 422, "code $code");
}

// ---------------------------------------------------------------------
// Menage
// ---------------------------------------------------------------------
req('DELETE', "$base/stores/$magasinId", null, $jeton);

echo "\n$reussis verifications reussies, $echoues echouees\n";
exit($echoues === 0 ? 0 : 1);

function collect_premier(array $liste, int $id): array
{
    foreach ($liste as $e) {
        if (($e['id'] ?? null) === $id) {
            return $e;
        }
    }
    return [];
}
