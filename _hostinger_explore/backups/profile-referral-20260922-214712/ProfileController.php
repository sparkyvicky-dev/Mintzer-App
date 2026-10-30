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
                    'role_id' => $user->role_id,
                    'wallet_amount' => $user->wallet,
                    'is_active' => $user->is_active,
                    'is_new_user' => $user->is_verified == 1 ? true : false,
                    'is_whatsapp_access' => $user->whatsapp_access == 1 ? true : false,
                    'is_bank_account_added' => $user->bank_account_number ? true : false,
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
        // V3: client sends PAN only; name comes from The Verifico (NSDL).
        // Legacy clients that still post `name` keep working when Verifico is off.
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
            if (\App\Services\Verifico\VerificoPanService::enabled()) {
                $result = \App\Services\Verifico\VerificoPanService::verifyPan($pan);
                if (!$result['ok']) {
                    $this->Log(
                        __FUNCTION__,
                        request()->method(),
                        'Verifico PAN failed: ' . ($result['message'] ?? ''),
                        Auth::user()->id,
                        request()->ip(),
                        gethostname(),
                        1,
                        LogType::Error
                    );
                    return response()->json([
                        'status' => false,
                        'message' => $result['message'] ?? 'PAN could not be verified',
                    ], 400);
                }
                $name = $result['name'];
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
        // UPI optional (LOCKED payout sheet). Empty string clears UPI.
        $rules = [
            'full_name' => 'required|string',
            'bank_name' => 'required|string',
            'bank_account_number' => 'required|string',
            'bank_ifsc' => 'required|string',
            'upi_address' => 'nullable|string',
        ];
        $messages = [
            'full_name.required' => 'full_name is required.',
            'bank_name.required' => 'bank_name is required.',
            'bank_account_number.required' => 'bank_account_number is required.',
            'bank_ifsc.required' => 'bank_ifsc is required.',
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
                'bank_full_name' => $request->full_name,
                'bank_name' => $request->bank_name,
                'bank_account_number' => $request->bank_account_number,
                'bank_ifsc' => $request->bank_ifsc,
                'upi_address' => $request->upi_address ?? '',
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
            if ($bankName === '' && $account === '') {
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
