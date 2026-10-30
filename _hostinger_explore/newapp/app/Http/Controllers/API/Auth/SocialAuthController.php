<?php

namespace App\Http\Controllers\API\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Traits\Common;
use GuzzleHttp\Client;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SocialAuthController extends Controller
{
    use Common;
    public function social_register(Request $request)
    {
        $rules = [
            'token' => 'required',
            'unique_id' => 'required',
            'email' => 'required',
            'medium' => 'required|in:google,facebook,apple'
        ];
        $messages = [
            'token.required' => 'token is required.',
            'unique_id.required' => 'unique_id is required.',
            'email.required' => 'email is required.',
            'medium.required' => 'medium is required.',
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }

        $user = User::where('email', $request->email)->first();
        if ($user) {
            return response()->json([
                'status' => false,
                'message' => "Email already exist.",
            ], 400);
        }

        $client = new Client();
        $token = $request->token;
        $unique_id = $request->unique_id;
        $email = $request->email;
        $device_id = $request->device_id;

        try {
            if ($request['medium'] == 'google') {
                $res = $client->request('GET', 'https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=' . $token);
                $data = json_decode($res->getBody()->getContents(), true);
            } elseif ($request['medium'] == 'facebook') {
                $res = $client->request('GET', 'https://graph.facebook.com/' . $unique_id . '?access_token=' . $token . '&&fields=name,email');
                $data = json_decode($res->getBody()->getContents(), true);
            } else {
                $jwt = json_decode(base64_decode(str_replace('_', '/', str_replace('-', '+', explode('.', $request->token)[1]))));
                $data = ['name' => $request->name, 'email' => $request->email, 'id' => $request->unique_id, 'kid' => $request->unique_id];
                // dd($jwt);
            }
        } catch (\Exception $e) {
            return response()->json(['status' => false, 'message' => $e->getMessage()], 400);
        }
        if (strcmp($email, $data['email']) === 0) {
            $user = User::where('email', $email)->first();
            if (isset($user) == false) {
                $user = User::where('social_id', $request->unique_id)->first();
            }
            // dd($user);
            if (isset($user) == false) {
                if (!isset($data['id']) && !isset($data['kid'])) {
                    return response()->json(['error' => 'wrong credential.'], 403);
                }
                $pk = isset($data['id']) ? $data['id'] : $data['kid'];

                $user = User::create([
                    'display_name' => $data['name'],
                    'email' => $email,
                    'password' => bcrypt($pk),
                    'login_medium' => $request['medium'],
                    'social_id' => $pk,
                    'device_id' => $device_id,
                ]);
            } else {
                return response()->json([
                    'status' => false,
                    'message' => "Email already exist.",
                ], 400);
            }
            if ($request['medium'] == 'apple') {
                $data = [
                    'social_id' => $user->social_id,
                    'password' => $user->social_id
                ];
            } else {
                $data = [
                    'email' => $user->email,
                    'password' => $user->social_id
                ];
            }

            if (auth()->attempt($data)) {
                $token = $user->createToken('mintzer')->plainTextToken;
                if (!auth()->user()->status) {
                    return response()->json([
                        'status' => false,
                        'message' => "Your account is blocked.",
                    ], 400);
                }
                return response()->json(['is_new_user' => true, 'user_id' => $user->id, 'token' => $token], 200);
            } else {
                return response()->json([
                    'status' => false,
                    'message' => "Unauthorized.",
                ], 400);
            }
        }
        return response()->json([
            'status' => false,
            'message' => "Email dosen't matched.",
        ], 400);
    }

    public function social_update(Request $request)
    {
        $rules = [
            'email' => 'required',
            'mobile' => 'required',
        ];
        $messages = [
            'email.required' => 'email is required.',
            'mobile.required' => 'mobile is required.',
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }

        $referral_code = $request->referral_code;

        $user = User::where('email', $request->email)->first();

        $random_digits = substr($request->mobile, rand(0, strlen($request->mobile) - 4), 4);
        $ref_code = 'ref' . $random_digits;

        // Check if the device_id already exists in the user table
        $existing_user = User::where('device_id', $user->device_id)->where('referral_code', $referral_code)->first();

        if ($existing_user) {
            return response()->json([
                'status' => false,
                'message' => "This device has already used this referral code.",
            ], 400);
        }

        DB::table('users')->where('email', $request->email)->update([
            'mobile' => $request->mobile,
            'referral_code' => $ref_code
        ]);

        if ($referral_code) {
            $referred_by = User::where('referral_code', $referral_code)->first();
            if (!$referred_by) {
                return response()->json([
                    'status' => false,
                    'message' => "Invalid! Referral Code.",
                ], 400);
            }

            $this->verifyReferral($referral_code, $user->id);
        }
        return response()->json([
            'status' => true,
            'message' => "Profile updated successfully.",
        ], 200);
    }

    public function social_login(Request $request)
    {
        $rules = [
            'token' => 'required',
            'unique_id' => 'required',
            'email' => 'required',
            'medium' => 'required|in:google,facebook,apple'
        ];
        $messages = [
            'token.required' => 'token is required.',
            'unique_id.required' => 'unique_id is required.',
            'email.required' => 'email is required.',
            'medium.required' => 'medium is required.',
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }

        $client = new Client();
        $token = $request->token;
        $unique_id = $request->unique_id;
        $email = $request->email;

        try {
            if ($request['medium'] == 'google') {
                $res = $client->request('GET', 'https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=' . $token);
                $data = json_decode($res->getBody()->getContents(), true);
            } elseif ($request['medium'] == 'facebook') {
                $res = $client->request('GET', 'https://graph.facebook.com/' . $unique_id . '?access_token=' . $token . '&&fields=name,email');
                $data = json_decode($res->getBody()->getContents(), true);
            } else {
                $jwt = json_decode(base64_decode(str_replace('_', '/', str_replace('-', '+', explode('.', $request->token)[1]))));
                $data = ['name' => $request->name, 'email' => $request->email, 'id' => $request->unique_id, 'kid' => $request->unique_id];
                // dd($jwt);
            }
        } catch (\Exception $e) {
            return response()->json(['status' => false, 'message' => $e->getMessage()], 400);
        }
        if (strcmp($email, $data['email']) != 0 || (!isset($data['id']) && !isset($data['kid']))) {

            return response()->json([
                'status' => false,
                'message' => "Email dosen't matched.",
            ], 400);
        }

        $user = User::where('email', $email)->first();
        if (isset($user) == false) {
            $user = User::where('social_id', $request->unique_id)->first();
        }
        if (isset($user) == false) {
            return response()->json(['is_new_user' => false, 'token' => null], 200);
        }

        if ($user->social_id == null) {
            return response()->json(['is_new_user' => false, 'token' => null], 200);
        }

        if ($request['medium'] == 'apple') {
            $data = [
                'social_id' => $user->social_id,
                'password' => $user->social_id
            ];
        } else {
            $data = [
                'email' => $user->email,
                'password' => $user->social_id
            ];
        }

        if (auth()->attempt($data)) {
            $token = $user->createToken('mintzer')->plainTextToken;
            if (!auth()->user()->status) {
                return response()->json([
                    'status' => false,
                    'message' => "Your account is blocked.",
                ], 400);
            }
            return response()->json(['is_new_user' => false, 'user_id' => $user->id, 'token' => $token], 200);
        } else {
            return response()->json([
                'status' => false,
                'message' => "Unauthorized.",
            ], 400);
        }
        return response()->json([
            'status' => false,
            'message' => "Email dosen't matched.",
        ], 400);
    }
}
