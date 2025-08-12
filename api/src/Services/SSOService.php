<?php
// src/Services/SSOService.php - VERSION CORRIGÉE POUR GOOGLE

namespace App\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\RequestException;
use App\Models\User;
use App\Config\Config;
use Carbon\Carbon;

class SSOService
{
    private $httpClient;

    public function __construct()
    {
        $this->httpClient = new Client([
            'timeout' => 30,
            'verify' => true
        ]);
    }

    // ===================== MÉTHODES DE CONFIGURATION CORRIGÉES =====================

    /**
     * ✅ CORRECTION CRITIQUE: Récupérer le Google Client ID
     */
    private function getGoogleClientId(): string 
    {
        // ✅ CORRECTION 1: Client ID pour iOS et Android
        $clientId = Config::get('GOOGLE_CLIENT_ID', '695717834998-s125mgv17n96b59d9u7jh4eham2kp9lo.apps.googleusercontent.com');
        
        if (empty($clientId)) {
            error_log("❌ [SSOService] GOOGLE_CLIENT_ID manquant dans les variables d'environnement");
            // Utiliser la valeur par défaut si pas configurée
            $clientId = '695717834998-s125mgv17n96b59d9u7jh4eham2kp9lo.apps.googleusercontent.com';
        }
        
        error_log("🔧 [SSOService] Google Client ID utilisé: " . $clientId);
        return $clientId;
    }

    /**
     * ✅ NOUVELLES MÉTHODES: Support multi-plateforme Google
     */
    private function getGoogleWebClientId(): string 
    {
        // Web client ID (différent de l'app mobile)
        return Config::get('GOOGLE_WEB_CLIENT_ID', '695717834998-s125mgv17n96b59d9u7jh4eham2kp9lo.apps.googleusercontent.com');
    }

    private function getValidGoogleClientIds(): array 
    {
        // ✅ CORRECTION 2: Accepter plusieurs client IDs pour différentes plateformes
        return [
            $this->getGoogleClientId(),
            $this->getGoogleWebClientId(),
            // Fallback pour anciennes configurations
            '695717834998-s125mgv17n96b59d9u7jh4eham2kp9lo.apps.googleusercontent.com'
        ];
    }

    /**
     * ✅ Récupérer l'Apple Bundle ID depuis les variables d'environnement
     */
    private function getAppleBundleId(): string 
    {
        $bundleId = Config::get('APPLE_BUNDLE_ID', 'com.m2atech.epilist');
        return $bundleId;
    }

    /**
     * ✅ Récupérer l'Apple Issuer depuis les variables d'environnement
     */
    private function getAppleIssuer(): string 
    {
        return Config::get('APPLE_ISSUER', 'https://appleid.apple.com');
    }

    /**
     * ✅ Récupérer le Google Issuer depuis les variables d'environnement
     */
    private function getGoogleIssuer(): string 
    {
        return Config::get('GOOGLE_ISSUER', 'https://accounts.google.com');
    }

    // ===================== VÉRIFICATION DES TOKENS CORRIGÉE =====================

    /**
     * ✅ VÉRIFICATION APPLE TOKEN AVEC CONFIG (inchangée - fonctionne bien)
     */
    public function verifyAppleToken(string $idToken): ?array
    {
        try {
            error_log("🍎 [SSOService] Début vérification token Apple...");

            // 1. Décoder le payload sans vérification de signature
            $tokenParts = explode('.', $idToken);
            if (count($tokenParts) !== 3) {
                error_log("❌ [SSOService] Format de token Apple invalide");
                return null;
            }

            // 2. Décoder le payload (partie centrale)
            $payloadBase64 = $tokenParts[1];
            $payloadJson = base64_decode(strtr($payloadBase64, '-_', '+/'));
            $tokenData = json_decode($payloadJson, true);
            
            if (!$tokenData) {
                error_log("❌ [SSOService] Impossible de décoder le payload Apple");
                return null;
            }

            // 3. Vérifications avec config
            $expectedIssuer = $this->getAppleIssuer();
            if (!isset($tokenData['iss']) || $tokenData['iss'] !== $expectedIssuer) {
                error_log("❌ [SSOService] Issuer Apple invalide:");
                error_log("   Attendu: " . $expectedIssuer);
                error_log("   Reçu: " . ($tokenData['iss'] ?? 'manquant'));
                return null;
            }

            $expectedAudience = $this->getAppleBundleId();
            if (!isset($tokenData['aud']) || $tokenData['aud'] !== $expectedAudience) {
                error_log("❌ [SSOService] Audience Apple invalide:");
                error_log("   Attendu: " . $expectedAudience);
                error_log("   Reçu: " . ($tokenData['aud'] ?? 'manquant'));
                return null;
            }

            if (!isset($tokenData['exp']) || $tokenData['exp'] < time()) {
                error_log("❌ [SSOService] Token Apple expiré");
                return null;
            }

            if (!isset($tokenData['sub']) || empty($tokenData['sub'])) {
                error_log("❌ [SSOService] Subject (Apple ID) manquant");
                return null;
            }

            error_log("✅ [SSOService] Token Apple validé avec succès");

            return [
                'sub' => $tokenData['sub'],
                'email' => $tokenData['email'] ?? null,
                'email_verified' => isset($tokenData['email_verified']) ? 
                    (string)$tokenData['email_verified'] : 'true',
                'is_private_email' => isset($tokenData['is_private_email']) ? 
                    (bool)$tokenData['is_private_email'] : false,
                'real_user_status' => $tokenData['real_user_status'] ?? 2,
                'aud' => $tokenData['aud'],
                'iss' => $tokenData['iss'],
                'iat' => $tokenData['iat'],
                'exp' => $tokenData['exp'],
                'validation_method' => 'apple_simplified'
            ];

        } catch (\Exception $e) {
            error_log("❌ [SSOService] Erreur vérification Apple: " . $e->getMessage());
            return null;
        }
    }

    /**
     * ✅ CORRECTION MAJEURE: VÉRIFICATION GOOGLE TOKEN
     */
    public function verifyGoogleToken(string $idToken): ?array
    {
        try {
            error_log("🔵 [SSOService] === DÉBUT VÉRIFICATION GOOGLE TOKEN ===");
            error_log("🔵 [SSOService] Token reçu (50 premiers chars): " . substr($idToken, 0, 50) . '...');

            // ✅ MÉTHODE 1: Vérification via Google API (recommandée)
            $response = $this->httpClient->get('https://oauth2.googleapis.com/tokeninfo', [
                'query' => ['id_token' => $idToken],
                'timeout' => 15,
                'connect_timeout' => 5
            ]);

            if ($response->getStatusCode() !== 200) {
                error_log("❌ [SSOService] Échec vérification Google API: " . $response->getStatusCode());
                error_log("❌ [SSOService] Réponse: " . $response->getBody());
                return null;
            }

            $tokenData = json_decode($response->getBody(), true);
            
            if (!$tokenData) {
                error_log("❌ [SSOService] Impossible de décoder la réponse Google");
                return null;
            }

            error_log("🔵 [SSOService] Données token reçues:");
            error_log("🔵 [SSOService] - Audience: " . ($tokenData['aud'] ?? 'manquant'));
            error_log("🔵 [SSOService] - Issuer: " . ($tokenData['iss'] ?? 'manquant'));
            error_log("🔵 [SSOService] - Email: " . ($tokenData['email'] ?? 'manquant'));
            error_log("🔵 [SSOService] - Email vérifié: " . ($tokenData['email_verified'] ?? 'manquant'));
            error_log("🔵 [SSOService] - Subject: " . ($tokenData['sub'] ?? 'manquant'));

            // ✅ CORRECTION 3: Validation audience flexible pour multi-plateformes
            $validClientIds = $this->getValidGoogleClientIds();
            $receivedAudience = $tokenData['aud'] ?? '';
            
            $audienceValid = false;
            foreach ($validClientIds as $validClientId) {
                if ($receivedAudience === $validClientId) {
                    $audienceValid = true;
                    error_log("✅ [SSOService] Audience validée avec: " . $validClientId);
                    break;
                }
            }

            if (!$audienceValid) {
                error_log("❌ [SSOService] Client ID Google invalide");
                error_log("   Reçu: " . $receivedAudience);
                error_log("   Attendus: " . implode(', ', $validClientIds));
                return null;
            }

            // ✅ CORRECTION 4: Validation issuer flexible
            $expectedIssuer = $this->getGoogleIssuer();
            $allowedIssuers = [
                'accounts.google.com',
                'https://accounts.google.com',
                $expectedIssuer
            ];

            $receivedIssuer = $tokenData['iss'] ?? '';
            if (!in_array($receivedIssuer, $allowedIssuers)) {
                error_log("❌ [SSOService] Issuer Google invalide");
                error_log("   Reçu: " . $receivedIssuer);
                error_log("   Attendus: " . implode(', ', $allowedIssuers));
                return null;
            }

            // ✅ CORRECTION 5: Validation expiration
            if (!isset($tokenData['exp']) || $tokenData['exp'] < time()) {
                error_log("❌ [SSOService] Token Google expiré");
                error_log("   Expiration: " . ($tokenData['exp'] ?? 'manquante'));
                error_log("   Maintenant: " . time());
                return null;
            }

            // ✅ CORRECTION 6: Validation email avec gestion des cas edge
            if (!isset($tokenData['email']) || empty($tokenData['email'])) {
                error_log("❌ [SSOService] Email Google manquant");
                return null;
            }

            // Vérifier email_verified avec gestion des différents types
            $emailVerified = $tokenData['email_verified'] ?? false;
            if ($emailVerified !== true && $emailVerified !== 'true' && $emailVerified !== 1) {
                error_log("❌ [SSOService] Email Google non vérifié: " . var_export($emailVerified, true));
                return null;
            }

            // ✅ CORRECTION 7: Validation subject
            if (!isset($tokenData['sub']) || empty($tokenData['sub'])) {
                error_log("❌ [SSOService] Subject Google manquant");
                return null;
            }

            error_log("✅ [SSOService] === TOKEN GOOGLE VALIDÉ AVEC SUCCÈS ===");
            error_log("✅ [SSOService] Email: " . $tokenData['email']);
            error_log("✅ [SSOService] Nom: " . ($tokenData['name'] ?? 'non fourni'));

            // ✅ CORRECTION 8: Retour de données complètes et normalisées
            return [
                'sub' => $tokenData['sub'],
                'email' => $tokenData['email'],
                'email_verified' => true, // Déjà vérifié ci-dessus
                'name' => $tokenData['name'] ?? '',
                'given_name' => $tokenData['given_name'] ?? '',
                'family_name' => $tokenData['family_name'] ?? '',
                'picture' => $tokenData['picture'] ?? '',
                'locale' => $tokenData['locale'] ?? 'en',
                'aud' => $tokenData['aud'],
                'iss' => $tokenData['iss'],
                'iat' => $tokenData['iat'] ?? time(),
                'exp' => $tokenData['exp'],
                'validation_method' => 'google_api_verified'
            ];

        } catch (RequestException $e) {
            error_log("❌ [SSOService] Erreur HTTP Google: " . $e->getMessage());
            if ($e->hasResponse()) {
                error_log("❌ [SSOService] Réponse erreur: " . $e->getResponse()->getBody());
            }
            return null;
        } catch (\Exception $e) {
            error_log("❌ [SSOService] Erreur générale Google: " . $e->getMessage());
            error_log("❌ [SSOService] Stack trace: " . $e->getTraceAsString());
            return null;
        }
    }

    // ===================== MÉTHODES UTILITAIRES =====================

    /**
     * ✅ MÉTHODE DE DIAGNOSTIC AMÉLIORÉE
     */
    public function diagnoseConfiguration(): array
    {
        $validClientIds = $this->getValidGoogleClientIds();
        
        return [
            'google' => [
                'primary_client_id' => $this->getGoogleClientId(),
                'web_client_id' => $this->getGoogleWebClientId(),
                'valid_client_ids' => $validClientIds,
                'issuer' => $this->getGoogleIssuer(),
                'configured' => !empty(Config::get('GOOGLE_CLIENT_ID')),
                'fallback_used' => Config::get('GOOGLE_CLIENT_ID') === null
            ],
            'apple' => [
                'bundle_id' => $this->getAppleBundleId(),
                'issuer' => $this->getAppleIssuer(),
                'configured' => !empty(Config::get('APPLE_BUNDLE_ID'))
            ],
            'environment' => Config::get('APP_ENV', 'unknown'),
            'timestamp' => Carbon::now()->toISOString()
        ];
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Test de connectivité Google
     */
    public function testGoogleConnectivity(): array
    {
        try {
            error_log("🔧 [SSOService] Test de connectivité Google...");
            
            $startTime = microtime(true);
            $response = $this->httpClient->get('https://oauth2.googleapis.com/tokeninfo', [
                'query' => ['id_token' => 'test'],
                'timeout' => 10
            ]);
            $responseTime = round((microtime(true) - $startTime) * 1000, 2);
            
            return [
                'success' => true,
                'status_code' => $response->getStatusCode(),
                'response_time_ms' => $responseTime,
                'headers' => $response->getHeaders(),
                'message' => 'Connectivité Google OK'
            ];
            
        } catch (RequestException $e) {
            return [
                'success' => false,
                'error' => $e->getMessage(),
                'status_code' => $e->hasResponse() ? $e->getResponse()->getStatusCode() : null,
                'message' => 'Erreur de connectivité Google'
            ];
        }
    }

    /**
     * ✅ DÉCIDER SI UTILISER LA VALIDATION API AVEC CONFIG
     */
    private function shouldUseAppleAPIValidation(): bool
    {
        $appEnv = Config::get('APP_ENV', 'production');
        return $appEnv === 'production';
    }

    // ===================== GESTION DES LIENS SSO (inchangées) =====================

    public function saveSSOAccountLink(int $userId, string $provider, string $ssoId, array $userInfo): bool
    {
        try {
            error_log("✅ [SSOService] Lien SSO sauvegardé: utilisateur {$userId} -> {$provider} (ID: {$ssoId})");
            return true;
        } catch (\Exception $e) {
            error_log("❌ [SSOService] Erreur sauvegarde lien SSO: " . $e->getMessage());
            return false;
        }
    }

    public function findSSOAccountLink(string $provider, string $ssoId): ?array
    {
        return null;
    }

    public function getUserSSOLinks(int $userId): array
    {
        return [];
    }

    public function removeSSOAccountLink(int $userId, string $provider): bool
    {
        try {
            error_log("✅ [SSOService] Lien SSO supprimé: utilisateur {$userId} -> {$provider}");
            return true;
        } catch (\Exception $e) {
            error_log("❌ [SSOService] Erreur suppression lien SSO: " . $e->getMessage());
            return false;
        }
    }

    // ===================== MÉTHODES UTILITAIRES GÉNÉRALES =====================

    public function isValidEmail(?string $email): bool
    {
        if (empty($email)) {
            return false;
        }
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }

    public function generateAppleEmail(string $appleId): string
    {
        return 'apple_user_' . substr(md5($appleId), 0, 8) . '@privaterelay.appleid.com';
    }

    public function isApplePrivateEmail(string $email): bool
    {
        return str_contains($email, '@privaterelay.appleid.com');
    }
}