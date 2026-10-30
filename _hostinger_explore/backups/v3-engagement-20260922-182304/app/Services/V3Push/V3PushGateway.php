<?php

namespace App\Services\V3Push;

use App\Services\AdminApp\AdminFcmClient;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Flipkart-style gateway for Flutter V3 only.
 * Does not replace HolderNotifyService / CronjobController (V2 Play).
 */
class V3PushGateway
{
    /** Soft kill-switch — when false, enqueue is no-op (V2 untouched). */
    public static function enabled(): bool
    {
        $env = getenv('MINTZER_V3_PUSH');
        if ($env === false || $env === '') {
            // Default ON once tables exist; set MINTZER_V3_PUSH=0 to pause V3 only.
            return Schema::hasTable('v3_push_devices');
        }
        return !in_array(strtolower((string) $env), ['0', 'false', 'off', 'no'], true);
    }

    public static function registerDevice(int $userId, string $token, string $platform = 'android'): void
    {
        if ($token === '' || !Schema::hasTable('v3_push_devices')) {
            return;
        }

        DB::table('v3_push_devices')->updateOrInsert(
            ['fcm_token' => $token],
            [
                'user_id' => $userId,
                'platform' => $platform,
                'app_channel' => 'flutter_v3',
                'updated_at' => now(),
                'created_at' => now(),
            ]
        );

        if (!Schema::hasTable('v3_push_prefs')) {
            return;
        }

        $exists = DB::table('v3_push_prefs')->where('user_id', $userId)->exists();
        if (!$exists) {
            DB::table('v3_push_prefs')->insert([
                'user_id' => $userId,
                'master' => 1,
                'deals' => 1,
                'orders' => 1,
                'payments' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public static function savePrefs(int $userId, array $prefs): void
    {
        if (!Schema::hasTable('v3_push_prefs')) {
            return;
        }

        DB::table('v3_push_prefs')->updateOrInsert(
            ['user_id' => $userId],
            [
                'master' => !empty($prefs['master']) ? 1 : 0,
                'deals' => !empty($prefs['deals']) ? 1 : 0,
                'orders' => !empty($prefs['orders']) ? 1 : 0,
                'payments' => !empty($prefs['payments']) ? 1 : 0,
                'updated_at' => now(),
                'created_at' => now(),
            ]
        );
    }

    public static function prefsFor(int $userId): array
    {
        $defaults = ['master' => true, 'deals' => true, 'orders' => true, 'payments' => true];
        if (!Schema::hasTable('v3_push_prefs')) {
            return $defaults;
        }
        $row = DB::table('v3_push_prefs')->where('user_id', $userId)->first();
        if (!$row) {
            return $defaults;
        }
        return [
            'master' => (bool) $row->master,
            'deals' => (bool) $row->deals,
            'orders' => (bool) $row->orders,
            'payments' => (bool) $row->payments,
        ];
    }

    /**
     * Enqueue + attempt immediate send for one user.
     * Caps are soft (skip), never throw into V2 flows.
     */
    public static function enqueueAndSend(
        int $userId,
        string $eventType,
        string $title,
        string $body,
        array $data = [],
        string $channel = 'mintzer_deals',
        string $tier = 'deals'
    ): bool {
        if (!self::enabled()) {
            return false;
        }

        $prefs = self::prefsFor($userId);
        if (!$prefs['master'] || empty($prefs[$tier])) {
            return false;
        }

        if (!self::passesCaps($userId, $eventType)) {
            return false;
        }

        if (self::inQuietHours() && $tier === 'deals') {
            // Commercial quiet hours — skip now (follow-up scheduler later).
            self::writeOutbox($userId, $eventType, $title, $body, $data, $channel, 'queued_quiet');
            return false;
        }

        $outboxId = self::writeOutbox($userId, $eventType, $title, $body, $data, $channel, 'sending');

        $tokens = [];
        if (Schema::hasTable('v3_push_devices')) {
            $tokens = DB::table('v3_push_devices')
                ->where('user_id', $userId)
                ->where('app_channel', 'flutter_v3')
                ->pluck('fcm_token')
                ->all();
        }

        // Fallback: same column V2 uses — only if V3 device row missing (transition).
        if (empty($tokens) && Schema::hasColumn('users', 'fcm_token')) {
            $legacy = DB::table('users')->where('id', $userId)->value('fcm_token');
            if (is_string($legacy) && trim($legacy) !== '') {
                $tokens = [trim($legacy)];
            }
        }

        $sentAny = false;
        $data['channel'] = $channel;
        $data['event_type'] = $eventType;
        $data['engine'] = 'v3';

        foreach ($tokens as $token) {
            if (AdminFcmClient::sendToToken((string) $token, $title, $body, $data)) {
                $sentAny = true;
            }
        }

        if ($outboxId && Schema::hasTable('v3_push_outbox')) {
            DB::table('v3_push_outbox')->where('id', $outboxId)->update([
                'status' => $sentAny ? 'sent' : 'failed',
                'sent_at' => $sentAny ? now() : null,
                'error' => $sentAny ? null : (AdminFcmClient::$lastError ?? 'send_failed'),
                'updated_at' => now(),
            ]);
        }

        if ($sentAny && Schema::hasTable('v3_push_send_log')) {
            DB::table('v3_push_send_log')->insert([
                'user_id' => $userId,
                'event_type' => $eventType,
                'deal_id' => isset($data['deal_id']) ? (int) $data['deal_id'] : null,
                'created_at' => now(),
            ]);
        }

        // Bell inbox (shared table — additive row; V2 list API still works).
        try {
            if (class_exists(\App\Models\Notification::class)) {
                $row = new \App\Models\Notification();
                $row->user_id = $userId;
                $row->title = $title;
                $row->content = $body;
                $row->status = $sentAny ? 1 : 0;
                $row->save();
            }
        } catch (\Throwable $e) {
            // best-effort
        }

        return $sentAny;
    }

    private static function writeOutbox(
        int $userId,
        string $eventType,
        string $title,
        string $body,
        array $data,
        string $channel,
        string $status
    ): ?int {
        if (!Schema::hasTable('v3_push_outbox')) {
            return null;
        }
        return (int) DB::table('v3_push_outbox')->insertGetId([
            'user_id' => $userId,
            'event_type' => $eventType,
            'channel' => $channel,
            'title' => $title,
            'body' => $body,
            'data_json' => json_encode($data),
            'status' => $status,
            'scheduled_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private static function passesCaps(int $userId, string $eventType): bool
    {
        if (!Schema::hasTable('v3_push_send_log')) {
            return true;
        }
        $day = DB::table('v3_push_send_log')
            ->where('user_id', $userId)
            ->where('created_at', '>=', now()->subDay())
            ->count();
        if ($day >= 2) {
            return false; // notificationMaxPushPerDay
        }
        $last = DB::table('v3_push_send_log')
            ->where('user_id', $userId)
            ->orderByDesc('id')
            ->value('created_at');
        if ($last && abs(now()->diffInHours(\Carbon\Carbon::parse($last), false)) < 8) {
            // Min gap — allow transactional order events through.
            if (strpos($eventType, 'deal.') === 0) {
                return false;
            }
        }
        return true;
    }

    private static function inQuietHours(): bool
    {
        try {
            $hour = (int) now('Asia/Kolkata')->format('G');
            return $hour >= 22 || $hour < 8;
        } catch (\Throwable $e) {
            return false;
        }
    }
}
