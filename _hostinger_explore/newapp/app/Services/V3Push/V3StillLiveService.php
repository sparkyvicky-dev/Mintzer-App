<?php

namespace App\Services\V3Push;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Multi-day still-live: while deal ON for 2–3+ days, fire ~every 8–12h (2–3/day).
 */
class V3StillLiveService
{
    /**
     * Cron tick — find deals live ≥24h and not pushed recently.
     *
     * @return array{deals:int,sent:int}
     */
    public static function tick(): array
    {
        $deals = 0;
        $sent = 0;

        if (!V3PushGateway::enabled() || !Schema::hasTable('deals')) {
            return compact('deals', 'sent');
        }

        $liveDeals = DB::table('deals')
            ->where('status', 1)
            ->where('order_qty', '>', 0)
            ->whereNull('deleted_at')
            ->get();

        foreach ($liveDeals as $deal) {
            $created = $deal->created_at ?? $deal->updated_at ?? null;
            if (!$created) {
                continue;
            }
            $ageHours = now()->diffInHours(\Carbon\Carbon::parse($created));
            if ($ageHours < 24) {
                continue; // day-1 covered by live + view follow-ups
            }

            $dayN = max(2, (int) floor($ageHours / 24) + 1);
            if ($dayN > 5) {
                continue; // stop after ~5 days
            }

            // Avoid stacking: last still_live for this deal within 8h?
            if (Schema::hasTable('v3_push_send_log')) {
                $recent = DB::table('v3_push_send_log')
                    ->where('deal_id', (int) $deal->id)
                    ->where('event_type', 'deal.still_live')
                    ->where('created_at', '>=', now()->subHours(8))
                    ->exists();
                if ($recent) {
                    continue;
                }
            }

            $deals++;
            $result = V3DealLiveService::notifyStillLive((int) $deal->id, $dayN);
            $sent += (int) ($result['sent'] ?? 0);
        }

        return compact('deals', 'sent');
    }
}
