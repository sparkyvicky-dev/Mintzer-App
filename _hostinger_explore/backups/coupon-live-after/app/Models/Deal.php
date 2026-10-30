<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Deal extends Model
{
    use HasFactory, SoftDeletes;
    protected $fillable = [
        'name',
        'image',
        'color',
        'status',
        'description',
        'store_id',
        'dealer_id',
        'bank_card_id',
        'order_qty',
        'offer_tittle',
        'offer_text',
        'coupon_code',
        'offer_link1',
        'offer_link2',
        'offer_link3',
        'cash_reward',
        'product_price',
        'dealer_price',
        'cashback',
        'discount',
        'platform_fee',
        'card_fee',
        'card_holder_spend',
        'card_holder_recieve',
        'card_holder_earn',
        'deal_status',
        'maximum_discount',
        'company_name',
        'gst_number',
        'gst_message',
        'gst_content',
        'instruction',
        'extra_note',
        'is_pine_lab',
        'pine_lab_url',
        'popup_on',
        'popup_image',
        'popup_link',
        'created_by',
        'updated_by',
    ];


    public function store()
    {
        return $this->belongsTo(Store::class, 'store_id');
    }

    public function dealer()
    {
        return $this->belongsTo(User::class, 'dealer_id');
    }

    public function bankCard()
    {
        return $this->belongsTo(BankCard::class, 'bank_card_id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function dealImages()
    {
        return $this->hasMany(DealImage::class);

    }
}
