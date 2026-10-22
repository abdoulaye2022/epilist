<?php
// scripts/run_migration.php - Joue une migration SQL, et dit ce qu'elle a fait.
//
// Usage : php scripts/run_migration.php migrations/012_planche_version_b.sql
//         php scripts/run_migration.php --dry migrations/...  (montre, ne joue pas)
//
// Pourquoi un lanceur plutot que `mysql < fichier.sql` : le mot de passe
// de la base vit dans .env et n'a rien a faire sur une ligne de commande,
// ou `ps` le lit. Ce script le prend dans .env, comme l'application.
//
// DEUX PIEGES, tous deux rencontres :
//
//   1. Un decoupage naif sur « ; » suivi d'un saut de ligne colle le
//      commentaire d'une section au premier ordre qui suit. Si le
//      programme saute ensuite les blocs commencant par « -- », il saute
//      l'ordre avec. C'est arrive : six ALTER TABLE n'ont jamais tourne,
//      et SANS ERREUR — `IF(@c = 0, ...)` avec @c jamais pose vaut NULL,
//      donc la branche « deja present » est prise en silence. D'ou le
//      retrait des commentaires AVANT le decoupage.
//
//   2. `PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;` tient sur
//      une seule ligne dans nos migrations : le decoupage doit donc se
//      faire sur CHAQUE « ; », pas seulement en fin de ligne.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($racine)->load();

$args = array_slice($argv, 1);
$sec = in_array('--dry', $args, true);
$args = array_values(array_filter($args, static fn($a) => $a !== '--dry'));

if (count($args) !== 1) {
    fwrite(STDERR, "Usage : php scripts/run_migration.php [--dry] <fichier.sql>\n");
    exit(1);
}

$chemin = $args[0];
if (!is_file($chemin)) {
    $chemin = $racine . '/' . ltrim($chemin, '/');
}
if (!is_file($chemin)) {
    fwrite(STDERR, "Fichier introuvable : {$args[0]}\n");
    exit(1);
}

$brut = file_get_contents($chemin);

// Retire les commentaires de ligne SANS toucher a ceux qui vivent dans
// une chaine (un COMMENT '...' peut contenir « -- »).
$propre = '';
$longueur = strlen($brut);
$guillemet = null;
for ($i = 0; $i < $longueur; $i++) {
    $c = $brut[$i];
    if ($guillemet !== null) {
        $propre .= $c;
        if ($c === $guillemet) {
            // Un guillemet double a l'interieur echappe le precedent.
            if ($i + 1 < $longueur && $brut[$i + 1] === $guillemet) {
                $propre .= $brut[++$i];
            } else {
                $guillemet = null;
            }
        }
        continue;
    }
    if ($c === "'" || $c === '"') {
        $guillemet = $c;
        $propre .= $c;
        continue;
    }
    if ($c === '-' && $i + 1 < $longueur && $brut[$i + 1] === '-') {
        while ($i < $longueur && $brut[$i] !== "\n") {
            $i++;
        }
        $propre .= "\n";
        continue;
    }
    $propre .= $c;
}

$ordres = array_values(array_filter(
    array_map('trim', explode(';', $propre)),
    static fn($o) => $o !== ''
));

echo "Migration : " . basename($chemin) . "\n";
echo "Base      : {$_ENV['DB_DATABASE']} sur {$_ENV['DB_HOST']}:{$_ENV['DB_PORT']}\n";
echo "Ordres    : " . count($ordres) . "\n\n";

if ($sec) {
    foreach ($ordres as $n => $o) {
        echo sprintf("%2d. %s\n", $n + 1, preg_replace('/\s+/', ' ', substr($o, 0, 110)));
    }
    echo "\n(--dry : rien n'a ete joue)\n";
    exit(0);
}

$pdo = new PDO(
    "mysql:host={$_ENV['DB_HOST']};port={$_ENV['DB_PORT']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD'],
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$joues = 0;
foreach ($ordres as $n => $ordre) {
    try {
        $st = $pdo->query($ordre);
        $joues++;
        // La derniere requete d'une migration maison est sa verification.
        if ($st !== false && stripos(ltrim($ordre), 'SELECT') === 0) {
            $lignes = $st->fetchAll(PDO::FETCH_ASSOC);
            foreach ($lignes as $ligne) {
                // Les « SELECT "deja present" » des branches ELSE ne
                // meritent pas qu'on les affiche.
                if (count($ligne) === 1 && str_contains((string) array_key_first($ligne), 'deja')) {
                    continue;
                }
                foreach ($ligne as $clef => $valeur) {
                    echo "  $clef = " . var_export($valeur, true) . "\n";
                }
            }
        }
    } catch (Throwable $e) {
        fwrite(STDERR, "\nECHEC a l'ordre " . ($n + 1) . " :\n");
        fwrite(STDERR, preg_replace('/\s+/', ' ', substr($ordre, 0, 300)) . "\n");
        fwrite(STDERR, $e->getMessage() . "\n");
        exit(1);
    }
}

echo "\n$joues ordres joues, sans erreur.\n";
