<?php

namespace App\Models;

use App\Enums\RoleTypes;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'display_name',
        'device_id',
        'mobile',
        'email',
        'password',
        'role_id',
        'is_active',
        'otp',
        'otp_expiry',
        'otp_verified',
        'profile_picture',
        'pan',
        'pan_name',
        'wallet',
        'bank_full_name',
        'bank_name',
        'bank_account_number',
        'bank_ifsc',
        'upi_address',
        'address',
        'address2',
        'landmark',
        'city',
        'pincode',
        'is_verified',
        'is_admin_verified',
        'ip_address',
        'fcm_token',
        'whatsapp_access',
        'referral_code',
        'is_allow_whatsapp_notification',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    public function scopeAdmin($query)
    {
        return $query->where('role_id', RoleTypes::Admin);
    }
    public function scopeDealer($query)
    {
        return $query->where('role_id', RoleTypes::Dealer);
    }
    public function scopeCustomer($query)
    {
        return $query->where('role_id', RoleTypes::Customer);
    }
    public function scopeVerifiedCustomer($query)
    {
        return $query->where('is_verified', 1);
    }
    
    public function tickets()
    {
        return $this->hasMany(Ticket::class);
    }

    public function updatedTickets()
    {
        return $this->hasMany(Ticket::class, 'updated_by');
    }
    
    public function referralHistory()
    {
        return $this->hasOne(UserReferralHistory::class, 'user_id', 'id');
    }
    
    public function withdrawRequest()
    {
        return $this->hasOne(WithdrawRequest::class, 'user_id', 'id');
    }
    
    public function feedback()
    {
        return $this->hasOne(Feedback::class, 'user_id', 'id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'user_id');
    }
}
