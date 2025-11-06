<?php

namespace App\Controllers;

use App\Models\ListMessage;
use App\Models\MessageReadStatus;
use App\Models\ShoppingList;
use App\Models\SharedList;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class MessageController
{
    /**
     * Get all messages for a shopping list
     * GET /api/lists/{listId}/messages
     */
    public function getMessages(Request $request, Response $response, array $args): Response
    {
        $listId = (int) $args['listId'];
        $userId = $request->getAttribute('user_id');

        // Verify user has access to this list
        if (!$this->userHasAccessToList($userId, $listId)) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Access denied to this list'
            ]));
            return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
        }

        // Get query parameters for pagination
        $params = $request->getQueryParams();
        $limit = isset($params['limit']) ? (int) $params['limit'] : 50;
        $offset = isset($params['offset']) ? (int) $params['offset'] : 0;

        // Get messages with user information
        $messages = ListMessage::where('list_id', $listId)
            ->with(['user', 'readStatus'])
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->offset($offset)
            ->get();

        // Get unread count
        $unreadCount = ListMessage::getUnreadCountForList($listId, $userId);

        $response->getBody()->write(json_encode([
            'success' => true,
            'data' => [
                'messages' => $messages,
                'unread_count' => $unreadCount,
                'total' => ListMessage::where('list_id', $listId)->count()
            ]
        ]));

        return $response->withHeader('Content-Type', 'application/json');
    }

    /**
     * Send a new message
     * POST /api/lists/{listId}/messages
     */
    public function sendMessage(Request $request, Response $response, array $args): Response
    {
        $listId = (int) $args['listId'];
        $userId = $request->getAttribute('user_id');
        $data = $request->getParsedBody();

        // Verify user has access to this list
        if (!$this->userHasAccessToList($userId, $listId)) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Access denied to this list'
            ]));
            return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
        }

        // Validate message data
        $errors = $this->validateMessageData($data);
        if (!empty($errors)) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $errors
            ]));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        try {
            // Create message
            $message = ListMessage::create([
                'list_id' => $listId,
                'user_id' => $userId,
                'message' => $data['message'],
                'message_type' => $data['message_type'] ?? 'text',
                'image_url' => $data['image_url'] ?? null,
            ]);

            // Load user relation
            $message->load('user');

            // Mark as read by sender
            $message->markAsReadBy($userId);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Message sent successfully',
                'data' => $message
            ]));

            return $response->withStatus(201)->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to send message: ' . $e->getMessage()
            ]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Mark message as read
     * POST /api/messages/{messageId}/read
     */
    public function markAsRead(Request $request, Response $response, array $args): Response
    {
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

        // Verify user has access to this list
        if (!$this->userHasAccessToList($userId, $message->list_id)) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Access denied'
            ]));
            return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
        }

        try {
            $message->markAsReadBy($userId);

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Message marked as read'
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to mark message as read: ' . $e->getMessage()
            ]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Delete a message
     * DELETE /api/messages/{messageId}
     */
    public function deleteMessage(Request $request, Response $response, array $args): Response
    {
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

        // Only message creator or list owner can delete
        $list = ShoppingList::find($message->list_id);
        if ($message->user_id !== $userId && $list->user_id !== $userId) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'You can only delete your own messages'
            ]));
            return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
        }

        try {
            $message->delete();

            $response->getBody()->write(json_encode([
                'success' => true,
                'message' => 'Message deleted successfully'
            ]));

            return $response->withHeader('Content-Type', 'application/json');

        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Failed to delete message: ' . $e->getMessage()
            ]));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }
    }

    /**
     * Get unread message count for a list
     * GET /api/lists/{listId}/messages/unread-count
     */
    public function getUnreadCount(Request $request, Response $response, array $args): Response
    {
        $listId = (int) $args['listId'];
        $userId = $request->getAttribute('user_id');

        // Verify user has access to this list
        if (!$this->userHasAccessToList($userId, $listId)) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Access denied to this list'
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
    }

    /**
     * Validate message data
     */
    private function validateMessageData(array $data): array
    {
        $validator = new Validator($data);
        $validator->lang('en');

        $validator->rule('required', 'message')->message('Message content is required');
        $validator->rule('lengthMin', 'message', 1)->message('Message cannot be empty');
        $validator->rule('lengthMax', 'message', 5000)->message('Message cannot exceed 5000 characters');

        $validator->rule('in', 'message_type', ['text', 'image', 'system'])
            ->message('Message type must be text, image, or system');

        if (isset($data['message_type']) && $data['message_type'] === 'image') {
            $validator->rule('required', 'image_url')->message('Image URL is required for image messages');
            $validator->rule('url', 'image_url')->message('Image URL must be a valid URL');
        }

        if (!$validator->validate()) {
            return $validator->errors();
        }

        return [];
    }

    /**
     * Check if user has access to a list (owner or shared with)
     */
    private function userHasAccessToList(int $userId, int $listId): bool
    {
        $list = ShoppingList::find($listId);

        if (!$list) {
            return false;
        }

        // Check if user is the owner
        if ($list->user_id === $userId) {
            return true;
        }

        // Check if list is shared with user
        $sharedList = SharedList::where('list_id', $listId)
            ->where('shared_with_user_id', $userId)
            ->where('status', 'accepted')
            ->first();

        return $sharedList !== null;
    }
}
