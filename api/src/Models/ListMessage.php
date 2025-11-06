<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ListMessage extends Model
{
    use SoftDeletes;

    protected $table = 'list_messages';
    protected $primaryKey = 'id';

    public $timestamps = true;

    protected $fillable = [
        'list_id',
        'user_id',
        'message',
        'message_type',
        'image_url',
        'is_read',
        'created_at',
        'updated_at',
        'deleted_at'
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime'
    ];

    protected $hidden = [
        'deleted_at'
    ];

    /**
     * Get the shopping list that owns the message.
     */
    public function shoppingList(): BelongsTo
    {
        return $this->belongsTo(ShoppingList::class, 'list_id');
    }

    /**
     * Get the user that created the message.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the read status for this message.
     */
    public function readStatus(): HasMany
    {
        return $this->hasMany(MessageReadStatus::class, 'message_id');
    }

    /**
     * Check if a user has read this message.
     */
    public function isReadBy(int $userId): bool
    {
        return $this->readStatus()
            ->where('user_id', $userId)
            ->exists();
    }

    /**
     * Mark message as read by a user.
     */
    public function markAsReadBy(int $userId): void
    {
        MessageReadStatus::firstOrCreate([
            'message_id' => $this->id,
            'user_id' => $userId
        ]);
    }

    /**
     * Get unread count for a list by a user.
     */
    public static function getUnreadCountForList(int $listId, int $userId): int
    {
        return self::where('list_id', $listId)
            ->where('user_id', '!=', $userId) // Exclude own messages
            ->whereDoesntHave('readStatus', function ($query) use ($userId) {
                $query->where('user_id', $userId);
            })
            ->count();
    }

    /**
     * Format message for API response.
     */
    public function toArray(): array
    {
        $data = parent::toArray();

        // Add user info
        if ($this->relationLoaded('user') && $this->user) {
            $fullName = trim(($this->user->first_name ?? '') . ' ' . ($this->user->last_name ?? ''));
            if (empty($fullName)) {
                $fullName = $this->user->email ?? 'Unknown User';
            }

            $data['user'] = [
                'id' => $this->user->id,
                'name' => $fullName,
                'email' => $this->user->email ?? '',
            ];
        }

        // Add read count
        if ($this->relationLoaded('readStatus')) {
            $data['read_by_count'] = $this->readStatus->count();
        }

        return $data;
    }
}
