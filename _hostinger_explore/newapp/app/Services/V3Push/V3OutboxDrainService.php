<?php

namespace App\Services\V3Push;

use App\Services\AdminApp\AdminFcmClient;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Drain scheduled / quiet-queued V3 outbox rows.
 * Call from cron (additive) every 5–15 minutes.
 */
class V3OutboxDrainService
{
    /**
     * @return array{processed:int,sent:int,failed:int,cancelled:int}
     */
    public static function drain(int $limit = 80): array
    {
        $processed = 0;
        $sent = 0;
        $failed = 0;
        $cancelled = 0;

        if (!V3PushGateway::enabled() || !Schema::hasTable('v3_push_outbox')) {
            return compact('processed', 'sent', 'failed', 'cancelled');
        }

        $rows = DB::table('v3_push_outbox')
            ->whereIn('status', ['pending', 'queued_quiet'])
            ->where('scheduled_at', '<=', now())
            ->orderBy('id')
            ->limit($limit)
            ->get();

        foreach ($rows as $row) {
            $processed++;
            $userId = (int) $row->user_id;
            $eventType = (string) $row->event_type;
            $data = json_decode((string) ($row->data_json ?? '{}'), true);
            if (!is_array($data)) {
                $data = [];
            }

            // Skip if deal turned off for deal.* commercial
            if (isset($data['deal_id']) && strpos($eventType, 'deal.') === 0 && $eventType !== 'deal.catalog') {
                $dealId = (int) $data['deal_id'];
                if ($dealId > 0 && Schema::hasTable('deals')) {
                    $status = DB::table('deals')->where('id', $dealId)->value('status');
                    if ((int) $status !== 1) {
                        DB::table('v3_push_outbox')->where('id', $row->id)->update([
                            'status' => 'cancelled',
                            'updated_at' => now(),
                        ]);
                        $cancelled++;
                        continue;
                    }
                }
            }

            // Re-check prefs + active placement
            $prefs = V3PushGateway::prefsFor($userId);
            $tier = 'deals';
            if (strpos($eventType, 'order.') === 0 || strpos($eventType, 'placement.') === 0) {
                $tier = 'orders';
            } elseif (strpos($eventType, 'payout.') === 0 || strpos($eventType, 'payment.') === 0) {
                $tier = 'payments';
            }
            if (!$prefs['master'] || empty($prefs[$tier])) {
                DB::table('v3_push_outbox')->where('id', $row->id)->update([
                    'status' => 'cancelled',
                    'updated_at' => now(),
                ]);
                $cancelled++;
                continue;
            }
            if (
                $tier === 'deals'
                && strpos($eventType, 'deal.') === 0
                && $eventType !== 'deal.catalog'
                && V3PushGateway::hasActivePlacement($userId)
            ) {
                DB::table('v3_push_outbox')->where('id', $row->id)->update([
                    'status' => 'cancelled',
                    'updated_at' => now(),
                ]);
                $cancelled++;
                continue;
            }

            DB::table('v3_push_outbox')->where('id', $row->id)->update([
                'status' => 'sending',
                'updated_at' => now(),
            ]);

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

            $data['channel'] = (string) $row->channel;
            $data['event_type'] = $eventType;
            $data['engine'] = 'v3';
            if (!isset($data['type'])) {
                $data['type'] = $eventType;
            }

            $sentAny = false;
            foreach ($tokens as $token) {
                if (AdminFcmClient::sendToToken(
                    (string) $token,
                    (string) $row->title,
                    (string) $row->body,
                    $data
                )) {
                    $sentAny = true;
                }
            }

            DB::table('v3_push_outbox')->where('id', $row->id)->update([
                'status' => $sentAny ? 'sent' : 'failed',
                'sent_at' => $sentAny ? now() : null,
                'error' => $sentAny ? null : (AdminFcmClient::$lastError ?? 'send_failed'),
                'updated_at' => now(),
            ]);

            if ($sentAny) {
                $sent++;
                if (Schema::hasTable('v3_push_send_log')) {
                    DB::table('v3_push_send_log')->insert([
                        'user_id' => $userId,
                        'event_type' => $eventType,
                        'deal_id' => isset($data['deal_id']) ? (int) $data['deal_id'] : null,
                        'created_at' => now(),
                    ]);
                }
                try {
                    if (class_exists(\App\Models\Notification::class)) {
                        $n = new \App\Models\Notification();
                        $n->user_id = $userId;
                        $n->title = (string) $row->title;
                        $n->content = (string) $row->body;
                        $n->status = 1;
                        $n->save();
                    }
                } catch (\Throwable $e) {
                    // ignore
                }
            } else {
                $failed++;
            }
        }

        return compact('processed', 'sent', 'failed', 'cancelled');
    }
}
