<?php
// app/Controllers/BudgetController.php

namespace App\Controllers;

use App\Models\Budget;
use App\Models\ShoppingList;
use App\Models\SharedList;
use App\Models\User;
use App\Models\Currency;
use Carbon\Carbon;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class BudgetController
{
    /**
     * ✅ VALIDATE BUDGET DATA
     */
    private function validateBudgetData(array $data, bool $isUpdate = false): array
    {
        $validator = new Validator($data);
        
        // Set language to English for consistent API responses
        $validator->lang('en');
        
        // Basic rules
        if (!$isUpdate) {
            $validator->rule('required', 'name')->message('Budget name is required');
            $validator->rule('required', 'budget_amount')->message('Budget amount is required');
            $validator->rule('required', 'period_type')->message('Period type is required');
            $validator->rule('required', 'start_date')->message('Start date is required');
            $validator->rule('required', 'end_date')->message('End date is required');
        }
        
        if (isset($data['name'])) {
            $validator->rule('lengthMin', 'name', 3)->message('Budget name must be at least 3 characters');
            $validator->rule('lengthMax', 'name', 255)->message('Budget name cannot exceed 255 characters');
        }
        
        // Amount validation
        if (isset($data['budget_amount'])) {
            $validator->rule('numeric', 'budget_amount')->message('Budget amount must be a number');
            $validator->rule('min', 'budget_amount', 0.01)->message('Budget amount must be at least 0.01');
            $validator->rule('max', 'budget_amount', 999999.99)->message('Budget amount cannot exceed 999,999.99');
        }
        
        // Period type validation
        if (isset($data['period_type'])) {
            $validator->rule('in', 'period_type', ['weekly', 'monthly', 'yearly', 'custom'])->message('Invalid period type');
        }
        
        // Date validation
        if (isset($data['start_date'])) {
            $validator->rule('date', 'start_date')->message('Start date must be a valid date');
        }
        
        if (isset($data['end_date'])) {
            $validator->rule('date', 'end_date')->message('End date must be a valid date');
        }
        
        // Alert threshold validation
        if (isset($data['alert_threshold'])) {
            $validator->rule('integer', 'alert_threshold')->message('Alert threshold must be an integer');
            $validator->rule('min', 'alert_threshold', 1)->message('Alert threshold must be at least 1');
            $validator->rule('max', 'alert_threshold', 100)->message('Alert threshold cannot exceed 100');
        }
        
        // List ID validation
        if (isset($data['list_id'])) {
            $validator->rule('integer', 'list_id')->message('List ID must be an integer');
        }
        
        // Custom validation for date logic
        if (isset($data['start_date']) && isset($data['end_date'])) {
            $validator->rule(function($field, $value, $params) use ($data) {
                $startDate = Carbon::parse($data['start_date']);
                $endDate = Carbon::parse($data['end_date']);
                return $endDate->gt($startDate);
            }, 'end_date')->message('End date must be after start date');
        }
        
        return $validator->validate() ? [] : $validator->errors();
    }

    /**
     * ✅ CHECK LIST ACCESS (if budget is for specific list)
     */
    private function checkListAccess(int $userId, int $listId): bool
    {
        // Check if user owns the list
        $ownList = ShoppingList::where('user_id', $userId)
            ->where('id', $listId)
            ->exists();

        if ($ownList) {
            return true;
        }

        // Check if user has access to shared list
        $sharedList = SharedList::where('shared_with_user_id', $userId)
            ->whereHas('shoppingList', function($query) use ($listId) {
                $query->where('id', $listId);
            })
            ->where('status', SharedList::STATUS_ACCEPTED)
            ->where('is_active', true)
            ->exists();

        return $sharedList;
    }

    /**
     * ✅ GET ALL BUDGETS FOR USER
     */
    public function index(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $params = $request->getQueryParams();

            $query = Budget::forUser($user_id)
                ->with(['shoppingList'])
                ->orderBy('created_at', 'desc');

            // Filters
            if (isset($params['status'])) {
                switch ($params['status']) {
                    case 'active':
                        $query->active()->current();
                        break;
                    case 'expired':
                        $query->expired();
                        break;
                    case 'upcoming':
                        $query->upcoming();
                        break;
                    case 'exceeded':
                        $query->exceeded();
                        break;
                }
            }

            if (isset($params['period_type'])) {
                $query->byPeriod($params['period_type']);
            }

            if (isset($params['list_id'])) {
                if ($params['list_id'] === 'general') {
                    $query->general();
                } else {
                    $query->forList((int)$params['list_id']);
                }
            }

            $budgets = $query->get();
            $user = User::with('currency')->find($user_id);

            $formattedBudgets = $budgets->map(function($budget) use ($user) {
                return $budget->getApiDataForUser($user);
            });

            // Calculate summary stats
            $activeBudgets = $budgets->filter(function($budget) {
                return $budget->isActive();
            });

            $totalBudgeted = $activeBudgets->sum('budget_amount');
            $totalSpent = $activeBudgets->sum(function($budget) {
                return $budget->getSpentAmount();
            });

            $exceedingBudgets = $activeBudgets->filter(function($budget) {
                return $budget->isExceeded();
            });

            $warningBudgets = $activeBudgets->filter(function($budget) {
                return $budget->isNearLimit() && !$budget->isExceeded();
            });

            $currency = $user->currency ?? Currency::getDefault();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $formattedBudgets,
                'meta' => [
                    'total_budgets' => $budgets->count(),
                    'active_budgets' => $activeBudgets->count(),
                    'exceeding_budgets' => $exceedingBudgets->count(),
                    'warning_budgets' => $warningBudgets->count(),
                    'total_budgeted' => round($totalBudgeted, 2),
                    'total_spent' => round($totalSpent, 2),
                    'formatted_total_budgeted' => $currency->formatAmount($totalBudgeted),
                    'formatted_total_spent' => $currency->formatAmount($totalSpent)
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Budget index error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving budgets',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ CREATE NEW BUDGET
     */
    public function store(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();

        try {
            $user_id = $request->getAttribute('auth_id');

            // Validation
            $errors = $this->validateBudgetData($data, false);
            if (!empty($errors)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Invalid input data',
                        'validation_errors' => $errors
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            // Check list access if list_id is provided
            if (!empty($data['list_id'])) {
                if (!$this->checkListAccess($user_id, (int)$data['list_id'])) {
                    $response->getBody()->write(json_encode([
                        'success' => false,
                        'error' => [
                            'code' => 'ACCESS_DENIED',
                            'message' => 'You do not have access to this shopping list'
                        ]
                    ]));
                    return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
                }
            }

            // Check for overlapping budgets
            $startDate = Carbon::parse($data['start_date']);
            $endDate = Carbon::parse($data['end_date']);
            
            $overlappingQuery = Budget::forUser($user_id)
                ->active()
                ->where(function($query) use ($startDate, $endDate) {
                    $query->whereBetween('start_date', [$startDate, $endDate])
                          ->orWhereBetween('end_date', [$startDate, $endDate])
                          ->orWhere(function($q) use ($startDate, $endDate) {
                              $q->where('start_date', '<=', $startDate)
                                ->where('end_date', '>=', $endDate);
                          });
                });

            if (!empty($data['list_id'])) {
                $overlappingQuery->where('list_id', $data['list_id']);
            } else {
                $overlappingQuery->whereNull('list_id');
            }

            if ($overlappingQuery->exists()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'OVERLAPPING_BUDGET',
                        'message' => 'A budget already exists for this period and scope'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(409);
            }

            // Create budget
            $data['user_id'] = $user_id;
            $budget = Budget::createClean($data);

            $user = User::with('currency')->find($user_id);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $budget->getApiDataForUser($user),
                'message' => 'Budget created successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            error_log("Budget store error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while creating the budget',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ SHOW SPECIFIC BUDGET
     */
    public function show(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $budgetId = (int) $args['id'];

            $budget = Budget::forUser($user_id)
                ->with(['shoppingList'])
                ->find($budgetId);

            if (!$budget) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Budget not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $user = User::with('currency')->find($user_id);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $budget->getApiDataForUser($user)
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Budget show error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving the budget',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ UPDATE BUDGET
     */
    public function update(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $budgetId = (int) $args['id'];

        try {
            $user_id = $request->getAttribute('auth_id');

            $budget = Budget::forUser($user_id)->find($budgetId);

            if (!$budget) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Budget not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            // Validation
            $errors = $this->validateBudgetData($data, true);
            if (!empty($errors)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Invalid input data',
                        'validation_errors' => $errors
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            // Check list access if changing list_id
            if (isset($data['list_id']) && $data['list_id'] !== $budget->list_id) {
                if (!empty($data['list_id']) && !$this->checkListAccess($user_id, (int)$data['list_id'])) {
                    $response->getBody()->write(json_encode([
                        'success' => false,
                        'error' => [
                            'code' => 'ACCESS_DENIED',
                            'message' => 'You do not have access to this shopping list'
                        ]
                    ]));
                    return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
                }
            }

            $budget->updateClean($data);
            $budget = $budget->fresh(['shoppingList']);

            $user = User::with('currency')->find($user_id);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $budget->getApiDataForUser($user),
                'message' => 'Budget updated successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Budget update error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while updating the budget',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ DELETE BUDGET
     */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $budgetId = (int) $args['id'];

            $budget = Budget::forUser($user_id)->find($budgetId);

            if (!$budget) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Budget not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $budget->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Budget deleted successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Budget destroy error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while deleting the budget',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ GET BUDGET ALERTS FOR USER
     */
    public function getAlerts(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');

            $budgets = Budget::forUser($user_id)
                ->active()
                ->current()
                ->with(['shoppingList'])
                ->get();

            $alerts = [];

            foreach ($budgets as $budget) {
                if ($budget->shouldShowAlert()) {
                    $alerts[] = [
                        'id' => $budget->id,
                        'budget_name' => $budget->name,
                        'list_name' => $budget->shoppingList ? $budget->shoppingList->name : null,
                        'status' => $budget->getAlertStatus(),
                        'message' => $budget->getAlertMessage(),
                        'spent_percentage' => $budget->getSpentPercentage(),
                        'is_exceeded' => $budget->isExceeded(),
                        'days_remaining' => $budget->getDaysRemaining()
                    ];
                }
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $alerts,
                'meta' => [
                    'total_alerts' => count($alerts),
                    'exceeded_count' => count(array_filter($alerts, fn($a) => $a['is_exceeded'])),
                    'warning_count' => count(array_filter($alerts, fn($a) => !$a['is_exceeded']))
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Budget alerts error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving budget alerts',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ GET BUDGET SUMMARY/DASHBOARD
     */
    public function dashboard(Request $request, Response $response): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $user = User::with('currency')->find($user_id);
            $currency = $user->currency ?? Currency::getDefault();

            // Current budgets
            $currentBudgets = Budget::forUser($user_id)
                ->active()
                ->current()
                ->with(['shoppingList'])
                ->get();

            // Expired budgets (last 30 days)
            $recentExpiredBudgets = Budget::forUser($user_id)
                ->where('end_date', '>=', Carbon::now()->subDays(30))
                ->where('end_date', '<', Carbon::now())
                ->with(['shoppingList'])
                ->get();

            // Calculate summary statistics
            $totalBudgeted = $currentBudgets->sum('budget_amount');
            $totalSpent = $currentBudgets->sum(function($budget) {
                return $budget->getSpentAmount();
            });

            $exceededBudgets = $currentBudgets->filter(fn($b) => $b->isExceeded());
            $warningBudgets = $currentBudgets->filter(fn($b) => $b->isNearLimit() && !$b->isExceeded());
            $onTrackBudgets = $currentBudgets->filter(fn($b) => !$b->isNearLimit());

            // Best and worst performing budgets
            $budgetPerformance = $currentBudgets->map(function($budget) use ($user) {
                return [
                    'budget' => $budget->getApiDataForUser($user),
                    'performance_score' => 100 - $budget->getSpentPercentage()
                ];
            })->sortByDesc('performance_score');

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'summary' => [
                        'total_budgets' => $currentBudgets->count(),
                        'total_budgeted' => round($totalBudgeted, 2),
                        'total_spent' => round($totalSpent, 2),
                        'total_remaining' => round($totalBudgeted - $totalSpent, 2),
                        'overall_spent_percentage' => $totalBudgeted > 0 ? round(($totalSpent / $totalBudgeted) * 100, 1) : 0,
                        'formatted_total_budgeted' => $currency->formatAmount($totalBudgeted),
                        'formatted_total_spent' => $currency->formatAmount($totalSpent),
                        'formatted_total_remaining' => $currency->formatAmount($totalBudgeted - $totalSpent),
                    ],
                    'status_breakdown' => [
                        'exceeded' => $exceededBudgets->count(),
                        'warning' => $warningBudgets->count(),
                        'on_track' => $onTrackBudgets->count()
                    ],
                    'current_budgets' => $currentBudgets->map(fn($b) => $b->getApiDataForUser($user))->values(),
                    'recent_expired' => $recentExpiredBudgets->map(fn($b) => $b->getApiDataForUser($user))->values(),
                    'performance' => [
                        'best_performing' => $budgetPerformance->take(3)->values(),
                        'needs_attention' => $budgetPerformance->reverse()->take(3)->values()
                    ]
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Budget dashboard error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving budget dashboard',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ CREATE QUICK BUDGET TEMPLATES
     */
    public function createQuickBudget(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();

        try {
            $user_id = $request->getAttribute('auth_id');

            $budgetType = $data['type'] ?? 'monthly';
            $amount = $data['amount'] ?? 0;
            $listId = $data['list_id'] ?? null;

            if ($amount <= 0) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Budget amount must be greater than 0'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            // Check list access if provided
            if ($listId && !$this->checkListAccess($user_id, $listId)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'ACCESS_DENIED',
                        'message' => 'You do not have access to this shopping list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            // Calculate dates based on budget type
            [$startDate, $endDate] = match($budgetType) {
                'weekly' => [Carbon::now()->startOfWeek(), Carbon::now()->endOfWeek()],
                'yearly' => [Carbon::now()->startOfYear(), Carbon::now()->endOfYear()],
                default => [Carbon::now()->startOfMonth(), Carbon::now()->endOfMonth()]
            };

            // Check for overlapping budgets
            $overlappingQuery = Budget::forUser($user_id)
                ->active()
                ->where(function($query) use ($startDate, $endDate) {
                    $query->whereBetween('start_date', [$startDate, $endDate])
                          ->orWhereBetween('end_date', [$startDate, $endDate])
                          ->orWhere(function($q) use ($startDate, $endDate) {
                              $q->where('start_date', '<=', $startDate)
                                ->where('end_date', '>=', $endDate);
                          });
                });

            if ($listId) {
                $overlappingQuery->where('list_id', $listId);
            } else {
                $overlappingQuery->whereNull('list_id');
            }

            if ($overlappingQuery->exists()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'OVERLAPPING_BUDGET',
                        'message' => 'A budget already exists for this period and scope'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(409);
            }

            $name = $data['name'] ?? $this->generateBudgetName($budgetType, $listId);

            $budget = match($budgetType) {
                'weekly' => Budget::createWeeklyBudget($user_id, $name, $amount, Carbon::now()->startOfWeek(), $listId),
                'yearly' => Budget::createYearlyBudget($user_id, $name, $amount, null, $listId),
                default => Budget::createMonthlyBudget($user_id, $name, $amount, null, $listId)
            };

            $user = User::with('currency')->find($user_id);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $budget->getApiDataForUser($user),
                'message' => 'Quick budget created successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            error_log("Quick budget creation error: " . $e->getMessage());

            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while creating the quick budget',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ HELPER METHOD TO GENERATE BUDGET NAMES
     */
    private function generateBudgetName(string $type, ?int $listId = null): string
    {
        $scope = $listId ? 'List Budget' : 'General Budget';
        $period = ucfirst($type);
        $date = Carbon::now()->format('M Y');
        
        return "{$period} {$scope} - {$date}";
    }
}