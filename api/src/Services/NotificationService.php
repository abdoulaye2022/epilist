<?php
namespace App\Services;

use Kreait\Firebase\Factory;

class NotificationService
{
    protected $messaging;

    public function __construct()
    {
        $serviceAccountPath = __DIR__ . '/../../service-account.json';
        $factory = (new Factory)->withServiceAccount($serviceAccountPath);
        $this->messaging = $factory->createMessaging();
    }

    public function sendNotification($token, $title, $body)
    {
        $message = [
            'token' => $token,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
        ];

        try {
            $this->messaging->send($message);
            return true;
        } catch (\Kreait\Firebase\Exception\MessagingException $e) {
            error_log('Erreur lors de l\'envoi de la notification : ' . $e->getMessage());
            return false;
        }
    }
}