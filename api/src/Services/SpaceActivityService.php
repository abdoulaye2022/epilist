<?php
// src/Services/SpaceActivityService.php - Journal d'activité d'un
// espace (§12) : événements STRUCTURÉS (type + payload), jamais de
// phrase préformatée — le client rend le texte traduit fr/en.
// Journal réservé aux espaces PARTAGÉS : l'activité d'un espace
// personnel n'apporte rien (l'utilisateur est seul).
// L'écriture est best-effort : un échec de journalisation ne doit
// jamais faire échouer l'action métier.

namespace App\Services;

use App\Models\Space;
use Illuminate\Database\Capsule\Manager as DB;

class SpaceActivityService
{
    // Types d'événements Phase 2. En ajouter = ajouter une clé de
    // traduction côté app, rien d'autre.
    public const LIST_CREATED = 'list_created';
    public const ITEM_ADDED = 'item_added';
    public const ITEM_PURCHASED = 'item_purchased';
    public const RECEIPT_ADDED = 'receipt_added';
    public const BUDGET_CREATED = 'budget_created';
    public const MEMBER_JOINED = 'member_joined';
    public const MEMBER_LEFT = 'member_left';
    public const INVENTORY_OUT = 'inventory_out';
    public const PURCHASE_REQUEST_CREATED = 'purchase_request_created';
    public const PURCHASE_REQUEST_APPROVED = 'purchase_request_approved';
    public const PURCHASE_REQUEST_REJECTED = 'purchase_request_rejected';
    public const PRICE_ALERT_TRIGGERED = 'price_alert_triggered';

    public static function log(?Space $space, ?int $userId, string $type, array $payload = []): void
    {
        try {
            if (!$space || $space->type === Space::TYPE_PERSONAL) {
                return;
            }
            DB::table('space_activities')->insert([
                'space_id' => $space->id,
                'user_id' => $userId,
                'type' => $type,
                'payload' => json_encode($payload, JSON_UNESCAPED_UNICODE),
                'created_at' => date('Y-m-d H:i:s'),
            ]);
        } catch (\Throwable $e) {
            error_log('SpaceActivity log failed: ' . $e->getMessage());
        }
    }

    /** Dernières activités, avec le prénom de l'auteur. */
    public static function recent(int $spaceId, int $limit = 30): array
    {
        return DB::table('space_activities as a')
            ->leftJoin('users as u', 'u.id', '=', 'a.user_id')
            ->where('a.space_id', $spaceId)
            ->orderByDesc('a.id')
            ->limit(max(1, min(100, $limit)))
            ->get(['a.id', 'a.type', 'a.payload', 'a.created_at', 'a.user_id', 'u.first_name', 'u.last_name'])
            ->map(fn($row) => [
                'id' => $row->id,
                'type' => $row->type,
                'payload' => json_decode($row->payload ?? '{}', true),
                'user_id' => $row->user_id,
                'user_name' => trim(($row->first_name ?? '') . ' ' . ($row->last_name ?? '')),
                'created_at' => $row->created_at,
            ])
            ->all();
    }
}
