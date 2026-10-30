<?php

namespace App\Services\AdminApp;

use App\Services\V3Push\V3PushGateway;
use App\Services\V3Push\V3PushTemplateBank;
use Illuminate\Support\Facades\DB;

/**
 * Order / holder operational notifies — copy from V3 30-template banks.
 * Sends via V3PushGateway (Flutter devices + bell) with force=true.
 */
class HolderNotifyService
{
    public static function verificationUpdated(int $orderId, string $status): void
    {
        $bank = match ($status) {
            'Verified' => 'invoice_verified',
            'Re-Upload' => 'invoice_reupload',
            default => 'invoice_needed', // Alerted / upload reminder
        };
        self::sendBank($orderId, $bank, 'order.invoice', 'orders');
    }

    public static function paymentVerified(int $orderId): void
    {
        self::sendBank($orderId, 'payment_verified', 'order.payment_verified', 'payments');
    }

    public static function trackingReminder(int $orderId): void
    {
        self::sendBank($orderId, 'tracking', 'order.tracking_reminder', 'orders');
    }

    public static function trackingDone(int $orderId): void
    {
        self::sendBank($orderId, 'tracking_done', 'order.tracking_done', 'orders');
    }

    public static function otpReminder(int $orderId): void
    {
        self::sendBank($orderId, 'otp', 'order.otp_reminder', 'orders');
    }

    public static function orderIdReminder(int $orderId, ?string $endsAt = null): void
    {
        self::sendBank($orderId, 'order_id', 'order.order_id_reminder', 'orders', [
            'endsAt' => $endsAt ?? '',
            'expiry' => $endsAt ?? '',
        ]);
    }

    public static function orderCancelled(int $orderId, string $reason): void
    {
        $ctx = self::context($orderId);
        if ($ctx === null) {
            return;
        }
        $reasonText = trim($reason) !== '' ? trim($reason) : 'operational issue';
        // No dedicated cancel bank yet — keep short rotating set + reason token.
        $titles = [
            'Order Update',
            'Order Cancelled',
            'Important Order Update',
            'Order Status Changed',
        ];
        $bodies = [
            "Your order {$ctx['order_ref']} was cancelled due to {$reasonText}. Check the app for other deals.",
            "Order {$ctx['order_ref']} cancelled ({$reasonText}). You can place a new order anytime.",
            "We had to cancel order {$ctx['order_ref']} due to {$reasonText}. Explore other offers in Mintzer.",
            "Order {$ctx['order_ref']} could not be completed ({$reasonText}). Open the app for support.",
        ];
        $i = array_rand($titles);
        self::dispatchUser(
            (int) $ctx['user']->id,
            $titles[$i],
            $bodies[$i],
            'order.cancelled',
            'orders',
            ['order_id' => (string) $orderId]
        );
    }

    public static function accountStatus(int $userId, bool $active): void
    {
        $title = $active ? 'Account Activated' : 'Account Deactivated';
        $body = $active ? 'Your account has been activated.' : 'Your account has been deactivated.';
        self::dispatchUser($userId, $title, $body, 'account.status', 'orders', []);
    }

    public static function ticketReply(int $userId, int $ticketId, string $preview): void
    {
        $copy = V3PushTemplateBank::pick('ticket_reply', [
            'preview' => mb_substr(trim($preview), 0, 120),
            'ref' => '#' . $ticketId,
            'product' => '',
            'store' => '',
            'earn' => '',
            'spend' => '',
            'amount' => '',
            'n' => '1',
        ]);
        self::dispatchUser(
            $userId,
            $copy['title'],
            $copy['body'],
            'ticket.reply',
            'orders',
            [
                'type' => 'ticket.reply',
                'ticket_id' => (string) $ticketId,
                'channel' => 'mintzer_orders',
            ]
        );
    }

    private static function sendBank(
        int $orderId,
        string $bank,
        string $eventType,
        string $tier,
        array $extraTokens = []
    ): void {
        $ctx = self::context($orderId);
        if ($ctx === null) {
            return;
        }
        $tokens = array_merge(
            V3PushTemplateBank::tokensFromDeal($ctx['deal'] ?? (object) []),
            [
                'ref' => $ctx['order_ref'],
                'product' => $ctx['deal_name'],
            ],
            $extraTokens
        );
        $copy = V3PushTemplateBank::pick($bank, $tokens);
        self::dispatchUser(
            (int) $ctx['user']->id,
            $copy['title'],
            $copy['body'],
            $eventType,
            $tier,
            ['order_id' => (string) $orderId, 'type' => 'order']
        );
    }

    private static function dispatchUser(
        int $userId,
        string $title,
        string $body,
        string $eventType,
        string $tier,
        array $data
    ): void {
        try {
            V3PushGateway::enqueueAndSend(
                $userId,
                $eventType,
                $title,
                $body,
                $data,
                $tier === 'payments' ? 'mintzer_payments' : 'mintzer_orders',
                $tier,
                true // force — operational, never drop for quiet/caps
            );
            return;
        } catch (\Throwable $e) {
            // Fall through to legacy path.
        }

        // Legacy fallback if V3 gateway unavailable.
        $user = DB::table('users')->where('id', $userId)->first();
        if (!$user) {
            return;
        }
        $token = trim((string) ($user->fcm_token ?? ''));
        $sent = false;
        if ($token !== '' && class_exists(AdminFcmClient::class)) {
            $sent = AdminFcmClient::sendToToken($token, $title, $body, $data);
        }
        try {
            if (class_exists(\App\Models\Notification::class)) {
                $row = new \App\Models\Notification();
                $row->user_id = $userId;
                $row->title = $title;
                $row->content = $body;
                if (isset($data['order_id']) && \Illuminate\Support\Facades\Schema::hasColumn('notifications', 'order_id')) {
                    $row->order_id = (int) $data['order_id'];
                }
                $row->status = $sent ? 1 : 0;
                $row->save();
            }
        } catch (\Throwable $e) {
            // best-effort
        }
    }

    private static function context(int $orderId): ?array
    {
        $order = DB::table('orders')->where('id', $orderId)->first();
        if (!$order) {
            return null;
        }

        $user = DB::table('users')->where('id', $order->user_id)->first();
        if (!$user) {
            return null;
        }

        $deal = DB::table('deals')->where('id', $order->deal_id)->first();
        $dealName = trim((string) ($deal->name ?? '')) ?: 'your order';
        $storeId = trim((string) ($order->store_order_id ?? ''));
        $orderNo = trim((string) ($order->order_number ?? ''));
        $ref = $storeId !== '' ? $storeId : ($orderNo !== '' ? $orderNo : ('#' . $orderId));

        return [
            'user' => $user,
            'deal' => $deal,
            'deal_name' => $dealName,
            'order_ref' => $ref,
        ];
    }
}
