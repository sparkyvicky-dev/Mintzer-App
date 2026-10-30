<?php

namespace App\Traits;


use App\Enums\MenuPermissionType;
use App\Enums\LogType;
use App\Models\AdminSettings;
use App\Models\BusinessSettings;
use App\Models\Deal;
use App\Models\DealerAddress;
use App\Models\Log;
use App\Models\Menu;
use App\Models\Notification;
use App\Models\Order;
use App\Models\RefferalSettings;
use App\Models\Role;
use App\Models\RolePermission;
use App\Models\SmsSettings;
use App\Models\User;
use App\Models\UserReferralHistory;
use App\Models\UserRolePermission;
use App\Models\UserWallet;
use Carbon\Carbon;
use GuzzleHttp\Client;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Google\Auth\OAuth2;

trait Common
{

    private $recordsperpage = 10;
    public $errorMessage = "Something went wrong!. Please try again.";

    public $is_staging = false;
    public function getBaseUrl()
    {
        return url('/');
    }

    public function getReferralSetting()
    {
        return RefferalSettings::first();
    }

    //Referral
    public function verifyReferral($referral_code, $userId)
    {
        $referred_by = User::where('referral_code', $referral_code)
            ->first();
        $this->addReferralHistory($userId, $referred_by);
        return true;
    }

    public function addReferralHistory($user_id, $referred_by)
    {
        UserReferralHistory::create([
            'user_id' => $user_id,
            'referred_by' => $referred_by->id,
            'referred_on' => Carbon::today()
        ]);
    }

    public function addReferralWallet($user_id)
    {
        $referral_points = $this->getReferralSetting()->earnpoints_per_referral;
        //Add referral points to user wallet
        $this->addWallet($user_id, $referral_points, 'Referral');
    }

    //Referrer
    public function addReferrerWallet($user_id)
    {
        $referred_by = UserReferralHistory::where('user_id', $user_id)->pluck('referred_by')->first();
        $referrer_points = $this->getReferralSetting()->earnpoints_per_referrer;
        $this->addWallet($referred_by, $referrer_points, 'Referrer');
    }

    public function addWallet($id, $points, $type)
    {
        //Get current wallet points for user
        $user_wallet_points = User::where('id', $id)
            ->value('wallet');

        $current_wallet_points = ($user_wallet_points + $points);

        $wallets = UserWallet::create([
            'user_id' => $id,
            'amount' => $points,
            'balance' => $current_wallet_points,
            'wallet_transaction_type' => $type,
            'transaction_date' => now()
        ]);

        User::where('id', $id)->update([
            'wallet' => $current_wallet_points
        ]);

        // Return the response with a 200 status code
        return true;
    }

    //Create New User
    public function createUser($user_name, $email, $password, $ref_id, $display_name, $mobile, $role_id, $is_active, $user_img_path, $created_by)
    {
        $user = User::create([
            'user_name' => $user_name,
            'email' => $email,
            'password' => Hash::make($password),
            'ref_id' => $ref_id,
            'display_name' => $display_name,
            'mobile' => $mobile,
            'role_id' => $role_id,
            'is_active' => $is_active,
            'otp_verified' => 1,
            'is_approved' => 1,
            'user_img_path' => $user_img_path,
            'created_by' => $created_by,
            'updated_by' => $created_by
        ]);

        $role_menus = RolePermission::where('role_id', $role_id)->pluck('menu_id')->first();
        $menus = explode(',', $role_menus);
        $menuPermissionData = [];
        foreach ($menus as $key => $menu) {
            $menuPermissionData['user_id'] = $user->id;
            $menuPermissionData['menu_id'] = $menu;
            $menuPermissionData['is_edit'] = 1;
            $menuPermissionData['is_delete'] = 1;
            $menuPermissionData['is_view'] = 1;
            $menuPermissionData['is_print'] = 1;
            $menuPermissionData['is_approval'] = 1;
            $menuPermissionData['created_by'] = $created_by;
            $menuPermissionData['updated_by'] = $created_by;
            UserRolePermission::create($menuPermissionData);
        }
    }

    //Update User
    public function updateUser($user_name, $email, $password, $ref_id, $display_name, $mobile, $role_id, $is_active, $user_img_path, $created_by, $user_id = null)
    {

        if ($user_id) {
            $existing_role_id = User::where('id', $user_id)->pluck('role_id')->first();

            User::where('id', $user_id)->update([
                'user_name' => $user_name,
                'email' => $email,
                'ref_id' => $ref_id,
                'display_name' => $display_name,
                'mobile' => $mobile,
                'role_id' => $role_id,
                'is_active' => $is_active,
                'user_img_path' => $user_img_path,
                'updated_by' => $created_by,
            ]);

            if ($existing_role_id != $role_id) {
                $role_menus = RolePermission::where('role_id', $role_id)->pluck('menu_id')->first();
                $menus = explode(',', $role_menus);
                $menuPermissionData = [];
                foreach ($menus as $key => $menu) {
                    $menuPermissionData['user_id'] = $user_id;
                    $menuPermissionData['menu_id'] = $menu;
                    $menuPermissionData['is_edit'] = 1;
                    $menuPermissionData['is_delete'] = 1;
                    $menuPermissionData['is_view'] = 1;
                    $menuPermissionData['is_print'] = 1;
                    $menuPermissionData['is_approval'] = 1;
                    $menuPermissionData['created_by'] = $created_by;
                    $menuPermissionData['updated_by'] = $created_by;
                    UserRolePermission::create($menuPermissionData);
                }
            }
        } else {
            User::where('ref_id', $ref_id)->where('role_id', $role_id)->update([
                'user_name' => $user_name,
                'email' => $email,
                'ref_id' => $ref_id,
                'display_name' => $display_name,
                'mobile' => $mobile,
                'role_id' => $role_id,
                'is_active' => $is_active,
                'user_img_path' => $user_img_path,
                'updated_by' => $created_by,
            ]);
        }
    }

    public function checkUserPermission($user_id)
    {
        $userPermission = UserRolePermission::select('menu_id')->where('user_id', $user_id)->get()->toArray();
        $getMenuId = explode(',', $userPermission['menu_id'] ?? 0);
        $checkpermission = Menu::whereIn('id', [$getMenuId])->first();
        if ($checkpermission) {
            return true;
        } else {
            return false;
        }
    }

    public function fileUpload($fileinput, $filepath, $fileName)
    {
        $fileinput->move(public_path($filepath), $fileName);
        return $filepath . '/' . $fileName;
    }

    public function getOtpDetails()
    {
        return AdminSettings::first();
    }

    public function getSmsDetails()
    {
        return SmsSettings::first();
    }

    public function generateRandom($digit)
    {
        $min = pow(10, $digit - 1);
        $max = pow(10, $digit) - 1;
        return rand($min, $max);
    }

    public function sendSMS($mobile, $msg, $tempid)
    {
        $digits = preg_replace('/\D+/', '', (string) $mobile);
        if (strlen($digits) >= 12 && strpos($digits, '91') === 0) {
            $digits = substr($digits, 2, 10);
        }
        $digits = substr($digits, 0, 10);
        if (strlen($digits) !== 10) {
            return false;
        }
        $number91 = '91' . $digits;

        $apiKey = env('SMS_GATEWAY_HUB_API_KEY', 'EjfB54EMukyiq6AX8iXajQ');
        $senderId = env('SMS_GATEWAY_HUB_SENDER_ID', 'Mintzr');
        $channel = env('SMS_GATEWAY_HUB_CHANNEL', 'OTP');
        $dcs = env('SMS_GATEWAY_HUB_DCS', '0');
        $route = env('SMS_GATEWAY_HUB_ROUTE', '1');
        $peId = env('SMS_GATEWAY_HUB_PE_ID', '1301164605410549107');
        $templateId = trim((string) $tempid) !== ''
            ? trim((string) $tempid)
            : env('SMS_GATEWAY_HUB_TEMPLATE_ID', '1307164710973291856');

        $params = [
            'APIKey' => $apiKey,
            'senderid' => $senderId,
            'channel' => $channel,
            'DCS' => $dcs,
            'flashsms' => '0',
            'number' => $number91,
            'text' => $msg,
            'route' => $route,
            'EntityId' => $peId,
            'dlttemplateid' => $templateId,
        ];

        $url = 'https://www.smsgatewayhub.com/api/mt/SendSMS?' . http_build_query($params);

        try {
            $client = new Client(['timeout' => 8, 'connect_timeout' => 4]);
            $response = $client->request('GET', $url);
            $responseData = json_decode((string) $response->getBody(), true);
            if (isset($responseData['ErrorCode']) && (string) $responseData['ErrorCode'] === '000') {
                return true;
            }
            \Log::warning('SMS Gateway Hub rejected OTP SMS', [
                'error' => $responseData['ErrorMessage'] ?? null,
                'code' => $responseData['ErrorCode'] ?? null,
                'mobile' => $number91,
            ]);
            return false;
        } catch (\Throwable $e) {
            \Log::warning('SMS Gateway Hub request failed', ['message' => $e->getMessage()]);
            return false;
        }
    }


    public function getRolesForDropDown()
    {
        $role_id = [1, 3, 4, 5, 6, 17, 18];
        $roles = Role::whereNotIn('id', $role_id)->get();

        return $roles;
    }

    public function getUserRolesForDropDown()
    {
        $role_id = [1, 3, 4, 5, 6, 17, 18];
        $users = User::where('is_active', 1)->whereNotIn('role_id', $role_id)->whereNull('deleted_at')->get();

        return $users;
    }

    public function Log($transaction_name, $mode, $log_message, $user_id, $ip_address, $system_name, $is_app = 0, $type)
    {
        Log::create([
            'transaction_name' => $transaction_name,
            'mode' => $mode,
            'log_type' => $type,
            'log_message' => $log_message,
            'user_id' => $user_id,
            'ip_address' => $ip_address,
            'system_name' => $system_name,
            'is_app' => $is_app,
            'log_date' => Carbon::now()
        ]);
    }

    function getUser($user_id)
    {
        return User::find($user_id);
    }

    public function getMenuUrl()
    {
        $previousUrl = url()->previous();
        $path = parse_url($previousUrl, PHP_URL_PATH);
        $segments = explode('/', $path);
        $menuUrl = '/' . $segments[1];

        return $menuUrl;
    }

    public function chkUserMenuPermission()
    {
        $menu = Menu::where('menu_url', $this->getMenuUrl())->first();
        if ($menu) {
            $chkUserFilePermission = UserRolePermission::select('is_edit', 'is_delete', 'is_view', 'is_print', 'is_approval')
                ->where('user_id', Auth::user()->id)
                ->where('menu_id', $menu->id)
                ->first();
            return $chkUserFilePermission;
        }
    }

    public function chkUserHasPermission()
    {
        $menu = Menu::where('menu_url', $this->getMenuUrl())->first();
        if ($menu) {
            $chkUserHasPermission = UserRolePermission::where('user_id', Auth::user()->id)
                ->where('menu_id', $menu->id)
                ->first();
            return ($chkUserHasPermission ? true : false);
        } else {
            return false;
        }
    }

    public function isUserHavePermission($permissionType)
    {
        if (Auth::user()->id == 1) {
            return true;
        }

        $userMenuPermission = $this->chkUserMenuPermission();

        switch ($permissionType) {
            case MenuPermissionType::Edit:
                return ($userMenuPermission->is_edit == 1);
            case MenuPermissionType::Delete:
                return ($userMenuPermission->is_delete == 1);
            case MenuPermissionType::View:
                return ($userMenuPermission->is_view == 1);
            case MenuPermissionType::Print:
                return ($userMenuPermission->is_print == 1);
            case MenuPermissionType::Approval:
                return ($userMenuPermission->is_approval == 1);
        }
    }


    public function dealDataFormat($deals, $userId)
    {
        $formattedDeals = [];
        $dealIds = collect($deals)->pluck('id')->filter()->unique()->values()->all();

        $latestOrdersByDeal = collect();
        $reservedAddressesById = collect();

        if (!empty($dealIds) && !empty($userId)) {
            $latestPendingOrders = Order::whereIn('deal_id', $dealIds)
                ->where('user_id', $userId)
                ->whereNull('store_order_id')
                ->where('order_status', 'Placed')
                ->orderBy('id', 'DESC')
                ->get(['id', 'deal_id', 'address_id']);

            $latestOrdersByDeal = $latestPendingOrders->unique('deal_id')->keyBy('deal_id');

            $addressIds = $latestPendingOrders->pluck('address_id')->filter()->unique()->values()->all();
            if (!empty($addressIds)) {
                $reservedAddressesById = DealerAddress::whereIn('id', $addressIds)
                    ->where('is_reserved', 1)
                    ->where('is_ordered', 0)
                    ->get(['id', 'is_reserved', 'reserved_date_time'])
                    ->keyBy('id');
            }
        }

        foreach ($deals as $deal) {
            $storeId = $deal->store ? $deal->store->id : null;
            $storeImage = $deal->store ? url($deal->store->image) : null;
            $bankCardId = $deal->bankCard ? $deal->bankCard->id : null;
            $bankCardImage = $deal->bankCard ? url($deal->bankCard->image) : null;

            $formattedDeal = [
                'id' => $deal->id,
                'store_id' => $storeId,
                'bank_card_id' => $bankCardId,
                'name' => $deal->name,
                'product_image' => url($deal->image),
                'store_name' => $deal->store ? $deal->store->name : null,
                'store_image' => $storeImage,
                'bank_card_image' => $bankCardImage,
                'color' => $deal->color,
                'original_price' => (int) round($deal->product_price ?? 0),
                'selling_price' => (int) round($deal->card_holder_spend),
                'earning_price' => (int) $this->tdsDeduction($deal->card_holder_earn),
                'discount' => (int) round($deal->discount ?? 0),
                'cashback' => (int) round($deal->cashback ?? 0),
                'platform_fee' => (int) round($deal->platform_fee ?? 0),
                'card_fee' => (int) round($deal->card_fee ?? 0),
                'is_pine_lab' => (int) ($deal->is_pine_lab ?? 0),
                'offer' => $deal->bankCard->name ?? '',
                'gst_number' => $deal->gst_number,
            ];
            
            $dealImagesSource = $deal->relationLoaded('dealImages')
                ? $deal->dealImages
                : $deal->dealImages()->get(['image']);
            $dealImages = collect($dealImagesSource)
                ->pluck('image')
                ->filter()
                ->map(function ($image) {
                    return url($image);
                })
                ->values()
                ->toArray();
    
            $formattedDeal['deal_images'] = $dealImages;

            $latestIsReserved = $latestOrdersByDeal->get($deal->id);

            if ($latestIsReserved && $deal->is_pine_lab === 0) {
                $isReservedAddress = $reservedAddressesById->get($latestIsReserved->address_id);

                $isReserved = [
                    'accept_order_id' => $latestIsReserved->id,
                    'is_reserved' => $isReservedAddress ? (bool) $isReservedAddress->is_reserved : false,
                    'reserved_date_time' => $isReservedAddress->reserved_date_time ?? null
                ];
            } else {
                $isReserved = [
                    'accept_order_id' => null,
                    'is_reserved' => false,
                    'reserved_date_time' => null
                ];
            }

            $formattedDeal['is_reserved_order'] = $isReserved;

            $formattedDeals[] = $formattedDeal;
        }

        return $formattedDeals;
    }

    public function tdsDeduction($amount)
    {
        $tdsPercent = BusinessSettings::where('key', 'tds_percent')->value('value');
        $tdsAmount = $amount * $tdsPercent / 100;
        return (int) round($amount - $tdsAmount);
    }

    public function dealDetailDataFormat($deal, $userId = null)
    {
        $storeId = $deal->store ? $deal->store->id : null;
        $storeImage = $deal->store ? url($deal->store->image) : null;
        $bankCardId = $deal->bankCard ? $deal->bankCard->id : null;
        $bankCardImage = $deal->bankCard ? url($deal->bankCard->image) : null;

        $tdsPercent = BusinessSettings::where('key', 'tds_percent')->value('value');
        $tdsAmount = $deal->card_holder_earn * $tdsPercent / 100;

        $formattedDeal = [
            'id' => $deal->id,
            'store_id' => $storeId,
            'bank_card_id' => $bankCardId,
            'name' => $deal->name,
            'product_image' => url($deal->image),
            'store_name' => $deal->store->name,
            'store_image' => $storeImage,
            'bank_card_image' => $bankCardImage,
            'color' => $deal->color,
            'quantity' => (int) ($deal->order_qty ?? 0),
            'original_price' => (int) round($deal->product_price ?? 0),
            'selling_price' => (int) round($deal->card_holder_spend),
            'earning_price' => (int) round($deal->card_holder_earn),
            'card_holder_receive' => (int) round($deal->card_holder_recieve),
            'discount' => (int) round($deal->discount ?? 0),
            'cashback' => (int) round($deal->cashback ?? 0),
            'cash_reward' => (int) round($deal->cash_reward ?? 0),
            'platform_fee' => (int) round($deal->platform_fee ?? 0),
            'card_fee' => (int) round($deal->card_fee ?? 0),
            'offer' => $deal->bankCard->name,
            'offer_tittle' => $deal->offer_tittle,
            'offer_content' => $deal->offer_text,
            'gst_number' => $deal->gst_number,
            'gst_content' => $deal->gst_content,
            'pincode' => $deal->pin_code,
            'instruction' => $deal->instruction,
            'extra_note' => $deal->extra_note,
            'offer_link1' => $deal->offer_link1,
            'offer_link2' => $deal->offer_link2,
            'offer_link3' => $deal->offer_link3,
            'tds_amount' => (int) round($tdsAmount),
            'pine_lab_url' => $deal->pine_lab_url,
        ];

        $dealImages = $deal->dealImages()
            ->pluck('image')
            ->map(function ($image) {
                return url($image);
            })
            ->toArray();

        $formattedDeal['deal_images'] = $dealImages;

        $latestOrderAddress = Order::where('deal_id', $deal->id)->Where('user_id', $userId)->where('store_order_id', null)->where('order_status', 'Placed')->latest()->first();

        if ($latestOrderAddress) {
            $formattedDeal['accept_order_id'] = $latestOrderAddress->id;
        } else {
            $formattedDeal['accept_order_id'] = null;
        }

        $dealerMobile = User::where('role_id', 2)->where('id', $deal->dealer_id)->value('mobile');
        $formattedAddress = null;
        if ($latestOrderAddress) {
            $isReservedAddress = DealerAddress::where('id', $latestOrderAddress->address_id)
                ->where('is_reserved', 1)
                ->where('is_ordered', 0)
                ->first();

            if ($isReservedAddress) {
                $formattedAddress = [
                    'address_id' => $isReservedAddress->id,
                    'dealer_id' => $isReservedAddress->dealer_id,
                    'display_name' => $isReservedAddress->display_name,
                    'address' => $isReservedAddress->address,
                    'address2' => $isReservedAddress->address2,
                    'landmark' => $isReservedAddress->landmark,
                    'city' => $isReservedAddress->city,
                    'state' => $isReservedAddress->state,
                    'country' => $isReservedAddress->country,
                    'pincode' => $isReservedAddress->pincode,
                    'is_reserved' => $isReservedAddress->is_reserved,
                    'reserved_date_time' => $isReservedAddress->reserved_date_time,
                    'is_ordered' => $isReservedAddress->is_ordered,
                    'company_name' => $deal->company_name,
                    'mobile' => $dealerMobile,
                ];
            }
        } else {
            $randomAddress = DealerAddress::where('dealer_id', $deal->dealer_id)
                ->where('status', 1)
                ->where('is_reserved', 0)
                ->where('is_ordered', 0)
                ->inRandomOrder()
                ->first();

            if ($randomAddress) {
                $formattedAddress = [
                    'address_id' => $randomAddress->id,
                    'dealer_id' => $randomAddress->dealer_id,
                    'display_name' => $randomAddress->display_name,
                    'address' => $randomAddress->address,
                    'address2' => $randomAddress->address2,
                    'landmark' => $randomAddress->landmark,
                    'city' => $randomAddress->city,
                    'state' => $randomAddress->state,
                    'country' => $randomAddress->country,
                    'pincode' => $randomAddress->pincode,
                    'is_reserved' => $randomAddress->is_reserved,
                    'reserved_date_time' => $randomAddress->reserved_date_time,
                    'is_ordered' => $randomAddress->is_ordered,
                    'company_name' => $deal->company_name,
                    'mobile' => $dealerMobile,
                ];
            }
        }

        $formattedDeal['address'] = $formattedAddress;

        return $formattedDeal;
    }

    public function payoutHistoryDataFormat($payoutHistories, $withdrawHistories)
    {
        $formattedHistories = [];

        // Format payout histories
        foreach ($payoutHistories as $payoutHistory) {
            $formattedHistory = [
                'accept_order_id' => $payoutHistory->id,
                'name' => $payoutHistory->deal_name,
                'image' => $payoutHistory->deal_image ? url($payoutHistory->deal_image) : null,
                'recieved_amount' => (int) round($payoutHistory->card_holder_recieve ?? 0),
                'is_payout_requested' => $payoutHistory->is_payout_requested ? true : false,
                'is_payout' => $payoutHistory->is_payout ? true : false,
                'payot_status' => $payoutHistory->is_payout ? 'Settled' : ($payoutHistory->is_payout_requested ? 'Requested' : ''),
                'updated_on' => Carbon::parse($payoutHistory->updated_at)->format('Y-m-d H:i:s'),
            ];

            $formattedHistories[] = $formattedHistory;
        }

        // Format withdraw histories
        foreach ($withdrawHistories as $withdrawHistory) {
            $formattedHistory = [
                'accept_order_id' => null,
                'name' => 'Wallet Request',
                'image' => null,
                'recieved_amount' => (int) round($withdrawHistory->withdraw_amount ?? 0),
                'is_payout_requested' => null,
                'is_payout' => $withdrawHistory->is_payout ? true : false,
                'payot_status' => $withdrawHistory->status,
                'updated_on' => Carbon::parse($withdrawHistory->updated_at)->format('Y-m-d H:i:s'),
            ];

            $formattedHistories[] = $formattedHistory;
        }

        return $formattedHistories;
    }

    public function orderDataFormat($orders)
    {
        $formattedOrders = [];

        foreach ($orders as $order) {
            $dealImage = !empty($order->image) ? url($order->image) : null;
            $storeImage = !empty($order->store_image) ? url($order->store_image) : null;
            $paymentScreenshot = !empty($order->payment_screenshot) ? url($order->payment_screenshot) : null;
            $orderDealImage = !empty($order->order_deal_image) ? url($order->order_deal_image) : null;

            $formattedOrder = [
                'accept_order_id' => $order->id,
                'id' => $order->id,
                'order_number' => $order->order_number,
                // V3 Flutter needs store Order ID on list/wallet (was missing → showed "—").
                'store_order_id' => $order->store_order_id,
                'store_name' => $order->store_name ?? null,
                'offer' => $order->offer ?? null,
                'order_delivery_otp' => $order->order_delivery_otp,
                'verification_status' => $order->verification_status,
                'transaction_id' => $order->transaction_id,
                'name' => $order->name,
                'image' => $dealImage,
                'store_image' => $storeImage,
                'color' => $order->color,
                'qty' => (int) ($order->order_qty ?? 0),
                'gst_number' => $order->gst_number,
                'pin_code' => $order->pin_code,
                // Android My Orders parses money fields as int — never send doubles
                'earning_price' => (int) round($order->earnings != 0 ? $order->earnings : $order->card_holder_earn),
                'to_card_holder' => (int) round($order->to_card_holder),
                'tds_amount' => (int) round($order->tds_amount),
                'order_amount' => (int) round($order->order_amount),
                // Bank transfer (From Mintzer / Total receive) — not profit alone.
                'mintzer_payout' => (int) round(
                    $order->order_deal_card_holder_receive
                        ?? $order->deal_card_holder_recieve
                        ?? 0
                ),
                'card_holder_receive' => (int) round(
                    $order->order_deal_card_holder_receive
                        ?? $order->deal_card_holder_recieve
                        ?? 0
                ),
                'delivery_partner_id' => $order->delivery_partner_id,
                'order_tracking_id' => $order->order_tracking_id,
                'order_status' => $order->order_status,
                'order_date' => $order->order_date,
                'shipped_date' => $order->shipped_date,
                'out_for_delivery_date' => $order->out_for_delivery_date,
                'delivery_date' => $order->delivery_date,
                'tracking_update' => $order->shipped_date ? true : false,
                'out_for_delivery_update' => $order->out_for_delivery_date ? true : false,
                'is_invoice_uploaded' => $order->account_order_pdf ? true : false,
                'account_order_pdf' => !empty($order->account_order_pdf) ? $order->account_order_pdf : null,
                'is_payout' => $order->is_payout ? true : false,
                'is_pine_lab_deal' => $order->is_pine_lab_deal,
                'payment_screenshot' => $paymentScreenshot,
                'is_payment_verified' => $order->is_payment_verified,
                'cancel_reason' => $order->cancel_reason,
                'order_deal_name' => $order->order_deal_name,
                'order_deal_image' => $orderDealImage,
                'order_deal_color' => $order->order_deal_color,
                'order_deal_order_qty' => $order->order_deal_order_qty !== null
                    ? (int) $order->order_deal_order_qty
                    : null,
                'order_deal_gst_number' => $order->order_deal_gst_number,
                'order_deal_pin_code' => $order->order_deal_pin_code,
                'order_deal_card_holder_earn' => $order->order_deal_card_holder_earn !== null
                    ? (int) round($order->order_deal_card_holder_earn)
                    : null,
            ];

            $formattedOrders[] = $formattedOrder;
        }

        return $formattedOrders;
    }

    public function payoutStageFormat($order)
    {
        $isReservedAddress = DealerAddress::where('id', $order->address_id)
            ->where('is_reserved', 1)
            ->where('is_ordered', 0)
            ->first();

        $modelName = $order->order_deal_name ?: $order->deal_name;
        $modelImage = $order->order_deal_image ?: $order->deal_image;
        $modelColor = $order->order_deal_color ?: $order->deal_color;
        $modelQty = $order->order_deal_order_qty ?: $order->deal_order_qty;
        $modelGst = $order->order_deal_gst_number ?: $order->deal_gst_number;
        $modelPin = $order->order_deal_pin_code ?: $order->deal_pin_code;
        $modelEarn = $order->order_deal_card_holder_earn ?: $order->deal_card_holder_earn;

        // Format the order data
        $formattedOrder = [
            'accept_order_id' => $order->id,
            'deal_id' => $order->deal_id,
            'order_number' => $order->order_number,
            'store_order_id' => $order->store_order_id,
            'is_reserved' => $isReservedAddress->is_reserved ?? 0,
            'reserved_date_time' => $isReservedAddress->reserved_date_time ?? null,
            'is_ordered' => $isReservedAddress->is_ordered ?? 0,
            'is_payout' => $order->is_payout ? true : false,
            'earning_price' => (int) round($modelEarn ?? $order->card_holder_earn ?? 0),
            'delivery_partner_id' => $order->delivery_partner_id,
            'order_tracking_id' => $order->order_tracking_id,
            'mobile_no' => $order->account_mobile_number,
            'otp' => $order->order_delivery_otp,
            'order_status' => $order->order_status,
            'tracking_update' => $order->shipped_date ? true : false,
            'out_for_delivery_update' => $order->out_for_delivery_date ? true : false,
            'is_invoice_uploaded' => $order->account_order_pdf ? true : false,
            'verification_status' => $order->verification_status,
            'order_amount' => (int) round($order->order_amount),
            'total_amount' => (int) round($order->total_amount),
            'to_card_holder' => (int) round($order->to_card_holder),
            'tds_amount' => (int) round($order->tds_amount),
            'order_deal_name' => $modelName,
            'order_deal_image' => $modelImage ? url($modelImage) : null,
            'order_deal_color' => $modelColor,
            'order_deal_order_qty' => $modelQty !== null ? (int) $modelQty : null,
            'order_deal_gst_number' => $modelGst,
            'order_deal_pin_code' => $modelPin,
            'order_deal_card_holder_earn' => $modelEarn !== null
                ? (int) round($modelEarn)
                : null,
        ];

        return $formattedOrder;
    }

    public function getAccessToken()
    {
        // Prefer Flutter app project (mintzer-e45d6); fall back to legacy e14bd.
        $credentialsPath = null;
        if (class_exists(\App\Services\AdminApp\AdminFcmClient::class)) {
            $credentialsPath = \App\Services\AdminApp\AdminFcmClient::credentialsPath();
        }
        if ($credentialsPath === null || !is_readable($credentialsPath)) {
            $credentialsPath = public_path('mintzer-e45d6-firebase.json');
        }
        if (!is_readable($credentialsPath)) {
            $credentialsPath = public_path('mintzer-e14bd-b876d21e557c.json');
        }

        $credentials = new ServiceAccountCredentials(
            'https://www.googleapis.com/auth/firebase.messaging',
            $credentialsPath
        );

        $token = $credentials->fetchAuthToken();
        return $token['access_token'];
    }

    /** Firebase project id for HTTP v1 sends (matches getAccessToken credentials). */
    public function fcmProjectId(): string
    {
        $path = null;
        if (class_exists(\App\Services\AdminApp\AdminFcmClient::class)) {
            $path = \App\Services\AdminApp\AdminFcmClient::credentialsPath();
        }
        if ($path && is_readable($path)) {
            $raw = @file_get_contents($path);
            $json = $raw ? json_decode($raw, true) : null;
            if (is_array($json) && !empty($json['project_id'])) {
                return (string) $json['project_id'];
            }
        }
        if (is_readable(public_path('mintzer-e45d6-firebase.json'))) {
            return 'mintzer-e45d6';
        }
        return 'mintzer-e14bd';
    }

    public function sendVerificationPushNotify($fcmToken, $title, $body, $pushNotificationKey, $order_id)
    {
        if (empty($fcmToken)) {
            return null;
        }

        $data = [];
        $key = is_string($pushNotificationKey) ? trim($pushNotificationKey) : '';
        if ($key === 'ticket_reply' || $key === 'ticket.reply') {
            $data['type'] = 'ticket.reply';
            $data['ticket_id'] = (string) $order_id;
            $data['channel'] = 'mintzer_orders';
        } else {
            $data['type'] = $key !== '' ? $key : 'order.update';
            $data['order_id'] = (string) $order_id;
            $data['channel'] = 'mintzer_orders';
        }

        // Primary path: Flutter project (e45d6) via AdminFcmClient.
        if (class_exists(\App\Services\AdminApp\AdminFcmClient::class)) {
            $ok = \App\Services\AdminApp\AdminFcmClient::sendToToken(
                (string) $fcmToken,
                (string) $title,
                (string) $body,
                $data
            );
            return $ok ? 'ok' : 'fail';
        }

        $accessToken = $this->getAccessToken();
        $projectId = $this->fcmProjectId();
        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        $headers = [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json',
        ];

        $notificationData = [
            'message' => [
                'token' => $fcmToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => array_map('strval', $data),
                'android' => [
                    'priority' => 'high',
                ],
            ],
        ];

        $notificationDataJson = json_encode($notificationData);
        $ch = curl_init();

        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $notificationDataJson);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        $response = curl_exec($ch);
        curl_close($ch);

        $this->Log(__FUNCTION__, "GET", $response, Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        return $response;
    }

    public function sendFcmNotificationToTopic($topic, $data){
        $accessToken = $this->getAccessToken();

        $url = "https://fcm.googleapis.com/v1/projects/" . $this->fcmProjectId() . "/messages:send";

        $headers = [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json',
        ];

        $notificationData = [
            'message' => [
                'topic' => $topic,
                'notification' => [
                    'title' => $data['title'],
                    'body' => $data['body'],
                    'image' => $data['image'] ?? null, 
                ],
                'data' => [
                    'deal_id' => (string) $data['deal_id'], 
                ]
            ]
        ];

        $notificationDataJson = json_encode($notificationData);
        $ch = curl_init();

        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $notificationDataJson);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        $response = curl_exec($ch);
        curl_close($ch);

        $this->Log(__FUNCTION__, "GET", $response, Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        if ($response === false) {
            return null;
        } else {
            return json_decode($response, true);
        }
    }
    
    public function orderCancelPushNotify($order, $cancelReason)
    {
        $user = User::find($order->user_id);
        $fcmToken = $user?->fcm_token;

        $pushNotificationKey = BusinessSettings::where('key', 'push_notification_key')->first()->value;
        $orderRef = $order->store_order_id ?: $order->order_number ?: ('#' . $order->id);
        $reasonText = trim((string) $cancelReason) ?: 'operational issue';
        $messagePayload = $this->buildOrderCancelMessage($orderRef, $reasonText);
        $title = $messagePayload['title'];
        $body  = $messagePayload['body'];

        $pushResponse = false;
        if ($fcmToken) {
            $pushResponse = $this->sendVerificationPushNotify(
                $fcmToken,
                $title,
                $body,
                $pushNotificationKey,
                $order->id
            );
        }

        $notification = new Notification();
        $notification->user_id = $order->user_id;
        $notification->title   = $title;
        $notification->content = $body;
        $notification->status  = ($pushResponse !== false) ? 1 : 0;
        $notification->save();
    }

    private function buildOrderCancelMessage(string $orderRef, string $reasonText): array
    {
        $titles = [
            'Order Update',
            'Order Cancelled',
            'Important Order Update',
            'Quick Update On Your Order',
            'We Are Sorry',
            'Order Status Changed',
            'Order Cancellation Notice',
            'Please Check This Update',
        ];

        $bodies = [
            "Your order {$orderRef} was cancelled due to {$reasonText}. Please check app for other active deals.",
            "Order {$orderRef} has been cancelled because of {$reasonText}. You can place a new order anytime.",
            "We had to cancel order {$orderRef} due to {$reasonText}. Please explore other available offers.",
            "Order {$orderRef} is cancelled due to {$reasonText}. Tap app to view similar deals.",
            "Important: order {$orderRef} was cancelled because {$reasonText}. Thanks for your understanding.",
            "Your order {$orderRef} could not be completed due to {$reasonText}. Please place a fresh order if needed.",
            "Order {$orderRef} cancellation update: {$reasonText}. We are here if you need support.",
            "Sorry, order {$orderRef} is cancelled due to {$reasonText}. Please check app for new options.",
        ];

        return [
            'title' => $titles[array_rand($titles)],
            'body' => $bodies[array_rand($bodies)],
        ];
    }
}
