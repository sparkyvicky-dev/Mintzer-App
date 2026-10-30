<?php
$tokenExpected = 'mz_v3_test_20260921b';
if (!isset($_GET['token']) || $_GET['token'] !== $tokenExpected) {
    http_response_code(403);
    header('Content-Type: text/plain');
    echo 'forbidden';
    exit;
}

require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Services\AdminApp\AdminFcmClient;
use App\Services\V3Push\V3DealLiveService;
use App\Services\V3Push\V3PushGateway;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

header('Content-Type: application/json');

try {
    $sent = [];

    // 1) Prefer V3 device rows
    if (Schema::hasTable('v3_push_devices')) {
        $rows = DB::table('v3_push_devices')
            ->where('app_channel', 'flutter_v3')
            ->orderByDesc('updated_at')
            ->limit(20)
            ->get();
        foreach ($rows as $row) {
            $ok = V3DealLiveService::notifyUserTest((int) $row->user_id);
            $sent[] = ['via' => 'v3_devices', 'user_id' => (int) $row->user_id, 'ok' => $ok];
        }
    }

    // 2) Fallback: recent users.fcm_token (V2 column) — register into V3 then send
    if (count($sent) === 0 && Schema::hasColumn('users', 'fcm_token')) {
        $users = DB::table('users')
            ->whereNotNull('fcm_token')
            ->where('fcm_token', '!=', '')
            ->orderByDesc('updated_at')
            ->limit(5)
            ->get(['id', 'fcm_token']);

        foreach ($users as $u) {
            $token = trim((string) $u->fcm_token);
            if ($token === '') {
                continue;
            }
            V3PushGateway::registerDevice((int) $u->id, $token, 'android');
            $ok = AdminFcmClient::sendToToken(
                $token,
                'Mintzer V3 push',
                'New notification engine is live on your device.',
                ['type' => 'system.test', 'engine' => 'v3', 'channel' => 'mintzer_orders']
            );
            $sent[] = [
                'via' => 'users.fcm_token',
                'user_id' => (int) $u->id,
                'ok' => $ok,
                'err' => $ok ? null : AdminFcmClient::$lastError,
            ];
        }
    }

    echo json_encode(['status' => true, 'sent' => $sent]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['status' => false, 'message' => $e->getMessage()]);
}
