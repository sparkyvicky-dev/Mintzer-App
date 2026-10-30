<?php


namespace App\Http\Controllers\API;

use App\Enums\LogType;
use App\Http\Controllers\Controller;
use App\Models\BusinessSettings;
use App\Models\User;
use App\Models\WithdrawRequest;
use App\Traits\Common;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class WalletController extends Controller
{
    use Common;
    public function withdrawRequest(Request $request)
    {
        $rules = [
            'withdraw_amount' => 'required|string'
        ];
        $messages = [
            'withdraw_amount.required' => 'withdraw_amount is required.'
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }

        $withdrawRequestAmount = $request->withdraw_amount;

        try {
            $minWithdrawReqAmt = BusinessSettings::where('key', 'min_witdraw_request_amount')->first();
            if ($withdrawRequestAmount < $minWithdrawReqAmt->value) {
                return response()->json([
                    'status' => false,
                    'message' => "Withdraw request amount is below the minimum withdraw amount of {$minWithdrawReqAmt->value}!",
                ], 400);
            }
            $currentWalletAmount = User::where('id', Auth::user()->id)->first();
            if ($withdrawRequestAmount > $currentWalletAmount->wallet) {
                return response()->json([
                    'status' => false,
                    'message' => "Insufficient balance for withdrawal!",
                ], 400);
            }
            $withdraw = WithdrawRequest::create([
                'user_id' => Auth::user()->id,
                'withdraw_amount' => $withdrawRequestAmount
            ]);
            $response = [
                'message' => "Withdrawal request sent successfully"
            ];
            return response()->json($response, 200);
            $this->Log(__FUNCTION__, request()->method(), 'Withdrawal request sent successfully.', $withdraw->user_id, request()->ip(), gethostname(), 1, LogType::Activity);
        } catch (\Exception $e) {
            // dd($e);
            $response = [
                'message' => "Withdrawal request failed"
            ];
            return response()->json($response, 400);
        }
    }
}
