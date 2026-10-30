<?php

namespace App\Services\V3Push;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Placement timer warnings — 5 min and 1 min before reserved_date_time.
 * Uses locked banks timer_5m / timer_1m.
 */
class V3PlacementTimerService
{
    /**
     * @return array{checked:int,sent_5m:int,sent_1m:int}
     */
    public static function tick(): array
    {
        $checked = 0;
        $sent_5m = 0;
        $sent_1m = 0;

        if (!V3PushGateway::enabled() || !Schema::hasTable('orders')) {
            return compact('checked', 'sent_5m', 'sent_1m');
        }

        $now = now();
        $q = DB::table('orders')
            ->where('order_status', 'Placed')
            ->whereNull('deleted_at')
            ->where(function ($w) {
                $w->whereNull('store_order_id')->orWhere('store_order_id', '');
            });

        // reserved_date_time may live on orders or dealer_addresses
        $orders = $q->orderByDesc('id')->limit(200)->get();

        foreach ($orders as $order) {
            $checked++;
            $endsAt = self::endsAtFor($order);
            if ($endsAt === null) {
                continue;
            }

            $minsLeft = $now->diffInMinutes($endsAt, false);
            // Carbon: negative if endsAt is in the past
            if ($minsLeft < 0) {
                continue;
            }

            $userId = (int) ($order->user_id ?? 0);
            $orderId = (int) $order->id;
            if ($userId < 1) {
                continue;
            }

            $deal = null;
            if (Schema::hasTable('deals') && !empty($order->deal_id)) {
                $deal = DB::table('deals')->where('id', $order->deal_id)->first();
            }
            $tokens = V3PushTemplateBank::tokensFromDeal($deal ?? (object) []);
            $tokens['ref'] = trim((string) ($order->order_number ?? ('#' . $orderId)));
            $tokens['expiry'] = $endsAt->format('h:i A');
            $tokens['endsAt'] = $tokens['expiry'];

            // ~5 minutes left (window 4–6) once
            if ($minsLeft >= 4 && $minsLeft <= 6) {
                if (!self::alreadySent($userId, $orderId, 'placement.timer_5m')) {
                    $copy = V3PushTemplateBank::pick('timer_5m', $tokens);
                    $ok = V3PushGateway::enqueueAndSend(
                        $userId,
                        'placement.timer_5m',
                        $copy['title'],
                        $copy['body'],
                        [
                            'type' => 'placement.timer_warning',
                            'order_id' => (string) $orderId,
                            'deal_id' => (string) ($order->deal_id ?? ''),
                            'wave' => '5m',
                        ],
                        'mintzer_orders',
                        'orders',
                        true
                    );
                    if ($ok) {
                        $sent_5m++;
                    }
                }
            }

            // ~1 minute left (window 0–2) once
            if ($minsLeft >= 0 && $minsLeft <= 2) {
                if (!self::alreadySent($userId, $orderId, 'placement.timer_1m')) {
                    $copy = V3PushTemplateBank::pick('timer_1m', $tokens);
                    $ok = V3PushGateway::enqueueAndSend(
                        $userId,
                        'placement.timer_1m',
                        $copy['title'],
                        $copy['body'],
                        [
                            'type' => 'placement.timer_warning',
                            'order_id' => (string) $orderId,
                            'deal_id' => (string) ($order->deal_id ?? ''),
                            'wave' => '1m',
                        ],
                        'mintzer_orders',
                        'orders',
                        true
                    );
                    if ($ok) {
                        $sent_1m++;
                    }
                }
            }
        }

        return compact('checked', 'sent_5m', 'sent_1m');
    }

    private static function endsAtFor(object $order): ?\Carbon\Carbon
    {
        foreach (['reserved_date_time', 'order_end_time', 'expire_at'] as $col) {
            if (!empty($order->{$col})) {
                try {
                    return \Carbon\Carbon::parse($order->{$col});
                } catch (\Throwable $e) {
                    // continue
                }
            }
        }
        // dealer_addresses.reserved_date_time via address_id
        try {
            if (!empty($order->address_id) && Schema::hasTable('dealer_addresses')) {
                $raw = DB::table('dealer_addresses')->where('id', $order->address_id)->value('reserved_date_time');
                if ($raw) {
                    return \Carbon\Carbon::parse($raw);
                }
            }
        } catch (\Throwable $e) {
            // ignore
        }
        return null;
    }

    private static function alreadySent(int $userId, int $orderId, string $eventType): bool
    {
        if (Schema::hasTable('v3_push_outbox')) {
            $hit = DB::table('v3_push_outbox')
                ->where('user_id', $userId)
                ->where('event_type', $eventType)
                ->whereIn('status', ['sent', 'sending', 'pending'])
                ->where('created_at', '>=', now()->subHours(6))
                ->where('data_json', 'like', '%"order_id":"' . $orderId . '"%')
                ->exists();
            if ($hit) {
                return true;
            }
        }
        return false;
    }
}
