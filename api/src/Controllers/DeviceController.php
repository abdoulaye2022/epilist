<?php
// app/Controllers/DeviceController.php

namespace App\Controllers;

use App\Models\UserDevice;
use App\Models\User;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class DeviceController
{
    /**
     * ✅ ENREGISTRER UN NOUVEL APPAREIL
     */
    public function register(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();

        try {
            $user_id = $request->getAttribute('auth_id');

            // Validation
            $errors = $this->validateDeviceData($data);
            if (!empty($errors)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Invalid device data',
                        'validation_errors' => $errors
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            // Enregistrer ou mettre à jour l'appareil
            $device = UserDevice::registerDevice(array_merge($data, [
                'user_id' => $user_id
            ]));

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'device_id' => $device->id,
                    'registered' => true,
                    'device_info' => $device->getDeviceInfo()
                ],
                'message' => 'Device registered successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);

        } catch (\Exception $e) {
            error_log("Device registration error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while registering the device',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ METTRE À JOUR LE TOKEN PUSH
     */
    public function updatePushToken(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();

        try {
            $user_id = $request->getAttribute('auth_id');

            if (empty($data['device_id']) || empty($data['push_token'])) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Device ID and push token are required'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $device = UserDevice::forUser($user_id)
                ->where('device_id', $data['device_id'])
                ->first();

            if (!$device) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Device not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $device->updatePushToken($data['push_token']);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'device_id' => $device->id,
                    'push_token_updated' => true
                ],
                'message' => 'Push token updated successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Push token update error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while updating push token',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ OBTENIR LES APPAREILS DE L'UTILISATEUR
     */
    public function index(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');

            $devices = UserDevice::forUser($user_id)
                ->orderBy('last_active_at', 'desc')
                ->get();

            $formattedDevices = $devices->map(function($device) {
                return $device->getDeviceInfo();
            });

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $formattedDevices,
                'meta' => [
                    'total_devices' => $devices->count(),
                    'active_devices' => $devices->filter(fn($d) => $d->isActive())->count()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Device index error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving devices',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ METTRE À JOUR LES PRÉFÉRENCES DE NOTIFICATION
     */
    public function updateNotificationPreferences(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();

        try {
            $user_id = $request->getAttribute('auth_id');

            if (empty($data['device_id'])) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Device ID is required'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $device = UserDevice::forUser($user_id)
                ->where('device_id', $data['device_id'])
                ->first();

            if (!$device) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Device not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $preferences = $data['preferences'] ?? [];
            $device->setNotificationPreferences($preferences);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'device_id' => $device->id,
                    'preferences' => $device->getNotificationPreferences()
                ],
                'message' => 'Notification preferences updated successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Notification preferences update error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while updating preferences',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ DÉSACTIVER UN APPAREIL
     */
    public function deactivate(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();

        try {
            $user_id = $request->getAttribute('auth_id');

            if (empty($data['device_id'])) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Device ID is required'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $device = UserDevice::forUser($user_id)
                ->where('device_id', $data['device_id'])
                ->first();

            if (!$device) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Device not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $device->deactivate();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Device deactivated successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Device deactivation error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while deactivating device',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ TESTER UNE NOTIFICATION
     */
    public function testNotification(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();

        try {
            $user_id = $request->getAttribute('auth_id');

            if (empty($data['device_id'])) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Device ID is required'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $device = UserDevice::forUser($user_id)
                ->where('device_id', $data['device_id'])
                ->first();

            if (!$device) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Device not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            if (!$device->canReceiveNotifications()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'DEVICE_UNAVAILABLE',
                        'message' => 'Device cannot receive notifications'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Envoyer une notification de test
            $notificationService = new \App\Services\MobileNotificationService();
            $testNotification = [
                'title' => '🧪 Test Notification',
                'body' => 'Votre appareil peut recevoir les notifications EpiList!',
                'icon' => 'test',
                'sound' => 'default',
                'priority' => 'normal',
                'data' => [
                    'type' => 'test',
                    'timestamp' => time(),
                    'action' => 'none'
                ]
            ];

            $success = false;
            if ($device->platform === 'android') {
                $success = $notificationService->sendFCMNotification($device, $testNotification);
            } elseif ($device->platform === 'ios') {
                $success = $notificationService->sendAPNSNotification($device, $testNotification);
            }

            $response->getBody()->write(json_encode([
                'success' => $success,
                'data' => [
                    'notification_sent' => $success,
                    'platform' => $device->platform
                ],
                'message' => $success ? 'Test notification sent' : 'Failed to send test notification'
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Test notification error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while sending test notification',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ VALIDATION DES DONNÉES APPAREIL
     */
    private function validateDeviceData(array $data): array
    {
        $validator = new Validator($data);
        
        $validator->lang('en');
        
        $validator->rule('required', 'device_id')->message('Device ID is required');
        $validator->rule('required', 'platform')->message('Platform is required');
        $validator->rule('required', 'push_token')->message('Push token is required');
        
        $validator->rule('in', 'platform', ['android', 'ios'])->message('Platform must be android or ios');
        $validator->rule('lengthMax', 'device_id', 255)->message('Device ID too long');
        $validator->rule('lengthMax', 'push_token', 512)->message('Push token too long');
        
        if (isset($data['app_version'])) {
            $validator->rule('lengthMax', 'app_version', 50)->message('App version too long');
        }
        
        if (isset($data['os_version'])) {
            $validator->rule('lengthMax', 'os_version', 50)->message('OS version too long');
        }
        
        if (isset($data['device_model'])) {
            $validator->rule('lengthMax', 'device_model', 100)->message('Device model too long');
        }
        
        return $validator->validate() ? [] : $validator->errors();
    }
}