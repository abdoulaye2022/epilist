<?php
// src/Models/AppVersion.php - Configuration de version par plateforme
// (une ligne ios, une ligne android — jamais plus).

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppVersion extends Model
{
    protected $table = 'app_versions';

    protected $fillable = [
        'platform',
        'current_version',
        'minimum_version',
        'message_fr',
        'message_en',
        'store_url',
        'force_update',
        'active',
        'stats_updated',
        'stats_dismissed',
    ];

    protected $casts = [
        'force_update' => 'boolean',
        'active' => 'boolean',
        'stats_updated' => 'integer',
        'stats_dismissed' => 'integer',
    ];
}
