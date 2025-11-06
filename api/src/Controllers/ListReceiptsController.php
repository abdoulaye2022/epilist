<?php
// app/Controllers/ListReceiptsController.php

namespace App\Controllers;

use App\Models\ListReceipt;
use App\Models\ShoppingList;
use App\Models\SharedList;
use App\Models\User;
use App\Models\Currency;
use App\Services\ReceiptExportService;
use Carbon\Carbon;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class ListReceiptsController
{
    /**
     * ✅ LOG HELPER - Only log in development mode
     */
    private function debugLog(string $message): void
    {
        if (getenv('APP_ENV') === 'development') {
            error_log($message);
        }
    }

    /**
     * ✅ CHECK LIST ACCESS PERMISSIONS
     */
    private function checkListAccess(int $user_id, int $list_id, string $requiredPermission = 'read'): ?array
    {
        // 1. Check if it's user's own list
        $ownList = ShoppingList::where('user_id', $user_id)
            ->where('id', $list_id)
            ->first();

        if ($ownList) {
            return [
                'list' => $ownList,
                'is_owner' => true,
                'permission' => 'admin',
                'can_read' => true,
                'can_edit' => true,
                'can_delete' => true
            ];
        }

        // 2. Check if it's a shared list
        $sharedList = SharedList::with(['shoppingList'])
            ->where('shared_with_user_id', $user_id)
            ->whereHas('shoppingList', function($query) use ($list_id) {
                $query->where('id', $list_id);
            })
            ->where('status', SharedList::STATUS_ACCEPTED)
            ->where('is_active', true)
            ->first();

        if ($sharedList) {
            $canEdit = $sharedList->canEdit();
            $canDelete = $sharedList->canDelete();

            $hasPermission = match($requiredPermission) {
                'read' => true,
                'edit' => $canEdit,
                'delete' => $canDelete,
                default => false
            };

            if (!$hasPermission) {
                return null;
            }

            return [
                'list' => $sharedList->shoppingList,
                'is_owner' => false,
                'permission' => $sharedList->permission,
                'can_read' => true,
                'can_edit' => $canEdit,
                'can_delete' => $canDelete
            ];
        }

        return null;
    }

    /**
     * ✅ VALIDATE RECEIPT DATA
     */
    private function validateReceiptData(array $data, bool $isUpdate = false): array
    {
        $validator = new Validator($data);
        
        // Set language to English for consistent API responses
        $validator->lang('en');
        
        // Basic rules
        if (!$isUpdate) {
            $validator->rule('required', 'store_name')->message('Store name is required');
            $validator->rule('required', 'total_amount')->message('Total amount is required');
            $validator->rule('required', 'purchase_date')->message('Purchase date is required');
        }
        
        if (isset($data['store_name'])) {
            $validator->rule('lengthMin', 'store_name', 2)->message('Store name must be at least 2 characters');
            $validator->rule('lengthMax', 'store_name', 255)->message('Store name cannot exceed 255 characters');
        }
        
        // Amount validation
        if (isset($data['total_amount'])) {
            $validator->rule('numeric', 'total_amount')->message('Total amount must be a number');
            $validator->rule('min', 'total_amount', 0.01)->message('Total amount must be at least 0.01');
            $validator->rule('max', 'total_amount', 999999.99)->message('Total amount cannot exceed 999,999.99');
        }
        
        // Date validation
        if (isset($data['purchase_date'])) {
            $validator->rule('date', 'purchase_date')->message('Purchase date must be a valid date');
        }
        
        // Notes validation
        if (isset($data['notes'])) {
            $validator->rule('lengthMax', 'notes', 1000)->message('Notes cannot exceed 1000 characters');
        }
        
        return $validator->validate() ? [] : $validator->errors();
    }

    /**
     * ✅ GET ALL RECEIPTS FOR A LIST
     */
    public function index(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = (int) $args['listId'];

            $access = $this->checkListAccess($user_id, $listId, 'read');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'ACCESS_DENIED',
                        'message' => 'You do not have permission to access this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $receipts = ListReceipt::where('list_id', $listId)
                ->orderBy('purchase_date', 'desc')
                ->orderBy('created_at', 'desc')
                ->get();

            // Get user for currency formatting
            $user = User::with('currency')->find($user_id);
            $formattedReceipts = $receipts->map(function($receipt) use ($user) {
                return $receipt->getApiDataForUser($user);
            });

            $totalAmount = $receipts->sum('total_amount');
            $currency = $user->currency ?? Currency::getDefault();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $formattedReceipts,
                'meta' => [
                    'list_name' => $access['list']->name,
                    'is_owner' => $access['is_owner'],
                    'permission' => $access['permission'],
                    'can_edit' => $access['can_edit'],
                    'can_delete' => $access['can_delete'],
                    'total_receipts' => $receipts->count(),
                    'total_amount' => round($totalAmount, 2),
                    'formatted_total' => $currency->formatAmount($totalAmount),
                    'unique_stores' => $receipts->unique('store_name')->count()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("❌ [ERROR] Receipt index error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving receipts',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ CREATE NEW RECEIPT
     */
    public function store(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = (int) $args['listId'];

        try {
            $user_id = $request->getAttribute('auth_id');

            // Check edit permissions
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to add receipts to this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            // Validation
            $errors = $this->validateReceiptData($data, false);
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

            // Create receipt with clean data
            $data['list_id'] = $listId;
            $receipt = ListReceipt::createClean($data);

            // Get user for currency formatting
            $user = User::with('currency')->find($user_id);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $receipt->getApiDataForUser($user),
                'message' => 'Receipt added successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            error_log("❌ [ERROR] Receipt store error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while adding the receipt',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ SHOW SPECIFIC RECEIPT
     */
    public function show(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = (int) $args['listId'];
            $receiptId = (int) $args['receiptId'];

            $access = $this->checkListAccess($user_id, $listId, 'read');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'ACCESS_DENIED',
                        'message' => 'You do not have permission to access this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $receipt = ListReceipt::where('list_id', $listId)
                ->where('id', $receiptId)
                ->first();

            if (!$receipt) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Receipt not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $user = User::with('currency')->find($user_id);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $receipt->getApiDataForUser($user),
                'meta' => [
                    'can_edit' => $access['can_edit'],
                    'can_delete' => $access['can_edit'],
                    'permission' => $access['permission']
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("❌ [ERROR] Receipt show error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving the receipt',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ UPDATE RECEIPT - VERSION AVEC LOGS DÉTAILLÉS
     */
    public function update(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = (int) $args['listId'];
        $receiptId = (int) $args['receiptId'];

        // ✅ LOGS DE DÉBOGAGE DÉTAILLÉS
        $this->debugLog("🔄 DÉBUT UPDATE RECEIPT");
        $this->debugLog("📥 Raw request data: " . json_encode($data));
        $this->debugLog("🆔 List ID: " . $listId);
        $this->debugLog("🆔 Receipt ID: " . $receiptId);

        try {
            $user_id = $request->getAttribute('auth_id');
            $this->debugLog("👤 User ID: " . $user_id);

            // Check permissions
            $access = $this->checkListAccess($user_id, $listId, 'edit');

            if (!$access) {
                error_log("❌ [SECURITY] Access denied for user $user_id on list $listId");
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to modify receipts in this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $this->debugLog("✅ Access granted - Permission: " . $access['permission']);

            // Find receipt
            $receipt = ListReceipt::where('list_id', $listId)
                ->where('id', $receiptId)
                ->first();

            if (!$receipt) {
                $this->debugLog("❌ Receipt not found: listId=$listId, receiptId=$receiptId");
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Receipt not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $this->debugLog("✅ Receipt found: " . json_encode([
                'id' => $receipt->id,
                'store_name' => $receipt->store_name,
                'total_amount' => $receipt->total_amount,
                'purchase_date' => $receipt->purchase_date->toDateString(),
                'notes' => $receipt->notes
            ]));

            // ✅ VALIDATION AVEC LOGS
            $errors = $this->validateReceiptData($data, true);
            if (!empty($errors)) {
                $this->debugLog("❌ Validation errors: " . json_encode($errors));
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

            $this->debugLog("✅ Validation passed");

            // ✅ PRÉPARER LES DONNÉES POUR LA MISE À JOUR
            $updateData = [];

            if (isset($data['store_name']) && !empty(trim($data['store_name']))) {
                $updateData['store_name'] = trim($data['store_name']);
                $this->debugLog("📝 Updating store_name: " . $updateData['store_name']);
            }

            if (isset($data['total_amount']) && is_numeric($data['total_amount'])) {
                $updateData['total_amount'] = (float) $data['total_amount'];
                $this->debugLog("💰 Updating total_amount: " . $updateData['total_amount']);
            }

            if (isset($data['purchase_date']) && !empty($data['purchase_date'])) {
                try {
                    $updateData['purchase_date'] = $data['purchase_date'];
                    $this->debugLog("📅 Updating purchase_date: " . $updateData['purchase_date']);
                } catch (\Exception $e) {
                    $this->debugLog("❌ Invalid date format: " . $data['purchase_date']);
                }
            }

            if (isset($data['notes'])) {
                $updateData['notes'] = !empty(trim($data['notes'])) ? trim($data['notes']) : null;
                $this->debugLog("📝 Updating notes: " . ($updateData['notes'] ?? 'NULL'));
            }

            $this->debugLog("📦 Final update data: " . json_encode($updateData));

            if (empty($updateData)) {
                $this->debugLog("⚠️ No data to update");
                $user = User::with('currency')->find($user_id);
                $response->getBody()->write(json_encode([
                    'success' => true,
                    'data' => $receipt->getApiDataForUser($user),
                    'message' => 'No changes to update'
                ]));
                return $response->withHeader('Content-Type', 'application/json');
            }

            // ✅ EFFECTUER LA MISE À JOUR
            $this->debugLog("🔄 Calling updateClean method...");
            $updateResult = $receipt->updateClean($updateData);
            $this->debugLog("✅ UpdateClean result: " . ($updateResult ? 'SUCCESS' : 'FAILED'));

            if (!$updateResult) {
                error_log("❌ [ERROR] Receipt update failed for receipt ID: $receiptId");
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'UPDATE_FAILED',
                        'message' => 'Failed to update receipt'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
            }

            // ✅ RECHARGER LA FACTURE ET RETOURNER LA RÉPONSE
            $receipt = $receipt->fresh();
            error_log("📄 Updated receipt: " . json_encode([
                'id' => $receipt->id,
                'store_name' => $receipt->store_name,
                'total_amount' => $receipt->total_amount,
                'purchase_date' => $receipt->purchase_date->toDateString(),
                'notes' => $receipt->notes
            ]));

            $user = User::with('currency')->find($user_id);
            $responseData = $receipt->getApiDataForUser($user);
            
            error_log("📤 Response data: " . json_encode($responseData));

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $responseData,
                'message' => 'Receipt updated successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("❌ Receipt update error: " . $e->getMessage());
            error_log("❌ Stack trace: " . $e->getTraceAsString());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while updating the receipt',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ DELETE RECEIPT
     */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = (int) $args['listId'];
            $receiptId = (int) $args['receiptId'];

            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to delete receipts from this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $receipt = ListReceipt::where('list_id', $listId)
                ->where('id', $receiptId)
                ->first();

            if (!$receipt) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Receipt not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $receipt->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Receipt deleted successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Receipt destroy error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while deleting the receipt',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ GET RECEIPTS GROUPED BY STORE
     */
    public function byStore(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = (int) $args['listId'];

            $access = $this->checkListAccess($user_id, $listId, 'read');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'ACCESS_DENIED',
                        'message' => 'You do not have permission to access this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $receipts = ListReceipt::where('list_id', $listId)
                ->orderBy('purchase_date', 'desc')
                ->get();

            // Group by store
            $storeGroups = $receipts->groupBy('store_name');
            $user = User::with('currency')->find($user_id);
            $currency = $user->currency ?? Currency::getDefault();

            $storeData = [];
            foreach ($storeGroups as $storeName => $storeReceipts) {
                $storeTotal = $storeReceipts->sum('total_amount');
                
                $storeData[] = [
                    'store_name' => $storeName,
                    'receipts_count' => $storeReceipts->count(),
                    'total_amount' => round($storeTotal, 2),
                    'formatted_total' => $currency->formatAmount($storeTotal),
                    'receipts' => $storeReceipts->map(function($receipt) use ($user) {
                        return $receipt->getApiDataForUser($user);
                    })->values(),
                    'latest_purchase' => $storeReceipts->first()->purchase_date->toDateString()
                ];
            }

            // Sort by total amount (descending)
            usort($storeData, function($a, $b) {
                return $b['total_amount'] <=> $a['total_amount'];
            });

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $storeData,
                'meta' => [
                    'total_stores' => count($storeData),
                    'total_receipts' => $receipts->count(),
                    'grand_total' => round($receipts->sum('total_amount'), 2),
                    'formatted_grand_total' => $currency->formatAmount($receipts->sum('total_amount'))
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Receipt byStore error: " . $e->getMessage());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving store data',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ GET RECEIPT STATISTICS FOR A LIST
     */
    public function stats(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = (int) $args['listId'];

            $access = $this->checkListAccess($user_id, $listId, 'read');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'ACCESS_DENIED',
                        'message' => 'You do not have permission to access this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $shoppingList = ShoppingList::with(['receipts', 'items'])->find($listId);
            
            if (!$shoppingList) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Shopping list not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            // ✅ CALCUL DES STATISTIQUES MANUELLEMENT (compatible Slim)
            $receipts = $shoppingList->receipts ?? collect();
            $items = $shoppingList->items ?? collect();
            
            $itemsTotal = $items->sum(function($item) {
                return ($item->price ?? 0) * ($item->quantity ?? 1);
            });
            
            $receiptsTotal = $receipts->sum('total_amount');
            $bestTotal = max($itemsTotal, $receiptsTotal);
            $variance = $receiptsTotal - $itemsTotal;
            
            // Calculer la qualité des données
            $totalItems = $items->count();
            $itemsWithPrices = $items->filter(function($item) {
                return isset($item->price) && $item->price > 0;
            })->count();
            
            $dataQuality = 'unknown';
            if ($totalItems > 0) {
                $priceRatio = $itemsWithPrices / $totalItems;
                if ($priceRatio >= 0.8) {
                    $dataQuality = 'excellent';
                } elseif ($priceRatio >= 0.6) {
                    $dataQuality = 'good';
                } elseif ($priceRatio >= 0.4) {
                    $dataQuality = 'fair';
                } else {
                    $dataQuality = 'poor';
                }
            }
            
            // ✅ ASSURER QUE TOUS LES ENTIERS SONT BIEN DES ENTIERS
            $stats = [
                'items_total' => round((float)$itemsTotal, 2),
                'receipts_total' => round((float)$receiptsTotal, 2),
                'best_total' => round((float)$bestTotal, 2),
                'total_items' => (int)$totalItems,
                'total_receipts' => (int)$receipts->count(),
                'items_with_prices' => (int)$itemsWithPrices,
                'variance' => round((float)$variance, 2),
                'data_quality' => (string)$dataQuality
            ];
            
            $user = User::with('currency')->find($user_id);
            $currency = $user->currency ?? Currency::getDefault();

            // Add formatted amounts
            $stats['formatted_amounts'] = [
                'items_total' => $currency->formatAmount($stats['items_total']),
                'receipts_total' => $currency->formatAmount($stats['receipts_total']),
                'best_total' => $currency->formatAmount($stats['best_total'])
            ];

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $stats,
                'meta' => [
                    'currency' => $currency->code,
                    'last_updated' => Carbon::now()->toISOString()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            error_log("Receipt stats error: " . $e->getMessage());
            error_log("Receipt stats trace: " . $e->getTraceAsString());
            
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving statistics',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ EXPORT RECEIPTS TO PDF
     */
    public function exportPDF(Request $request, Response $response, array $args): Response
    {
        try {
            $list_id = (int) $args['listId'];
            $user_id = $request->getAttribute('user_id');

            error_log("📄 [EXPORT] PDF export requested for list {$list_id} by user {$user_id}");

            // Vérifier l'accès
            $access = $this->checkListAccess($user_id, $list_id, 'read');
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'ACCESS_DENIED',
                        'message' => 'You do not have permission to access this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $user = User::findOrFail($user_id);
            $htmlContent = ReceiptExportService::exportToPDF($list_id, $user);

            // Retourner le HTML (le client peut utiliser une librairie comme react-native-html-to-pdf)
            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'html' => $htmlContent,
                    'filename' => 'receipts_' . date('Y-m-d') . '.pdf'
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);

        } catch (\Exception $e) {
            error_log("❌ [EXPORT] PDF error: " . $e->getMessage());

            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'EXPORT_ERROR',
                    'message' => 'Failed to generate PDF export',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ EXPORT RECEIPTS TO CSV
     */
    public function exportCSV(Request $request, Response $response, array $args): Response
    {
        try {
            $list_id = (int) $args['listId'];
            $user_id = $request->getAttribute('user_id');

            error_log("📊 [EXPORT] CSV export requested for list {$list_id} by user {$user_id}");

            // Vérifier l'accès
            $access = $this->checkListAccess($user_id, $list_id, 'read');
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'ACCESS_DENIED',
                        'message' => 'You do not have permission to access this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $user = User::findOrFail($user_id);
            $csvContent = ReceiptExportService::exportToCSV($list_id, $user);

            // Retourner le CSV
            $response->getBody()->write($csvContent);
            return $response
                ->withHeader('Content-Type', 'text/csv')
                ->withHeader('Content-Disposition', 'attachment; filename="receipts_' . date('Y-m-d') . '.csv"')
                ->withStatus(200);

        } catch (\Exception $e) {
            error_log("❌ [EXPORT] CSV error: " . $e->getMessage());

            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'EXPORT_ERROR',
                    'message' => 'Failed to generate CSV export',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }
}