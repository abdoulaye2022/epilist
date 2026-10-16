<?php
// scripts/test_error_middleware.php — Verifie le comportement du
// middleware d'erreurs. Usage :
//   php scripts/test_error_middleware.php
// Prerequis : base de donnees joignable (le test ecrit puis relit des
// lignes dans api_error_logs, et les supprime en sortant).
//
// Ce que ces quatre cas protegent :
//   1. Les erreurs du MOTEUR PHP (TypeError, appel sur null,
//      ArgumentCountError...) n'heritent pas de \Exception. Le middleware
//      ne rattrapait que \Exception : elles repartaient en page d'erreur
//      Slim — du HTML, la ou l'application attend du JSON — et aucune
//      trace n'arrivait dans l'ecran Monitoring.
//   2. Un controleur qui rattrape son exception et repond « 500 » de sa
//      propre main n'etait jamais journalise. L'ecran Monitoring restait
//      calme pendant que l'application accumulait les erreurs.
//   3. Un identifiant qui ne designe rien est une erreur de l'appelant :
//      404, et surtout pas une ligne dans le journal des erreurs.
//   4. Une reponse normale ne doit rien journaliser.

$root = dirname(__DIR__);
require $root . '/vendor/autoload.php';
Dotenv\Dotenv::createImmutable($root)->load();

$capsule = new Illuminate\Database\Capsule\Manager();
$capsule->addConnection([
    'driver' => $_ENV['DB_CONNECTION'],
    'host' => $_ENV['DB_HOST'],
    'database' => $_ENV['DB_DATABASE'],
    'username' => $_ENV['DB_USERNAME'],
    'password' => $_ENV['DB_PASSWORD'],
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix' => '',
]);
$capsule->setAsGlobal();
$capsule->bootEloquent();
$DB = Illuminate\Database\Capsule\Manager::class;

// Le middleware ecrit beaucoup sur error_log : on le met de cote.
ini_set('error_log', '/dev/null');

$pass = 0;
$fail = 0;
function check(string $name, bool $ok, string $detail = ''): void
{
    global $pass, $fail;
    if ($ok) { $pass++; echo "  OK  $name\n"; }
    else { $fail++; echo "  NON $name" . ($detail !== '' ? " — $detail" : '') . "\n"; }
}

$factory = new Slim\Psr7\Factory\ResponseFactory();
$middleware = new App\Middleware\ErrorMiddleware($factory);
$request = (new Slim\Psr7\Factory\ServerRequestFactory())
    ->createServerRequest('POST', 'http://test.local/cas/de/test')
    ->withAttribute('auth_id', 0);

/** Fabrique un gestionnaire de requete a partir d'une fermeture. */
function handler(callable $fn): Psr\Http\Server\RequestHandlerInterface
{
    return new class($fn) implements Psr\Http\Server\RequestHandlerInterface {
        private $fn;
        public function __construct(callable $fn) { $this->fn = $fn; }
        public function handle(Psr\Http\Message\ServerRequestInterface $r): Psr\Http\Message\ResponseInterface
        {
            return ($this->fn)($r);
        }
    };
}

$marker = $DB::table('api_error_logs')->max('id') ?? 0;

echo "1. Erreur du moteur PHP (\\Error, pas \\Exception)\n";
$r = $middleware($request, handler(function () { throw new TypeError('TypeError de test'); }));
$body = (string) $r->getBody();
check('statut 500', $r->getStatusCode() === 500, "recu {$r->getStatusCode()}");
check('corps en JSON et non en HTML', json_decode($body, true) !== null, $body);

echo "2. 500 fabrique a la main par un controleur\n";
$r = $middleware($request, handler(function () use ($factory) {
    $resp = $factory->createResponse(500);
    $resp->getBody()->write(json_encode(['success' => false, 'message' => '500 maison']));
    return $resp;
}));
check('statut 500 conserve', $r->getStatusCode() === 500);
check(
    'corps rendu intact (la lecture pour le journal ne le consomme pas)',
    (string) $r->getBody() === json_encode(['success' => false, 'message' => '500 maison']),
    (string) $r->getBody()
);

echo "3. Identifiant inexistant (ModelNotFoundException)\n";
$r = $middleware($request, handler(function () {
    throw new Illuminate\Database\Eloquent\ModelNotFoundException();
}));
check('statut 404 et non 500', $r->getStatusCode() === 404, "recu {$r->getStatusCode()}");

echo "4. Reponse normale\n";
$r = $middleware($request, handler(fn() => $factory->createResponse(200)));
check('statut 200 inchange', $r->getStatusCode() === 200);

echo "5. Journal des erreurs\n";
$logged = $DB::table('api_error_logs')->where('id', '>', $marker)->get();
check(
    'exactement 2 lignes : l\'erreur moteur et le 500 maison',
    count($logged) === 2,
    count($logged) . ' ligne(s) : ' . implode(' | ', array_map(fn($l) => $l->status . ' ' . substr($l->message, 0, 40), $logged->all()))
);
check(
    'la ligne de l\'erreur moteur porte son message',
    $logged->contains(fn($l) => str_contains($l->message, 'TypeError de test'))
);
check(
    'la ligne du 500 maison porte le corps de la reponse',
    $logged->contains(fn($l) => str_contains($l->message, '500 maison'))
);
check(
    'le chemin appele est enregistre',
    $logged->every(fn($l) => $l->path === '/cas/de/test')
);

// Nettoyage : ces lignes sont du test, pas de l'exploitation.
$DB::table('api_error_logs')->where('id', '>', $marker)->delete();

printf("\n%d verifications reussies, %d echouees\n", $pass, $fail);
exit($fail === 0 ? 0 : 1);
