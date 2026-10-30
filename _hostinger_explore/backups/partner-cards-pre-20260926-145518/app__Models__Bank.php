<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Bank extends Model
{
    use HasFactory, SoftDeletes;
    protected $fillable = [
        'name',
        'image',
        'apply_url',
        'created_by',
        'updated_by',
        'created_at',
        'updated_at',
        'deleted_at',
        'status',
    ];

    public function bankCards()
    {
        return $this->hasMany(BankCard::class);
    }
}
