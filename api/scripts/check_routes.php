<?php
// scripts/check_routes.php — Verifie que CHAQUE route declaree dans
// public/index.php designe une methode qui existe vraiment. Usage :
//   php scripts/check_routes.php
// Sort en code 1 si une route est cassee : utilisable avant un deploiement.
//
// Pourquoi : /auth/reset-link, /auth/validate-reset-token et
// /auth/reset-password ont vecu des mois en pointant vers des methodes
// absentes d'AuthController. Chaque appel repondait 500 (« ... is not
// resolvable ») sans que rien ne le signale. Une faute de frappe dans un
// nom de methode est invisible a la lecture et au php -l : seule une
// verification systematique la trouve.

$root = dirname(__DIR__);
$index = file_get_contents($root . '/public/index.php');

preg_match_all(
    "/->(get|post|put|patch|delete)\(\s*'([^']+)'\s*,\s*\[\s*([A-Za-z_\\\\]+)::class\s*,\s*'([^']+)'\s*\]/",
    $index,
    $routes,
    PREG_SET_ORDER
);

// Carte « nom court de classe » -> fichier, construite depuis src/.
$files = [];
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root . '/src'));
foreach ($it as $file) {
    if ($file->isFile() && $file->getExtension() === 'php') {
        $files[$file->getBasename('.php')] = $file->getPathname();
    }
}

$broken = [];
foreach ($routes as [, $verb, $path, $class, $method]) {
    $short = substr(strrchr('\\' . $class, '\\'), 1);
    if (!isset($files[$short])) {
        $broken[] = sprintf('%-16s %-6s %-46s %s', 'FICHIER ABSENT', strtoupper($verb), $path, $class);
        continue;
    }
    $body = file_get_contents($files[$short]);
    if (!preg_match('/function\s+' . preg_quote($method, '/') . '\s*\(/', $body)) {
        $broken[] = sprintf('%-16s %-6s %-46s %s', 'METHODE ABSENTE', strtoupper($verb), $path, "$short::$method");
    }
}

foreach ($broken as $line) {
    echo $line . "\n";
}
printf("\n%d routes avec controleur verifiees, %d cassees\n", count($routes), count($broken));
exit($broken === [] ? 0 : 1);
