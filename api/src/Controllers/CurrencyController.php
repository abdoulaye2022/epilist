<?php
// src/Controllers/CurrencyController.php - VERSION AFFICHAGE SEULEMENT

namespace App\Controllers;

use App\Models\Currency;
use App\Models\User;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class CurrencyController
{
    /**
     * ✅ Obtenir toutes les devises disponibles pour l'affichage
     */
    public function index(Request $request, Response $response): Response
    {
        try {
            $params = $request->getQueryParams();
            $popularOnly = isset($params['popular']) && $params['popular'] === 'true';
            
            if ($popularOnly) {
                $currencies = Currency::getPopular();
            } else {
                $currencies = Currency::getActiveOrdered();
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $currencies,
                'meta' => [
                    'count' => count($currencies),
                    'popular_only' => $popularOnly,
                    'default_currency' => Currency::getDefault()->getApiFormatAttribute(),
                    'type' => 'display_only'
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving currencies',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Obtenir une devise spécifique par ID ou code
     */
    public function show(Request $request, Response $response, array $args): Response
    {
        try {
            $identifier = $args['id'];
            
            // Essayer de trouver par ID d'abord, puis par code
            if (is_numeric($identifier)) {
                $currency = Currency::active()->find($identifier);
            } else {
                $currency = Currency::findByCode($identifier);
            }

            if (!$currency) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Currency not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $currency->getApiFormatAttribute()
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving the currency',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Obtenir les devises populaires
     */
    public function getPopular(Request $request, Response $response): Response
    {
        try {
            $currencies = Currency::getPopular();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $currencies,
                'meta' => [
                    'count' => count($currencies),
                    'default_currency' => Currency::getDefault()->getApiFormatAttribute(),
                    'type' => 'display_only'
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving popular currencies',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Mettre à jour la devise d'affichage de l'utilisateur
     */
    public function updateUserCurrency(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();
        
        // Validation
        $validator = new Validator($data);
        $validator->rule('required', 'currency_id')->message('Currency ID is required');
        $validator->rule('integer', 'currency_id')->message('Currency ID must be an integer');
        $validator->rule('min', 'currency_id', 1)->message('Currency ID must be at least 1');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'Invalid input data',
                    'validation_errors' => $validator->errors()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');
            $currencyId = $data['currency_id'];

            // Vérifier que la devise existe et est active
            $currency = Currency::active()->find($currencyId);
            if (!$currency) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'INVALID_CURRENCY',
                        'message' => 'Selected currency is not available'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
            }

            // Mettre à jour l'utilisateur
            $user = User::findOrFail($user_id);
            $oldCurrencyId = $user->currency_id;
            
            $user->update(['currency_id' => $currencyId]);

            // Recharger l'utilisateur avec sa nouvelle devise
            $user->load('currency');

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'user_id' => $user->id,
                    'currency' => $currency->getApiFormatAttribute(),
                    'set_at' => $user->updated_at->toISOString()
                ],
                'message' => 'Display currency updated successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while updating display currency',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Obtenir la devise d'affichage de l'utilisateur actuel
     */
    public function getUserCurrency(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            
            $user = User::with('currency')->findOrFail($user_id);
            
            if (!$user->currency) {
                // Si pas de devise assignée, utiliser la devise par défaut
                $currency = Currency::getDefault();
                $user->update(['currency_id' => $currency->id]);
            } else {
                $currency = $user->currency;
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'user_id' => $user->id,
                    'currency' => $currency->getApiFormatAttribute(),
                    'set_at' => $user->updated_at->toISOString()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving user currency',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ Formater un montant dans la devise d'affichage de l'utilisateur (SANS CONVERSION)
     */
    public function formatUserAmount(Request $request, Response $response): Response
    {
        $params = $request->getQueryParams();
        
        // Validation
        $validator = new Validator($params);
        $validator->rule('required', 'amount')->message('Amount is required');
        $validator->rule('numeric', 'amount')->message('Amount must be a number');

        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'Invalid parameters',
                    'validation_errors' => $validator->errors()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');
            $amount = (float)$params['amount'];
            $showCode = isset($params['show_code']) && $params['show_code'] === 'true';

            $user = User::with('currency')->findOrFail($user_id);
            $currency = $user->currency ?: Currency::getDefault();

            // ✅ IMPORTANT: Pas de conversion, juste changement de symbole
            $formattedAmount = $currency->formatAmountDisplay($amount, $showCode);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'original_amount' => $amount,
                    'formatted_amount' => $formattedAmount,
                    'currency' => $currency->getApiFormatAttribute(),
                    'show_code' => $showCode,
                    'note' => 'Display format only - no conversion applied'
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while formatting amount',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}