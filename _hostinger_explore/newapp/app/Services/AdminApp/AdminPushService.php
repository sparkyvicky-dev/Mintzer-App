<?php

namespace App\Services\AdminApp;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 3 — owner/admin phone tray notifications (separate from holder tokens).
 */
class AdminPushService
{
    /** Default ON (matches Flutter Settings important flags). */
    private const DEFAULT_ON = [
        'invoice_uploaded',
        'waiting_payment',
        'payout_ready',
        'new_ticket',
        'new_order',
    ];

    public static function registerToken(int $userId, string $token, string $platform = 'android'): void
    {
        if ($token === '') {
            return;
        }

        if (!Schema::hasTable('admin_device_tokens')) {
            return;
        }

        DB::table('admin_device_tokens')->updateOrInsert(
            ['user_id' => $userId, 'fcm_token' => $token],
            ['platform' => $platform, 'updated_at' => now(), 'created_at' => now()]
        );
    }

    public static function removeToken(int $userId, string $token): void
    {
        if (!Schema::hasTable('admin_device_tokens')) {
            return;
        }

        DB::table('admin_device_tokens')
            ->where('user_id', $userId)
            ->where('fcm_token', $token)
            ->delete();
    }

    public static function savePushPrefs(int $userId, array $prefs): void
    {
        if (!Schema::hasTable('admin_app_push_prefs')) {
            return;
        }

        DB::table('admin_app_push_prefs')->updateOrInsert(
            ['user_id' => $userId],
            ['prefs' => json_encode($prefs), 'updated_at' => now(), 'created_at' => now()]
        );
    }

    public static function notifyAdmins(string $typeId, string $title, string $body, array $data = []): int
    {
        if (!Schema::hasTable('admin_device_tokens')) {
            return 0;
        }

        $data['typeId'] = $typeId;
        $sent = 0;

        $tokens = DB::table('admin_device_tokens')->get();
        foreach ($tokens as $row) {
            if (!self::pushEnabledForUser((int) $row->user_id, $typeId)) {
                continue;
            }
            if (AdminFcmClient::sendToToken($row->fcm_token, $title, $body, $data)) {
                $sent++;
            }
        }

        return $sent;
    }

    public static function sendTestToUser(int $userId): int
    {
        if (!Schema::hasTable('admin_device_tokens')) {
            return 0;
        }

        $sent = 0;
        $tokens = DB::table('admin_device_tokens')->where('user_id', $userId)->get();
        foreach ($tokens as $row) {
            if (AdminFcmClient::sendToToken(
                $row->fcm_token,
                'Mintzer Admin',
                'Phone notifications are working.',
                ['typeId' => 'new_ticket']
            )) {
                $sent++;
            }
        }

        return $sent;
    }

    /** Called from holder API hooks (invoice upload, ticket, etc.). */
    public static function notifyFromOrderEvent(string $typeId, int $orderId): void
    {
        $order = DB::table('orders')
            ->join('users', 'users.id', '=', 'orders.user_id')
            ->join('deals', 'deals.id', '=', 'orders.deal_id')
            ->where('orders.id', $orderId)
            ->first([
                'orders.id',
                'orders.store_order_id',
                'orders.order_tracking_id',
                'orders.order_delivery_otp',
                'orders.is_pine_lab_deal',
                'users.display_name',
                'deals.name as deal_name',
            ]);

        if (!$order) {
            return;
        }

        $user = $order->display_name ?: 'User';
        $model = $order->deal_name ?: 'Order';
        $orderLabel = $order->store_order_id ?: ('#' . $orderId);
        $otp = trim((string) ($order->order_delivery_otp ?? ''));
        $track = trim((string) ($order->order_tracking_id ?? ''));
        $pine = (int) ($order->is_pine_lab_deal ?? 0) === 1;

        $copy = self::pickPushCopy($typeId, [
            'user' => $user,
            'model' => $model,
            'orderLabel' => $orderLabel,
            'otp' => $otp,
            'track' => $track,
            'pine' => $pine,
        ]);

        // tracking_updated reuses the "new_order" Settings toggle (no separate chip yet)
        $prefType = $typeId === 'tracking_updated' ? 'new_order' : $typeId;

        self::notifyAdmins($prefType, $copy[0], $copy[1], [
            'orderServerId' => (string) $orderId,
            'orderId' => $orderLabel,
        ]);
    }

    /**
     * Randomised title/body — always name + model/order + action hint where useful.
     * @return array{0: string, 1: string}
     */
    private static function pickPushCopy(string $typeId, array $ctx): array
    {
        $user = $ctx['user'];
        $model = $ctx['model'];
        $orderLabel = $ctx['orderLabel'];
        $otp = $ctx['otp'];
        $track = $ctx['track'];
        $pine = $ctx['pine'];

        $sets = match ($typeId) {
            'invoice_uploaded' => $pine ? [
                ['🧾 Pine proof · ' . $user, "{$model} · Tap to verify"],
                ['📄 Payment screenshot · ' . $user, "Pine Lab · {$model} · Tap to verify"],
                ['⏳ Pine waiting · ' . $user, "Confirm payment · Tap to verify"],
            ] : [
                ['📄 ' . $user . ' uploaded invoice', "{$model} · Tap to verify"],
                ['🧾 Invoice in · ' . $user, "{$model} · {$orderLabel} · Tap to verify"],
                ['📄 GST waiting · ' . $user, "{$model} · Tap to verify"],
                ['🧾 Verify invoice · ' . $user, "{$orderLabel} · Tap to verify"],
                ['📄 New bill · ' . $user, "{$model} · Tap to verify"],
            ],
            'waiting_payment' => [
                ['⏳ Pine payment · ' . $user, "{$model} · Tap to verify"],
                ['🧾 Screenshot in · ' . $user, "Pine Lab · {$model} · Tap to verify"],
                ['📄 Confirm Pine · ' . $user, "{$model} · Tap to verify"],
            ],
            'payout_ready' => [
                ['💸 Pay ' . $user, "{$model} · Tap to pay"],
                ['💰 Payout due · ' . $user, "{$model} · {$orderLabel} · Tap to pay"],
                ['💸 Release payout · ' . $user, "Invoice verified · Tap to pay"],
                ['💰 Holder waiting · ' . $user, "{$model} · Tap to pay"],
                ['💸 Payout ready · ' . $user, "{$orderLabel} · Tap to pay"],
            ],
            'new_order' => [
                ['🎉 Yay! ' . $user . ' ordered', "{$model} · Tap to open"],
                ['🛒 Boom · ' . $user . ' placed it', "{$model} · {$orderLabel} · Tap to open"],
                ['✨ Nice · ' . $user . ' ordered', "{$model} · Tap to open"],
                ['🎊 Order in · ' . $user, "{$model} · {$orderLabel} · Tap to open"],
                ['🔥 ' . $user . ' just ordered', "{$model} · Tap to open"],
                ['🎉 Fresh order · ' . $user, "{$orderLabel} · {$model} · Tap to open"],
            ],
            'otp_updated' => [
                [
                    '🔐 OTP · ' . $user,
                    ($otp !== '' && $otp !== '0')
                        ? "{$model} · OTP {$otp} · Tap to open"
                        : "{$model} · Tap to open",
                ],
                [
                    '📦 OFD · ' . $user,
                    ($otp !== '' && $otp !== '0')
                        ? "OTP {$otp} · {$model} · Tap to open"
                        : "{$model} · Tap to open",
                ],
                [
                    '🔐 Delivery OTP · ' . $user,
                    ($otp !== '' && $otp !== '0')
                        ? "{$otp} · {$orderLabel} · Tap to open"
                        : "{$orderLabel} · Tap to open",
                ],
            ],
            'tracking_updated' => [
                [
                    '📦 Shipped · ' . $user,
                    $track !== '' ? "{$model} · {$track} · Tap to open" : "{$model} · Tap to open",
                ],
                [
                    '🚚 Tracking · ' . $user,
                    $track !== '' ? "Track {$track} · Tap to open" : "{$model} · Tap to open",
                ],
            ],
            default => [
                ['📋 Update · ' . $user, "{$model} · Tap to open"],
            ],
        };

        return $sets[array_rand($sets)];
    }

    public static function notifyNewTicket(int $ticketId, string $subject, string $userName): void
    {
        $subject = $subject ?: 'Support';
        $userName = $userName ?: 'User';
        $sets = [
            ['🎫 Ticket · ' . $userName, "{$subject} · Tap to reply"],
            ['🎫 New ticket · ' . $userName, "{$subject} · Tap to open"],
            ['🎫 Needs reply · ' . $userName, "{$subject} · Tap to reply"],
        ];
        $copy = $sets[array_rand($sets)];

        self::notifyAdmins(
            'new_ticket',
            $copy[0],
            $copy[1],
            ['ticketId' => 'T-' . $ticketId]
        );
    }

    private static function pushEnabledForUser(int $userId, string $typeId): bool
    {
        if (!Schema::hasTable('admin_app_push_prefs')) {
            return in_array($typeId, self::DEFAULT_ON, true);
        }

        $row = DB::table('admin_app_push_prefs')->where('user_id', $userId)->first();
        if (!$row || empty($row->prefs)) {
            return in_array($typeId, self::DEFAULT_ON, true);
        }

        $prefs = json_decode($row->prefs, true);
        if (!is_array($prefs)) {
            return in_array($typeId, self::DEFAULT_ON, true);
        }

        if (($prefs['mute_all'] ?? false) === true) {
            return false;
        }

        if (($prefs['p1_only'] ?? false) === true) {
            return in_array($typeId, self::DEFAULT_ON, true);
        }

        return ($prefs[$typeId] ?? in_array($typeId, self::DEFAULT_ON, true)) === true;
    }
}
