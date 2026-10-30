<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class OrderDeal extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'order_deal';

    protected $fillable = [
        'order_id',
        'name',
        'image',
        'color',
        'gst_number',
        'pin_code',
        'card_holder_earn',
        'gst_content',
        'status',
        'description',
        'store_id',
        'dealer_id',
        'bank_card_id',
        'order_qty',
        'offer_tittle',
        'offer_text',
        'offer_link1',
        'offer_link2',
        'offer_link3',
        'product_price',
        'dealer_price',
        'discount',
        'cash_reward',
        'cashback',
        'card_holder_spend',
        'card_holder_receive',
        'deal_status',
        'maximum_discount',
        'company_name',
        'gst_message',
        'instruction',
        'extra_note',
        'is_pine_lab',
        'pine_lab_url',
        'deleted_at',
        'created_by',
        'updated_by',
    ];
}