<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
// use Illuminate\Database\Eloquent\SoftDeletes;

class DealImage extends Model
{
    use HasFactory;

    protected $fillable = [
        'deal_id',
        'image',
    ];

    /**
     * Get the parent deal.
     */
    public function deal()
    {
        return $this->belongsTo(Deal::class);
    }
}