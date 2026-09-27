<?php
// src/Models/RecurringList.php - Modèle de liste récurrente.

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class RecurringList extends Model
{
    protected $table = 'recurring_lists';

    protected $fillable = [
        'user_id',
        'name',
        'recurrence_type',
        'weekday',
        'next_run_at',
        'store_id',
        'enabled',
        'auto_generate',
        'last_generated_at',
    ];

    protected $casts = [
        'weekday' => 'integer',
        'next_run_at' => 'datetime',
        'enabled' => 'boolean',
        'auto_generate' => 'boolean',
        'last_generated_at' => 'datetime',
    ];

    public function items(): HasMany
    {
        return $this->hasMany(RecurringListItem::class, 'recurring_list_id');
    }

    /**
     * Prochaine occurrence après une génération (ou après la date donnée).
     */
    public function computeNextRun(?Carbon $from = null): Carbon
    {
        $from ??= Carbon::now();
        switch ($this->recurrence_type) {
            case 'monthly':
                return $from->copy()->addMonthNoOverflow()->startOfDay()->addHours(8);
            case 'biweekly':
                $next = $from->copy()->addWeeks(2);
                break;
            default: // weekly
                $next = $from->copy()->addWeek();
        }
        if ($this->weekday !== null) {
            // Carbon : 1 = lundi ... 7 = dimanche (isoWeekday)
            $next = $next->startOfWeek()->addDays($this->weekday - 1);
            if ($next->lessThanOrEqualTo($from)) {
                $next = $next->addWeek();
            }
        }
        return $next->startOfDay()->addHours(8);
    }
}
