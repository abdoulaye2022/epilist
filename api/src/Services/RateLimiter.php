<?php
// src/Services/RateLimiter.php - PROTECTION CONTRE LES BOTS

namespace App\Services;

use Carbon\Carbon;

class RateLimiter
{
    private string $storageDir;

    // Configuration des limites
    private const LIMITS = [
        'registration' => [
            'max_attempts_per_ip' => 3,       // 3 inscriptions max par IP
            'window_minutes' => 60,           // Fenêtre de 60 minutes
            'global_max_per_hour' => 50,      // 50 inscriptions max par heure (tous IPs confondus)
        ],
        'registration_email' => [
            'max_attempts' => 5,              // 5 tentatives max par email
            'window_minutes' => 1440,         // Fenêtre de 24h
        ],
        'verification_code' => [
            'max_attempts' => 5,              // 5 tentatives max de vérification
            'window_minutes' => 30,           // Fenêtre de 30 minutes
        ],
        'password_reset' => [
            'max_attempts_per_ip' => 5,       // 5 tentatives max par IP
            'window_minutes' => 60,           // Fenêtre de 60 minutes
        ]
    ];

    public function __construct()
    {
        $this->storageDir = dirname(__DIR__, 2) . '/storage/rate_limits';

        // Créer le dossier s'il n'existe pas
        if (!is_dir($this->storageDir)) {
            mkdir($this->storageDir, 0755, true);
        }
    }

    /**
     * Vérifier si une action est autorisée pour une IP donnée
     */
    public function checkIPLimit(string $action, string $ipAddress): bool
    {
        if (!isset(self::LIMITS[$action])) {
            error_log("⚠️  [RateLimiter] Action inconnue: {$action}");
            return true; // Par défaut, autoriser si action inconnue
        }

        $config = self::LIMITS[$action];
        $maxAttempts = $config['max_attempts_per_ip'] ?? $config['max_attempts'];
        $windowMinutes = $config['window_minutes'];

        $attempts = $this->getAttempts($action, $ipAddress, $windowMinutes);
        $allowed = count($attempts) < $maxAttempts;

        if (!$allowed) {
            error_log("🚫 [RateLimiter] Limite atteinte pour {$action} - IP: {$ipAddress} ({$maxAttempts} tentatives en {$windowMinutes}min)");
        } else {
            error_log("✅ [RateLimiter] Tentative autorisée pour {$action} - IP: {$ipAddress} (" . count($attempts) . "/{$maxAttempts})");
        }

        return $allowed;
    }

    /**
     * Vérifier si une action est autorisée pour un email donné
     */
    public function checkEmailLimit(string $action, string $email): bool
    {
        if (!isset(self::LIMITS[$action])) {
            return true;
        }

        $config = self::LIMITS[$action];
        $maxAttempts = $config['max_attempts'];
        $windowMinutes = $config['window_minutes'];

        $emailHash = md5(strtolower($email)); // Hash pour la confidentialité
        $attempts = $this->getAttempts($action . '_email', $emailHash, $windowMinutes);
        $allowed = count($attempts) < $maxAttempts;

        if (!$allowed) {
            error_log("🚫 [RateLimiter] Limite atteinte pour {$action} - Email: {$emailHash} ({$maxAttempts} tentatives en {$windowMinutes}min)");
        }

        return $allowed;
    }

    /**
     * Vérifier le nombre global d'inscriptions par heure (anti-spam massif)
     */
    public function checkGlobalRegistrationLimit(): bool
    {
        $config = self::LIMITS['registration'];
        $maxPerHour = $config['global_max_per_hour'];

        $attempts = $this->getGlobalAttempts('registration', 60);
        $allowed = count($attempts) < $maxPerHour;

        if (!$allowed) {
            error_log("🚫 [RateLimiter] Limite GLOBALE atteinte pour les inscriptions ({$maxPerHour}/heure)");
        }

        return $allowed;
    }

    /**
     * Enregistrer une tentative
     */
    public function recordAttempt(string $action, string $identifier): void
    {
        $cacheFile = $this->getCacheFile($action, $identifier);
        $now = Carbon::now('UTC')->getTimestamp();

        // Lire les tentatives existantes
        $attempts = [];
        if (file_exists($cacheFile)) {
            $content = file_get_contents($cacheFile);
            $attempts = $content ? json_decode($content, true) : [];
        }

        // Ajouter la nouvelle tentative
        $attempts[] = $now;

        // Sauvegarder
        file_put_contents($cacheFile, json_encode($attempts));

        error_log("📝 [RateLimiter] Tentative enregistrée pour {$action} - {$identifier}");
    }

    /**
     * Enregistrer une tentative globale
     */
    public function recordGlobalAttempt(string $action): void
    {
        $cacheFile = $this->storageDir . "/{$action}_global.json";
        $now = Carbon::now('UTC')->getTimestamp();

        $attempts = [];
        if (file_exists($cacheFile)) {
            $content = file_get_contents($cacheFile);
            $attempts = $content ? json_decode($content, true) : [];
        }

        $attempts[] = $now;
        file_put_contents($cacheFile, json_encode($attempts));
    }

    /**
     * Obtenir les tentatives récentes
     */
    private function getAttempts(string $action, string $identifier, int $windowMinutes): array
    {
        $cacheFile = $this->getCacheFile($action, $identifier);

        if (!file_exists($cacheFile)) {
            return [];
        }

        $content = file_get_contents($cacheFile);
        $attempts = $content ? json_decode($content, true) : [];

        // Filtrer les tentatives dans la fenêtre de temps
        $cutoff = Carbon::now('UTC')->subMinutes($windowMinutes)->getTimestamp();
        $recentAttempts = array_filter($attempts, function($timestamp) use ($cutoff) {
            return $timestamp > $cutoff;
        });

        // Sauvegarder seulement les tentatives récentes (nettoyage)
        if (count($recentAttempts) !== count($attempts)) {
            file_put_contents($cacheFile, json_encode(array_values($recentAttempts)));
        }

        return $recentAttempts;
    }

    /**
     * Obtenir les tentatives globales récentes
     */
    private function getGlobalAttempts(string $action, int $windowMinutes): array
    {
        $cacheFile = $this->storageDir . "/{$action}_global.json";

        if (!file_exists($cacheFile)) {
            return [];
        }

        $content = file_get_contents($cacheFile);
        $attempts = $content ? json_decode($content, true) : [];

        $cutoff = Carbon::now('UTC')->subMinutes($windowMinutes)->getTimestamp();
        $recentAttempts = array_filter($attempts, function($timestamp) use ($cutoff) {
            return $timestamp > $cutoff;
        });

        if (count($recentAttempts) !== count($attempts)) {
            file_put_contents($cacheFile, json_encode(array_values($recentAttempts)));
        }

        return $recentAttempts;
    }

    /**
     * Obtenir le chemin du fichier cache
     */
    private function getCacheFile(string $action, string $identifier): string
    {
        // Hasher l'identifiant pour la confidentialité et éviter problèmes de noms de fichiers
        $hash = md5($identifier);
        return $this->storageDir . "/{$action}_{$hash}.json";
    }

    /**
     * Obtenir le temps restant avant de pouvoir réessayer (en secondes)
     */
    public function getRetryAfter(string $action, string $identifier): int
    {
        if (!isset(self::LIMITS[$action])) {
            return 0;
        }

        $config = self::LIMITS[$action];
        $windowMinutes = $config['window_minutes'];

        $attempts = $this->getAttempts($action, $identifier, $windowMinutes);

        if (empty($attempts)) {
            return 0;
        }

        // Le temps d'attente est calculé depuis la première tentative
        $firstAttempt = min($attempts);
        $windowEndTime = $firstAttempt + ($windowMinutes * 60);
        $now = Carbon::now('UTC')->getTimestamp();

        $retryAfter = max(0, $windowEndTime - $now);

        return $retryAfter;
    }

    /**
     * Réinitialiser les tentatives pour un identifiant (utile après succès)
     */
    public function resetAttempts(string $action, string $identifier): void
    {
        $cacheFile = $this->getCacheFile($action, $identifier);

        if (file_exists($cacheFile)) {
            unlink($cacheFile);
            error_log("🔄 [RateLimiter] Tentatives réinitialisées pour {$action} - {$identifier}");
        }
    }

    /**
     * Vérifier si une IP est suspecte (pattern de bot)
     */
    public function isSuspiciousIP(string $ipAddress): bool
    {
        // Vérifier si l'IP a des tentatives sur plusieurs actions en peu de temps
        $actions = ['registration', 'password_reset', 'verification_code'];
        $suspiciousCount = 0;

        foreach ($actions as $action) {
            $attempts = $this->getAttempts($action, $ipAddress, 10); // 10 dernières minutes
            if (count($attempts) >= 3) {
                $suspiciousCount++;
            }
        }

        // Si l'IP a 2+ actions différentes avec beaucoup de tentatives = suspect
        $suspicious = $suspiciousCount >= 2;

        if ($suspicious) {
            error_log("⚠️  [RateLimiter] IP SUSPECTE détectée: {$ipAddress}");
        }

        return $suspicious;
    }

    /**
     * Bloquer temporairement une IP (ban de 1 heure)
     */
    public function blockIP(string $ipAddress, int $durationMinutes = 60): void
    {
        $cacheFile = $this->storageDir . "/blocked_" . md5($ipAddress) . ".txt";
        $unblockTime = Carbon::now('UTC')->addMinutes($durationMinutes)->getTimestamp();

        file_put_contents($cacheFile, $unblockTime);
        error_log("🔒 [RateLimiter] IP bloquée pour {$durationMinutes}min: {$ipAddress}");
    }

    /**
     * Vérifier si une IP est bloquée
     */
    public function isIPBlocked(string $ipAddress): bool
    {
        $cacheFile = $this->storageDir . "/blocked_" . md5($ipAddress) . ".txt";

        if (!file_exists($cacheFile)) {
            return false;
        }

        $unblockTime = (int)file_get_contents($cacheFile);
        $now = Carbon::now('UTC')->getTimestamp();

        if ($now >= $unblockTime) {
            // Le ban a expiré, supprimer le fichier
            unlink($cacheFile);
            error_log("🔓 [RateLimiter] IP débloquée: {$ipAddress}");
            return false;
        }

        error_log("🚫 [RateLimiter] IP toujours bloquée: {$ipAddress}");
        return true;
    }

    /**
     * Nettoyer les anciens fichiers (maintenance)
     */
    public function cleanup(): void
    {
        $files = glob($this->storageDir . '/*.json');
        $deleted = 0;

        foreach ($files as $file) {
            // Supprimer les fichiers de plus de 7 jours
            if (filemtime($file) < time() - (7 * 24 * 60 * 60)) {
                unlink($file);
                $deleted++;
            }
        }

        if ($deleted > 0) {
            error_log("🧹 [RateLimiter] Nettoyage: {$deleted} fichiers supprimés");
        }
    }
}
