<?php
// src/Models/RefreshToken.php - Suivi des refresh tokens émis
// (hachés SHA-256, jamais stockés en clair) pour permettre leur
// révocation : logout, rotation au refresh, désactivation de compte.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RefreshToken extends Model
{
    protected $table = 'refresh_tokens';
    public $timestamps = false;

    protected $fillable = ['user_id', 'token_hash', 'expires_at', 'revoked_at', 'created_at'];

    public static function hashFor(string $token): string
    {
        return hash('sha256', $token);
    }

    /** Enregistre un token fraîchement émis. Jamais bloquant. */
    public static function register(int $userId, string $token, int $ttlSeconds): void
    {
        try {
            self::create([
                'user_id' => $userId,
                'token_hash' => self::hashFor($token),
                'expires_at' => date('Y-m-d H:i:s', time() + $ttlSeconds),
                'created_at' => date('Y-m-d H:i:s'),
            ]);
        } catch (\Throwable $e) {
            // L'émission du token ne doit pas échouer à cause du suivi.
            error_log('RefreshToken::register: ' . $e->getMessage());
        }
    }

    /**
     * active  : connu et utilisable ;
     * revoked : connu mais révoqué (logout, rotation, compte désactivé) ;
     * unknown : émis avant la mise en place du suivi (grâce héritée).
     */
    public static function statusOf(string $token): string
    {
        $row = self::where('token_hash', self::hashFor($token))->first();
        if ($row === null) {
            return 'unknown';
        }
        return $row->revoked_at === null ? 'active' : 'revoked';
    }

    public static function revokeToken(string $token): void
    {
        self::where('token_hash', self::hashFor($token))
            ->whereNull('revoked_at')
            ->update(['revoked_at' => date('Y-m-d H:i:s')]);
    }

    public static function revokeAllForUser(int $userId): int
    {
        return self::where('user_id', $userId)
            ->whereNull('revoked_at')
            ->update(['revoked_at' => date('Y-m-d H:i:s')]);
    }
}
