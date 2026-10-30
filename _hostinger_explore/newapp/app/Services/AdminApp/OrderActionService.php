<?php

namespace App\Services\AdminApp;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class OrderActionService
{
    public static function updateVerification(int $orderId, string $status): array
    {
        $allowed = ['Verified', 'Re-Upload', 'Alerted'];
        if (!in_array($status, $allowed, true)) {
            throw new \InvalidArgumentException('Invalid verification status.');
        }

        $order = DB::table('orders')->where('id', $orderId)->whereNull('deleted_at')->first();
        if (!$order) {
            throw new \RuntimeException('Order not found.');
        }

        $updates = ['verification_status' => $status, 'updated_at' => now()];
        if ($status === 'Verified') {
            if (Schema::hasColumn('orders', 'is_ready_for_payout')) {
                $updates['is_ready_for_payout'] = 1;
            }
            if (Schema::hasColumn('orders', 'is_payout_requested')) {
                $updates['is_payout_requested'] = 1;
            }
        }

        DB::table('orders')->where('id', $orderId)->update($updates);
        try {
            HolderNotifyService::verificationUpdated($orderId, $status);
        } catch (\Throwable $e) {
            // Don't fail the admin action if holder push/SMS fails.
            \Log::warning('Holder notify after verification failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);
        }

        return [
            'order_id' => $orderId,
            'verification_status' => $status,
            'message' => 'Invoice status updated to ' . $status . '.',
        ];
    }

    public static function verifyPayment(int $orderId): array
    {
        $order = DB::table('orders')->where('id', $orderId)->whereNull('deleted_at')->first();
        if (!$order) {
            throw new \RuntimeException('Order not found.');
        }

        $updates = ['updated_at' => now()];
        if (Schema::hasColumn('orders', 'is_payment_verified')) {
            $updates['is_payment_verified'] = 1;
        }
        if (Schema::hasColumn('orders', 'is_ready_for_payout')) {
            $updates['is_ready_for_payout'] = 1;
        }
        if (Schema::hasColumn('orders', 'is_payout_requested')) {
            $updates['is_payout_requested'] = 1;
        }

        DB::table('orders')->where('id', $orderId)->update($updates);
        try {
            HolderNotifyService::paymentVerified($orderId);
        } catch (\Throwable $e) {
            \Log::warning('Holder notify after payment verify failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);
        }

        return [
            'order_id' => $orderId,
            'message' => 'Payment verified.',
        ];
    }

    public static function approvePayout(int $orderId, string $transactionId, ?string $notes = null): array
    {
        $order = DB::table('orders')->where('id', $orderId)->whereNull('deleted_at')->first();
        if (!$order) {
            throw new \RuntimeException('Order not found.');
        }

        $updates = [
            'transaction_id' => $transactionId,
            'updated_at' => now(),
        ];
        if ($notes !== null && Schema::hasColumn('orders', 'payout_notes')) {
            $updates['payout_notes'] = $notes;
        }
        if (Schema::hasColumn('orders', 'is_payout')) {
            $updates['is_payout'] = 1;
        }

        DB::table('orders')->where('id', $orderId)->update($updates);

        try {
            if (class_exists(\App\Services\V3Push\V3PayoutNotifyService::class)) {
                \App\Services\V3Push\V3PayoutNotifyService::notifyPayoutSent($orderId);
            }
        } catch (\Throwable $e) {
            // soft-fail
        }

        return [
            'order_id' => $orderId,
            'message' => 'Payout marked done.',
        ];
    }

    public static function detail(int $orderId): array
    {
        $cols = OrderListService::selectColumnsForDetail();
        $order = DB::table('orders')
            ->join('users', 'users.id', '=', 'orders.user_id')
            ->join('deals', 'deals.id', '=', 'orders.deal_id')
            ->where('orders.id', $orderId)
            ->whereNull('orders.deleted_at')
            ->first($cols);

        if (!$order) {
            throw new \RuntimeException('Order not found.');
        }

        $row = OrderListService::formatRow($order);
        $row['userMobile'] = $order->user_mobile ?? null;
        $row['pipeline'] = OrderListService::pipelineFor($order);
        $row['bank'] = OrderListService::bankFromRow($order);

        return $row;
    }

    public static function markDelivered(int $orderId): array
    {
        $order = DB::table('orders')->where('id', $orderId)->whereNull('deleted_at')->first();
        if (!$order) {
            throw new \RuntimeException('Order not found.');
        }

        $updates = [
            'order_status' => 'Delivered',
            'updated_at' => now(),
        ];
        if (Schema::hasColumn('orders', 'delivery_date')) {
            $updates['delivery_date'] = now();
        }
        if (Schema::hasColumn('orders', 'order_end')) {
            $updates['order_end'] = now()->format('Y-m-d');
        }

        DB::table('orders')->where('id', $orderId)->update($updates);

        return ['order_id' => $orderId, 'message' => 'Marked delivered.'];
    }

    public static function remind(int $orderId, string $type): array
    {
        $order = DB::table('orders')->where('id', $orderId)->whereNull('deleted_at')->first();
        if (!$order) {
            throw new \RuntimeException('Order not found.');
        }

        try {
            if ($type === 'tracking') {
                HolderNotifyService::trackingReminder($orderId);

                return ['order_id' => $orderId, 'message' => 'Tracking reminder sent to holder.'];
            }
            if ($type === 'otp') {
                HolderNotifyService::otpReminder($orderId);

                return ['order_id' => $orderId, 'message' => 'OTP reminder sent to holder.'];
            }
            if ($type === 'invoice') {
                self::updateVerification($orderId, 'Alerted');

                return ['order_id' => $orderId, 'message' => 'Invoice reminder sent to holder.'];
            }
        } catch (\Throwable $e) {
            \Log::warning('Holder reminder failed', [
                'order_id' => $orderId,
                'type' => $type,
                'error' => $e->getMessage(),
            ]);
            throw new \RuntimeException('Could not send reminder.');
        }

        throw new \InvalidArgumentException('Invalid reminder type.');
    }

    public static function cancel(int $orderId, string $reason, ?string $otherReason = null): array
    {
        $order = DB::table('orders')->where('id', $orderId)->whereNull('deleted_at')->first();
        if (!$order) {
            throw new \RuntimeException('Order not found.');
        }

        $status = (string) ($order->order_status ?? '');
        if (in_array($status, ['Delivered', 'Declined', 'Cancelled'], true)) {
            throw new \InvalidArgumentException('Order already ' . $status);
        }

        $allowed = ['Wrong variant', 'Duplicate order', 'No info given', 'Cancelled by store', 'Other'];
        if (!in_array($reason, $allowed, true)) {
            throw new \InvalidArgumentException('Invalid cancel reason.');
        }

        $finalReason = $reason === 'Other'
            ? trim((string) $otherReason)
            : $reason;
        if ($finalReason === '') {
            throw new \InvalidArgumentException('Please enter a reason.');
        }

        $updates = [
            'order_status' => 'Cancelled',
            'updated_at' => now(),
        ];
        if (Schema::hasColumn('orders', 'cancel_reason')) {
            $updates['cancel_reason'] = $finalReason;
        }
        if (Schema::hasColumn('orders', 'is_admin_cancelled')) {
            $updates['is_admin_cancelled'] = 1;
        }
        if (Schema::hasColumn('orders', 'order_end')) {
            $updates['order_end'] = now()->format('Y-m-d');
        }

        DB::table('orders')->where('id', $orderId)->update($updates);

        try {
            HolderNotifyService::orderCancelled($orderId, $finalReason);
        } catch (\Throwable $e) {
            \Log::warning('Holder notify after cancel failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);
        }

        $label = trim((string) ($order->store_order_id ?? '')) ?: ('#' . $orderId);

        return [
            'order_id' => $orderId,
            'message' => "Order {$label} cancelled.",
        ];
    }

    public static function assetUrl(?string $path): ?string
    {
        if ($path === null || trim($path) === '') {
            return null;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            if (str_contains($path, 'localhost') || str_contains($path, '127.0.0.1')) {
                $path = ltrim(parse_url($path, PHP_URL_PATH) ?: '', '/');
            } else {
                return $path;
            }
        }

        $base = (string) config('admin-app.public_asset_url', 'https://app.mintzer.in');
        if ($base === '' || str_contains($base, 'localhost') || str_contains($base, '127.0.0.1')) {
            $base = 'https://app.mintzer.in';
        }

        return rtrim($base, '/') . '/' . ltrim($path, '/');
    }
}
