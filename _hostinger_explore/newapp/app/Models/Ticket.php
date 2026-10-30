<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ticket extends Model
{
    use HasFactory;
    protected $fillable = [
        'user_id',
        'subject_id',
        'subject',
        'message',
        'ticket_status',
        'is_notified',
        'updated_by',
        'order_ref',
        'created_at',
        'updated_at',
    ];

    public function ticketSubject()
    {
        return $this->belongsTo(Subject::class, 'subject_id');
    }


    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function updatedBy()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function replies()
    {
        return $this->hasMany(TicketReply::class)->orderBy('created_at');
    }
}
