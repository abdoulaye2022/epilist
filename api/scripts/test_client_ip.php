<?php
// scripts/test_client_ip.php — l'adresse du client, selon qui parle a PHP.
//
// Sans serveur : le service se teste avec des requetes fabriquees.
//   php scripts/test_client_ip.php

require __DIR__ . '/../vendor/autoload.php';

use App\Services\ClientIp;
use Slim\Psr7\Factory\ServerRequestFactory;

$ok = 0; $ko = 0;
function verifier(string $cas, string $attendu, string $obtenu): void {
    global $ok, $ko;
    if ($attendu === $obtenu) { $ok++; echo "  ok   $cas\n"; }
    else { $ko++; echo "  KO   $cas : attendu $attendu, obtenu $obtenu\n"; }
}
function requete(string $remote, array $entetes = []) {
    $r = (new ServerRequestFactory())->createServerRequest('GET', '/x', ['REMOTE_ADDR' => $remote]);
    foreach ($entetes as $k => $v) { $r = $r->withHeader($k, $v); }
    return $r;
}

echo "Sans TRUSTED_PROXIES (detection par adresse privee)\n";
unset($_ENV['TRUSTED_PROXIES']);
verifier('client direct, pas d\'en-tete', '203.0.113.9', ClientIp::depuis(requete('203.0.113.9')));
verifier('client direct qui MENT dans X-Forwarded-For', '203.0.113.9',
    ClientIp::depuis(requete('203.0.113.9', ['X-Forwarded-For' => '1.1.1.1'])));
verifier('client direct qui ment dans X-Real-IP', '203.0.113.9',
    ClientIp::depuis(requete('203.0.113.9', ['X-Real-IP' => '1.1.1.1'])));
verifier('derriere un repartiteur interne : derniere adresse de la chaine', '198.51.100.7',
    ClientIp::depuis(requete('10.151.40.2', ['X-Forwarded-For' => '1.1.1.1, 198.51.100.7'])));
verifier('derriere un repartiteur : le client a prefixe une fausse adresse', '198.51.100.7',
    ClientIp::depuis(requete('10.151.40.2', ['X-Forwarded-For' => '9.9.9.9, 8.8.8.8, 198.51.100.7'])));
verifier('derriere un repartiteur : deux mandataires internes en bout de chaine', '198.51.100.7',
    ClientIp::depuis(requete('10.151.40.2', ['X-Forwarded-For' => '198.51.100.7, 10.0.0.5'])));
verifier('derriere un repartiteur, X-Real-IP seulement', '198.51.100.8',
    ClientIp::depuis(requete('172.16.3.4', ['X-Real-IP' => '198.51.100.8'])));
verifier('derriere un repartiteur, rien d\'exploitable', '10.151.40.2',
    ClientIp::depuis(requete('10.151.40.2', ['X-Forwarded-For' => 'pas-une-ip'])));
verifier('REMOTE_ADDR absent', '0.0.0.0', ClientIp::depuis(requete('')));
verifier('IPv6 locale : derriere un mandataire', '2001:db8::1',
    ClientIp::depuis(requete('::1', ['X-Forwarded-For' => '2001:db8::1'])));

echo "Avec TRUSTED_PROXIES\n";
$_ENV['TRUSTED_PROXIES'] = '203.0.113.1, 192.0.2.0/24';
verifier('mandataire declare (IP seule)', '198.51.100.7',
    ClientIp::depuis(requete('203.0.113.1', ['X-Forwarded-For' => '198.51.100.7'])));
verifier('mandataire declare (CIDR)', '198.51.100.7',
    ClientIp::depuis(requete('192.0.2.200', ['X-Forwarded-For' => '5.5.5.5, 198.51.100.7'])));
verifier('adresse privee NON declaree : plus de detection automatique', '10.151.40.2',
    ClientIp::depuis(requete('10.151.40.2', ['X-Forwarded-For' => '198.51.100.7'])));
verifier('client public non declare qui ment', '203.0.113.9',
    ClientIp::depuis(requete('203.0.113.9', ['X-Forwarded-For' => '198.51.100.7'])));
verifier('CIDR : hors du bloc', '192.0.3.1',
    ClientIp::depuis(requete('192.0.3.1', ['X-Forwarded-For' => '198.51.100.7'])));
unset($_ENV['TRUSTED_PROXIES']);

echo "Appartenance a un bloc\n";
verifier('10.0.0.0/8 contient 10.255.255.255', '1', ClientIp::dansLesBlocs('10.255.255.255', ['10.0.0.0/8']) ? '1' : '0');
verifier('172.16.0.0/12 contient 172.31.0.1', '1', ClientIp::dansLesBlocs('172.31.0.1', ['172.16.0.0/12']) ? '1' : '0');
verifier('172.16.0.0/12 exclut 172.32.0.1', '0', ClientIp::dansLesBlocs('172.32.0.1', ['172.16.0.0/12']) ? '1' : '0');
verifier('fc00::/7 contient fd12::1', '1', ClientIp::dansLesBlocs('fd12::1', ['fc00::/7']) ? '1' : '0');
verifier('IPv4 jamais dans un bloc IPv6', '0', ClientIp::dansLesBlocs('10.0.0.1', ['fc00::/7']) ? '1' : '0');

echo "\n$ok ok, $ko KO\n";
exit($ko === 0 ? 0 : 1);
