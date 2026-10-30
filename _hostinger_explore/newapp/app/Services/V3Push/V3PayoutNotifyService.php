<?php

namespace App\Services\V3Push;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Money push — ₹ released to bank only (locked product rule).
 * Dual-send: V3 gateway + legacy fcm_token via AdminFcmClient fallback inside gateway.
 *
 * {amount} = Mintzer bank transfer (card_holder_receive / Total receive), NOT profit alone.
 * {earn}   = holder profit after TDS (for templates that mention earn).
 */
class V3PayoutNotifyService
{
    public static function notifyPayoutSent(int $orderId): bool
    {
        if (!Schema::hasTable('orders')) {
            return false;
        }

        $order = DB::table('orders')->where('id', $orderId)->whereNull('deleted_at')->first();
        if (!$order) {
            return false;
        }

        $userId = (int) ($order->user_id ?? 0);
        if ($userId < 1) {
            return false;
        }

        $deal = null;
        if (Schema::hasTable('deals') && !empty($order->deal_id)) {
            $deal = DB::table('deals')->where('id', $order->deal_id)->first();
        }

        $orderDeal = null;
        if (Schema::hasTable('order_deal')) {
            $orderDeal = DB::table('order_deal')->where('order_id', $orderId)->first();
        }

        // Profit after TDS (small) — kept as {earn}.
        $profit = (float) (
            $order->to_card_holder
            ?? (($order->earnings ?? $order->card_holder_earn ?? ($deal->card_holder_earn ?? 0))
                - ($order->tds_amount ?? 0))
            ?? 0
        );
        if ($profit < 0) {
            $profit = 0;
        }

        // Bank credit = admin "Card holder will receive" (From Mintzer), not profit.
        $bankCredit = (float) (
            ($orderDeal->card_holder_receive ?? null)
            ?? ($deal->card_holder_recieve ?? null)
            ?? 0
        );
        if ($bankCredit <= 0) {
            // Fallback: checkout amount + profit (approx return).
            $spend = (float) ($order->order_amount ?? 0);
            $bankCredit = $spend > 0 ? ($spend + $profit) : $profit;
        }

        $product = trim((string) ($orderDeal->name ?? $deal->name ?? 'your order'));
        $ref = trim((string) ($order->store_order_id ?? $order->order_number ?? ('#' . $orderId)));
        $amount = (string) (int) round($bankCredit);
        $earnStr = (string) (int) round($profit);

        $tokens = [
            'product' => $product !== '' ? $product : 'your order',
            'earn' => $earnStr,
            'amount' => $amount,
            'ref' => $ref,
            'store' => 'Store',
            'spend' => (string) (int) round((float) ($order->order_amount ?? 0)),
            'card' => '',
            'n' => '1',
            'expiry' => '',
            'endsAt' => '',
            'preview' => '',
            'reason' => '',
        ];

        $copy = V3PushTemplateBank::pick('payout_sent', $tokens);

        return V3PushGateway::enqueueAndSend(
            $userId,
            'payout.sent',
            $copy['title'],
            $copy['body'],
            [
                'type' => 'payout.sent',
                'order_id' => (string) $orderId,
                'deepLink' => 'mintzer://wallet',
            ],
            'mintzer_payments',
            'payments',
            true // force — money must land
        );
    }
}
