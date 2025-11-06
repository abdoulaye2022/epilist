<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MessageReadStatus extends Model
{
    protected $table = 'message_read_status';
    protected $primaryKey = 'id';

    public $timestamps = false; // Only read_at timestamp

    protected $fillable = [
        'message_id',
        'user_id',
        'read_at'
    ];

    protected $casts = [
        'read_at' => 'datetime'
    ];

    /**
     * Get the message that this read status belongs to.
     */
    public function message(): BelongsTo
    {
        return $this->belongsTo(ListMessage::class, 'message_id');
    }

    /**
     * Get the user who read the message.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
