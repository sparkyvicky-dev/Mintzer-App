<?php

namespace App\Services\V3Push;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Broadcast a live deal to Flutter V3 devices only.
 * Does not alter V2 cron / HolderNotifyService / topic fan-out.
 */
class V3DealLiveService
{
    /**
     * @return array{targeted:int,sent:int,skipped:int}
     */
    public static function notifyDealLive(
        int $dealId,
        ?int $minEarnInr = null,
        ?string $title = null,
        ?string $body = null
    ): array {
        $targeted = 0;
        $sent = 0;
        $skipped = 0;

        if (!V3PushGateway::enabled() || !Schema::hasTable('deals')) {
            return compact('targeted', 'sent', 'skipped');
        }

        $deal = DB::table('deals')->where('id', $dealId)->first();
        if (!$deal) {
            return compact('targeted', 'sent', 'skipped');
        }

        $earn = (float) ($deal->card_holder_earn ?? $deal->you_earn ?? $deal->earn ?? $deal->cashback ?? 0);
        if ($minEarnInr !== null && $earn < $minEarnInr) {
            return compact('targeted', 'sent', 'skipped');
        }

        $name = trim((string) ($deal->name ?? $deal->product_name ?? 'New deal'));
        if ($title === null || $title === '') {
            $earnLabel = $earn > 0 ? ('Earn ₹' . (int) round($earn)) : 'New deal live';
            $title = $earnLabel . ' · Mintzer';
        }
        if ($body === null || $body === '') {
            $body = $name . ' is live. Open to accept.';
        }

        $userIds = [];
        if (Schema::hasTable('v3_push_devices')) {
            $userIds = DB::table('v3_push_devices')
                ->where('app_channel', 'flutter_v3')
                ->distinct()
                ->pluck('user_id')
                ->map(fn ($id) => (int) $id)
                ->all();
        }

        foreach ($userIds as $userId) {
            $targeted++;
            $ok = V3PushGateway::enqueueAndSend(
                $userId,
                'deal.live',
                $title,
                $body,
                [
                    'deal_id' => (string) $dealId,
                    'type' => 'deal.live',
                ],
                'mintzer_deals',
                'deals'
            );
            if ($ok) {
                $sent++;
            } else {
                $skipped++;
            }
        }

        return compact('targeted', 'sent', 'skipped');
    }

    /**
     * Silent-ish catalog refresh for V3: admin toggle / edit / stock change.
     * Flutter listens for data.type = deal.catalog and reloads getDealdata.
     */
    public static function notifyCatalogChanged(?int $dealId = null, string $reason = 'updated'): array
    {
        $targeted = 0;
        $sent = 0;
        $skipped = 0;

        if (!V3PushGateway::enabled()) {
            return compact('targeted', 'sent', 'skipped');
        }

        $userIds = [];
        if (Schema::hasTable('v3_push_devices')) {
            $userIds = DB::table('v3_push_devices')
                ->where('app_channel', 'flutter_v3')
                ->distinct()
                ->pluck('user_id')
                ->map(fn ($id) => (int) $id)
                ->all();
        }

        $title = $reason === 'on' ? 'New deals on Home' : 'Deals updated';
        $body = $reason === 'on'
            ? 'Pull open Mintzer — catalog just changed.'
            : 'Your Home deals list was refreshed.';

        foreach ($userIds as $userId) {
            $targeted++;
            $ok = V3PushGateway::enqueueAndSend(
                $userId,
                'deal.catalog',
                $title,
                $body,
                [
                    'type' => 'deal.catalog',
                    'reason' => $reason,
                    'deal_id' => $dealId !== null ? (string) $dealId : '',
                    'refresh' => '1',
                ],
                'mintzer_deals',
                'deals'
            );
            if ($ok) {
                $sent++;
            } else {
                $skipped++;
            }
        }

        return compact('targeted', 'sent', 'skipped');
    }

    public static function notifyUserTest(int $userId): bool
    {
        return V3PushGateway::enqueueAndSend(
            $userId,
            'system.test',
            'Mintzer V3 push',
            'New notification engine is live on your device.',
            ['type' => 'system.test'],
            'mintzer_orders',
            'orders'
        );
    }
}
