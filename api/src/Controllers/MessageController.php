<?php

namespace App\Controllers;

use App\Models\ListMessage;
use App\Models\ShoppingList;
use App\Models\User;
use App\Services\NotificationService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class MessageController
{
    /**
     * Get messages for a shopping list
     */
    public function getMessages(Request $request, Response $response, array $args): Response
    {
        try {
            $listId = (int) $args['listId'];
            $userId = $request->getAttribute('user_id');

            // Get query parameters
            $params = $request->getQueryParams();
            $limit = isset($params['limit']) ? (int) $params['limit'] : 50;
            $offset = isset($params['offset']) ? (int) $params['offset'] : 0;

            // Check if user has access to this list
            $list = ShoppingList::find($listId);
            if (!$list) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'List not found'
                ]));
                return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
            }

            // Check access
            if (!$list->canBeAccessedBy($userId)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'You do not have access to this list'
                ]));
                return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
            }

            // Get total count
            $total = ListMessage::where('list_id', $listId)->count();

            // Get messages with pagination (newest first)
            $messages = ListMessage::with('user')
                ->where('list_id', $listId)
                ->orderBy('created_at', 'desc')
                ->limit($limit)
                ->offset($offset)
                ->get();

            // Get unread count for this user
            $unreadCount = ListMessage::getUnreadCountForList($listId, $userId);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'messages' => $messages->toArray(),
                    'total' => $total,
                    'unread_count' => $unreadCount
                ]
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Error getting messages: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to get messages'
            ]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Send a message to a shopping list
     */
    public function sendMessage(Request $request, Response $response, array $args): Response
    {
        try {
            $listId = (int) $args['listId'];
            $userId = $request->getAttribute('user_id');

            $data = $request->getParsedBody();

            // Validate input
            $v = new Validator($data);
            $v->rule('required', 'message')->message('Message is required');
            $v->rule('in', 'message_type', ['text', 'image'])->message('Invalid message type');

            if (!$v->validate()) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $v->errors()
                ]));
                return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
            }

            // Check if user has access to this list
            $list = ShoppingList::find($listId);
            if (!$list) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'List not found'
                ]));
                return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
            }

            // Check access
            if (!$list->canBeAccessedBy($userId)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'You do not have access to this list'
                ]));
                return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
            }

            // Create message
            $message = ListMessage::create([
                'list_id' => $listId,
                'user_id' => $userId,
                'message' => $data['message'],
                'message_type' => $data['message_type'] ?? 'text',
                'image_url' => $data['image_url'] ?? null
            ]);

            // Load user relation
            $message->load('user');

            // Send push notifications to all users who have access to this list
            try {
                $sender = User::find($userId);
                $recipientUserIds = $list->getAllAccessUsers();

                // Prepare message preview
                $messagePreview = $data['message_type'] === 'image'
                    ? '📷 Photo'
                    : substr($data['message'], 0, 100);

                $notificationService = new NotificationService();
                $notificationResult = $notificationService->sendNewMessageNotification(
                    $sender,
                    $list,
                    $messagePreview,
                    $recipientUserIds
                );

                error_log("Notification sent for new message: " . json_encode($notificationResult));
            } catch (\Exception $e) {
                // Log error but don't fail the request
                error_log("Failed to send notification for new message: " . $e->getMessage());
            }

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Message sent successfully',
                'data' => $message->toArray()
            ]));

            return $response->withStatus(201)->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Error sending message: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to send message'
            ]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Get unread message count for a list
     */
    public function getUnreadCount(Request $request, Response $response, array $args): Response
    {
        try {
            $listId = (int) $args['listId'];
            $userId = $request->getAttribute('user_id');

            // Check if user has access to this list
            $list = ShoppingList::find($listId);
            if (!$list) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'List not found'
                ]));
                return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
            }

            // Check access
            if (!$list->canBeAccessedBy($userId)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'You do not have access to this list'
                ]));
                return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
            }

            $unreadCount = ListMessage::getUnreadCountForList($listId, $userId);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'unread_count' => $unreadCount
                ]
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Error getting unread count: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to get unread count'
            ]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Mark a message as read
     */
    public function markAsRead(Request $request, Response $response, array $args): Response
    {
        try {
            $messageId = (int) $args['messageId'];
            $userId = $request->getAttribute('user_id');

            $message = ListMessage::find($messageId);
            if (!$message) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Message not found'
                ]));
                return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
            }

            // Check if user has access to the list
            $list = $message->shoppingList;
            if (!$list || !$list->canBeAccessedBy($userId)) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'You do not have access to this list'
                ]));
                return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
            }

            // Mark as read
            $message->markAsReadBy($userId);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Message marked as read'
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Error marking message as read: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to mark message as read'
            ]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Delete a message
     */
    public function deleteMessage(Request $request, Response $response, array $args): Response
    {
        try {
            $messageId = (int) $args['messageId'];
            $userId = $request->getAttribute('user_id');

            $message = ListMessage::find($messageId);
            if (!$message) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'Message not found'
                ]));
                return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
            }

            // Check if user owns the message
            if ($message->user_id !== $userId) {
                $response->getBody()->write(json_encode([
                    'success' => false,
                    'message' => 'You can only delete your own messages'
                ]));
                return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
            }

            // Soft delete the message
            $message->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Message deleted successfully'
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            error_log("Error deleting message: " . $e->getMessage());
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to delete message'
            ]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }
}
