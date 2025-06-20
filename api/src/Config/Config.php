<?php

namespace App\Config;

use Dotenv\Dotenv;

class Config
{
    private static $loaded = false;

    public static function load()
    {
        if (!self::$loaded) {
            $dotenv = Dotenv::createImmutable(__DIR__ . '/../..');
            $dotenv->load();
            self::$loaded = true;
        }
    }

    public static function get($key, $default = null)
    {
        self::load();
        return $_ENV[$key] ?? $default;
    }
}