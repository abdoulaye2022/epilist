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
    /**
     * Droit d'écriture sur la liste. Passe par le service unifié : sans
     * lui, un membre d'un espace partagé (foyer, restaurant) ne pouvait
     * PAS ajouter de photo, seuls le propriétaire et les partages
     * historiques étant reconnus.
     */
    private function canEditList(int $userId, int $listId): bool
    {
        return \App\Services\ListAccessService::check($userId, $listId, 'edit') !== null;
    }

    /**
     * Droit de LECTURE sur la liste. Un membre en lecture seule a le
     * droit de regarder un reçu : lui demander le droit d'écriture
     * reviendrait à lui cacher la facture de ses propres courses.
     */
    private function canReadList(int $userId, int $listId): bool
    {
        return \App\Services\ListAccessService::check($userId, $listId, 'read') !== null;
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

            // La photo appartient au PRODUIT, pas a cet article-ci : la
            // meme boite de pates photographiee aujourd'hui doit
            // illustrer l'alerte de prix de la semaine prochaine, et la
            // suggestion du mois suivant. Un echec ici ne doit jamais
            // faire perdre la photo qui vient d'etre prise.
            try {
                $liste = \App\Models\ShoppingList::find($listId);
                \App\Models\ProductImage::poser(
                    $liste?->space_id,
                    (string) $item->product_name,
                    $url,
                    (int) $userId
                );
            } catch (\Throwable $e) {
                error_log('[ImageController] product_images: ' . $e->getMessage());
            }

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
    /**
     * POST /shopping-lists/{listId}/receipts/{receiptId}/image
     * Photo du reçu papier (champ multipart « image »). Remplace la
     * précédente s'il y en avait une.
     */
    public function uploadReceiptImage(Request $request, Response $response, array $args): Response
    {
        $userId = $request->getAttribute('auth_id');
        $listId = (int) $args['listId'];
        $receiptId = (int) $args['receiptId'];

        if (!$this->canEditList($userId, $listId)) {
            return $this->json($response, [
                'success' => false,
                'message' => "Vous n'avez pas la permission de modifier cette liste",
            ], 403);
        }

        $receipt = \App\Models\ListReceipt::where('list_id', $listId)->find($receiptId);
        if (!$receipt) {
            return $this->json($response, ['success' => false, 'message' => 'Facture introuvable'], 404);
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
            // 1600 px : un reçu doit rester lisible une fois rangé.
            //
            // PRIVÉ, et c'est le cœur de la correction : un reçu porte le
            // magasin, la date et les montants. Il était téléversé en
            // lecture publique — l'URL suffisait à le lire, sans compte.
            // On garde désormais la CLÉ de l'objet ; l'image ne se
            // regarde qu'à travers une URL signée de quinze minutes,
            // délivrée à qui a le droit de voir la liste.
            $cle = $storage->uploadPrivee($bytes, 'receipts', 1600);

            // L'ancienne photo part, qu'elle ait été publique ou privée.
            $storage->deleteByUrl($receipt->image_path ?: $receipt->image_url);

            $receipt->image_path = $cle;
            // Plus aucune URL publique n'existe pour ce reçu : laisser
            // l'ancienne en base ferait croire aux applications d'avant
            // qu'une image est joignable, et elles afficheraient une
            // erreur de chargement au lieu de « pas de photo ».
            $receipt->image_url = null;
            $receipt->save();

            return $this->json($response, [
                'success' => true,
                'data' => $receipt->fresh(),
                'message' => 'Photo ajoutée',
            ]);
        } catch (\InvalidArgumentException $e) {
            return $this->json($response, ['success' => false, 'message' => $e->getMessage()], 422);
        } catch (\Throwable $e) {
            error_log('uploadReceiptImage: ' . $e->getMessage());
            return $this->json($response, [
                'success' => false,
                'message' => "Impossible d'enregistrer la photo",
            ], 500);
        }
    }

    /**
     * GET /shopping-lists/{listId}/receipts/{receiptId}/image-url
     *
     * Rend une URL signée de quinze minutes pour regarder la photo du
     * reçu. C'est la SEULE façon de la voir depuis la migration 015 :
     * l'objet n'est plus lisible publiquement.
     *
     * Le droit est vérifié ici, et une seule fois, par le service d'accès
     * aux listes : propriétaire, membre actif de l'espace (foyer,
     * restaurant) ou partage accepté. Toute autre personne reçoit 403,
     * même si elle connaît l'identifiant du reçu.
     */
    public function receiptImageUrl(Request $request, Response $response, array $args): Response
    {
        $userId = $request->getAttribute('auth_id');
        $listId = (int) $args['listId'];
        $receiptId = (int) $args['receiptId'];

        if (!$this->canReadList($userId, $listId)) {
            return $this->json($response, [
                'success' => false,
                'message' => "Vous n'avez pas accès à cette liste",
            ], 403);
        }

        $receipt = \App\Models\ListReceipt::where('list_id', $listId)->find($receiptId);
        if (!$receipt) {
            return $this->json($response, ['success' => false, 'message' => 'Facture introuvable'], 404);
        }

        try {
            $storage = new ImageStorageService();
            $cle = $receipt->cleDeLImage($storage);
            if ($cle === null) {
                return $this->json($response, [
                    'success' => false,
                    'message' => 'Ce reçu n\'a pas de photo',
                ], 404);
            }

            $signee = $storage->urlSignee($cle);

            return $this->json($response, [
                'success' => true,
                'data' => [
                    'url' => $signee['url'],
                    'expires_at' => $signee['expire_a'],
                ],
            ]);
        } catch (\Throwable $e) {
            error_log('receiptImageUrl: ' . $e->getMessage());
            return $this->json($response, [
                'success' => false,
                'message' => "Impossible d'ouvrir la photo",
            ], 500);
        }
    }

    /** DELETE /shopping-lists/{listId}/receipts/{receiptId}/image */
    public function deleteReceiptImage(Request $request, Response $response, array $args): Response
    {
        $userId = $request->getAttribute('auth_id');
        $listId = (int) $args['listId'];
        $receiptId = (int) $args['receiptId'];

        if (!$this->canEditList($userId, $listId)) {
            return $this->json($response, [
                'success' => false,
                'message' => "Vous n'avez pas la permission de modifier cette liste",
            ], 403);
        }

        $receipt = \App\Models\ListReceipt::where('list_id', $listId)->find($receiptId);
        if (!$receipt) {
            return $this->json($response, ['success' => false, 'message' => 'Facture introuvable'], 404);
        }

        try {
            (new ImageStorageService())->deleteByUrl($receipt->image_path ?: $receipt->image_url);
        } catch (\Throwable $e) {
            error_log('deleteReceiptImage: ' . $e->getMessage());
        }
        $receipt->image_path = null;
        $receipt->image_url = null;
        $receipt->save();

        return $this->json($response, [
            'success' => true,
            'data' => $receipt->fresh(),
            'message' => 'Photo retirée',
        ]);
    }

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
