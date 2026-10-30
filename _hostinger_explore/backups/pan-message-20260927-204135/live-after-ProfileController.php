<?php

namespace App\Http\Controllers\API;

use App\Enums\LogType;
use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\User;
use App\Traits\Common;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ProfileController extends Controller
{
    use Common;

    function getUserProfile()
    {
        try {
            $user = $this->getUser(Auth::user()->id);
            if ($user) {
                $data = [
                    'user_id' => $user->id,
                    'mobile' => $user->mobile,
                    'User_name' => $user->display_name,
                    'email' => $user->email ?? null,
                    'profile_picture' => $user->profile_picture ? url($user->profile_picture) : null,
                    'referral_code' => $user->referral_code ?? null,
                    'role_id' => $user->role_id,
                    'wallet_amount' => $user->wallet,
                    'is_active' => $user->is_active,
                    'is_new_user' => $user->is_verified == 1 ? true : false,
                    'is_whatsapp_access' => $user->whatsapp_access == 1 ? true : false,
                    'is_bank_account_added' => ($user->bank_account_number || $user->upi_address) ? true : false,
                    'is_address_added' => $user->address ? true : false,
                    'is_allow_whatsapp_notification' => $user->is_allow_whatsapp_notification ? true : false,
                    'pan_details' => [
                        'pan_verified' => $user->pan_name && $user->pan ? true : false,
                        'pan_name' => $user->pan_name ?? null,
                        'pan' => $user->pan ?? null
                    ]

                ];
            } else {
                $data = [
                    'pan_verified'  => false,
                    'is_new_user'  => true,
                ];
            }

            return response()->json(['data' => $data], 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), Auth::user()->id ?? 1, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }

    function updateProfile(Request $request)
    {
        $request->merge([
            'name' => $this->normalizePersonName($request->name),
        ]);

        $validatedData = $request->validate([
            'name' => ['required', 'string', 'max:30'],
            'email' => 'nullable|email',
            // 'mobile' => 'required|string',
        ]);
        try {

            $this->getUser(Auth::user()->id)->update([
                'display_name' => $request->name,
                'email' => $request->email ?? null,
                // 'mobile' => $request->mobile,
            ]);

            $response = [
                'message' => "Profile Updated Successfully",
            ];

            $this->Log(__FUNCTION__, request()->method(), 'Profile Updated Successfully', Auth::user()->id, request()->ip(), gethostname(), 1, LogType::Activity);
            return response()->json($response, 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 0, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }

    private function normalizePersonName(?string $name): string
    {
        $name = preg_replace('/[^A-Za-z\s]/', '', (string) $name);
        $name = preg_replace('/\s+/', ' ', $name);
        $name = trim($name);
        return ucwords(strtolower($name));
    }

    function updateProfileImage(Request $request)
    {
        try {
            if ($request->hasFile('profile_image')) {

                $request->validate([
                    'profile_image' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
                ]);

                // Get the user
                $user = $this->getUser(Auth::user()->id);

                // Delete old profile picture if exists
                if ($user->profile_picture && file_exists(public_path($user->profile_picture))) {
                    unlink(public_path($user->profile_picture));
                }

                $file = $request->file('profile_image');

                $fileName = hexdec(uniqid()) . '.webp';
                $filePath = 'uploads/profile';
                $fullPath = public_path($filePath);

                if (!file_exists($fullPath)) {
                    mkdir($fullPath, 0777, true);
                }
                $originalPath = $file->getRealPath();
                $imageInfo = getimagesize($originalPath);

                if ($imageInfo !== false) {
                    $mimeType = $imageInfo['mime'];

                    switch ($mimeType) {
                        case 'image/jpeg':
                        case 'image/jpg':
                            $image = imagecreatefromjpeg($originalPath);
                            break;
                        case 'image/png':
                            $image = imagecreatefrompng($originalPath);
                            break;
                        case 'image/gif':
                            $image = imagecreatefromgif($originalPath);
                            break;
                        case 'image/webp':
                            $image = imagecreatefromwebp($originalPath);
                            break;
                        default:
                            return response()->json([
                                'status' => false,
                                'message' => 'Unsupported image format.'
                            ], 400);
                    }

                    // Convert non-truecolor to truecolor to prevent issues
                    if (!imageistruecolor($image)) {
                        $width = imagesx($image);
                        $height = imagesy($image);
                        $trueColorImage = imagecreatetruecolor($width, $height);
                        imagealphablending($trueColorImage, false);
                        imagesavealpha($trueColorImage, true);
                        imagecopy($trueColorImage, $image, 0, 0, 0, 0, $width, $height);
                        imagedestroy($image);
                        $image = $trueColorImage;
                    }
                    imagewebp($image, $fullPath . '/' . $fileName, 90);
                    imagedestroy($image);
                }

                $user->update([
                    'profile_picture' => $filePath . '/' . $fileName,
                ]);

                return response()->json([
                    'message' => "Profile Image Updated Successfully",
                    'profile_picture' => $filePath . '/' . $fileName
                ], 200);
            } else {
                return response()->json([
                    'status' => false,
                    'message' => "No profile image uploaded",
                ], 400);
            }
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 0, request()->ip(), gethostname(), 1, LogType::Error);
            return response()->json([
                'message' => 'Something went wrong. Please try again.',
                'status' => false,
            ], 500);
        }
    }

    public function updateSettings(Request $request)
    {
        try {
            $user = $this->getUser(Auth::user()->id);
            $user->is_allow_whatsapp_notification = $request->allow_whatsapp_notification;
            $user->save();

            $message = ($request->allow_whatsapp_notification == 1) ? "Activated" : "Deactivated";

            $response = [
                'message' => $message
            ];
            return response()->json($response, 200);
        } catch (Exception $e) {
            // dd($e);
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 0, request()->ip(), gethostname(), 1, LogType::Error);
        }
    }

    // function register(Request $request)
    // {
    //     $rules = [
    //         'name' => 'required|string',
    //         'pan' => 'nullable|string',
    //         'whatsapp' => 'required|boolean',
    //     ];
    //     $messages = [
    //         'name.required' => 'Name is required',
    //         'whatsapp.required' => 'WhatsApp access is required',
    //         'whatsapp.boolean' => 'WhatsApp access must be a boolean value',
    //     ];

    //     $validator = Validator::make($request->all(), $rules, $messages);

    //     if ($validator->fails()) {
    //         $response = [
    //             'status' => false,
    //             'message' => $validator->errors()->first(),
    //         ];
    //         return response()->json($response, 400);
    //     }

    //     try {
    //         $this->getUser(Auth::user()->id)->update([
    //             'display_name' => $request->name,
    //             'pan' => $request->pan ?? null,
    //             'is_verified' => 1,
    //             'whatsapp_access' => $request->whatsapp,
    //         ]);
    //         $user = $this->getUser(Auth::user()->id);
    //         $response = [
    //             'message' => "Profile Updated Successfully",
    //         ];

    //         $this->Log(__FUNCTION__, request()->method(), 'You tried to login and OTP has been sent to the registered mobile number.', $user->id, request()->ip(), gethostname(), 1, LogType::Activity);
    //         return response()->json($response, 200);
    //     } catch (Exception $e) {
    //         dd($e);
    //         $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 0, request()->ip(), gethostname(), 1, LogType::Error);
    //         $response = array(
    //             'message' => $this->errorMessage,
    //             'status' => false,
    //         );
    //         return response($response, 400);
    //     }
    // }

    function panVerify(Request $request)
    {
        // V3: client sends PAN only; name comes from PowerAPI (API Sathi if that key is off).
        // Legacy clients that still post `name` keep working when both providers are off.
        $rules = [
            'pan' => 'required|string|min:10|max:10',
            'name' => 'nullable|string',
        ];
        $messages = [
            'pan.required' => 'Pan is required',
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }

        try {
            $pan = strtoupper(preg_replace('/[^A-Z0-9]/i', '', (string) $request->pan) ?? '');
            if (!preg_match('/^[A-Z]{5}[0-9]{4}[A-Z]$/', $pan)) {
                return response()->json([
                    'status' => false,
                    'message' => 'PAN format is invalid',
                ], 400);
            }

            $name = null;
            $userRow = $this->getUser(Auth::user()->id);
            $savedPan = strtoupper(preg_replace('/[^A-Z0-9]/i', '', (string) ($userRow->pan ?? '')) ?? '');
            $savedName = trim((string) ($userRow->pan_name ?? ''));
            if ($savedPan !== '' && $savedName !== '') {
                if ($pan !== $savedPan) {
                    return response()->json([
                        'status' => false,
                        'message' => 'PAN is already verified on this account.',
                    ], 400);
                }
                return response()->json([
                    'status' => true,
                    'message' => 'Pan Verified Successfully.',
                    'pan_name' => $savedName,
                    'pan' => $savedPan,
                ], 200);
            }

            $panCacheKey = 'apisathi_pan_' . hash('sha256', $pan);
            $cached = Cache::get($panCacheKey);
            if (is_array($cached) && trim((string) ($cached['name'] ?? '')) !== '') {
                $name = trim((string) $cached['name']);
            } elseif (\App\Services\PowerApi\PowerApiPanService::enabled() || \App\Services\ApiSathi\ApiSathiPanService::enabled()) {
                $day = Carbon::now('Asia/Kolkata')->format('Ymd');
                $phone = preg_replace('/\D/', '', (string) ($userRow->mobile ?? '')) ?? '';
                $userTryKey = 'pan_try_user_' . $userRow->id . '_' . $day;
                $phoneTryKey = 'pan_try_phone_' . hash('sha256', $phone) . '_' . $day;
                $allTryKey = 'pan_try_all_' . $day;
                $lockKey = 'pan_try_lock_' . $userRow->id;
                if (!Cache::add($lockKey, 1, Carbon::now()->addSeconds(30))) {
                    return response()->json([
                        'status' => false,
                        'message' => 'PAN check already running. Wait a moment.',
                    ], 429);
                }
                if ((int) Cache::get($userTryKey, 0) >= 3 || ($phone !== '' && (int) Cache::get($phoneTryKey, 0) >= 3)) {
                    Cache::forget($lockKey);
                    return response()->json([
                        'status' => false,
                        'message' => 'PAN check limit reached for today. Try again tomorrow.',
                    ], 429);
                }
                if ((int) Cache::get($allTryKey, 0) >= 150) {
                    Cache::forget($lockKey);
                    return response()->json([
                        'status' => false,
                        'message' => 'PAN verification is busy. Try again tomorrow.',
                    ], 429);
                }
                $ttl = Carbon::now('Asia/Kolkata')->endOfDay()->addHours(2);
                Cache::put($userTryKey, (int) Cache::get($userTryKey, 0) + 1, $ttl);
                if ($phone !== '') {
                    Cache::put($phoneTryKey, (int) Cache::get($phoneTryKey, 0) + 1, $ttl);
                }
                Cache::put($allTryKey, (int) Cache::get($allTryKey, 0) + 1, $ttl);

                $usePower = \App\Services\PowerApi\PowerApiPanService::enabled();
                $result = $usePower
                    ? \App\Services\PowerApi\PowerApiPanService::verifyPan($pan)
                    : \App\Services\ApiSathi\ApiSathiPanService::verifyPan($pan);
                $powerNote = '';
                $powerMsg = (string) ($result['message'] ?? '');
                if (
                    $usePower
                    && !$result['ok']
                    && (
                        strpos($powerMsg, 'name was missing') !== false
                        || strpos($powerMsg, 'Could not reach') !== false
                    )
                ) {
                    $powerNote = (string) $result['message'];
                    if (\App\Services\ApiSathi\ApiSathiPanService::enabled()) {
                        $result = \App\Services\ApiSathi\ApiSathiPanService::verifyPan($pan);
                    }
                }
                Cache::forget($lockKey);
                if (!$result['ok']) {
                    $shown = trim((string) preg_replace('/\s*\[fields:[^\]]*\]/', '', (string) ($result['message'] ?? '')));
                    $httpNote = isset($result['http_status']) ? ' [http ' . (int) $result['http_status'] . ']' : '';
                    $this->Log(
                        __FUNCTION__,
                        request()->method(),
                        ($usePower ? 'PowerAPI' : 'API Sathi') . ' PAN failed: ' . $shown . $httpNote . ($powerNote !== '' ? ' | ' . $powerNote : ''),
                        Auth::user()->id,
                        request()->ip(),
                        gethostname(),
                        1,
                        LogType::Error
                    );
                    return response()->json([
                        'status' => false,
                        'message' => $shown !== '' ? $shown : 'PAN could not be verified',
                    ], 400);
                }
                $name = $result['name'];
                if (!$result['sandbox']) {
                    Cache::put($panCacheKey, ['name' => $name], Carbon::now()->addDays(30));
                }
            } else {
                $name = trim((string) ($request->name ?? ''));
                if ($name === '') {
                    return response()->json([
                        'status' => false,
                        'message' => 'PAN verification is not configured',
                    ], 400);
                }
            }

            $this->getUser(Auth::user()->id)->update([
                'pan_name' => $name,
                'pan' => $pan,
                'is_verified' => 1,
            ]);
            $user = $this->getUser(Auth::user()->id);
            $response = [
                'status' => true,
                'message' => 'Pan Verified Successfully.',
                'pan_name' => $name,
                'pan' => $pan,
            ];

            $this->Log(__FUNCTION__, request()->method(), 'Pan Verified Successfully.', $user->id, request()->ip(), gethostname(), 1, LogType::Activity);
            return response()->json($response, 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 0, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 400);
        }
    }

    function ifscLookup(Request $request)
    {
        $ifsc = strtoupper(preg_replace('/[^A-Z0-9]/i', '', (string) $request->input('ifsc', '')) ?? '');
        if (!preg_match('/^[A-Z]{4}0[A-Z0-9]{6}$/', $ifsc)) {
            return response()->json([
                'status' => false,
                'message' => 'Enter a valid IFSC code',
            ], 400);
        }

        $cacheKey = 'apisathi_ifsc_' . $ifsc;
        $cached = Cache::get($cacheKey);
        if (is_array($cached) && trim((string) ($cached['bank'] ?? '')) !== '') {
            return response()->json([
                'status' => true,
                'ifsc' => $ifsc,
                'bank' => $cached['bank'],
                'branch' => $cached['branch'] ?? null,
                'city' => $cached['city'] ?? null,
            ], 200);
        }

        $day = Carbon::now('Asia/Kolkata')->format('Ymd');
        $user = $this->getUser(Auth::user()->id);
        $tryKey = 'ifsc_try_user_' . $user->id . '_' . $day;
        if ((int) Cache::get($tryKey, 0) >= 20) {
            return response()->json([
                'status' => false,
                'message' => 'IFSC check limit reached for today. Try again tomorrow.',
            ], 429);
        }

        $result = \App\Services\ApiSathi\ApiSathiIfscService::lookup($ifsc);
        $ttl = Carbon::now('Asia/Kolkata')->endOfDay()->addHours(2);
        Cache::put($tryKey, (int) Cache::get($tryKey, 0) + 1, $ttl);
        if (!$result['ok']) {
            return response()->json([
                'status' => false,
                'message' => $result['message'],
            ], 400);
        }

        Cache::put($cacheKey, [
            'bank' => $result['bank'],
            'branch' => $result['branch'],
            'city' => $result['city'],
        ], Carbon::now()->addDays(90));

        return response()->json([
            'status' => true,
            'ifsc' => $ifsc,
            'bank' => $result['bank'],
            'branch' => $result['branch'],
            'city' => $result['city'],
        ], 200);
    }

    function getnotifications()
    {
        $notifications = Notification::where('user_id', Auth::user()->id)->orderBy('id', 'DESC')->get();
        $user = User::find(Auth::user()->id);
        $data = [];
        $unread = false;

        foreach ($notifications as $notify) {
            $isRead = $notify->is_readed == 1;
            if (!$isRead) {
                $unread = true;
            }
            // Do not auto-mark read on fetch — app Mark all / tap owns that.
            $data[] = [
                'id' => $notify->id,
                'title' => $notify->title,
                'content' => $notify->content ?? null,
                'image' => $notify->image_url ? url($notify->image_url) : ($user->profile_picture ? url($user->profile_picture) : null),
                'is_read' => $isRead ? true : false,
                'date' => Carbon::parse($notify->created_at)->timezone('Asia/Kolkata')->toDateTimeString(),
            ];
        }

        return response()->json([
            'data' => $data,
            'unread_notification' => $unread,
        ], 200);
    }

    function updatenotifications(Request $request)
    {
        $action = $request->input('action', $request->query('action'));
        if ($action === 'clear') {
            Notification::where('user_id', Auth::user()->id)->delete();
            return response()->json([
                'message' => 'Notifications cleared',
            ], 200);
        }

        $notifyId = $request->query('notification_id') ?? $request->input('notification_id');

        if ($notifyId) {
            $notification = Notification::where('id', $notifyId)
                ->where('user_id', Auth::user()->id)
                ->first();

            if (!$notification) {
                return response()->json([
                    'status' => false,
                    'message' => 'Notification not found!',
                ], 400);
            }

            $notification->update(['is_readed' => 1]);
        } else {
            Notification::where('user_id', Auth::user()->id)
                ->where('is_readed', 0)
                ->update(['is_readed' => 1]);
        }

        return response()->json([
            'message' => 'Notification(s) marked as read',
        ], 200);
    }

    function updateBankDetail(Request $request)
    {
        // One payout method: bank (account + IFSC) or UPI. Old app sends bank fields and optional UPI.
        $fullName = trim((string) $request->input('full_name', ''));
        $method = strtolower(trim((string) $request->input('payout_method', '')));
        $upi = trim((string) $request->input('upi_address', ''));
        $acct = preg_replace('/\s+/', '', (string) $request->input('bank_account_number', ''));
        $ifsc = strtoupper(preg_replace('/\s+/', '', (string) $request->input('bank_ifsc', '')));
        $bankName = trim((string) $request->input('bank_name', ''));

        if ($fullName === '') {
            return response()->json(['status' => false, 'message' => 'full_name is required.'], 400);
        }

        $upiOnly = $method === 'upi' || ($method === '' && $upi !== '' && $acct === '' && $ifsc === '');
        if ($upiOnly) {
            if (!preg_match('/^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$/', $upi)) {
                return response()->json(['status' => false, 'message' => 'Enter a valid UPI ID'], 400);
            }
            $bankName = '';
            $acct = '';
            $ifsc = '';
        } else {
            if ($acct === '' || !preg_match('/^\d{9,18}$/', $acct)) {
                return response()->json(['status' => false, 'message' => 'bank_account_number is required.'], 400);
            }
            if (!preg_match('/^[A-Z]{4}0[A-Z0-9]{6}$/', $ifsc)) {
                return response()->json(['status' => false, 'message' => 'bank_ifsc is required.'], 400);
            }
            if ($bankName === '') {
                return response()->json(['status' => false, 'message' => 'bank_name is required.'], 400);
            }
            if ($method === 'bank') {
                $upi = '';
            }
        }

        try {

            $this->getUser(Auth::user()->id)->update([
                'bank_full_name' => $fullName,
                'bank_name' => $bankName,
                'bank_account_number' => $acct,
                'bank_ifsc' => $ifsc,
                'upi_address' => $upi,
            ]);

            $response = [
                'message' => "Bank Detail Updated Successfully",
            ];
            return response()->json($response, 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 0, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }

    function getBankDetail()
    {
        try {
            $user = $this->getUser(Auth::user()->id);
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'User bank details are not provided.'
                ], 400);
            }

            $bankName = trim((string) ($user->bank_name ?? ''));
            $account = preg_replace('/\s+/', '', (string) ($user->bank_account_number ?? ''));
            $ifsc = trim((string) ($user->bank_ifsc ?? ''));
            $holder = trim((string) ($user->bank_full_name ?? ''));
            $upi = trim((string) ($user->upi_address ?? ''));

            // Soft: return whatever is saved. Old strict all-fields gate blocked V3 Account row.
            if ($bankName === '' && $account === '' && $upi === '') {
                return response()->json([
                    'status' => false,
                    'message' => 'User bank details are not provided.'
                ], 400);
            }

            $data = [
                'account_holder_name' => $holder !== '' ? $holder : null,
                'bank_name' => $bankName !== '' ? $bankName : null,
                'account_number' => $account !== '' ? $account : null,
                'ifsc_code' => $ifsc !== '' ? $ifsc : null,
                'upi_address' => $upi !== '' ? $upi : null,
            ];
            return response()->json(['data' => $data, 'status' => true], 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), Auth::user()->id ?? 1, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }

    function updateAddress(Request $request)
    {
        $rules = [
            'address' => 'required|string',
            'landmark' => 'required|string',
            'city' => 'required|string',
            'pincode' => 'required|string'
        ];
        $messages = [
            'address.required' => 'address is required.',
            'landmark.required' => 'landmark is required.',
            'city.required' => 'city is required.',
            'pincode.required' => 'pincode is required.',
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }
        try {

            $this->getUser(Auth::user()->id)->update([
                'address' => $request->address,
                'landmark' => $request->landmark,
                'city' => $request->city,
                'pincode' => $request->pincode,
            ]);

            $response = [
                'message' => "Address Updated Successfully",
            ];
            return response()->json($response, 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 0, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }

    function getAddress()
    {
        try {
            $user = $this->getUser(Auth::user()->id);
            if ($user) {
                if (is_null($user->address) || is_null($user->landmark) || is_null($user->city) || is_null($user->pincode)) {
                    return response()->json([
                        'status' => false,
                        'message' => 'User addresses are not provided.'
                    ], 400);
                }
                $data = [
                    'address_line_1' => $user->address,
                    'landmark' => $user->landmark,
                    'city' => $user->city,
                    'pincode' => $user->pincode,
                ];
            }
            return response()->json(['data' => $data], 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), Auth::user()->id ?? 1, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }

    /**
     * Start change-phone: OTP to the *new* number. Does not create a second user.
     * Pending payload lives in cache for 10 minutes.
     */
    function changePhone(Request $request)
    {
        $mobile = preg_replace('/\D/', '', (string) $request->input('mobile', ''));
        if (strlen($mobile) !== 10) {
            return response()->json([
                'status' => false,
                'message' => 'Enter a valid 10-digit mobile number',
            ], 400);
        }

        $user = Auth::user();
        $current = preg_replace('/\D/', '', (string) ($user->mobile ?? ''));
        if ($mobile === $current) {
            return response()->json([
                'status' => false,
                'message' => 'That’s already your number',
            ], 400);
        }

        $taken = User::where('mobile', $mobile)->where('id', '!=', $user->id)->exists();
        if ($taken) {
            return response()->json([
                'status' => false,
                'message' => 'This number is already linked to another Mintzer account',
            ], 400);
        }

        try {
            $otpdetails = $this->getOtpDetails();
            $otp = ($mobile == '9876543210')
                ? 123456
                : $this->generateRandom($otpdetails->otp_length ?? 6);

            $smsdetails = $this->getSmsDetails();
            $dltTemplate = 'Welcome to Mintzer! Here is your OTP {{}} to login into your mintzer account. For more details visit: mintzer.in Regards Mintzr.';
            $msg = str_replace('{{}}', (string) $otp, $dltTemplate);
            $tempid = (is_object($smsdetails) && !empty($smsdetails->otp_msg_tempid))
                ? $smsdetails->otp_msg_tempid
                : env('SMS_GATEWAY_HUB_TEMPLATE_ID', '1307164710973291856');

            if (env('APP_ENV') == 'local') {
                $smsOk = true;
            } else {
                $smsOk = $this->sendSMS($mobile, $msg, $tempid);
            }

            if (!$smsOk) {
                return response()->json([
                    'status' => false,
                    'message' => 'Could not send OTP. Try again.',
                ], 400);
            }

            Cache::put('change_phone_' . $user->id, [
                'mobile' => $mobile,
                'otp' => (string) $otp,
            ], now()->addMinutes(10));

            $response = [
                'status' => true,
                'message' => 'OTP Sent Successfully',
            ];
            if (env('APP_ENV') == 'local') {
                $response['OTP'] = $otp;
            }
            return response()->json($response, 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), $user->id, request()->ip(), gethostname(), 1, LogType::Error);
            return response()->json([
                'status' => false,
                'message' => $this->errorMessage,
            ], 500);
        }
    }

    /**
     * Confirm change-phone OTP and rewrite users.mobile.
     */
    function verifyChangePhone(Request $request)
    {
        $mobile = preg_replace('/\D/', '', (string) $request->input('mobile', ''));
        $otp = trim((string) $request->input('otp', ''));
        if (strlen($mobile) !== 10 || $otp === '') {
            return response()->json([
                'status' => false,
                'message' => 'Mobile and OTP are required',
            ], 400);
        }

        $user = Auth::user();
        $pending = Cache::get('change_phone_' . $user->id);
        if (!is_array($pending)
            || (string) ($pending['mobile'] ?? '') !== $mobile
            || (string) ($pending['otp'] ?? '') !== $otp
        ) {
            return response()->json([
                'status' => false,
                'message' => 'Invalid or expired OTP',
            ], 400);
        }

        $taken = User::where('mobile', $mobile)->where('id', '!=', $user->id)->exists();
        if ($taken) {
            Cache::forget('change_phone_' . $user->id);
            return response()->json([
                'status' => false,
                'message' => 'This number is already linked to another Mintzer account',
            ], 400);
        }

        try {
            $this->getUser($user->id)->update(['mobile' => $mobile]);
            Cache::forget('change_phone_' . $user->id);
            return response()->json([
                'status' => true,
                'message' => 'Phone updated successfully',
                'mobile' => $mobile,
            ], 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), $user->id, request()->ip(), gethostname(), 1, LogType::Error);
            return response()->json([
                'status' => false,
                'message' => $this->errorMessage,
            ], 500);
        }
    }
}
