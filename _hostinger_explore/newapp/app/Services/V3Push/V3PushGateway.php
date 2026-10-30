<?php

namespace App\Services\V3Push;

use App\Services\AdminApp\AdminFcmClient;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Flipkart-style gateway for Flutter V3 only.
 * Does not replace HolderNotifyService / CronjobController (V2 Play).
 *
 * Caps: engagement-first (LOCKED NOTIFICATION-TEMPLATES-LOCKED.md).
 */
class V3PushGateway
{
    /** Soft ceiling commercial / user / day */
    public const MAX_COMMERCIAL_PER_DAY = 12;

    /** Min minutes between any two commercial sends */
    public const MIN_GAP_MINUTES = 25;

    /** Events that always bypass quiet hours */
    private const QUIET_EXEMPT = [
        'deal.live',
        'deal.relist',
        'deal.stock',
        'system.test',
        'placement.timer_warning',
    ];

    /** Soft kill-switch — when false, enqueue is no-op (V2 untouched). */
    public static function enabled(): bool
    {
        $env = getenv('MINTZER_V3_PUSH');
        if ($env === false || $env === '') {
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
     * User has an active placement (accepted, placing order) — suppress other-deal commercial.
     */
    public static function hasActivePlacement(int $userId): bool
    {
        try {
            if (!Schema::hasTable('orders')) {
                return false;
            }
            return DB::table('orders')
                ->where('user_id', $userId)
                ->whereNull('deleted_at')
                ->where('order_status', 'Placed')
                ->where(function ($q) {
                    $q->whereNull('store_order_id')->orWhere('store_order_id', '');
                })
                ->exists();
        } catch (\Throwable $e) {
            return false;
        }
    }

    /**
     * Enqueue + attempt immediate send for one user.
     *
     * @param  bool  $force  Bypass caps / quiet (admin / timer critical)
     */
    public static function enqueueAndSend(
        int $userId,
        string $eventType,
        string $title,
        string $body,
        array $data = [],
        string $channel = 'mintzer_deals',
        string $tier = 'deals',
        bool $force = false,
        ?\DateTimeInterface $scheduledAt = null
    ): bool {
        if (!self::enabled()) {
            return false;
        }

        $prefs = self::prefsFor($userId);
        if (!$prefs['master'] || empty($prefs[$tier])) {
            return false;
        }

        // Suppress soft commercial while mid-placement — but NEVER block live/relist
        // (every publish must reach the tray; product rule).
        $isLiveOrRelist = in_array($eventType, ['deal.live', 'deal.relist', 'deal.stock'], true);
        if (
            !$force
            && !$isLiveOrRelist
            && $tier === 'deals'
            && strpos($eventType, 'deal.') === 0
            && $eventType !== 'deal.catalog'
            && self::hasActivePlacement($userId)
        ) {
            return false;
        }

        // Future schedule: write outbox now; caps apply at drain time.
        if ($scheduledAt !== null && $scheduledAt > now()) {
            self::writeOutbox(
                $userId,
                $eventType,
                $title,
                $body,
                $data,
                $channel,
                'pending',
                $scheduledAt
            );
            return false;
        }

        if (!$force && !self::passesCaps($userId, $eventType)) {
            return false;
        }

        $quietExempt = in_array($eventType, self::QUIET_EXEMPT, true)
            || strpos($eventType, 'placement.timer') === 0;

        if (!$force && !$quietExempt && self::inQuietHours() && $tier === 'deals') {
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
        if (!isset($data['type'])) {
            $data['type'] = $eventType;
        }

        foreach ($tokens as $token) {
            if (AdminFcmClient::sendToToken((string) $token, $title, $body, $data)) {
                $sentAny = true;
            } else {
                self::pruneDeadToken((string) $token, AdminFcmClient::$lastError ?? '');
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

        try {
            if (class_exists(\App\Models\Notification::class)) {
                $row = new \App\Models\Notification();
                $row->user_id = $userId;
                $row->title = $title;
                $row->content = $body;
                $row->status = $sentAny ? 1 : 0;
                if (
                    isset($data['order_id'])
                    && Schema::hasColumn('notifications', 'order_id')
                ) {
                    $row->order_id = (int) $data['order_id'];
                }
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
        string $status,
        ?\DateTimeInterface $scheduledAt = null
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
            'scheduled_at' => $scheduledAt
                ? \Carbon\Carbon::parse($scheduledAt)->format('Y-m-d H:i:s')
                : now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private static function passesCaps(int $userId, string $eventType): bool
    {
        if (!Schema::hasTable('v3_push_send_log')) {
            return true;
        }

        // Every publish / re-publish must fire — no min-gap, soft day ceiling only.
        $isLiveOrRelist = in_array($eventType, ['deal.live', 'deal.relist', 'deal.stock'], true);

        $day = DB::table('v3_push_send_log')
            ->where('user_id', $userId)
            ->where('created_at', '>=', now()->subDay())
            ->count();
        if (!$isLiveOrRelist && $day >= self::MAX_COMMERCIAL_PER_DAY) {
            return false;
        }
        // Absurd volume guard for live/relist only
        if ($isLiveOrRelist && $day >= 30) {
            return false;
        }
        if ($isLiveOrRelist) {
            return true;
        }

        $last = DB::table('v3_push_send_log')
            ->where('user_id', $userId)
            ->orderByDesc('id')
            ->value('created_at');
        if ($last) {
            $mins = abs(now()->diffInMinutes(\Carbon\Carbon::parse($last), false));
            if ($mins < self::MIN_GAP_MINUTES) {
                if (strpos($eventType, 'deal.') === 0 || strpos($eventType, 'user.') === 0) {
                    return false;
                }
            }
        }
        return true;
    }

    /** Drop stale / wrong-project tokens so they stop poisoning sends. */
    private static function pruneDeadToken(string $token, string $error): void
    {
        if ($token === '' || !Schema::hasTable('v3_push_devices')) {
            return;
        }
        $dead = (
            stripos($error, 'NotRegistered') !== false
            || stripos($error, 'UNREGISTERED') !== false
            || stripos($error, 'SenderId mismatch') !== false
            || stripos($error, 'PERMISSION_DENIED') !== false
        );
        if (!$dead) {
            return;
        }
        try {
            DB::table('v3_push_devices')->where('fcm_token', $token)->delete();
        } catch (\Throwable $e) {
            // ignore
        }
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
