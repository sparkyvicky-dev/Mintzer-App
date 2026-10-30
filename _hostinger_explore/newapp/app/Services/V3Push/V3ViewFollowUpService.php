<?php

namespace App\Services\V3Push;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Tight follow-ups after qualifying deal view (no Accept).
 * Early: 30–60 min (1–2) · Mid: ~1.5h (1–2). Cancel on Accept; restart on re-view.
 */
class V3ViewFollowUpService
{
    public const MIN_DWELL_SECONDS = 15;

    /**
     * Record a deal view and (re)schedule follow-ups.
     *
     * @return array{ok:bool,scheduled:int,reason?:string}
     */
    public static function recordView(int $userId, int $dealId, int $dwellSeconds): array
    {
        if ($userId < 1 || $dealId < 1) {
            return ['ok' => false, 'scheduled' => 0, 'reason' => 'bad_ids'];
        }
        if ($dwellSeconds < self::MIN_DWELL_SECONDS) {
            return ['ok' => false, 'scheduled' => 0, 'reason' => 'bounce'];
        }
        if (!V3PushGateway::enabled() || !Schema::hasTable('v3_push_deal_views')) {
            return ['ok' => false, 'scheduled' => 0, 'reason' => 'tables'];
        }

        // Cancel prior pending follow-ups for this user+deal, then reschedule.
        self::cancelPending($userId, $dealId);

        DB::table('v3_push_deal_views')->insert([
            'user_id' => $userId,
            'deal_id' => $dealId,
            'dwell_seconds' => $dwellSeconds,
            'created_at' => now(),
        ]);

        if (!Schema::hasTable('deals')) {
            return ['ok' => true, 'scheduled' => 0, 'reason' => 'no_deal'];
        }
        $deal = DB::table('deals')->where('id', $dealId)->first();
        if (!$deal || (int) ($deal->status ?? 0) !== 1) {
            return ['ok' => true, 'scheduled' => 0, 'reason' => 'deal_off'];
        }

        $tokens = V3PushTemplateBank::tokensFromDeal($deal);
        try {
            if (Schema::hasTable('stores') && isset($deal->store_id)) {
                $sn = DB::table('stores')->where('id', $deal->store_id)->value('name');
                if ($sn) {
                    $tokens['store'] = (string) $sn;
                }
            }
        } catch (\Throwable $e) {
            // ignore
        }

        $scheduled = 0;
        // Early wave: 1–2 pushes between 30–60 min
        $earlyCount = random_int(1, 2);
        $earlyOffsets = $earlyCount === 1
            ? [random_int(30, 50)]
            : [random_int(30, 40), random_int(50, 60)];

        foreach ($earlyOffsets as $mins) {
            $copy = V3PushTemplateBank::pick('deal_viewed_early', $tokens);
            $ok = V3PushGateway::enqueueAndSend(
                $userId,
                'deal.viewed_followup_early',
                $copy['title'],
                $copy['body'],
                [
                    'deal_id' => (string) $dealId,
                    'type' => 'deal.viewed_followup_early',
                    'deepLink' => 'mintzer://deals/' . $dealId,
                    'wave' => 'early',
                ],
                'mintzer_deals',
                'deals',
                false,
                now()->addMinutes($mins)
            );
            // enqueueAndSend returns false when scheduled — still counts as scheduled
            $scheduled++;
        }

        // Mid wave: 1–2 at ~90–110 min
        $midCount = random_int(1, 2);
        $midOffsets = $midCount === 1
            ? [random_int(90, 100)]
            : [random_int(85, 95), random_int(100, 110)];

        foreach ($midOffsets as $mins) {
            $copy = V3PushTemplateBank::pick('deal_viewed_mid', $tokens);
            V3PushGateway::enqueueAndSend(
                $userId,
                'deal.viewed_followup_mid',
                $copy['title'],
                $copy['body'],
                [
                    'deal_id' => (string) $dealId,
                    'type' => 'deal.viewed_followup_mid',
                    'deepLink' => 'mintzer://deals/' . $dealId,
                    'wave' => 'mid',
                ],
                'mintzer_deals',
                'deals',
                false,
                now()->addMinutes($mins)
            );
            $scheduled++;
        }

        return ['ok' => true, 'scheduled' => $scheduled];
    }

    /** Cancel pending view follow-ups (Accept or deal off). */
    public static function cancelPending(int $userId, ?int $dealId = null): int
    {
        if (!Schema::hasTable('v3_push_outbox')) {
            return 0;
        }
        $q = DB::table('v3_push_outbox')
            ->where('user_id', $userId)
            ->whereIn('status', ['pending', 'queued_quiet'])
            ->where(function ($w) {
                $w->where('event_type', 'like', 'deal.viewed_followup%');
            });
        if ($dealId !== null) {
            $q->where(function ($w) use ($dealId) {
                $w->where('data_json', 'like', '%"deal_id":"' . (int) $dealId . '"%')
                    ->orWhere('data_json', 'like', '%"deal_id":' . (int) $dealId . '%');
            });
        }
        return $q->update([
            'status' => 'cancelled',
            'updated_at' => now(),
        ]);
    }

    /** Cancel all view follow-ups for user (e.g. after Accept any deal). */
    public static function cancelAllForUser(int $userId): int
    {
        return self::cancelPending($userId, null);
    }
}
