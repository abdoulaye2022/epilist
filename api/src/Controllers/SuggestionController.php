<?php

namespace App\Controllers;

use App\Services\SmartSuggestionService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class SuggestionController
{
    private SmartSuggestionService $suggestionService;

    public function __construct()
    {
        $this->suggestionService = new SmartSuggestionService();
    }

    /**
     * Get personalized suggestions for the current user
     * GET /api/suggestions
     */
    public function getSuggestions(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('user_id');
        $params = $request->getQueryParams();

        $options = [
            'limit' => isset($params['limit']) ? (int)$params['limit'] : 10,
            'include_associations' => isset($params['include_associations'])
                ? filter_var($params['include_associations'], FILTER_VALIDATE_BOOLEAN)
                : true,
            'current_list_items' => isset($params['current_items'])
                ? explode(',', $params['current_items'])
                : []
        ];

        try {
            $suggestions = $this->suggestionService->getSuggestionsForUser($userId, $options);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'suggestions' => $suggestions,
                    'count' => count($suggestions)
                ]
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to get suggestions: ' . $e->getMessage()
            ]));

            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Get suggestion for a specific product (quantity, price)
     * GET /api/suggestions/product
     */
    public function getProductSuggestion(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('user_id');
        $params = $request->getQueryParams();

        if (!isset($params['product_name'])) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Product name is required'
            ]));

            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $productName = $params['product_name'];

        try {
            $suggestedQuantity = $this->suggestionService->suggestQuantity($userId, $productName);
            $suggestedPrice = $this->suggestionService->suggestPrice($userId, $productName);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'product_name' => $productName,
                    'suggested_quantity' => $suggestedQuantity,
                    'suggested_price' => $suggestedPrice,
                ]
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to get product suggestion: ' . $e->getMessage()
            ]));

            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Record feedback on a suggestion
     * POST /api/suggestions/feedback
     */
    public function recordFeedback(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('user_id');
        $data = $request->getParsedBody();

        // Validation
        if (!isset($data['product_name']) || !isset($data['action'])) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Product name and action are required'
            ]));

            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        if (!in_array($data['action'], ['accepted', 'rejected', 'modified'])) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Action must be accepted, rejected, or modified'
            ]));

            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        try {
            $this->suggestionService->recordFeedback(
                $userId,
                $data['product_name'],
                $data['action'],
                $data['suggested_quantity'] ?? null,
                $data['actual_quantity'] ?? null
            );

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Feedback recorded successfully'
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to record feedback: ' . $e->getMessage()
            ]));

            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Recalculate purchase patterns for current user
     * POST /api/suggestions/recalculate
     */
    public function recalculatePatterns(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('user_id');

        try {
            $this->suggestionService->recalculatePatterns($userId);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Purchase patterns recalculated successfully'
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to recalculate patterns: ' . $e->getMessage()
            ]));

            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Get suggestion statistics
     * GET /api/suggestions/stats
     */
    public function getStatistics(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('user_id');

        try {
            $stats = $this->suggestionService->getStatistics($userId);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $stats
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to get statistics: ' . $e->getMessage()
            ]));

            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Get trending products
     * GET /api/suggestions/trending
     */
    public function getTrending(Request $request, Response $response): Response
    {
        $params = $request->getQueryParams();
        $limit = isset($params['limit']) ? (int)$params['limit'] : 10;

        try {
            $trending = $this->suggestionService->getTrendingProducts($limit);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'trending' => $trending,
                    'count' => count($trending)
                ]
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to get trending products: ' . $e->getMessage()
            ]));

            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
