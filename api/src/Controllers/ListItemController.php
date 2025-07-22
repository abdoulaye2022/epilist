<?php
// app/Controllers/ListItemController.php - MULTILINGUAL API WITH ENGLISH ERRORS

namespace App\Controllers;

use App\Models\ListItem;
use App\Models\ShoppingList;
use App\Models\SharedList;
use App\Models\ProductSuggestion;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class ListItemController
{
    /**
     * ✅ ADVANCED VALIDATION WITH ENGLISH MESSAGES
     */
    private function validateItemData(array $data, bool $isUpdate = false): array
    {
        $validator = new Validator($data);
        
        // Set language to English for consistent API responses
        $validator->lang('en');
        
        // Basic rules
        if (!$isUpdate) {
            $validator->rule('required', 'product_name')->message('Product name is required');
        }
        
        $validator->rule('lengthMin', 'product_name', 2)->message('Product name must be at least 2 characters');
        $validator->rule('lengthMax', 'product_name', 255)->message('Product name cannot exceed 255 characters');
        
        // Quantity validation
        $validator->rule('integer', 'quantity')->message('Quantity must be an integer');
        $validator->rule('min', 'quantity', 1)->message('Quantity must be at least 1');
        $validator->rule('max', 'quantity', 999)->message('Quantity cannot exceed 999');
        
        // Price validation
        $validator->rule('numeric', 'price')->message('Price must be a number');
        $validator->rule('min', 'price', 0)->message('Price cannot be negative');
        $validator->rule('max', 'price', 999999.99)->message('Price cannot exceed 999,999.99');
        
        // Store validation
        $validator->rule('lengthMax', 'store_name', 255)->message('Store name cannot exceed 255 characters');
        
        // Purchase status validation
        $validator->rule('boolean', 'is_purchased')->message('Purchase status must be true or false');
        
        // ✅ CUSTOM VALIDATIONS FOR MULTILINGUAL SUPPORT
        
        // Product name validation (must contain at least one letter or number)
        $validator->rule(function($field, $value) {
            if (empty($value)) return true; // Will be caught by 'required' if necessary
            
            // Support both English and French characters
            $cleanValue = trim(preg_replace('/[^a-zA-ZÀ-ÿ0-9\s]/', '', $value));
            return !empty($cleanValue);
        }, 'product_name')->message('Product name must contain at least one letter or number');
        
        // Price decimal validation
        $validator->rule(function($field, $value) {
            if ($value === null || $value === '') return true;
            if (!is_numeric($value)) return false;
            
            // Check if it has more than 2 decimal places
            $decimal_places = strlen(substr(strrchr($value, "."), 1));
            return $decimal_places <= 2;
        }, 'price')->message('Price cannot have more than 2 decimal places');
        
        // Store name validation (if provided, must be meaningful)
        $validator->rule(function($field, $value) {
            if (empty($value)) return true;
            
            $cleanValue = trim(preg_replace('/[^a-zA-ZÀ-ÿ0-9\s&\'-]/', '', $value));
            return strlen($cleanValue) >= 2;
        }, 'store_name')->message('Store name must be at least 2 characters when provided');

        return $validator->validate() ? [] : $validator->errors();
    }

    /**
     * ✅ ENHANCED DUPLICATE DETECTION WITH MULTILINGUAL SUPPORT
     */
    private function checkForDuplicates(int $listId, string $productName, ?string $storeName = null): array
    {
        $duplicates = ListItem::findPotentialDuplicates($listId, $productName, $storeName);
        
        $suggestions = [];
        foreach ($duplicates as $duplicate) {
            // Calculate similarity score for better matching
            $similarity = $this->calculateSimilarity($productName, $duplicate['product_name']);
            
            if ($similarity > 0.7) { // 70% similarity threshold
                $suggestions[] = [
                    'id' => $duplicate['id'],
                    'product_name' => $duplicate['product_name'],
                    'store_name' => $duplicate['store_name'],
                    'quantity' => $duplicate['quantity'],
                    'price' => $duplicate['price'],
                    'similarity_score' => round($similarity * 100),
                    'suggestion_type' => $similarity > 0.9 ? 'exact_match' : 'similar_match',
                    'suggestion_message' => $similarity > 0.9 
                        ? 'This item already exists in your list'
                        : 'Similar item found in your list'
                ];
            }
        }
        
        // Sort by similarity score
        usort($suggestions, function($a, $b) {
            return $b['similarity_score'] <=> $a['similarity_score'];
        });
        
        return $suggestions;
    }

    /**
     * ✅ SIMILARITY CALCULATION FOR MULTILINGUAL PRODUCTS
     */
    private function calculateSimilarity(string $str1, string $str2): float
    {
        // Normalize both strings
        $norm1 = ListItem::normalizeProductName($str1);
        $norm2 = ListItem::normalizeProductName($str2);
        
        // Calculate similarity using multiple methods
        $levenshtein = 1 - (levenshtein(strtolower($norm1), strtolower($norm2)) / max(strlen($norm1), strlen($norm2)));
        $metaphone = metaphone($norm1) === metaphone($norm2) ? 1 : 0;
        
        // Weighted average
        return ($levenshtein * 0.8) + ($metaphone * 0.2);
    }

    /**
     * ✅ CLEAN AND VALIDATE DATA WITH MULTILINGUAL SUPPORT
     */
    private function cleanAndValidateData(array $data, bool $isUpdate = false): array
    {
        // 1. Validation
        $errors = $this->validateItemData($data, $isUpdate);
        if (!empty($errors)) {
            throw new \InvalidArgumentException(json_encode([
                'validation_errors' => $errors,
                'message' => 'Validation failed'
            ]));
        }
        
        // 2. Data cleaning and normalization
        $cleanData = [];
        
        if (isset($data['product_name'])) {
            $cleanData['product_name'] = ListItem::normalizeProductName($data['product_name']);
        }
        
        if (isset($data['quantity'])) {
            $cleanData['quantity'] = ListItem::validateQuantity($data['quantity']);
        }
        
        if (isset($data['price'])) {
            $cleanData['price'] = ListItem::validatePrice($data['price']);
        }
        
        if (isset($data['store_name'])) {
            $cleanData['store_name'] = ListItem::normalizeStoreName($data['store_name']);
        }
        
        if (isset($data['is_purchased'])) {
            $cleanData['is_purchased'] = (bool)$data['is_purchased'];
        }
        
        return $cleanData;
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
     * ✅ UPDATE PRODUCT SUGGESTIONS
     */
    private function updateProductSuggestion(int $user_id, array $productData): void
    {
        try {
            ProductSuggestion::createOrUpdate($user_id, $productData);
        } catch (\Exception $e) {
            error_log("Error updating product suggestions: " . $e->getMessage());
        }
    }

    /**
     * ✅ GET ALL ITEMS FROM A LIST
     */
    public function index(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];

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

            $items = ListItem::where('list_id', $listId)
                ->orderBy('is_purchased')
                ->orderBy('created_at', 'desc')
                ->get();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $items,
                'meta' => [
                    'list_name' => $access['list']->name,
                    'is_owner' => $access['is_owner'],
                    'permission' => $access['permission'],
                    'can_edit' => $access['can_edit'],
                    'can_delete' => $access['can_delete'],
                    'total_items' => $items->count(),
                    'purchased_items' => $items->where('is_purchased', true)->count()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving items',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ CREATE NEW ITEM WITH ENHANCED VALIDATION
     */
    public function store(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = $args['listId'];

        try {
            $user_id = $request->getAttribute('auth_id');

            // Check edit permissions
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to add items to this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            // ✅ VALIDATION AND DATA CLEANING
            try {
                $cleanData = $this->cleanAndValidateData($data, false);
                $cleanData['list_id'] = $listId;
            } catch (\InvalidArgumentException $e) {
                $errorData = json_decode($e->getMessage(), true);
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Invalid input data',
                        'validation_errors' => $errorData['validation_errors'] ?? []
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            // ✅ DUPLICATE DETECTION
            $duplicates = $this->checkForDuplicates(
                $listId, 
                $cleanData['product_name'], 
                $cleanData['store_name'] ?? null
            );

            if (!empty($duplicates)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'DUPLICATE_DETECTED',
                        'message' => 'Similar items found in your list',
                        'duplicates' => $duplicates,
                        'actions' => [
                            'force_add' => 'Add anyway',
                            'merge' => 'Update existing item',
                            'cancel' => 'Cancel operation'
                        ]
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(409);
            }

            // Create item with clean data
            $item = ListItem::create($cleanData);

            // Update suggestions
            $this->updateProductSuggestion($user_id, $cleanData);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item,
                'message' => 'Item added successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while adding the item',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ FORCE ADD ITEM (IGNORE DUPLICATES)
     */
    public function forceStore(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = $args['listId'];

        try {
            $user_id = $request->getAttribute('auth_id');

            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'Insufficient permissions'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            // Clean and validate without duplicate check
            try {
                $cleanData = $this->cleanAndValidateData($data, false);
                $cleanData['list_id'] = $listId;
            } catch (\InvalidArgumentException $e) {
                $errorData = json_decode($e->getMessage(), true);
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Invalid input data',
                        'validation_errors' => $errorData['validation_errors'] ?? []
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $item = ListItem::create($cleanData);
            $this->updateProductSuggestion($user_id, $cleanData);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item,
                'message' => 'Item added successfully (duplicates ignored)'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while adding the item',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ UPDATE ITEM WITH ENHANCED VALIDATION
     */
    public function update(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = $args['listId'];
        $itemId = $args['itemId'];

        try {
            $user_id = $request->getAttribute('auth_id');

            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'Insufficient permissions'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::where('list_id', $listId)->findOrFail($itemId);
            $oldData = $item->toArray();

            // Validation and cleaning
            try {
                $cleanData = $this->cleanAndValidateData($data, true);
            } catch (\InvalidArgumentException $e) {
                $errorData = json_decode($e->getMessage(), true);
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Invalid input data',
                        'validation_errors' => $errorData['validation_errors'] ?? []
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $item->update($cleanData);

            // Update suggestions if product name changed
            if (isset($cleanData['product_name']) && $cleanData['product_name'] !== $oldData['product_name']) {
                $suggestionData = array_merge($cleanData, ['product_name' => $cleanData['product_name']]);
                $this->updateProductSuggestion($user_id, $suggestionData);
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item->fresh(),
                'message' => 'Item updated successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while updating the item',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ TOGGLE PURCHASED STATUS
     */
    public function togglePurchased(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to modify items in this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::where('list_id', $listId)->findOrFail($itemId);
            $newStatus = !$item->is_purchased;
            $item->update(['is_purchased' => $newStatus]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item->fresh(),
                'message' => $newStatus ? 'Item marked as purchased' : 'Item marked as not purchased'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while updating the purchase status',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ DELETE ITEM
     */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to delete items from this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::where('list_id', $listId)->findOrFail($itemId);
            $item->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Item deleted successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while deleting the item',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ RESTORE DELETED ITEM
     */
    public function restore(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to restore items in this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $item = ListItem::withTrashed()
                ->where('list_id', $listId)
                ->findOrFail($itemId);

            $item->restore();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item->fresh(),
                'message' => 'Item restored successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while restoring the item',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Afficher un item spécifique
     */
    public function show(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $itemId = $args['itemId'];

            // Vérifier l'accès en lecture à la liste
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

            $item = ListItem::where('list_id', $listId)
                ->where('id', $itemId)
                ->first();

            if (!$item) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Item not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $item,
                'meta' => [
                    'can_edit' => $access['can_edit'],
                    'can_delete' => $access['can_edit'],
                    'permission' => $access['permission']
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving the item',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Fusionner avec un item existant
     */
    public function mergeWithExisting(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $listId = $args['listId'];
        $itemId = $args['itemId'];

        try {
            $user_id = $request->getAttribute('auth_id');

            // Vérifier les permissions d'édition
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to modify items in this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            // Récupérer l'item existant
            $existingItem = ListItem::where('list_id', $listId)
                ->where('id', $itemId)
                ->first();

            if (!$existingItem) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'Item not found'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
            }

            // Paramètres de fusion avec valeurs par défaut
            $additionalQuantity = $data['additional_quantity'] ?? 1;
            $newPrice = $data['new_price'] ?? $existingItem->price;

            // Validation de la quantité additionnelle
            if (!is_numeric($additionalQuantity) || $additionalQuantity < 1) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Additional quantity must be at least 1'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            // Calculer la nouvelle quantité
            $newQuantity = $existingItem->quantity + (int)$additionalQuantity;

            // Vérifier que la quantité totale ne dépasse pas la limite
            if ($newQuantity > 999) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Total quantity cannot exceed 999'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            // Mettre à jour l'item existant
            $existingItem->update([
                'quantity' => $newQuantity,
                'price' => $newPrice
            ]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $existingItem->fresh(),
                'message' => 'Items merged successfully'
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while merging items',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Obtenir des suggestions d'articles similaires
     */
    public function getSimilarItems(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $params = $request->getQueryParams();

            // Vérifier l'accès en lecture à la liste
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

            $productName = $params['product_name'] ?? '';
            $limit = min((int)($params['limit'] ?? 5), 20); // Max 20

            if (empty($productName)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'VALIDATION_ERROR',
                        'message' => 'Product name is required'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
            }

            $similarItems = ListItem::where('list_id', $listId)
                ->where('product_name', 'LIKE', "%{$productName}%")
                ->limit($limit)
                ->get();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $similarItems,
                'meta' => [
                    'query' => $productName,
                    'count' => $similarItems->count(),
                    'limit' => $limit
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while retrieving similar items',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Marquer tous les articles comme achetés/non achetés
     */
    public function markAllPurchased(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];
            $data = $request->getParsedBody();
            $purchased = $data['purchased'] ?? true;

            // Vérifier les permissions d'édition
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to modify items in this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $updatedCount = ListItem::where('list_id', $listId)
                ->update(['is_purchased' => (bool)$purchased]);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => ['updated_count' => $updatedCount],
                'message' => $purchased 
                    ? "All items marked as purchased" 
                    : "All items marked as not purchased"
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while updating items',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Supprimer tous les articles achetés
     */
    public function clearPurchased(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];

            // Vérifier les permissions d'édition
            $access = $this->checkListAccess($user_id, $listId, 'edit');
            
            if (!$access) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'error' => [
                        'code' => 'PERMISSION_DENIED',
                        'message' => 'You do not have permission to modify items in this list'
                    ]
                ]));
                return $response->withHeader('Content-Type', 'application/json')->withStatus(403);
            }

            $deletedCount = ListItem::where('list_id', $listId)
                ->where('is_purchased', true)
                ->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => ['deleted_count' => $deletedCount],
                'message' => "Purchased items cleared successfully ($deletedCount items)"
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'error' => [
                    'code' => 'INTERNAL_ERROR',
                    'message' => 'An error occurred while clearing purchased items',
                    'details' => $e->getMessage()
                ]
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ NOUVELLE MÉTHODE: Obtenir les statistiques d'une liste
     */
    public function getListStats(Request $request, Response $response, array $args): Response
    {
        try {
            $user_id = $request->getAttribute('auth_id');
            $listId = $args['listId'];

            // Vérifier l'accès en lecture à la liste
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

            $items = ListItem::where('list_id', $listId)->get();
            
            $totalItems = $items->count();
            $purchasedItems = $items->where('is_purchased', true)->count();
            $pendingItems = $totalItems - $purchasedItems;
            
            $totalPrice = $items->sum(function($item) {
                return ($item->price ?? 0) * $item->quantity;
            });
            
            $purchasedPrice = $items->where('is_purchased', true)->sum(function($item) {
                return ($item->price ?? 0) * $item->quantity;
            });
            
            $pendingPrice = $totalPrice - $purchasedPrice;

            $stats = [
                'total_items' => $totalItems,
                'purchased_items' => $purchasedItems,
                'pending_items' => $pendingItems,
                'total_price' => round($totalPrice, 2),
                'purchased_price' => round($purchasedPrice, 2),
                'pending_price' => round($pendingPrice, 2),
                'completion_percentage' => $totalItems > 0 ? round(($purchasedItems / $totalItems) * 100, 1) : 0,
                'last_updated' => now()->toISOString()
            ];

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $stats
            ]));
            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
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
}