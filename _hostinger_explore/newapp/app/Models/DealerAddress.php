<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class DealerAddress extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'dealer_id',
        'display_name',
        'address',
        'address2',
        'landmark',
        'city',
        'state',
        'country',
        'pincode',
        'is_reserved',
        'is_ordered',
        'reserved_date_time',
        'status',
        'created_by',
        'updated_by'
    ];

    protected $dates = ['deleted_at'];
}
