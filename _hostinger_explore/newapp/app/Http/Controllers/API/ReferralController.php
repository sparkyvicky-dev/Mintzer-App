<?php

namespace App\Http\Controllers\API;

use App\Enums\LogType;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use App\Models\UserReferralHistory;
use App\Models\UserWallet;
use App\Traits\Common;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ReferralController extends Controller
{
    use Common;
    public function getReferralSettings()
    {
        try {
            $reffereal_code = User::where('id', Auth::user()->id)->value('referral_code');
            $referral_settings = $this->getReferralSetting();

            $data = [
                'referral_content' => str_replace(["{{referral}}", "{{referrer}}"], [$referral_settings->earnpoints_per_referral, $referral_settings->earnpoints_per_referrer], $referral_settings->referral_content),
                'earnpoints_per_referral' => $referral_settings->earnpoints_per_referral,
                'earnpoints_per_referrer' => $referral_settings->earnpoints_per_referrer,
                'app_link' => $referral_settings->app_link,
                'referral_banner_path' => $this->getBaseUrl() . '/' . $referral_settings->referral_banner_path,
                'reffereal_code' => $reffereal_code,
            ];

            $response = [
                'data' => $data
            ];

            return response($response, 200);
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 1, LogType::Error);
            // return $this->error($e->getMessage(), 200);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }

    public function getReferralHistories()
    {
        try {
            $referralHistories = UserReferralHistory::with('user')->where('referred_by', Auth::user()->id)->get();

            $data = [];
            foreach ($referralHistories as $history) {
                $order = Order::where('user_id', $history->user_id)->whereNull('deleted_at')->orderBy('id', 'ASC')->first();
                if($order){
                    if($order->order_status == 'Delivered' && $history){
                        $status = 'Earned';
                        $earningAmount = UserWallet::where('user_id', $history->referred_by)->where('wallet_transaction_type', 'Referrer')->value('amount');
                    } elseif($order->order_status != 'Delivered' && $history){
                        $status = 'Ordered';
                        $earningAmount = null;
                    }
                } elseif($history){
                    $status = 'Registered';
                    $earningAmount = null;
                }
                $data[] = [
                    'name' => $history->user->display_name,
                    'earning_amount' => $earningAmount,
                    'status' => $status,
                ];
            }

            $response = [
                'data' => $data
            ];

            return response($response, 200);
        } catch (\Exception $e) {
            // dd($e);
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }
}
