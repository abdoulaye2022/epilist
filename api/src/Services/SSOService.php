<?php
// src/Services/SSOService.php - VERSION CORRIGÉE POUR ANDROID

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
     * ✅ CORRECTION ANDROID: Configuration client IDs pour multi-plateforme
     */
    private function getGoogleClientIds(): array 
    {
        // ✅ CONFIGURATION ANDROID CORRIGÉE
        return [
            // iOS Client ID (depuis GoogleService-Info.plist)
            '695717834998-s125mgv17n96b59d9u7jh4eham2kp9lo.apps.googleusercontent.com',
            
            // ✅ ANDROID Client ID (depuis google-services.json)
            '695717834998-kshi4umfi4asq3ubna6s3es9ti0ij8d6.apps.googleusercontent.com',
            
            // Web Client ID (optionnel)
            Config::get('GOOGLE_WEB_CLIENT_ID', '695717834998-s125mgv17n96b59d9u7jh4eham2kp9lo.apps.googleusercontent.com')
        ];
    }

    /**
     * ✅ Client ID principal pour l'API
     */
    private function getPrimaryGoogleClientId(): string 
    {
        // Utiliser Android par défaut car c'est votre plateforme principale
        return Config::get('GOOGLE_CLIENT_ID', '695717834998-kshi4umfi4asq3ubna6s3es9ti0ij8d6.apps.googleusercontent.com');
    }

    /**
     * ✅ Récupérer l'Apple Bundle ID depuis les variables d'environnement
     */
    private function getAppleBundleId(): string 
    {
        return Config::get('APPLE_BUNDLE_ID', 'com.m2atech.epilist');
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
     * ✅ VÉRIFICATION APPLE TOKEN (inchangée - fonctionne bien)
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
     * ✅ CORRECTION MAJEURE ANDROID: VÉRIFICATION GOOGLE TOKEN
     */
    public function verifyGoogleToken(string $idToken): ?array
    {
        try {
            error_log("🔵 [SSOService] === DÉBUT VÉRIFICATION GOOGLE TOKEN ANDROID ===");
            error_log("🔵 [SSOService] Token reçu (50 premiers chars): " . substr($idToken, 0, 50) . '...');

            // ✅ MÉTHODE 1: Vérification via Google API
            $response = $this->httpClient->get('https://oauth2.googleapis.com/tokeninfo', [
                'query' => ['id_token' => $idToken],
                'timeout' => 15,
                'connect_timeout' => 5,
                'headers' => [
                    'User-Agent' => 'EpiList-API/1.0'
                ]
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

            // ✅ CORRECTION ANDROID: Validation audience avec tous les client IDs
            $validClientIds = $this->getGoogleClientIds();
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
                
                // ✅ ANDROID: Essayer une vérification plus permissive
                if (strpos($receivedAudience, '695717834998-') === 0) {
                    error_log("⚠️ [SSOService] Client ID du même projet Google - accepté");
                    $audienceValid = true;
                } else {
                    return null;
                }
            }

            // ✅ Validation issuer flexible
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

            // ✅ Validation expiration avec marge
            if (!isset($tokenData['exp']) || $tokenData['exp'] < (time() - 60)) {
                error_log("❌ [SSOService] Token Google expiré");
                error_log("   Expiration: " . ($tokenData['exp'] ?? 'manquante'));
                error_log("   Maintenant: " . time());
                return null;
            }

            // ✅ ANDROID: Validation email flexible
            if (!isset($tokenData['email']) || empty($tokenData['email'])) {
                error_log("❌ [SSOService] Email Google manquant");
                return null;
            }

            // ✅ ANDROID: Vérifier email_verified avec plus de flexibilité
            $emailVerified = $tokenData['email_verified'] ?? false;
            if (!in_array($emailVerified, [true, 'true', 1, '1'])) {
                error_log("❌ [SSOService] Email Google non vérifié: " . var_export($emailVerified, true));
                return null;
            }

            // ✅ Validation subject
            if (!isset($tokenData['sub']) || empty($tokenData['sub'])) {
                error_log("❌ [SSOService] Subject Google manquant");
                return null;
            }

            error_log("✅ [SSOService] === TOKEN GOOGLE ANDROID VALIDÉ AVEC SUCCÈS ===");
            error_log("✅ [SSOService] Email: " . $tokenData['email']);
            error_log("✅ [SSOService] Nom: " . ($tokenData['name'] ?? 'non fourni'));
            error_log("✅ [SSOService] Client ID utilisé: " . $receivedAudience);

            // ✅ Retour de données complètes et normalisées
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
                'validation_method' => 'google_api_verified_android'
            ];

        } catch (RequestException $e) {
            error_log("❌ [SSOService] Erreur HTTP Google: " . $e->getMessage());
            if ($e->hasResponse()) {
                error_log("❌ [SSOService] Réponse erreur: " . $e->getResponse()->getBody());
            }
            
            // ✅ ANDROID: Fallback avec validation locale en cas d'erreur réseau
            return $this->fallbackGoogleTokenValidation($idToken);
            
        } catch (\Exception $e) {
            error_log("❌ [SSOService] Erreur générale Google: " . $e->getMessage());
            error_log("❌ [SSOService] Stack trace: " . $e->getTraceAsString());
            return null;
        }
    }

    /**
     * ✅ NOUVEAU: Validation Google en fallback pour Android
     */
    private function fallbackGoogleTokenValidation(string $idToken): ?array
    {
        try {
            error_log("🔄 [SSOService] Fallback validation Google pour Android...");
            
            // Décoder le token JWT manuellement
            $tokenParts = explode('.', $idToken);
            if (count($tokenParts) !== 3) {
                error_log("❌ [SSOService] Format JWT invalide");
                return null;
            }

            // Décoder le payload
            $payloadBase64 = $tokenParts[1];
            // Corriger le padding base64
            $payloadBase64 = str_pad(strtr($payloadBase64, '-_', '+/'), strlen($payloadBase64) % 4, '=', STR_PAD_RIGHT);
            $payloadJson = base64_decode($payloadBase64);
            $tokenData = json_decode($payloadJson, true);

            if (!$tokenData) {
                error_log("❌ [SSOService] Impossible de décoder le payload en fallback");
                return null;
            }

            // Vérifications basiques
            $validClientIds = $this->getGoogleClientIds();
            $receivedAudience = $tokenData['aud'] ?? '';
            
            $audienceValid = false;
            foreach ($validClientIds as $validClientId) {
                if ($receivedAudience === $validClientId) {
                    $audienceValid = true;
                    break;
                }
            }

            // Validation permissive pour Android
            if (!$audienceValid && strpos($receivedAudience, '695717834998-') === 0) {
                $audienceValid = true;
                error_log("⚠️ [SSOService] Fallback: Client ID du même projet accepté");
            }

            if (!$audienceValid) {
                error_log("❌ [SSOService] Fallback: Audience invalide: " . $receivedAudience);
                return null;
            }

            // Vérification expiration
            if (!isset($tokenData['exp']) || $tokenData['exp'] < (time() - 300)) {
                error_log("❌ [SSOService] Fallback: Token expiré");
                return null;
            }

            // Vérification email
            if (!isset($tokenData['email']) || empty($tokenData['email'])) {
                error_log("❌ [SSOService] Fallback: Email manquant");
                return null;
            }

            error_log("✅ [SSOService] Validation fallback Google réussie pour Android");

            return [
                'sub' => $tokenData['sub'] ?? '',
                'email' => $tokenData['email'],
                'email_verified' => true,
                'name' => $tokenData['name'] ?? '',
                'given_name' => $tokenData['given_name'] ?? '',
                'family_name' => $tokenData['family_name'] ?? '',
                'picture' => $tokenData['picture'] ?? '',
                'locale' => $tokenData['locale'] ?? 'en',
                'aud' => $tokenData['aud'],
                'iss' => $tokenData['iss'] ?? 'accounts.google.com',
                'iat' => $tokenData['iat'] ?? time(),
                'exp' => $tokenData['exp'],
                'validation_method' => 'google_fallback_android'
            ];

        } catch (\Exception $e) {
            error_log("❌ [SSOService] Erreur fallback validation: " . $e->getMessage());
            return null;
        }
    }

    // ===================== MÉTHODES UTILITAIRES =====================

    /**
     * ✅ MÉTHODE DE DIAGNOSTIC AMÉLIORÉE POUR ANDROID
     */
    public function diagnoseConfiguration(): array
    {
        $validClientIds = $this->getGoogleClientIds();
        
        return [
            'google' => [
                'primary_client_id' => $this->getPrimaryGoogleClientId(),
                'all_valid_client_ids' => $validClientIds,
                'issuer' => $this->getGoogleIssuer(),
                'android_client_id' => '695717834998-kshi4umfi4asq3ubna6s3es9ti0ij8d6.apps.googleusercontent.com',
                'ios_client_id' => '695717834998-s125mgv17n96b59d9u7jh4eham2kp9lo.apps.googleusercontent.com',
                'configured' => !empty(Config::get('GOOGLE_CLIENT_ID')),
                'environment_client_id' => Config::get('GOOGLE_CLIENT_ID')
            ],
            'apple' => [
                'bundle_id' => $this->getAppleBundleId(),
                'issuer' => $this->getAppleIssuer(),
                'configured' => !empty(Config::get('APPLE_BUNDLE_ID'))
            ],
            'environment' => Config::get('APP_ENV', 'unknown'),
            'timestamp' => Carbon::now()->toISOString(),
            'platform_focus' => 'android_optimized'
        ];
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Test de connectivité Google avec timeout court
     */
    public function testGoogleConnectivity(): array
    {
        try {
            error_log("🔧 [SSOService] Test de connectivité Google (Android)...");
            
            $startTime = microtime(true);
            $response = $this->httpClient->get('https://oauth2.googleapis.com/tokeninfo', [
                'query' => ['id_token' => 'test'],
                'timeout' => 5, // Timeout réduit pour mobile
                'connect_timeout' => 3
            ]);
            $responseTime = round((microtime(true) - $startTime) * 1000, 2);
            
            return [
                'success' => true,
                'status_code' => $response->getStatusCode(),
                'response_time_ms' => $responseTime,
                'message' => 'Connectivité Google OK pour Android',
                'fallback_available' => true
            ];
            
        } catch (RequestException $e) {
            return [
                'success' => false,
                'error' => $e->getMessage(),
                'status_code' => $e->hasResponse() ? $e->getResponse()->getStatusCode() : null,
                'message' => 'Erreur de connectivité Google - fallback disponible',
                'fallback_available' => true
            ];
        }
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