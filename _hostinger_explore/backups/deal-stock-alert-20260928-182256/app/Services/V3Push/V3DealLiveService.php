<?php

namespace App\Services\V3Push;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Broadcast live / relist / catalog / still-live to Flutter V3 devices only.
 * Copy from V3PushTemplateBank (JSON or DB) — no APK for new templates.
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
        return self::broadcastDeal($dealId, 'deal.live', 'deal_live', $minEarnInr, $title, $body, true);
    }

    /**
     * Same deal turned off → on again.
     *
     * @return array{targeted:int,sent:int,skipped:int}
     */
    public static function notifyDealRelist(
        int $dealId,
        ?string $title = null,
        ?string $body = null
    ): array {
        return self::broadcastDeal($dealId, 'deal.relist', 'deal_relist', null, $title, $body, false);
    }

    /**
     * Multi-day still-live (one user or fan-out).
     *
     * @return array{targeted:int,sent:int,skipped:int}
     */
    public static function notifyStillLive(int $dealId, ?int $dayN = null): array
    {
        return self::broadcastDeal($dealId, 'deal.still_live', 'still_live', null, null, null, false, $dayN);
    }

    /**
     * @return array{targeted:int,sent:int,skipped:int}
     */
    private static function broadcastDeal(
        int $dealId,
        string $eventType,
        string $bankKey,
        ?int $minEarnInr,
        ?string $title,
        ?string $body,
        bool $useFunnyMix,
        ?int $dayN = null
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

        $tokens = V3PushTemplateBank::tokensFromDeal($deal, $dayN);
        $earn = (float) ($tokens['earn'] ?? 0);
        if ($minEarnInr !== null && $earn < $minEarnInr) {
            return compact('targeted', 'sent', 'skipped');
        }

        // Enrich store name if we can join.
        try {
            if (empty($tokens['store']) || $tokens['store'] === 'Store') {
                if (Schema::hasTable('stores') && isset($deal->store_id)) {
                    $sn = DB::table('stores')->where('id', $deal->store_id)->value('name');
                    if ($sn) {
                        $tokens['store'] = (string) $sn;
                    }
                }
            }
        } catch (\Throwable $e) {
            // ignore
        }

        if ($title === null || $title === '' || $body === null || $body === '') {
            if ($useFunnyMix && $eventType === 'deal.live') {
                $copy = V3PushTemplateBank::pickDealLive($tokens);
            } else {
                $copy = V3PushTemplateBank::pick($bankKey, $tokens);
            }
            $title = ($title === null || $title === '') ? $copy['title'] : $title;
            $body = ($body === null || $body === '') ? $copy['body'] : $body;
        }

        $userIds = self::v3UserIds();

        foreach ($userIds as $userId) {
            $targeted++;
            $ok = V3PushGateway::enqueueAndSend(
                $userId,
                $eventType,
                $title,
                $body,
                [
                    'deal_id' => (string) $dealId,
                    'type' => $eventType,
                    'deepLink' => 'mintzer://deals/' . $dealId,
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
     * Silent-ish catalog refresh for V3: admin toggle off / edit.
     * Prefer notifyDealRelist when status goes ON.
     */
    public static function notifyCatalogChanged(?int $dealId = null, string $reason = 'updated'): array
    {
        $targeted = 0;
        $sent = 0;
        $skipped = 0;

        if (!V3PushGateway::enabled()) {
            return compact('targeted', 'sent', 'skipped');
        }

        $userIds = self::v3UserIds();

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
            'orders',
            true
        );
    }

    /**
     * @return list<int>
     */
    private static function v3UserIds(): array
    {
        if (!Schema::hasTable('v3_push_devices')) {
            return [];
        }
        return DB::table('v3_push_devices')
            ->where('app_channel', 'flutter_v3')
            ->distinct()
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }
}
