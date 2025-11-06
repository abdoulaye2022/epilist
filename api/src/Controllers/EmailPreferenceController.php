<?php
// src/Controllers/EmailPreferenceController.php

namespace App\Controllers;

use App\Models\EmailPreference;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Psr7\Response as SlimResponse;
use Valitron\Validator;

class EmailPreferenceController
{
    /**
     * Obtenir les préférences d'email de l'utilisateur connecté
     */
    public function getPreferences(Request $request, Response $response): Response
    {
        try {
            $userId = $request->getAttribute('auth_id');

            if (!$userId) {
                return $this->errorResponse($response, 'User not authenticated', 401);
            }

            $preferences = EmailPreference::getOrCreateForUser($userId);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $preferences
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);

        } catch (\Exception $e) {
            error_log("❌ [EmailPreferenceController] Erreur getPreferences: " . $e->getMessage());
            return $this->errorResponse($response, 'Server error: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Mettre à jour les préférences d'email
     */
    public function updatePreferences(Request $request, Response $response): Response
    {
        try {
            $userId = $request->getAttribute('auth_id');

            if (!$userId) {
                return $this->errorResponse($response, 'User not authenticated', 401);
            }

            $data = $request->getParsedBody();

            // Validation
            $validator = new Validator($data);
            $validator->rule('optional', [
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
            ]);

            $validator->rule('in', 'notification_frequency', ['realtime', 'daily', 'weekly']);

            if (!$validator->validate()) {
                return $this->errorResponse($response, 'Validation failed', 400, $validator->errors());
            }

            $preferences = EmailPreference::getOrCreateForUser($userId);

            // Convertir les valeurs string "true"/"false" en boolean
            $booleanFields = [
                'email_verification', 'password_change_request', 'password_changed',
                'list_shared_with_me', 'list_item_added', 'list_item_checked', 'list_completed',
                'budget_alert', 'budget_summary', 'marketing_emails', 'product_updates', 'tips_and_tricks'
            ];

            foreach ($booleanFields as $field) {
                if (isset($data[$field])) {
                    $data[$field] = filter_var($data[$field], FILTER_VALIDATE_BOOLEAN);
                }
            }

            $preferences->updatePreferences($data);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Email preferences updated successfully',
                'data' => $preferences->fresh()
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);

        } catch (\Exception $e) {
            error_log("❌ [EmailPreferenceController] Erreur updatePreferences: " . $e->getMessage());
            return $this->errorResponse($response, 'Server error: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Réinitialiser toutes les préférences aux valeurs par défaut
     */
    public function resetPreferences(Request $request, Response $response): Response
    {
        try {
            $userId = $request->getAttribute('auth_id');

            if (!$userId) {
                return $this->errorResponse($response, 'User not authenticated', 401);
            }

            // Supprimer et recréer pour avoir les valeurs par défaut
            EmailPreference::where('user_id', $userId)->delete();
            $preferences = EmailPreference::create(['user_id' => $userId]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Email preferences reset to default',
                'data' => $preferences
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);

        } catch (\Exception $e) {
            error_log("❌ [EmailPreferenceController] Erreur resetPreferences: " . $e->getMessage());
            return $this->errorResponse($response, 'Server error: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Désabonner de tous les emails marketing (pour le lien unsubscribe)
     */
    public function unsubscribeMarketing(Request $request, Response $response): Response
    {
        try {
            $userId = $request->getAttribute('auth_id');

            if (!$userId) {
                return $this->errorResponse($response, 'User not authenticated', 401);
            }

            $preferences = EmailPreference::getOrCreateForUser($userId);
            $preferences->updatePreferences([
                'marketing_emails' => false,
                'product_updates' => false,
                'tips_and_tricks' => false,
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Successfully unsubscribed from marketing emails'
            ]));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(200);

        } catch (\Exception $e) {
            error_log("❌ [EmailPreferenceController] Erreur unsubscribeMarketing: " . $e->getMessage());
            return $this->errorResponse($response, 'Server error: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Helper pour retourner une erreur
     */
    private function errorResponse(Response $response, string $message, int $status, array $errors = null): Response
    {
        $body = [
            'success' => false,
            'message' => $message
        ];

        if ($errors) {
            $body['errors'] = $errors;
        }

        $response->getBody()->write(json_encode($body));

        return $response
            ->withHeader('Content-Type', 'application/json')
            ->withStatus($status);
    }
}
