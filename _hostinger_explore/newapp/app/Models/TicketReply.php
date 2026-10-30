<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TicketReply extends Model
{
    protected $fillable = [
        'ticket_id',
        'staff_user_id',
        'staff_name',
        'user_id',
        'is_from_user',
        'message',
    ];

    protected $casts = [
        'is_from_user' => 'boolean',
    ];

    public function ticket()
    {
        return $this->belongsTo(Ticket::class);
    }
}
