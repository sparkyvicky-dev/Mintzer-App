<?php
/**
 * ONE-SHOT debug: V3 push diagnose + force relist/live.
 * DELETE after use.
 * ?token=mz_v3_dbg_20260922&deal_id=ID&action=diag|relist|live|why
 */
$tokenExpected = 'mz_v3_dbg_20260922';
if (!isset($_GET['token']) || $_GET['token'] !== $tokenExpected) {
    http_response_code(403);
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
use App\Services\V3Push\V3PushTemplateBank;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

header('Content-Type: application/json');

$dealId = (int) ($_GET['deal_id'] ?? 0);
$action = (string) ($_GET['action'] ?? 'diag');
$q = trim((string) ($_GET['q'] ?? 'iphone'));

try {
    $out = [
        'v3_enabled' => V3PushGateway::enabled(),
        'device_users' => 0,
        'devices' => 0,
        'deal' => null,
        'recent_sends' => [],
        'recent_outbox' => [],
        'fcm_last_error' => null,
        'user_why' => [],
        'action_result' => null,
        'sample_copy' => null,
    ];

    if (Schema::hasTable('v3_push_devices')) {
        $out['devices'] = (int) DB::table('v3_push_devices')->where('app_channel', 'flutter_v3')->count();
        $out['device_users'] = (int) DB::table('v3_push_devices')
            ->where('app_channel', 'flutter_v3')
            ->distinct('user_id')
            ->count('user_id');
    }

    $deal = null;
    if ($dealId > 0 && Schema::hasTable('deals')) {
        $deal = DB::table('deals')->where('id', $dealId)->first();
    } elseif (Schema::hasTable('deals') && $q !== '') {
        $deal = DB::table('deals')->where('name', 'like', '%' . $q . '%')->orderByDesc('id')->first();
        if ($deal) {
            $dealId = (int) $deal->id;
        }
    }
    if ($deal) {
        $out['deal'] = [
            'id' => (int) $deal->id,
            'name' => $deal->name ?? null,
            'status' => $deal->status ?? null,
            'order_qty' => $deal->order_qty ?? null,
        ];
        $out['sample_copy'] = V3PushTemplateBank::pick('deal_relist', V3PushTemplateBank::tokensFromDeal($deal));
    }

    if (Schema::hasTable('v3_push_send_log')) {
        $out['recent_sends'] = DB::table('v3_push_send_log')
            ->orderByDesc('id')
            ->limit(15)
            ->get()
            ->map(fn ($r) => [
                'id' => $r->id,
                'user_id' => $r->user_id,
                'event_type' => $r->event_type,
                'deal_id' => $r->deal_id,
                'created_at' => (string) $r->created_at,
            ])
            ->all();
    }

    if (Schema::hasTable('v3_push_outbox')) {
        $out['recent_outbox'] = DB::table('v3_push_outbox')
            ->orderByDesc('id')
            ->limit(12)
            ->get()
            ->map(fn ($r) => [
                'id' => $r->id,
                'user_id' => $r->user_id,
                'event_type' => $r->event_type,
                'status' => $r->status,
                'error' => $r->error,
                'title' => $r->title,
                'created_at' => (string) $r->created_at,
            ])
            ->all();
    }

    // Per-user skip reasons
    if (Schema::hasTable('v3_push_devices')) {
        $uids = DB::table('v3_push_devices')
            ->where('app_channel', 'flutter_v3')
            ->distinct()
            ->pluck('user_id');
        foreach ($uids as $uid) {
            $uid = (int) $uid;
            $prefs = V3PushGateway::prefsFor($uid);
            $why = [];
            if (!$prefs['master']) {
                $why[] = 'master_off';
            }
            if (empty($prefs['deals'])) {
                $why[] = 'deals_off';
            }
            if (V3PushGateway::hasActivePlacement($uid)) {
                $why[] = 'active_placement';
            }
            $last = null;
            $day = 0;
            if (Schema::hasTable('v3_push_send_log')) {
                $day = DB::table('v3_push_send_log')
                    ->where('user_id', $uid)
                    ->where('created_at', '>=', now()->subDay())
                    ->count();
                $last = DB::table('v3_push_send_log')
                    ->where('user_id', $uid)
                    ->orderByDesc('id')
                    ->value('created_at');
            }
            $gapMins = $last ? abs(now()->diffInMinutes(\Carbon\Carbon::parse($last), false)) : null;
            if ($gapMins !== null && $gapMins < 25) {
                $why[] = 'min_gap_' . $gapMins . 'm';
            }
            $tokens = DB::table('v3_push_devices')
                ->where('user_id', $uid)
                ->where('app_channel', 'flutter_v3')
                ->pluck('fcm_token')
                ->all();
            if (empty($tokens)) {
                $why[] = 'no_token';
            }
            $out['user_why'][] = [
                'user_id' => $uid,
                'prefs' => $prefs,
                'day_sends' => $day,
                'last_send' => $last ? (string) $last : null,
                'gap_mins' => $gapMins,
                'tokens' => count($tokens),
                'token_prefix' => !empty($tokens) ? substr((string) $tokens[0], 0, 16) . '…' : null,
                'blockers' => $why,
            ];
        }
    }

    if ($dealId > 0 && $action === 'relist') {
        $out['action_result'] = V3DealLiveService::notifyDealRelist($dealId);
        $out['fcm_last_error'] = AdminFcmClient::$lastError ?? null;
    } elseif ($dealId > 0 && $action === 'live') {
        $out['action_result'] = V3DealLiveService::notifyDealLive($dealId);
        $out['fcm_last_error'] = AdminFcmClient::$lastError ?? null;
    } elseif ($dealId > 0 && $action === 'force_one') {
        // Bypass caps: send to first V3 user with force=true
        $uid = (int) (DB::table('v3_push_devices')->where('app_channel', 'flutter_v3')->value('user_id') ?? 0);
        $copy = $out['sample_copy'] ?? ['title' => 'Test', 'body' => 'Test'];
        $ok = V3PushGateway::enqueueAndSend(
            $uid,
            'deal.relist',
            $copy['title'] ?? 'Relist',
            $copy['body'] ?? 'Back',
            ['deal_id' => (string) $dealId, 'type' => 'deal.relist'],
            'mintzer_deals',
            'deals',
            true
        );
        $out['action_result'] = ['user_id' => $uid, 'ok' => $ok];
        $out['fcm_last_error'] = AdminFcmClient::$lastError ?? null;
    }

    // Refresh outbox tail after action
    if (Schema::hasTable('v3_push_outbox') && in_array($action, ['relist', 'live', 'force_one'], true)) {
        $out['recent_outbox'] = DB::table('v3_push_outbox')
            ->orderByDesc('id')
            ->limit(8)
            ->get()
            ->map(fn ($r) => [
                'id' => $r->id,
                'user_id' => $r->user_id,
                'event_type' => $r->event_type,
                'status' => $r->status,
                'error' => $r->error,
                'title' => $r->title,
            ])
            ->all();
    }

    echo json_encode($out, JSON_PRETTY_PRINT);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['status' => false, 'message' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
}
