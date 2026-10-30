<?php

namespace App\Services\AdminApp;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

/**
 * Afternoon/evening digests for unfinished admin work (invoice verify + unpaid payout).
 * Not per-user spam — one digest per kind per slot while the pending queue is non-empty.
 */
class AdminReminderService
{
    private const TZ = 'Asia/Kolkata';

    /**
     * Run from cron / artisan. Safe to call often (idempotent per day+slot).
     *
     * @return array{ok: bool, skipped?: string, sent?: array<int, string>}
     */
    public static function run(): array
    {
        self::ensureLogTable();

        $now = Carbon::now(self::TZ);

        // Quiet hours: no reminder digests (instant event pushes still fire elsewhere).
        if ($now->hour < 8 || $now->hour >= 23) {
            return ['ok' => true, 'skipped' => 'quiet_hours'];
        }

        // Reminders only after 12:00 noon IST.
        if ($now->hour < 12) {
            return ['ok' => true, 'skipped' => 'before_noon'];
        }

        $slot = $now->hour < 18 ? 'afternoon' : 'evening';
        $date = $now->toDateString();
        $sent = [];

        // Invoice: max 1 digest reminder / day (afternoon slot only) + immediate on upload.
        if ($slot === 'afternoon') {
            $r = self::maybeSendInvoiceDigest($date, $slot);
            if ($r !== null) {
                $sent[] = $r;
            }
        }

        // Payout: afternoon + evening digests (up to 2 reminder digests / day).
        $r = self::maybeSendPayoutDigest($date, $slot);
        if ($r !== null) {
            $sent[] = $r;
        }

        return ['ok' => true, 'sent' => $sent, 'slot' => $slot, 'date' => $date];
    }

    private static function maybeSendInvoiceDigest(string $date, string $slot): ?string
    {
        if (self::alreadySent('invoice_digest', $date, $slot)) {
            return null;
        }

        $rows = self::pendingInvoiceRows(5);
        $count = self::pendingInvoiceCount();
        if ($count < 1) {
            return null;
        }

        $copy = self::invoiceDigestCopy($count, $rows);
        $n = AdminPushService::notifyAdmins('invoice_uploaded', $copy[0], $copy[1], [
            'typeId' => 'invoice_uploaded',
            'reminder' => '1',
            'pendingCount' => (string) $count,
        ]);

        self::markSent('invoice_digest', $date, $slot, $count);
        Log::info('admin_push_reminder', ['kind' => 'invoice_digest', 'count' => $count, 'fcm' => $n]);

        return "invoice_digest:{$count}";
    }

    private static function maybeSendPayoutDigest(string $date, string $slot): ?string
    {
        if (self::alreadySent('payout_digest', $date, $slot)) {
            return null;
        }

        $rows = self::pendingPayoutRows(5);
        $count = self::pendingPayoutCount();
        if ($count < 1) {
            return null;
        }

        $copy = self::payoutDigestCopy($count, $rows);
        $n = AdminPushService::notifyAdmins('payout_ready', $copy[0], $copy[1], [
            'typeId' => 'payout_ready',
            'reminder' => '1',
            'pendingCount' => (string) $count,
        ]);

        self::markSent('payout_digest', $date, $slot, $count);
        Log::info('admin_push_reminder', ['kind' => 'payout_digest', 'count' => $count, 'fcm' => $n, 'slot' => $slot]);

        return "payout_digest:{$count}";
    }

    /** @param array<int, object> $rows */
    private static function invoiceDigestCopy(int $count, array $rows): array
    {
        $name = self::firstName($rows);
        $sets = $count === 1
            ? [
                ["⏳ Still waiting · {$name} invoice", "1 invoice to verify · Tap to verify"],
                ["📄 Reminder · {$name}", "Invoice still pending · Tap to verify"],
                ["🧾 Don't forget · {$name}", "GST invoice waiting · Tap to verify"],
            ]
            : [
                ["⏳ {$count} invoices waiting", 'Still need verify · Tap to review'],
                ["📄 Reminder · {$count} invoices", 'Pending approval · Tap to review'],
                ["🧾 Queue check · {$count} bills", 'Verify before payout · Tap to review'],
            ];

        return $sets[array_rand($sets)];
    }

    /** @param array<int, object> $rows */
    private static function payoutDigestCopy(int $count, array $rows): array
    {
        $name = self::firstName($rows);
        $sets = $count === 1
            ? [
                ["💸 Reminder · pay {$name}", 'Payout still unpaid · Tap to pay'],
                ["💸 {$name} waiting for payout", 'Release payment · Tap to pay'],
                ["💰 Don't forget · {$name}", 'Holder unpaid · Tap to pay'],
            ]
            : [
                ["💸 {$count} payouts unpaid", 'Holders waiting · Tap to review'],
                ["💰 Reminder · {$count} payouts", 'Still unpaid · Tap to review'],
                ["💸 Pay holders · {$count} due", 'Clear the queue · Tap to review'],
            ];

        return $sets[array_rand($sets)];
    }

    /** @param array<int, object> $rows */
    private static function firstName(array $rows): string
    {
        if ($rows === []) {
            return 'User';
        }
        $n = trim((string) ($rows[0]->display_name ?? ''));

        return $n !== '' ? $n : 'User';
    }

    private static function pendingInvoiceCount(): int
    {
        return self::pendingInvoiceQuery()->count();
    }

    /** @return array<int, object> */
    private static function pendingInvoiceRows(int $limit): array
    {
        return self::pendingInvoiceQuery()
            ->orderByDesc('orders.updated_at')
            ->limit($limit)
            ->get([
                'orders.id',
                'users.display_name',
                'deals.name as deal_name',
            ])
            ->all();
    }

    private static function pendingInvoiceQuery()
    {
        $q = DB::table('orders')
            ->join('users', 'users.id', '=', 'orders.user_id')
            ->join('deals', 'deals.id', '=', 'orders.deal_id')
            ->whereNull('orders.deleted_at')
            ->where('orders.is_pine_lab_deal', 0)
            ->whereNotNull('orders.account_order_pdf');

        if (Schema::hasColumn('orders', 'verification_status')) {
            $q->where(function ($w) {
                $w->whereNull('orders.verification_status')
                    ->orWhere('orders.verification_status', 'Alerted');
            });
        }

        return $q;
    }

    private static function pendingPayoutCount(): int
    {
        return self::pendingPayoutQuery()->count();
    }

    /** @return array<int, object> */
    private static function pendingPayoutRows(int $limit): array
    {
        return self::pendingPayoutQuery()
            ->orderByDesc('orders.updated_at')
            ->limit($limit)
            ->get([
                'orders.id',
                'users.display_name',
                'deals.name as deal_name',
            ])
            ->all();
    }

    private static function pendingPayoutQuery()
    {
        $q = DB::table('orders')
            ->join('users', 'users.id', '=', 'orders.user_id')
            ->join('deals', 'deals.id', '=', 'orders.deal_id')
            ->whereNull('orders.deleted_at')
            ->where('orders.order_status', 'Delivered')
            ->where('orders.is_payout', '!=', 1);

        if (Schema::hasColumn('orders', 'is_ready_for_payout')) {
            $q->where('orders.is_ready_for_payout', 1);
        }

        if (Schema::hasColumn('orders', 'transaction_id')) {
            $q->where(function ($w) {
                $w->whereNull('orders.transaction_id')
                    ->orWhere('orders.transaction_id', '=', '')
                    ->orWhere('orders.transaction_id', '=', '0');
            });
        }

        if (Schema::hasColumn('orders', 'transaction_file')) {
            $q->where(function ($w) {
                $w->whereNull('orders.transaction_file')
                    ->orWhere('orders.transaction_file', '=', '');
            });
        }

        if (Schema::hasColumn('orders', 'verification_status')) {
            $q->where('orders.verification_status', 'Verified');
        }

        if (Schema::hasColumn('orders', 'order_delivery_otp')) {
            $q->whereNotNull('orders.order_delivery_otp')
                ->where('orders.order_delivery_otp', '!=', 0)
                ->where('orders.order_delivery_otp', '!=', '');
        }

        return $q;
    }

    private static function alreadySent(string $kind, string $date, string $slot): bool
    {
        if (!Schema::hasTable('admin_push_reminder_log')) {
            return false;
        }

        return DB::table('admin_push_reminder_log')
            ->where('kind', $kind)
            ->where('remind_date', $date)
            ->where('slot', $slot)
            ->exists();
    }

    private static function markSent(string $kind, string $date, string $slot, int $count): void
    {
        if (!Schema::hasTable('admin_push_reminder_log')) {
            return;
        }

        DB::table('admin_push_reminder_log')->updateOrInsert(
            ['kind' => $kind, 'remind_date' => $date, 'slot' => $slot],
            ['pending_count' => $count, 'updated_at' => now(), 'created_at' => now()]
        );
    }

    private static function ensureLogTable(): void
    {
        if (Schema::hasTable('admin_push_reminder_log')) {
            return;
        }

        Schema::create('admin_push_reminder_log', function ($t) {
            $t->id();
            $t->string('kind', 40);
            $t->date('remind_date');
            $t->string('slot', 20);
            $t->unsignedInteger('pending_count')->default(0);
            $t->timestamps();
            $t->unique(['kind', 'remind_date', 'slot']);
        });
    }
}
