<?php

namespace App\Http\Controllers\API\Deal;

use App\Http\Controllers\Controller;
use App\Models\Bank;
use App\Models\BankCard;
use Illuminate\Http\Request;

class bankController extends Controller
{
    function getBanks()
    {
        $banks = Bank::whereNull('deleted_at')->get();

        $formattedBanks = $banks->map(function ($bank) {
            return [
                'id' => $bank->id,
                'name' => $bank->name,
                'image' => $bank->image ? url($bank->image) : null,
                'apply_url' => $bank->apply_url ?? null,
                'status' => $bank->status,
            ];
        });

        return response()->json(['data' => empty($formattedBanks) ? [] : $formattedBanks], 200);
    }

    function getBankCards($id = 0)
    {
        $cardsQuery = BankCard::with('bank')->whereNull('deleted_at');

        if ($id) {
            $cardsQuery->where('bank_id', $id);
        }

        $cards = $cardsQuery->get();

        $formattedBanks = $cards->map(function ($card) {
            return [
                'id' => $card->id,
                'card_name' => $card->name,
                'bank_name' => $card->bank->name ?? null,
                'image' => $card->image ? url($card->image) : null,
                'status' => $card->status,
            ];
        });

        return response()->json(['data' => empty($formattedBanks) ? [] : $formattedBanks], 200);
    }
}
