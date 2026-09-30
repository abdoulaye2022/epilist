<?php
// src/Models/PurchaseRequest.php - Demande d'achat (§20) :
// employé → besoin → demande → validation → achat. Chaque changement
// de statut est historisé dans purchase_request_events.

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseRequest extends Model
{
    protected $table = 'purchase_requests';

    public const STATUS_DRAFT = 'draft';
    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_PURCHASED = 'purchased';
    public const STATUS_CANCELLED = 'cancelled';

    public const STATUSES = [
        self::STATUS_DRAFT, self::STATUS_PENDING, self::STATUS_APPROVED,
        self::STATUS_REJECTED, self::STATUS_PURCHASED, self::STATUS_CANCELLED,
    ];

    /** Transitions autorisées (from => [to...]). */
    public const TRANSITIONS = [
        self::STATUS_DRAFT => [self::STATUS_PENDING, self::STATUS_CANCELLED],
        self::STATUS_PENDING => [self::STATUS_APPROVED, self::STATUS_REJECTED, self::STATUS_CANCELLED],
        self::STATUS_APPROVED => [self::STATUS_PURCHASED, self::STATUS_CANCELLED],
        self::STATUS_REJECTED => [],
        self::STATUS_PURCHASED => [],
        self::STATUS_CANCELLED => [],
    ];

    protected $fillable = [
        'space_id', 'product_name', 'normalized_name', 'quantity', 'unit',
        'note', 'status', 'requested_by', 'approved_by', 'decided_at',
        'decision_comment',
    ];

    protected $casts = [
        'quantity' => 'float',
        'decided_at' => 'datetime',
    ];

    public function requester()
    {
        return $this->belongsTo(User::class, 'requested_by');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function events()
    {
        return $this->hasMany(PurchaseRequestEvent::class, 'request_id')->orderBy('id');
    }

    public function canTransitionTo(string $status): bool
    {
        return in_array($status, self::TRANSITIONS[$this->status] ?? [], true);
    }
}
