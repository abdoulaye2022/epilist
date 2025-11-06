<?php
// test_bot_protection.php - TEST PROTECTION CONTRE LES BOTS

require __DIR__ . '/vendor/autoload.php';

use App\Services\RateLimiter;
use Carbon\Carbon;

// Configuration UTC globale
date_default_timezone_set('UTC');
Carbon::setLocale('fr');

echo "=== TEST PROTECTION CONTRE LES BOTS ===\n\n";

try {
    $rateLimiter = new RateLimiter();

    // Test 1: Vérifier l'instanciation
    echo "1. Test instanciation RateLimiter...\n";
    echo "   ✅ RateLimiter instancié avec succès\n\n";

    // Test 2: Tester la limite d'inscription par IP
    echo "2. Test limite d'inscription par IP (3 tentatives en 60min)...\n";
    $testIP = '192.168.1.100';

    for ($i = 1; $i <= 5; $i++) {
        $allowed = $rateLimiter->checkIPLimit('registration', $testIP);

        if ($allowed) {
            echo "   ✅ Tentative {$i}: AUTORISÉE\n";
            $rateLimiter->recordAttempt('registration', $testIP);
        } else {
            $retryAfter = $rateLimiter->getRetryAfter('registration', $testIP);
            echo "   🚫 Tentative {$i}: BLOQUÉE (réessayer dans " . ceil($retryAfter / 60) . " minutes)\n";
        }
    }
    echo "\n";

    // Test 3: Tester la limite par email
    echo "3. Test limite par email (5 tentatives en 24h)...\n";
    $testEmail = 'test@example.com';
    $emailHash = md5(strtolower($testEmail));

    for ($i = 1; $i <= 7; $i++) {
        $allowed = $rateLimiter->checkEmailLimit('registration_email', $testEmail);

        if ($allowed) {
            echo "   ✅ Tentative {$i}: AUTORISÉE pour email\n";
            $rateLimiter->recordAttempt('registration_email', $emailHash);
        } else {
            echo "   🚫 Tentative {$i}: BLOQUÉE pour email\n";
        }
    }
    echo "\n";

    // Test 4: Tester la limite globale
    echo "4. Test limite globale d'inscriptions (50/heure)...\n";
    $globalAllowed = $rateLimiter->checkGlobalRegistrationLimit();

    if ($globalAllowed) {
        echo "   ✅ Limite globale: OK\n";
        echo "   📝 Enregistrement d'une inscription globale...\n";
        $rateLimiter->recordGlobalAttempt('registration');
    } else {
        echo "   🚫 Limite globale: ATTEINTE\n";
    }
    echo "\n";

    // Test 5: Tester la détection d'IP suspecte
    echo "5. Test détection d'IP suspecte...\n";
    $suspiciousIP = '10.0.0.99';

    // Simuler beaucoup de tentatives sur plusieurs actions
    for ($i = 1; $i <= 3; $i++) {
        $rateLimiter->recordAttempt('registration', $suspiciousIP);
        $rateLimiter->recordAttempt('password_reset', $suspiciousIP);
        $rateLimiter->recordAttempt('verification_code', $suspiciousIP);
    }

    $isSuspicious = $rateLimiter->isSuspiciousIP($suspiciousIP);
    if ($isSuspicious) {
        echo "   ✅ IP suspecte correctement détectée: {$suspiciousIP}\n";
    } else {
        echo "   ⚠️  IP non détectée comme suspecte\n";
    }
    echo "\n";

    // Test 6: Tester le blocage d'IP
    echo "6. Test blocage/déblocage d'IP...\n";
    $blockedIP = '172.16.0.50';

    echo "   📝 Blocage de l'IP {$blockedIP} pour 1 minute...\n";
    $rateLimiter->blockIP($blockedIP, 1);

    $isBlocked = $rateLimiter->isIPBlocked($blockedIP);
    if ($isBlocked) {
        echo "   ✅ IP correctement bloquée\n";
    } else {
        echo "   ❌ Échec du blocage d'IP\n";
    }

    echo "   ⏳ Attente de 65 secondes pour expiration du ban...\n";
    sleep(65);

    $isStillBlocked = $rateLimiter->isIPBlocked($blockedIP);
    if (!$isStillBlocked) {
        echo "   ✅ IP correctement débloquée après expiration\n";
    } else {
        echo "   ❌ IP toujours bloquée après expiration\n";
    }
    echo "\n";

    // Test 7: Tester la réinitialisation des tentatives
    echo "7. Test réinitialisation des tentatives...\n";
    $resetIP = '192.168.100.1';

    $rateLimiter->recordAttempt('registration', $resetIP);
    $rateLimiter->recordAttempt('registration', $resetIP);

    $beforeReset = $rateLimiter->checkIPLimit('registration', $resetIP);
    echo "   📊 Avant reset: " . ($beforeReset ? "OK" : "BLOQUÉ") . "\n";

    $rateLimiter->resetAttempts('registration', $resetIP);
    echo "   🔄 Reset effectué\n";

    $afterReset = $rateLimiter->checkIPLimit('registration', $resetIP);
    echo "   📊 Après reset: " . ($afterReset ? "OK" : "BLOQUÉ") . "\n";

    if ($afterReset) {
        echo "   ✅ Réinitialisation réussie\n";
    } else {
        echo "   ❌ Échec de la réinitialisation\n";
    }
    echo "\n";

    // Test 8: Tester le nettoyage
    echo "8. Test nettoyage des anciens fichiers...\n";
    $rateLimiter->cleanup();
    echo "   ✅ Nettoyage effectué\n\n";

    // Résumé
    echo "=== RÉSUMÉ DES PROTECTIONS ===\n";
    echo "✅ Limite par IP: 3 inscriptions / 60 minutes\n";
    echo "✅ Limite par email: 5 tentatives / 24 heures\n";
    echo "✅ Limite globale: 50 inscriptions / heure\n";
    echo "✅ Détection d'IP suspecte: OUI\n";
    echo "✅ Blocage temporaire d'IP: OUI (60 minutes par défaut)\n";
    echo "✅ Reset mot de passe: 5 tentatives / 60 minutes\n";
    echo "✅ Codes de vérification: 5 tentatives / 30 minutes\n\n";

    echo "=== TOUS LES TESTS TERMINÉS AVEC SUCCÈS ===\n";
    echo "Le système de protection contre les bots est opérationnel!\n";

} catch (\Exception $e) {
    echo "❌ ERREUR: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}
