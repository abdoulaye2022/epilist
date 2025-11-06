<?php
// src/Models/EmailPreference.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmailPreference extends Model
{
    protected $table = 'email_preferences';

    protected $fillable = [
        'user_id',
        'email_verification',
        'password_change_request',
        'password_changed',
        'list_shared_with_me',
        'list_item_added',
        'list_item_checked',
        'list_completed',
        'budget_alert',
        'budget_summary',
        'marketing_emails',
        'product_updates',
        'tips_and_tricks',
        'notification_frequency',
    ];

    protected $casts = [
        'email_verification' => 'boolean',
        'password_change_request' => 'boolean',
        'password_changed' => 'boolean',
        'list_shared_with_me' => 'boolean',
        'list_item_added' => 'boolean',
        'list_item_checked' => 'boolean',
        'list_completed' => 'boolean',
        'budget_alert' => 'boolean',
        'budget_summary' => 'boolean',
        'marketing_emails' => 'boolean',
        'product_updates' => 'boolean',
        'tips_and_tricks' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Relation avec User
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Obtenir ou créer les préférences pour un utilisateur
     */
    public static function getOrCreateForUser(int $userId): self
    {
        $preferences = self::where('user_id', $userId)->first();

        if (!$preferences) {
            $preferences = self::create(['user_id' => $userId]);
        }

        return $preferences;
    }

    /**
     * Vérifier si un type d'email est activé pour un utilisateur
     */
    public static function isEmailEnabled(int $userId, string $emailType): bool
    {
        $preferences = self::where('user_id', $userId)->first();

        if (!$preferences) {
            // Par défaut, tous les emails sont activés
            return true;
        }

        // Vérifier si le type d'email existe dans les préférences
        if (property_exists($preferences, $emailType)) {
            return (bool) $preferences->$emailType;
        }

        // Si le type n'existe pas, activer par défaut
        return true;
    }

    /**
     * Mettre à jour une préférence spécifique
     */
    public function updatePreference(string $key, $value): bool
    {
        if (in_array($key, $this->fillable)) {
            $this->$key = $value;
            return $this->save();
        }

        return false;
    }

    /**
     * Mettre à jour plusieurs préférences en une fois
     */
    public function updatePreferences(array $preferences): bool
    {
        foreach ($preferences as $key => $value) {
            if (in_array($key, $this->fillable)) {
                $this->$key = $value;
            }
        }

        return $this->save();
    }
}
