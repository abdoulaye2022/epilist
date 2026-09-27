<?php
// src/Controllers/ImageController.php — avatars utilisateurs et photos de
// produits. La securite (taille, octets, re-encodage anti-malware, nom
// aleatoire) est dans ImageStorageService.

namespace App\Controllers;

use App\Models\ListItem;
use App\Models\SharedList;
use App\Models\ShoppingList;
use App\Models\User;
use App\Services\ImageStorageService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class ImageController
{
    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    /** Récupère les octets du fichier 'image' du multipart, ou null. */
    private function readUploadedImage(Request $request): ?string
    {
        $files = $request->getUploadedFiles();
        $file = $files['image'] ?? null;
        if ($file === null || $file->getError() !== UPLOAD_ERR_OK) {
            return null;
        }
        return (string) $file->getStream();
    }

    /** L'utilisateur peut-il modifier les articles de cette liste ? */
    private function canEditList(int $userId, int $listId): bool
    {
        $isOwner = ShoppingList::where('id', $listId)->where('user_id', $userId)->exists();
        if ($isOwner) {
            return true;
        }
        $share = SharedList::where('list_id', $listId)
            ->where('shared_with_user_id', $userId)
            ->where('status', SharedList::STATUS_ACCEPTED)
            ->where('is_active', true)
            ->first();
        return $share !== null && $share->canEdit();
    }

    /** POST /user/avatar — multipart champ 'image' */
    public function uploadAvatar(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('auth_id');
        $bytes = $this->readUploadedImage($request);
        if ($bytes === null) {
            return $this->json($response, [
                'success' => false,
                'message' => "Fichier manquant (champ multipart 'image')",
            ], 422);
        }

        try {
            $user = User::findOrFail($userId);
            $storage = new ImageStorageService();
            // 512 px suffisent largement pour un avatar
            $url = $storage->uploadSanitized($bytes, 'avatars', 512);
            $storage->deleteByUrl($user->avatar_url);
            $user->avatar_url = $url;
            $user->save();

            return $this->json($response, [
                'success' => true,
                'data' => ['avatar_url' => $url],
                'message' => 'Avatar mis à jour',
            ]);
        } catch (\InvalidArgumentException $e) {
            return $this->json($response, ['success' => false, 'message' => $e->getMessage()], 422);
        } catch (\Throwable $e) {
            error_log('[ImageController] avatar: ' . $e->getMessage());
            return $this->json($response, [
                'success' => false,
                'message' => "Stockage d'images indisponible",
            ], 503);
        }
    }

    /** DELETE /user/avatar */
    public function deleteAvatar(Request $request, Response $response): Response
    {
        $userId = $request->getAttribute('auth_id');
        try {
            $user = User::findOrFail($userId);
            (new ImageStorageService())->deleteByUrl($user->avatar_url);
            $user->avatar_url = null;
            $user->save();
            return $this->json($response, ['success' => true, 'message' => 'Avatar supprimé']);
        } catch (\Throwable $e) {
            error_log('[ImageController] delete avatar: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur'], 500);
        }
    }

    /** POST /shopping-lists/{listId}/items/{itemId}/image — multipart 'image' */
    public function uploadItemImage(Request $request, Response $response, array $args): Response
    {
        $userId = $request->getAttribute('auth_id');
        $listId = (int) $args['listId'];
        $itemId = (int) $args['itemId'];

        if (!$this->canEditList($userId, $listId)) {
            return $this->json($response, [
                'success' => false,
                'message' => "Vous n'avez pas la permission de modifier cette liste",
            ], 403);
        }

        $item = ListItem::where('list_id', $listId)->find($itemId);
        if (!$item) {
            return $this->json($response, ['success' => false, 'message' => 'Article introuvable'], 404);
        }

        $bytes = $this->readUploadedImage($request);
        if ($bytes === null) {
            return $this->json($response, [
                'success' => false,
                'message' => "Fichier manquant (champ multipart 'image')",
            ], 422);
        }

        try {
            $storage = new ImageStorageService();
            $url = $storage->uploadSanitized($bytes, 'items', 1280);
            $storage->deleteByUrl($item->image_url);
            $item->image_url = $url;
            $item->save();

            return $this->json($response, [
                'success' => true,
                'data' => $item->fresh(),
                'message' => 'Photo ajoutée',
            ]);
        } catch (\InvalidArgumentException $e) {
            return $this->json($response, ['success' => false, 'message' => $e->getMessage()], 422);
        } catch (\Throwable $e) {
            error_log('[ImageController] item image: ' . $e->getMessage());
            return $this->json($response, [
                'success' => false,
                'message' => "Stockage d'images indisponible",
            ], 503);
        }
    }

    /** DELETE /shopping-lists/{listId}/items/{itemId}/image */
    public function deleteItemImage(Request $request, Response $response, array $args): Response
    {
        $userId = $request->getAttribute('auth_id');
        $listId = (int) $args['listId'];
        $itemId = (int) $args['itemId'];

        if (!$this->canEditList($userId, $listId)) {
            return $this->json($response, [
                'success' => false,
                'message' => "Vous n'avez pas la permission de modifier cette liste",
            ], 403);
        }

        $item = ListItem::where('list_id', $listId)->find($itemId);
        if (!$item) {
            return $this->json($response, ['success' => false, 'message' => 'Article introuvable'], 404);
        }

        try {
            (new ImageStorageService())->deleteByUrl($item->image_url);
            $item->image_url = null;
            $item->save();
            return $this->json($response, ['success' => true, 'data' => $item->fresh(), 'message' => 'Photo supprimée']);
        } catch (\Throwable $e) {
            error_log('[ImageController] delete item image: ' . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur'], 500);
        }
    }
}
