<?php
// app/Models/UserDevice.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class UserDevice extends Model
{
    use SoftDeletes;

    protected $table = 'user_devices';
    protected $primaryKey = 'id';
    public $timestamps = true;

    const PLATFORM_ANDROID = 'android';
    const PLATFORM_IOS = 'ios';

    protected $fillable = [
        'user_id',
        'device_id',
        'platform',
        'push_token',
        'app_version',
        'os_version',
        'device_model',
        'is_active',
        'last_active_at',
        'created_at',
        'updated_at',
        'deleted_at'
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'last_active_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
    ];

    protected $attributes = [
        'is_active' => true
    ];

    /**
     *  RELATIONS
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     *  VALIDATION RULES
     */
    public static function getValidationRules(): array
    {
        return [
            'device_id' => [
                'required' => 'Device ID is required',
                'lengthMax' => ['255', 'Device ID cannot exceed 255 characters']
            ],
            'platform' => [
                'required' => 'Platform is required',
                'in' => [['android', 'ios'], 'Platform must be android or ios']
            ],
            'push_token' => [
                'required' => 'Push token is required',
                'lengthMax' => ['512', 'Push token cannot exceed 512 characters']
            ],
            'app_version' => [
                'lengthMax' => ['50', 'App version cannot exceed 50 characters']
            ],
            'os_version' => [
                'lengthMax' => ['50', 'OS version cannot exceed 50 characters']
            ],
            'device_model' => [
                'lengthMax' => ['100', 'Device model cannot exceed 100 characters']
            ]
        ];
    }

    /**
     *  ENREGISTRER OU METTRE À JOUR UN APPAREIL
     */
    public static function registerDevice(array $deviceData): self
    {
        // Chercher un appareil existant avec le même device_id et user_id
        $existingDevice = self::where('user_id', $deviceData['user_id'])
            ->where('device_id', $deviceData['device_id'])
            ->first();

        if ($existingDevice) {
            // Mettre à jour l'appareil existant
            $existingDevice->update([
                'push_token' => $deviceData['push_token'],
                'platform' => $deviceData['platform'],
                'app_version' => $deviceData['app_version'] ?? null,
                'os_version' => $deviceData['os_version'] ?? null,
                'device_model' => $deviceData['device_model'] ?? null,
                'is_active' => true,
                'last_active_at' => Carbon::now()
            ]);
            
            return $existingDevice;
        }

        // Créer un nouvel appareil
        return self::create(array_merge($deviceData, [
            'is_active' => true,
            'last_active_at' => Carbon::now()
        ]));
    }

    /**
     *  MARQUER L'APPAREIL COMME ACTIF
     */
    public function markAsActive(): void
    {
        $this->update([
            'is_active' => true,
            'last_active_at' => Carbon::now()
        ]);
    }

    /**
     *  DÉSACTIVER L'APPAREIL
     */
    public function deactivate(): void
    {
        $this->update(['is_active' => false]);
    }

    /**
     *  METTRE À JOUR LE TOKEN PUSH
     */
    public function updatePushToken(string $newToken): bool
    {
        return $this->update([
            'push_token' => $newToken,
            'last_active_at' => Carbon::now()
        ]);
    }

    /**
     *  PRÉFÉRENCES DE NOTIFICATION
     *  Note: Les préférences sont maintenant gérées dans la table email_preferences
     *  Ces méthodes sont conservées pour compatibilité mais redirigent vers EmailPreference
     */
    public function hasNotificationPreference(string $type): bool
    {
        // Rediriger vers EmailPreference
        return \App\Models\EmailPreference::isEmailEnabled($this->user_id, $type);
    }

    /**
     *  VÉRIFICATIONS D'ÉTAT
     */
    public function isActive(): bool
    {
        return $this->is_active && 
               $this->last_active_at && 
               $this->last_active_at->greaterThan(Carbon::now()->subDays(30));
    }

    public function canReceiveNotifications(): bool
    {
        return $this->isActive() && 
               !empty($this->push_token) && 
               in_array($this->platform, [self::PLATFORM_ANDROID, self::PLATFORM_IOS]);
    }

    public function shouldReceiveBudgetAlerts(): bool
    {
        return $this->canReceiveNotifications() &&
               $this->hasNotificationPreference('budget_alert');
    }

    /**
     *  INFORMATIONS APPAREIL
     */
    public function getDeviceInfo(): array
    {
        return [
            'device_id' => $this->device_id,
            'platform' => $this->platform,
            'model' => $this->device_model,
            'os_version' => $this->os_version,
            'app_version' => $this->app_version,
            'is_active' => $this->isActive(),
            'last_active' => $this->last_active_at?->toISOString(),
            'can_receive_notifications' => $this->canReceiveNotifications()
        ];
    }

    /**
     *  NETTOYER LES ANCIENS APPAREILS
     */
    public static function cleanupInactiveDevices(): int
    {
        $cutoffDate = Carbon::now()->subDays(90);
        
        return self::where('last_active_at', '<', $cutoffDate)
            ->orWhere('is_active', false)
            ->delete();
    }

    /**
     *  OBTENIR LES STATISTIQUES DES APPAREILS
     */
    public static function getDeviceStats(): array
    {
        $total = self::count();
        $active = self::where('is_active', true)->count();
        $android = self::where('platform', self::PLATFORM_ANDROID)->count();
        $ios = self::where('platform', self::PLATFORM_IOS)->count();
        
        return [
            'total_devices' => $total,
            'active_devices' => $active,
            'android_devices' => $android,
            'ios_devices' => $ios,
            'inactive_devices' => $total - $active
        ];
    }

    /**
     *  SCOPES
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true)
                    ->where('last_active_at', '>', Carbon::now()->subDays(30));
    }

    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeAndroid($query)
    {
        return $query->where('platform', self::PLATFORM_ANDROID);
    }

    public function scopeIos($query)
    {
        return $query->where('platform', self::PLATFORM_IOS);
    }

    public function scopeCanReceiveNotifications($query)
    {
        return $query->active()
                    ->whereNotNull('push_token')
                    ->where('push_token', '!=', '');
    }

    /**
     *  BOOT METHOD
     */
    protected static function boot()
    {
        parent::boot();
        
        static::creating(function ($device) {
            if (!$device->last_active_at) {
                $device->last_active_at = Carbon::now();
            }
        });
        
        static::updating(function ($device) {
            // Si le token push change, marquer comme actif
            if ($device->isDirty('push_token')) {
                $device->last_active_at = Carbon::now();
                $device->is_active = true;
            }
        });
    }
}