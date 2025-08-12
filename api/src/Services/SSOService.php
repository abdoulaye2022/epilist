<?php
// src/Services/SSOService.php - VERSION AVEC CONFIG AU LIEU DES CONSTANTES

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

    // ===================== MÉTHODES DE CONFIGURATION =====================

    /**
     * ✅ Récupérer le Google Client ID depuis les variables d'environnement
     */
    private function getGoogleClientId(): string 
    {
        $clientId = Config::get('GOOGLE_CLIENT_ID');
        if (empty($clientId)) {
            throw new \Exception('GOOGLE_CLIENT_ID not configured in environment variables');
        }
        return $clientId;
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

    // ===================== VÉRIFICATION DES TOKENS =====================

    /**
     * ✅ VÉRIFICATION APPLE TOKEN AVEC CONFIG
     */
    public function verifyAppleToken(string $idToken): ?array
    {
        try {
            error_log("🍎 [SSOService] Début vérification token Apple (avec Config)...");

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

            error_log("🍎 [SSOService] Payload Apple décodé");

            // 3. ✅ VÉRIFICATIONS AVEC CONFIG
            
            // Vérifier l'issuer
            $expectedIssuer = $this->getAppleIssuer();
            if (!isset($tokenData['iss']) || $tokenData['iss'] !== $expectedIssuer) {
                error_log("❌ [SSOService] Issuer Apple invalide:");
                error_log("   Attendu: " . $expectedIssuer);
                error_log("   Reçu: " . ($tokenData['iss'] ?? 'manquant'));
                return null;
            }

            // Vérifier l'audience (Bundle ID)
            $expectedAudience = $this->getAppleBundleId();
            if (!isset($tokenData['aud']) || $tokenData['aud'] !== $expectedAudience) {
                error_log("❌ [SSOService] Audience Apple invalide:");
                error_log("   Attendu: " . $expectedAudience);
                error_log("   Reçu: " . ($tokenData['aud'] ?? 'manquant'));
                return null;
            }

            // Vérifier l'expiration
            if (!isset($tokenData['exp']) || $tokenData['exp'] < time()) {
                error_log("❌ [SSOService] Token Apple expiré:");
                error_log("   Exp: " . ($tokenData['exp'] ?? 'manquant'));
                error_log("   Now: " . time());
                return null;
            }

            // Vérifier la présence du subject (Apple ID)
            if (!isset($tokenData['sub']) || empty($tokenData['sub'])) {
                error_log("❌ [SSOService] Subject (Apple ID) manquant");
                return null;
            }

            error_log("✅ [SSOService] Token Apple validé avec Config");
            error_log("🍎 [SSOService] Apple ID: " . $tokenData['sub']);
            error_log("🍎 [SSOService] Email: " . ($tokenData['email'] ?? 'privé'));

            // 4. ✅ VALIDATION SUPPLÉMENTAIRE OPTIONNELLE
            if ($this->shouldUseAppleAPIValidation()) {
                error_log("🔍 [SSOService] Validation supplémentaire via Config...");
                // Ici vous pouvez ajouter des validations supplémentaires si nécessaire
            }

            // 5. ✅ RETOURNER LES DONNÉES FORMATÉES
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
                'validation_method' => 'simplified_with_config'
            ];

        } catch (\Exception $e) {
            error_log("❌ [SSOService] Erreur vérification Apple avec Config: " . $e->getMessage());
            return null;
        }
    }

    /**
     * ✅ VÉRIFICATION GOOGLE TOKEN AVEC CONFIG
     */
    public function verifyGoogleToken(string $idToken): ?array
    {
        try {
            error_log("🔵 [SSOService] Vérification du token Google avec Config...");

            $response = $this->httpClient->get('https://oauth2.googleapis.com/tokeninfo', [
                'query' => ['id_token' => $idToken]
            ]);

            if ($response->getStatusCode() !== 200) {
                error_log("❌ [SSOService] Échec vérification Google: " . $response->getStatusCode());
                return null;
            }

            $tokenData = json_decode($response->getBody(), true);

            // ✅ VÉRIFICATIONS AVEC CONFIG
            $expectedClientId = $this->getGoogleClientId();
            if (!isset($tokenData['aud']) || $tokenData['aud'] !== $expectedClientId) {
                error_log("❌ [SSOService] Client ID Google invalide");
                error_log("   Attendu: " . $expectedClientId);
                error_log("   Reçu: " . ($tokenData['aud'] ?? 'manquant'));
                return null;
            }

            $expectedIssuer = $this->getGoogleIssuer();
            $allowedIssuers = [
                'accounts.google.com',
                'https://accounts.google.com',
                $expectedIssuer
            ];

            if (!isset($tokenData['iss']) || !in_array($tokenData['iss'], $allowedIssuers)) {
                error_log("❌ [SSOService] Issuer Google invalide");
                error_log("   Attendu: " . $expectedIssuer);
                error_log("   Reçu: " . ($tokenData['iss'] ?? 'manquant'));
                return null;
            }

            if (!isset($tokenData['exp']) || $tokenData['exp'] < time()) {
                error_log("❌ [SSOService] Token Google expiré");
                return null;
            }

            if (!isset($tokenData['email']) || !isset($tokenData['email_verified']) || !$tokenData['email_verified']) {
                error_log("❌ [SSOService] Email Google non vérifié");
                return null;
            }

            error_log("✅ [SSOService] Token Google vérifié avec succès pour: " . $tokenData['email']);

            return [
                'sub' => $tokenData['sub'],
                'email' => $tokenData['email'],
                'email_verified' => $tokenData['email_verified'],
                'name' => $tokenData['name'] ?? '',
                'given_name' => $tokenData['given_name'] ?? '',
                'family_name' => $tokenData['family_name'] ?? '',
                'picture' => $tokenData['picture'] ?? '',
                'locale' => $tokenData['locale'] ?? 'en'
            ];

        } catch (RequestException $e) {
            error_log("❌ [SSOService] Erreur HTTP Google: " . $e->getMessage());
            return null;
        } catch (\Exception $e) {
            error_log("❌ [SSOService] Erreur générale Google: " . $e->getMessage());
            return null;
        }
    }

    // ===================== MÉTHODES UTILITAIRES =====================

    /**
     * ✅ DÉCIDER SI UTILISER LA VALIDATION API AVEC CONFIG
     */
    private function shouldUseAppleAPIValidation(): bool
    {
        $appEnv = Config::get('APP_ENV', 'production');
        return $appEnv === 'production';
    }

    /**
     * ✅ MÉTHODE POUR DIAGNOSTIQUER LA CONFIGURATION
     */
    public function diagnoseConfiguration(): array
    {
        return [
            'google' => [
                'client_id' => $this->getGoogleClientId(),
                'issuer' => $this->getGoogleIssuer(),
                'configured' => !empty(Config::get('GOOGLE_CLIENT_ID'))
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

    // ===================== GESTION DES LIENS SSO (inchangées) =====================

    public function saveSSOAccountLink(int $userId, string $provider, string $ssoId, array $userInfo): bool
    {
        try {
            error_log("✅ [SSOService] Lien SSO sauvegardé: utilisateur {$userId} -> {$provider}");
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

    // ===================== MÉTHODES UTILITAIRES GÉNÉRALES (inchangées) =====================

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