<?php

namespace App\Http\Controllers\API\Auth;

use App\Enums\LogType;
use App\Enums\RoleTypes;
use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterRequests;
use App\Models\Customer;
use App\Models\CustomerAddress;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Traits\Common;
use App\Traits\ResponseAPI;
use Carbon\Carbon;
use Exception;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Intervention\Image\Facades\Image;


class AuthController extends Controller
{
    use Common;
    use ResponseAPI;

    public function sendOTP(Request $request)
    {
        if ($request->mobile == null || $request->mobile == '' || !$request->mobile) {
            return response()->json([
                'status' => false,
                'message' => 'mobile number is required.',
            ], 400);
        }
        try {
            $deactivatedCustomer = User::where('mobile', $request->mobile)->where('is_active', 0)->first();
            if ($deactivatedCustomer) {
                return response()->json([
                    'status' => false,
                    'message' => "Your account has been deactivated by the admin. Please contact them.",
                ], 401);
            }

            $mobile = preg_replace('/\D+/', '', (string) $request->mobile);
            if (strlen($mobile) > 10) {
                $mobile = substr($mobile, -10);
            }
            $device_id = $request->device_id;
            $referral_code = $request->referral_code;
            $isReviewLogin = $mobile === '9876543210';

            // Google's fetch proxy. It moved ranges after the first block and texted again.
            // The review test number never sends an SMS, so Play's robots may still use it.
            $callerIp = (string) $request->ip();
            $fromGoogleProxy = preg_match('/^(66\.249\.|66\.102\.|74\.125\.|64\.233\.|172\.217\.|142\.250\.|142\.251\.|173\.194\.|108\.177\.|216\.239\.|209\.85\.|192\.178\.|192\.179\.)/', $callerIp) === 1;
            if ($fromGoogleProxy && !$isReviewLogin) {
                return response()->json([
                    'status' => false,
                    'message' => 'Could not send OTP. Try again.',
                ], 429);
            }

            // 5 texts a day is enough for a real login. Stops a repeat caller.
            $known = User::where('mobile', $mobile)->first();
            if ($known && !$isReviewLogin) {
                $dayCount = DB::table('logs')
                    ->where('user_id', $known->id)
                    ->where('transaction_name', 'sendOTP')
                    ->where('log_date', '>=', now()->subHours(24))
                    ->count();
                if ($dayCount >= 5) {
                    return response()->json([
                        'status' => false,
                        'message' => 'Too many OTP requests. Please try again later.',
                    ], 429);
                }
            }

            $otpdetails = $this->getOtpDetails();
            if ($mobile == 9876543210) {
                $otp = 123456;
            } else {
                $otp = $this->generateRandom($otpdetails->otp_length);
            }

            $smsdetails = $this->getSmsDetails();
            // DLT text must match approved Mintzer template exactly (ignore stale admin SMS copy).
            $dltTemplate = 'Welcome to Mintzer! Here is your OTP {{}} to login into your mintzer account. For more details visit: mintzer.in Regards Mintzr.';
            $msg = str_replace('{{}}', (string) $otp, $dltTemplate);
            $tempid = (is_object($smsdetails) && !empty($smsdetails->otp_msg_tempid))
                ? $smsdetails->otp_msg_tempid
                : env('SMS_GATEWAY_HUB_TEMPLATE_ID', '1307164710973291856');

            $expiry = now()->addMinutes($otpdetails->otp_expiry_duration);

            // Persist OTP first — never block the API on SMS Gateway Hub latency.
            $existing = User::where('mobile', $mobile)->first();
            if ($existing) {
                if ($referral_code) {
                    return response()->json([
                        'status' => false,
                        'message' => "You can't use Referral Code.",
                    ], 400);
                }
                $existing->otp = $otp;
                $existing->otp_expiry = $expiry;
                $existing->save();
                $user = $existing;
                $response = [
                    'is_new_user' => $user->is_verified == 0 ? true : false,
                    'message' => 'OTP Sent Successfully',
                    'OTP' => $otp,
                    'otp_expiry' => $expiry,
                ];
            } else {
                if ($referral_code) {
                    $referred_by = User::where('referral_code', $referral_code)->first();
                    if (!$referred_by) {
                        return response()->json([
                            'status' => false,
                            'message' => "Invalid! Referral Code.",
                        ], 400);
                    }
                    $existing_user = User::where('device_id', $device_id)->where('referral_code', $referral_code)->first();
                    if ($existing_user) {
                        return response()->json([
                            'status' => false,
                            'message' => "This device has already used this referral code.",
                        ], 400);
                    }
                }
                $name = 'User' . substr($mobile, -4);
                $random_digits = substr($mobile, rand(0, strlen($mobile) - 4), 4);
                $ref_code = 'ref' . $random_digits;
                $user = User::create([
                    'display_name' => $name,
                    'mobile' => $mobile,
                    'role_id' => RoleTypes::Customer,
                    'password' => Hash::make($mobile),
                    'otp' => $otp,
                    'otp_expiry' => $expiry,
                    'referral_code' => $ref_code,
                    'device_id' => $device_id,
                ]);
                if ($referral_code) {
                    $this->verifyReferral($referral_code, $user->id);
                }
                $response = [
                    'is_new_user' => true,
                    'message' => 'OTP Sent Successfully',
                    'OTP' => $otp,
                    'otp_expiry' => $expiry,
                ];
            }

            $this->Log(__FUNCTION__, request()->method(), 'You tried to login and OTP has been sent to the registered mobile number.', $user->id, request()->ip(), gethostname(), 1, LogType::Activity);

            // Send SMS after the HTTP response so login is not waiting on the hub (up to 20s).
            if (env('APP_ENV') != 'local' && (string) $mobile !== '9876543210') {
                $sender = $this;
                app()->terminating(function () use ($sender, $mobile, $msg, $tempid) {
                    try {
                        $ok = $sender->sendSMS($mobile, $msg, $tempid);
                        if (!$ok) {
                            \Log::warning('OTP SMS failed after response', ['mobile' => $mobile]);
                        }
                    } catch (\Throwable $e) {
                        \Log::warning('OTP SMS exception after response', ['message' => $e->getMessage()]);
                    }
                });
            }

            return response($response, 200);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);

            $response = array(
                'status' => false,
                'message' => $e,
            );
            return response($response, 400);
        }
    }

    public function verifyOTP(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'mobile' => 'required',
            'otp' => 'required'
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => implode(",", $validator->errors()->all())], 400);
        }
        try {

            $otp = $request->otp;
            $mobile = $request->mobile;
            $response = [];
            $user = null;
            $user = User::where('otp', $otp)
                ->where('mobile', $mobile)
                ->whereNull('deleted_at')
                ->first();

            if (!$user) {
                $message = 'Incorrect OTP!';
                $response = [
                    'status' => false,
                    'message' => $message,
                ];
                return response($response, 400);
            }
            else {
                if (Carbon::now() >= $user->otp_expiry) {
                    $message = 'Your login OTP has been expired!';
                    $response = [
                        'status' => false,
                        'message' => $message,
                    ];
                    return response($response, 400);
                }
                else {
                    User::findOrfail($user->id)->update([
                        'otp_verified' => 1,
                    ]);
                    Auth::login($user);
                    $token = $user->createToken('mintzer')->plainTextToken;

                    $message = 'Your login OTP has been verified.';
                    $response = [
                        'is_new_user' => $user->is_verified == 0 ? true : false,
                        'message' => $message,
                        'user_id' => $user->id,
                        'token' => $token,
                    ];
                }
            }


            $this->Log(__FUNCTION__, request()->method(), $message, $user->id, request()->ip(), gethostname(), 1, LogType::Activity);
            return response($response, 200);
        }
        catch (\Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), auth()->user()->id ?? 1, request()->ip(), gethostname(), 1, LogType::Error);

            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 400);
        }
    }

    // public function signup(RegisterRequests $request)
    // {

    //     $validator = Validator::make($request->all(), [
    //         'mobile'  => 'required',
    //         'name'  => 'required',
    //     ]);
    //     if ($validator->fails()) {
    //         return response()->json(['status' => false, 'message' => implode(",", $validator->errors()->all())], 200);
    //     }

    //     DB::beginTransaction();
    //     try {


    //         $user = User::where('mobile', $request->mobile)->where('role_id', RoleTypes::Customer)->whereNull('deleted_at')->first();

    //         if ($user && $user->otp_verified == 1) {
    //             $user->display_name = $request->name;
    //             $user->pan = $request->pan ?? null;
    //             $user->update();
    //         } else {

    //             return response()->json([
    //                 'message' => 'OTP Not Verified',
    //                 'otp_verified' => false,
    //                 'status' => false,
    //             ], 200);
    //         }


    //         DB::commit();
    //         $response = [
    //             'status' => true,
    //             'message' => 'Thanks for registering with us!'
    //         ];
    //         return response($response, 201);
    //     } catch (\Exception $e) {
    //         DB::rollback();
    //         $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);

    //         $response = array(
    //             'message' => $this->errorMessage,
    //             'status' => false,
    //         );
    //         return response($response, 500);
    //     }
    // }

    // public function login(Request $request)
    // {
    //     $validator = Validator::make($request->all(), [
    //         'mobile'  => 'required',
    //         'otp' => 'required'
    //     ]);

    //     if ($validator->fails()) {
    //         return response()->json(['status' => false, 'message' => implode(",", $validator->errors()->all())], 200);
    //     }

    //     try {
    //         $user = User::where('mobile', $request->mobile)
    //         ->whereNull('deleted_at')
    //         ->where('role_id', RoleTypes::Customer)
    //         ->first();
    //         // dd($request->all());

    //         if ($user && $user->is_verified == 1) {
    //             if ($request->has('otp')) {
    //                 $storedOtp = $user->otp;
    //                 $inputOtp = $request->input('otp');

    //                 $message = ($user->otp != $request->otp ? 'Incorrect OTP!' : (Carbon::now() >= $user->otp_expiry ? 'Your OTP has expired!' : 'Success'));
    //                 if ($storedOtp == $inputOtp && $message === 'Success') {
    //                     Auth::login($user);
    //                     $token = $user->createToken('mintzer')->plainTextToken;
    //                     $response = [
    //                         'status' => true,
    //                         'message' => "Logged in Successfully.",
    //                         'user' => $user,
    //                         'token' => $token,
    //                     ];
    //                 } else {
    //                     return response()->json(['status' => false, 'message' => $message], 200);
    //                 }
    //             } else {
    //                 return response()->json(['status' => false, 'message' => 'OTP is required'], 200);
    //             }
    //         } else {
    //             $response = [
    //                 'status' => false,
    //                 'message' => "Invalid Mobile Number. Please register with us."
    //             ];
    //         }

    //         return response($response, 200);
    //     } catch (\Exception $e) {
    //         $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);

    //         $response = array(
    //             'message' => $this->errorMessage,
    //             'status' => false,
    //         );
    //         return response($response, 500);
    //     }
    // }

    public function fcmTokenUpdate(Request $request)
    {
        $token = $request->fcm_token;
        $user_id = Auth::user()->id;
        try {
            if ($user_id && $token) {
                $user = User::find($user_id);
                if ($user->otp_verified != 1) {
                    $response = array(
                        'message' => "OTP Not Verified",
                        'status' => false,
                    );
                }
                else {
                    $user->fcm_token = $request->fcm_token;
                    $user->update();
                    $response = array(
                        'message' => "The FCM token updated successfully",
                    );
                    $this->Log(__FUNCTION__, request()->method(), "The FCM token updated successfully", $user->id, request()->ip(), gethostname(), 1, LogType::Activity);
                    return response($response, 200);
                }
            }
            else {
                $response = array(
                    'status' => false,
                    'message' => "Invalid User. Please register with us.",
                );
            }

            return response($response, 400);
        }
        catch (\Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }
    // public function verifyMobile(Request $request)
    // {
    //     $mobile = $request->mobile;
    //     try {
    //         $user = User::where('mobile', $mobile)
    //             ->whereNull('deleted_at')
    //             ->first();
    //         if ($user) {

    //             if ($user->otp_verified != 1) {
    //                 $response = array(
    //                     'message' => "OTP Not Verified",
    //                     'otp_verified' => false,
    //                     'registered' => true,
    //                     'status' => false,
    //                 );
    //             } else {
    //                 if ($user->is_admin_verified == 1) {
    //                     $response = array(
    //                         'message' => "success",
    //                         'otp_verified' => true,
    //                         'registered' => true,
    //                         'status' => true,
    //                     );
    //                 } else {
    //                     $response = array(
    //                         'message' => "Thanks for registering with us! Still your account is not approved. Please contact click your order support team for further clarifications.",
    //                         'otp_verified' => true,
    //                         'registered' => true,
    //                         'status' => false,
    //                     );
    //                 }
    //             }
    //         } else {
    //             $response = array(
    //                 'message' => "Invalid Mobile Number. Please register with us.",
    //                 'otp_verified' => false,
    //                 'registered' => false,
    //                 'customer_address' => false,
    //                 'status' => false,
    //             );
    //         }

    //         return response($response, 200);
    //     } catch (\Exception $e) {
    //         $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);
    //         // return $this->error($e->getMessage(), 200);
    //         $response = array(
    //             'message' => $this->errorMessage,
    //             'status' => false,
    //         );
    //         return response($response, 500);
    //     }
    // }
    public function logout(Request $request)
    {
        if (auth()->user()) {
            $request->user()->currentAccessToken()->delete();
            $this->Log(__FUNCTION__, request()->method(), 'Logged out successfully', auth()->user()->id, request()->ip(), gethostname(), 1, LogType::Activity);
            return response()->json(['message' => 'Logged out successfully'], 200);
        }
        else {
            return response()->json([
                'status' => false,
                'message' => 'You have already logged out. Please restart the app.'

            ], 400);
        }
    }

    public function deleteAccount()
    {
        try {
            $orders = Order::whereNotIn('order_status', ['Delivered', 'Declined'])
                ->where('user_id', Auth::user()->id)
                ->get();
            if ($orders->count() > 0) {
                $response = array(
                    'message' => "You can't delete your account now because there is a processing order!",
                    'status' => false,
                );
            }
            else {
                $user = User::find(Auth::user()->id);
                //Update user account 
                // $user->is_active = 0;
                // $user->save();
                //Delete user account
                $user->delete();
                $response = array(
                    'message' => 'Account deleted successfully',
                    'status' => true,
                );
            }
            return response($response, 200);
        }
        catch (\Exception $e) {
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), auth()->user()->id, request()->ip(), gethostname(), 1, LogType::Error);
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }
}
