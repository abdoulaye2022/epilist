<?php
// scripts/test_plafonds.php — les plafonds par compte tiennent-ils quand
// l'adresse change a chaque essai ? Sans serveur : le limiteur s'appelle
// directement, avec des identifiants de test qu'on efface a la fin.
//   php scripts/test_plafonds.php

require __DIR__ . '/../vendor/autoload.php';

use App\Services\RateLimiter;

$ok = 0; $ko = 0;
function verifier(string $cas, bool $attendu, bool $obtenu): void {
    global $ok, $ko;
    if ($attendu === $obtenu) { $ok++; echo "  ok   $cas\n"; }
    else { $ko++; echo "  KO   $cas\n"; }
}

$l = new RateLimiter();
$courriel = 'plafond-' . bin2hex(random_bytes(4)) . '@epilist.test';
$nettoyage = [];

foreach (['verification_code' => 5, 'two_factor_verify' => 5, 'admin_otp_verify' => 5,
          'resend_verification' => 3, 'contact_feedback' => 3] as $action => $max) {
    echo "$action : $max essais par compte, quelle que soit l'IP\n";
    $l->resetEmailAttempts($action, $courriel);
    for ($i = 1; $i <= $max; $i++) {
        $ip = "203.0.113.$i";                        // une IP neuve a chaque essai
        verifier("  essai $i depuis $ip autorise", true,
            $l->checkIPLimit($action, $ip) && $l->checkEmailLimit($action, $courriel));
        $l->recordAttempt($action, $ip);
        $l->recordEmailAttempt($action, $courriel);
        $nettoyage[] = [$action, $ip];
    }
    verifier("  essai " . ($max + 1) . " depuis une IP neuve REFUSE par le compte", false,
        $l->checkEmailLimit($action, $courriel));
    verifier("  ...alors que l'IP neuve, elle, passerait encore", true,
        $l->checkIPLimit($action, '203.0.113.250'));
    $l->resetEmailAttempts($action, $courriel);
    verifier("  apres succes, le compte repart a zero", true, $l->checkEmailLimit($action, $courriel));
}

echo "contact_feedback : plafond global, tous expediteurs confondus\n";
// On ne peut pas vider le compteur global sans toucher au fichier : on
// verifie seulement que la methode existe et repond un booleen coherent.
verifier('  checkGlobalLimit repond', true, is_bool($l->checkGlobalLimit('contact_feedback')));
verifier('  une action sans plafond global est toujours autorisee', true, $l->checkGlobalLimit('login'));

echo "la casse du courriel ne cree pas un second compteur\n";
$l->resetEmailAttempts('two_factor_verify', $courriel);
for ($i = 0; $i < 5; $i++) { $l->recordEmailAttempt('two_factor_verify', strtoupper($courriel)); }
verifier('  cinq essais en MAJUSCULES bloquent la version minuscule', false,
    $l->checkEmailLimit('two_factor_verify', $courriel));
$l->resetEmailAttempts('two_factor_verify', $courriel);

foreach ($nettoyage as [$action, $ip]) { $l->resetAttempts($action, $ip); }

echo "\n$ok ok, $ko KO\n";
exit($ko === 0 ? 0 : 1);
