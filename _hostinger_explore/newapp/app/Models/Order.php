<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory, SoftDeletes;
    protected $fillable = [
        'order_number',
        'user_id',
        'deal_id',
        'address_id',
        'order_amount',
        'to_card_holder',
        'earnings',
        'account_mobile_number',
        'store_order_id',
        'account_order_pdf',
        'account_order_screenshot',
        'delivery_date',
        'order_start',
        'order_end',
        'delivery_partner_id',
        'order_tracking_id',
        'is_out_for_delivery',
        'order_delivery_otp',
        'order_gst',
        'order_status',
        'is_ready_for_payout',
        'is_payout_requested',
        'order_date',
        'is_payout',
        'transaction_id',
        'transaction_file',
        'payout_notes',
        'status',
        'total_amount',
        'is_admin_cancelled',
        'cancel_reason',
        'is_pine_lab_deal',
        'payment_screenshot',
        'is_payment_verified',
        'tds_amount',
    ];

    public function deal()
    {
        return $this->belongsTo(Deal::class);
    }
}
