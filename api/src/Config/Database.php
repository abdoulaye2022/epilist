<?php

namespace App\Config;

use Illuminate\Database\Capsule\Manager as Capsule;
use RuntimeException;

class Database
{
    /**
     * Initialise et configure la connexion à la base de données via Eloquent ORM.
     *
     * @throws RuntimeException Si les variables d'environnement requises sont manquantes.
     */
    public static function connect(): void
    {
        // Valider les variables d'environnement requises
        self::validateEnvVariables();

        // Créer une instance de Capsule (gestionnaire de base de données Eloquent)
        $capsule = new Capsule;

        // Configurer la connexion à la base de données
        $capsule->addConnection([
            'driver'    => Config::get('DB_CONNECTION'), // Type de base de données (mysql, pgsql, etc.)
            'host'      => Config::get('DB_HOST'),       // Hôte de la base de données
            'database'  => Config::get('DB_DATABASE'),   // Nom de la base de données
            'username'  => Config::get('DB_USERNAME'),   // Nom d'utilisateur
            'password'  => Config::get('DB_PASSWORD'),   // Mot de passe
            'charset'   => 'utf8',                       // Encodage des caractères
            'collation' => 'utf8_unicode_ci',            // Collation des caractères
            'prefix'    => '',                           // Préfixe des tables (optionnel)
        ]);

        // Rendre la connexion globale (accessible partout dans l'application)
        $capsule->setAsGlobal();

        // Démarrer Eloquent ORM
        $capsule->bootEloquent();
    }

    /**
     * Valide les variables d'environnement requises pour la connexion à la base de données.
     *
     * @throws RuntimeException Si une variable d'environnement requise est manquante.
     */
    private static function validateEnvVariables(): void
    {
        // Liste des variables d'environnement requises
        $requiredEnvVars = [
            'DB_CONNECTION',
            'DB_HOST',
            'DB_PORT',
            'DB_DATABASE',
            'DB_USERNAME',
            // 'DB_PASSWORD', // Optionnel si le mot de passe est vide
        ];

        // Vérifier chaque variable
        foreach ($requiredEnvVars as $envVar) {
            if (empty(Config::get($envVar))) {
                throw new RuntimeException(
                    "La variable d'environnement $envVar est manquante ou vide. Veuillez vérifier votre fichier .env."
                );
            }
        }
    }
}