<?php

namespace App\Enums;

use Illuminate\Validation\Rules\Enum;

final class RoleTypes extends Enum
{
    const Admin = "1";
    const Dealer = "2";
    const Customer = "3";
}
