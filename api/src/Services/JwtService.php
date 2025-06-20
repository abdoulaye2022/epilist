<?php
// src/Services/JwtService.php

namespace App\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\BeforeValidException;
use Firebase\JWT\SignatureInvalidException;
use App\Config\Config;
use InvalidArgumentException;

class JwtService
{
    private string $secretKey;
    private string $algorithm;
    private int $expiration;
    private string $refreshSecretKey;
    private string $refreshAlgorithm;
    private int $refreshExpiration;
    private string $issuer;

    public function __construct()
    {
        $this->secretKey = Config::get('JWT_SECRET');
        $this->algorithm = Config::get('JWT_ALGORITHM') ?? 'HS256';
        $this->expiration = (int) Config::get('JWT_EXPIRATION');
        $this->refreshSecretKey = Config::get('JWT_REFRESH_SECRET');
        $this->refreshAlgorithm = Config::get('JWT_REFRESH_ALGORITHM') ?? 'HS256';
        $this->refreshExpiration = (int) Config::get('JWT_REFRESH_EXPIRATION');
        $this->issuer = Config::get('APP_URL') ?? 'kiloshare-api';

        $this->validateConfiguration();
    }

    /**
     * Validate JWT configuration
     */
    private function validateConfiguration(): void
    {
        if (empty($this->secretKey)) {
            throw new InvalidArgumentException('JWT_SECRET is required');
        }

        if (empty($this->refreshSecretKey)) {
            throw new InvalidArgumentException('JWT_REFRESH_SECRET is required');
        }

        if ($this->expiration <= 0) {
            throw new InvalidArgumentException('JWT_EXPIRATION must be positive');
        }

        if ($this->refreshExpiration <= 0) {
            throw new InvalidArgumentException('JWT_REFRESH_EXPIRATION must be positive');
        }
    }

    /**
     * Generate access token
     */
    public function generateToken(array $payload): string
    {
        if (!isset($payload['auth_id'])) {
            throw new InvalidArgumentException('auth_id is required in payload');
        }

        $now = time();
        $tokenPayload = [
            'iss' => $this->issuer,
            'aud' => $this->issuer,
            'sub' => $payload['auth_id'],
            'iat' => $now,
            'nbf' => $now,
            'exp' => $now + $this->expiration,
            'type' => 'access',
            'data' => $payload
        ];

        return JWT::encode($tokenPayload, $this->secretKey, $this->algorithm);
    }

    /**
     * Generate refresh token
     */
    public function generateRefreshToken(array $payload): string
    {
        if (!isset($payload['auth_id'])) {
            throw new InvalidArgumentException('auth_id is required in payload');
        }

        $now = time();
        $tokenPayload = [
            'iss' => $this->issuer,
            'aud' => $this->issuer,
            'sub' => $payload['auth_id'],
            'iat' => $now,
            'nbf' => $now,
            'exp' => $now + $this->refreshExpiration,
            'type' => 'refresh',
            'data' => $payload
        ];

        return JWT::encode($tokenPayload, $this->refreshSecretKey, $this->refreshAlgorithm);
    }

    /**
     * Validate access token
     */
    public function validateToken(string $token): ?array
    {
        try {
            $decoded = JWT::decode($token, new Key($this->secretKey, $this->algorithm));
            $payload = (array) $decoded;
            
            // Verify token type
            if (($payload['type'] ?? '') !== 'access') {
                return null;
            }

            return $payload;
        } catch (ExpiredException $e) {
            error_log('JWT expired: ' . $e->getMessage());
            return null;
        } catch (BeforeValidException $e) {
            error_log('JWT not yet valid: ' . $e->getMessage());
            return null;
        } catch (SignatureInvalidException $e) {
            error_log('JWT signature invalid: ' . $e->getMessage());
            return null;
        } catch (\Exception $e) {
            error_log('JWT validation error: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Validate refresh token
     */
    public function validateRefreshToken(string $token): ?array
    {
        try {
            $decoded = JWT::decode($token, new Key($this->refreshSecretKey, $this->refreshAlgorithm));
            $payload = (array) $decoded;
            
            // Verify token type
            if (($payload['type'] ?? '') !== 'refresh') {
                return null;
            }

            return $payload;
        } catch (ExpiredException $e) {
            error_log('Refresh token expired: ' . $e->getMessage());
            return null;
        } catch (BeforeValidException $e) {
            error_log('Refresh token not yet valid: ' . $e->getMessage());
            return null;
        } catch (SignatureInvalidException $e) {
            error_log('Refresh token signature invalid: ' . $e->getMessage());
            return null;
        } catch (\Exception $e) {
            error_log('Refresh token validation error: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Extract user ID from token payload
     */
    public function getUserIdFromPayload(array $payload): ?int
    {
        return $payload['data']->auth_id ?? $payload['data']->auth_id ?? null;
    }
}