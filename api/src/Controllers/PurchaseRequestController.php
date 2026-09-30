<?php
// src/Controllers/PurchaseRequestController.php - Demandes d'achat
// (§20, Phase 3). Espace PARTAGÉ requis.
//
// Flux : employé (add_items) crée une demande → un membre avec
// approve_purchases approuve/rejette (jamais sa propre validation
// implicite : le serveur historise qui décide) → une demande approuvée
// passe à purchased quand l'achat est fait. Chaque transition est
// historisée (purchase_request_events) et journalisée dans l'activité.
//
//  - GET    /purchase-requests?status=
//  - POST   /purchase-requests
//  - GET    /purchase-requests/{id}          (détail + historique)
//  - POST   /purchase-requests/{id}/submit   (draft → pending)
//  - POST   /purchase-requests/{id}/approve  (approve_purchases)
//  - POST   /purchase-requests/{id}/reject   (approve_purchases, commentaire)
//  - POST   /purchase-requests/{id}/purchased (add_items)
//  - POST   /purchase-requests/{id}/cancel   (demandeur ou manage_lists)

namespace App\Controllers;

use App\Models\PurchaseHistory;
use App\Models\PurchaseRequest;
use App\Models\PurchaseRequestEvent;
use App\Models\Space;
use App\Services\SpaceAccessService;
use App\Services\SpaceActivityService;
use Carbon\Carbon;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class PurchaseRequestController
{
    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    private function format(PurchaseRequest $r, bool $withEvents = false): array
    {
        $out = [
            'id' => $r->id,
            'product_name' => $r->product_name,
            'quantity' => $r->quantity,
            'unit' => $r->unit,
            'note' => $r->note,
            'status' => $r->status,
            'requested_by' => $r->requested_by,
            'requester_name' => trim(($r->requester?->first_name ?? '') . ' ' . ($r->requester?->last_name ?? '')),
            'approved_by' => $r->approved_by,
            'approver_name' => $r->approver
                ? trim(($r->approver->first_name ?? '') . ' ' . ($r->approver->last_name ?? ''))
                : null,
            'decided_at' => $r->decided_at?->toIso8601String(),
            'decision_comment' => $r->decision_comment,
            'created_at' => $r->created_at?->toIso8601String(),
        ];
        if ($withEvents) {
            $out['events'] = $r->events->map(fn($e) => [
                'from_status' => $e->from_status,
                'to_status' => $e->to_status,
                'comment' => $e->comment,
                'user_id' => $e->user_id,
                'created_at' => $e->created_at,
            ])->values();
        }
        return $out;
    }

    private function sharedSpace(Request $request, int $userId): ?Space
    {
        $space = SpaceAccessService::resolveSpace($request, $userId);
        return $space->type === Space::TYPE_PERSONAL ? null : $space;
    }

    private function recordEvent(PurchaseRequest $r, int $userId, ?string $from, string $to, ?string $comment = null): void
    {
        PurchaseRequestEvent::create([
            'request_id' => $r->id,
            'user_id' => $userId,
            'from_status' => $from,
            'to_status' => $to,
            'comment' => $comment,
            'created_at' => date('Y-m-d H:i:s'),
        ]);
    }

    public function index(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = $this->sharedSpace($request, $userId);
        if (!$space) {
            return $this->json($response, ['success' => true, 'data' => ['requests' => [], 'pending_count' => 0]]);
        }

        $status = (string) ($request->getQueryParams()['status'] ?? '');
        $query = PurchaseRequest::with(['requester:id,first_name,last_name', 'approver:id,first_name,last_name'])
            ->where('space_id', $space->id)
            ->orderByDesc('created_at');
        if (in_array($status, PurchaseRequest::STATUSES, true)) {
            $query->where('status', $status);
        }

        $requests = $query->limit(200)->get();
        $pendingCount = PurchaseRequest::where('space_id', $space->id)
            ->where('status', PurchaseRequest::STATUS_PENDING)->count();

        return $this->json($response, [
            'success' => true,
            'data' => [
                'requests' => $requests->map(fn($r) => $this->format($r))->values(),
                'pending_count' => $pendingCount,
            ],
        ]);
    }

    public function store(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = $this->sharedSpace($request, $userId);
        if (!$space) {
            return $this->json($response, ['success' => false, 'code' => 'PERSONAL_SPACE_PROTECTED'], 422);
        }
        SpaceAccessService::assertPermission($space->id, $userId, 'add_items');

        $data = (array) $request->getParsedBody();
        $product = trim((string) ($data['product_name'] ?? ''));
        if ($product === '' || mb_strlen($product) > 255) {
            return $this->json($response, ['success' => false, 'code' => 'INVALID_PRODUCT'], 422);
        }
        $asDraft = (bool) ($data['draft'] ?? false);

        $requestModel = PurchaseRequest::create([
            'space_id' => $space->id,
            'product_name' => $product,
            'normalized_name' => PurchaseHistory::normalizeProductName($product),
            'quantity' => isset($data['quantity']) && is_numeric($data['quantity'])
                ? (float) $data['quantity'] : null,
            'unit' => isset($data['unit']) ? mb_substr(trim((string) $data['unit']), 0, 10) : null,
            'note' => isset($data['note']) ? mb_substr(trim((string) $data['note']), 0, 500) : null,
            'status' => $asDraft ? PurchaseRequest::STATUS_DRAFT : PurchaseRequest::STATUS_PENDING,
            'requested_by' => $userId,
        ]);
        $this->recordEvent($requestModel, $userId, null, $requestModel->status);

        if ($requestModel->status === PurchaseRequest::STATUS_PENDING) {
            SpaceActivityService::log($space, $userId,
                SpaceActivityService::PURCHASE_REQUEST_CREATED,
                ['request_id' => $requestModel->id, 'product_name' => $product]);
        }

        return $this->json($response, [
            'success' => true,
            'data' => ['request' => $this->format($requestModel->load('requester'))],
        ], 201);
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = $this->sharedSpace($request, $userId);
        $r = $space
            ? PurchaseRequest::with(['requester:id,first_name,last_name', 'approver:id,first_name,last_name', 'events'])
                ->where('space_id', $space->id)->where('id', (int) $args['id'])->first()
            : null;
        if (!$r) {
            return $this->json($response, ['success' => false, 'code' => 'REQUEST_NOT_FOUND'], 404);
        }
        return $this->json($response, [
            'success' => true,
            'data' => ['request' => $this->format($r, withEvents: true)],
        ]);
    }

    public function submit(Request $request, Response $response, array $args): Response
    {
        return $this->transition($request, $response, (int) $args['id'], PurchaseRequest::STATUS_PENDING);
    }

    public function approve(Request $request, Response $response, array $args): Response
    {
        return $this->transition($request, $response, (int) $args['id'], PurchaseRequest::STATUS_APPROVED);
    }

    public function reject(Request $request, Response $response, array $args): Response
    {
        return $this->transition($request, $response, (int) $args['id'], PurchaseRequest::STATUS_REJECTED);
    }

    public function purchased(Request $request, Response $response, array $args): Response
    {
        return $this->transition($request, $response, (int) $args['id'], PurchaseRequest::STATUS_PURCHASED);
    }

    public function cancel(Request $request, Response $response, array $args): Response
    {
        return $this->transition($request, $response, (int) $args['id'], PurchaseRequest::STATUS_CANCELLED);
    }

    private function transition(Request $request, Response $response, int $id, string $to): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = $this->sharedSpace($request, $userId);
        $r = $space
            ? PurchaseRequest::where('space_id', $space->id)->where('id', $id)->first()
            : null;
        if (!$r) {
            return $this->json($response, ['success' => false, 'code' => 'REQUEST_NOT_FOUND'], 404);
        }

        // Droits par transition.
        switch ($to) {
            case PurchaseRequest::STATUS_PENDING: // soumettre son brouillon
                if ((int) $r->requested_by !== $userId) {
                    return $this->json($response, ['success' => false, 'code' => 'SPACE_PERMISSION_DENIED'], 403);
                }
                break;
            case PurchaseRequest::STATUS_APPROVED:
            case PurchaseRequest::STATUS_REJECTED:
                SpaceAccessService::assertPermission($space->id, $userId, 'approve_purchases');
                break;
            case PurchaseRequest::STATUS_PURCHASED:
                SpaceAccessService::assertPermission($space->id, $userId, 'add_items');
                break;
            case PurchaseRequest::STATUS_CANCELLED:
                // Le demandeur annule sa demande ; sinon manage_lists.
                if ((int) $r->requested_by !== $userId) {
                    SpaceAccessService::assertPermission($space->id, $userId, 'manage_lists');
                }
                break;
            default:
                return $this->json($response, ['success' => false, 'code' => 'INVALID_STATUS'], 422);
        }

        if (!$r->canTransitionTo($to)) {
            return $this->json($response, ['success' => false, 'code' => 'INVALID_TRANSITION', 'from' => $r->status], 422);
        }

        $data = (array) $request->getParsedBody();
        $comment = isset($data['comment']) ? mb_substr(trim((string) $data['comment']), 0, 500) : null;
        if ($to === PurchaseRequest::STATUS_REJECTED && ($comment === null || $comment === '')) {
            // Un refus s'explique (§20) — commentaire obligatoire.
            return $this->json($response, ['success' => false, 'code' => 'COMMENT_REQUIRED'], 422);
        }

        $from = $r->status;
        $r->status = $to;
        if (in_array($to, [PurchaseRequest::STATUS_APPROVED, PurchaseRequest::STATUS_REJECTED], true)) {
            $r->approved_by = $userId;
            $r->decided_at = Carbon::now();
            $r->decision_comment = $comment;
        }
        $r->save();
        $this->recordEvent($r, $userId, $from, $to, $comment);

        $activityType = match ($to) {
            PurchaseRequest::STATUS_PENDING => SpaceActivityService::PURCHASE_REQUEST_CREATED,
            PurchaseRequest::STATUS_APPROVED => SpaceActivityService::PURCHASE_REQUEST_APPROVED,
            PurchaseRequest::STATUS_REJECTED => SpaceActivityService::PURCHASE_REQUEST_REJECTED,
            default => null,
        };
        if ($activityType !== null) {
            SpaceActivityService::log($space, $userId, $activityType,
                ['request_id' => $r->id, 'product_name' => $r->product_name]);
        }

        return $this->json($response, [
            'success' => true,
            'data' => ['request' => $this->format($r->load(['requester', 'approver']))],
        ]);
    }
}
