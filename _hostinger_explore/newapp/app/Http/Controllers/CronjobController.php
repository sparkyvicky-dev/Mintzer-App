<?php

namespace App\Http\Controllers;

use App\Enums\LogType;
use App\Models\BusinessSettings;
use App\Models\DealerAddress;
use App\Models\Notification;
use App\Models\Order;
use App\Services\AdminApp\HolderNotifyService;
use App\Traits\Common;
use Carbon\Carbon;
use Illuminate\Support\Facades\Schema;

class CronjobController extends Controller
{
    use Common;

    public function cronJobs()
    {
        try {
            $orders = Order::where('order_status', 'Placed')->whereNull('store_order_id')->where('is_pine_lab_deal', 0)->whereNull('deleted_at')->get();
            $trackingUnUpdatedOrders = Order::where('order_status', 'Placed')->whereNull('order_tracking_id')->where('is_pine_lab_deal', 0)->whereNull('deleted_at')->get();
            $settings = BusinessSettings::where('key', 'auto_cancel_order_duration')->first();
            $cancelDuration = (int) $settings->value;
            $track_settings = BusinessSettings::where('key', 'tracking_reminder_update_time')->first();
            $trackReminderTime = (int) $track_settings->value;

            foreach ($orders as $order) {
                $dealerAddress = DealerAddress::where('id', $order->address_id)
                    ->whereNull('deleted_at')
                    ->first();
                $reservedTime = null;
                if ($dealerAddress && !empty($dealerAddress->reserved_date_time)) {
                    try {
                        $reservedTime = Carbon::parse($dealerAddress->reserved_date_time);
                    } catch (\Throwable $e) {
                        $reservedTime = null;
                    }
                }
                if ($reservedTime && Carbon::now()->greaterThanOrEqualTo($reservedTime)) {
                    if ($order->store_order_id == null) {
                        if (!empty($order->address_id) && $dealerAddress) {
                            $dealerAddress->is_reserved = 0;
                            $dealerAddress->reserved_date_time = null;
                            $dealerAddress->update();
                        }
                        $order->delete();
                        continue;
                    }
                }

                if (!$reservedTime) {
                    continue;
                }

                $timeDiff = $reservedTime->diffInMinutes(Carbon::now());

                $intervalCount = 3;
                $step = round($cancelDuration / ($intervalCount + 1));
                $reminderTimes = [];
                for ($i = 1; $i <= $intervalCount; $i++) {
                    $reminderTimes[] = $i * $step;
                }

                if (in_array($timeDiff, $reminderTimes)) {
                    try {
                        HolderNotifyService::orderIdReminder(
                            (int) $order->id,
                            $reservedTime->format('h:i A')
                        );
                    } catch (\Throwable $e) {
                        // soft-fail
                    }
                }
            }

            // Tracking ID update reminder — V3 bank `tracking` (30 variants).
            foreach ($trackingUnUpdatedOrders as $order) {
                if (!empty($order->order_tracking_id)) {
                    continue;
                }

                $reminderTime = Carbon::parse($order->created_at)->addHours($trackReminderTime);
                if (!Carbon::now()->greaterThanOrEqualTo($reminderTime)) {
                    continue;
                }

                // One reminder per order (any prior notification row for this order_id).
                $already = false;
                if (Schema::hasColumn('notifications', 'order_id')) {
                    $already = Notification::where('user_id', $order->user_id)
                        ->where('order_id', $order->id)
                        ->exists();
                }
                if ($already) {
                    continue;
                }

                try {
                    HolderNotifyService::trackingReminder((int) $order->id);
                } catch (\Throwable $e) {
                    // soft-fail
                }
            }

            // V3 Flutter — drain scheduled follow-ups + multi-day still-live + timers (soft-fail).
            try {
                \App\Services\V3Push\V3OutboxDrainService::drain(80);
                \App\Services\V3Push\V3StillLiveService::tick();
                \App\Services\V3Push\V3PlacementTimerService::tick();
            } catch (\Throwable $e) {
                // never break V2 cron
            }
        } catch (\Throwable $e) {
            $this->Log(__FUNCTION__, 'GET', $e->getMessage(), 1, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }
}
