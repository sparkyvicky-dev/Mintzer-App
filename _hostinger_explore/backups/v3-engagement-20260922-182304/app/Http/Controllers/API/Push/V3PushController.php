<?php

namespace App\Http\Controllers\API\Push;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\V3Push\V3DealLiveService;
use App\Services\V3Push\V3PushGateway;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;

/**
 * Flutter V3 push APIs — parallel to legacy /fcm-update.
 * Never modifies HolderNotifyService or cron FCM.
 */
class V3PushController extends Controller
{
    public function register(Request $request)
    {
        $token = trim((string) $request->input('fcm_token', ''));
        $platform = trim((string) $request->input('platform', 'android'));
        $userId = (int) Auth::id();

        if ($userId < 1 || $token === '') {
            return response()->json(['status' => false, 'message' => 'Invalid token'], 400);
        }

        if (!Schema::hasTable('v3_push_devices')) {
            return response()->json([
                'status' => false,
                'message' => 'V3 push tables not installed yet',
            ], 503);
        }

        V3PushGateway::registerDevice($userId, $token, $platform !== '' ? $platform : 'android');

        // Keep V2 column in sync so existing admin tools still see a token (additive).
        try {
            $user = User::find($userId);
            if ($user) {
                $user->fcm_token = $token;
                $user->save();
            }
        } catch (\Throwable $e) {
            // ignore
        }

        return response()->json(['status' => true, 'message' => 'V3 device registered'], 200);
    }

    public function prefs(Request $request)
    {
        $userId = (int) Auth::id();
        if ($userId < 1) {
            return response()->json(['status' => false], 401);
        }

        if ($request->isMethod('get')) {
            return response()->json(['status' => true, 'prefs' => V3PushGateway::prefsFor($userId)], 200);
        }

        V3PushGateway::savePrefs($userId, [
            'master' => $request->boolean('master', true),
            'deals' => $request->boolean('deals', true),
            'orders' => $request->boolean('orders', true),
            'payments' => $request->boolean('payments', true),
        ]);

        return response()->json(['status' => true, 'prefs' => V3PushGateway::prefsFor($userId)], 200);
    }

    /** Self-test for the logged-in Flutter user. */
    public function testSelf(Request $request)
    {
        $userId = (int) Auth::id();
        if ($userId < 1) {
            return response()->json(['status' => false], 401);
        }
        $ok = V3DealLiveService::notifyUserTest($userId);
        return response()->json([
            'status' => $ok,
            'message' => $ok ? 'Test push sent' : 'Not sent (prefs/caps/tables/token)',
        ], $ok ? 200 : 400);
    }

    public function dealLive(Request $request)
    {
        $user = Auth::user();
        if (!$user || (int) ($user->role_id ?? 0) !== 1) {
            return response()->json(['status' => false, 'message' => 'Admin only'], 403);
        }

        $dealId = (int) $request->input('deal_id', 0);
        if ($dealId < 1) {
            return response()->json(['status' => false, 'message' => 'deal_id required'], 400);
        }

        $minEarn = $request->has('min_earn') ? (int) $request->input('min_earn') : null;
        $result = V3DealLiveService::notifyDealLive($dealId, $minEarn);

        return response()->json(['status' => true, 'result' => $result], 200);
    }
}
