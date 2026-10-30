<?php

namespace App\Http\Controllers;

use App\Enums\LogType;
use App\Models\BusinessSettings;
use App\Models\DealerAddress;
use App\Models\Notification;
use App\Models\Order;
use App\Models\User;
use App\Traits\Common;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\Request;

class CronjobController extends Controller
{
    use Common;

    private function buildStoreOrderIdReminderMessage(Order $order, Carbon $reservedTime): array
    {
        $orderRef = $order->store_order_id ?: $order->order_number ?: ('#' . $order->id);
        $expiryText = $reservedTime->format('h:i A');

        $titles = [
            'Update Order ID 🔔',
            'Order ID Pending ⏳',
            'Action Needed: Order ID',
            'Quick Reminder 🚀',
            'Accepted Deal Update 📌',
        ];

        $bodies = [
            "Your accepted deal (Order {$orderRef}) needs Order ID update. Please add it before {$expiryText}.",
            "Order {$orderRef} is waiting for Store Order ID. Update now to avoid auto-cancel at {$expiryText}.",
            "Please update Order ID for {$orderRef} in app. Deadline: {$expiryText}.",
            "Final reminder for {$orderRef}: add Store Order ID before {$expiryText}.",
            "Deal accepted successfully. Now update Order ID for {$orderRef} before {$expiryText}.",
        ];

        return [
            'title' => $titles[array_rand($titles)],
            'body' => $bodies[array_rand($bodies)],
        ];
    }

    private function buildCronTrackingReminderMessage(Order $order): array
    {
        $orderRef = $order->store_order_id ?: $order->order_number ?: ('#' . $order->id);

        $titles = [
            'Tracking Update Needed 📦',
            'Shipping ID Pending 🚚',
            'Order Waiting For Tracking ⏳',
            'Action Needed: Tracking ID ⚡',
            'Quick Reminder: Update Tracking 🔔',
        ];

        $bodies = [
            "Order {$orderRef} is accepted and waiting for tracking ID. Please update now.",
            "Please add tracking details for Order {$orderRef} to continue delivery.",
            "Tracking ID is missing for Order {$orderRef}. Update it to avoid delay.",
            "Delivery flow is pending for {$orderRef}. Add tracking ID now.",
            "Your order {$orderRef} needs shipping update. Please submit tracking ID.",
        ];

        return [
            'title' => $titles[array_rand($titles)],
            'body' => $bodies[array_rand($bodies)],
        ];
    }

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

                //Auto Delete Order after reserved date time
                $dealerAddress = DealerAddress::where('id', $order->address_id)
                                ->whereNull('deleted_at')
                                ->first();
                if (Carbon::now() >= $dealerAddress->reserved_date_time) {

                    if ($order->store_order_id == null) {
        
                        if (!empty($order->address_id)) {
                            if ($dealerAddress) {
                                $dealerAddress->is_reserved = 0;
                                $dealerAddress->reserved_date_time = null;
                                $dealerAddress->update();
                            }
                        }

                        $order->delete();
                    }
                }
                //Reminder for Store Order ID update
                if ($order) {

                    $currentTime = Carbon::now();
                    $reservedTime = Carbon::parse($order->reserved_date_time);
                    $timeDiff = $reservedTime->diffInMinutes($currentTime);

                    $intervalCount = 3;
                    $step = round($cancelDuration / ($intervalCount + 1));
                    $reminderTimes = [];


                    for ($i = 1; $i <= $intervalCount; $i++) {
                        $reminderTimes[] = $i * $step;
                    }

                    if (in_array($timeDiff, $reminderTimes)) {

                        $user = User::where('id', $order->user_id)->first();
                        $messagePayload = $this->buildStoreOrderIdReminderMessage($order, $reservedTime);
                        $title = $messagePayload['title'];
                        $body = $messagePayload['body'];

                        if ($user->fcm_token !== null) {
                            $accessToken = $this->getAccessToken();
                            $url = "https://fcm.googleapis.com/v1/projects/mintzer-e14bd/messages:send";
                            $headers = [
                                'Authorization: Bearer ' . $accessToken,
                                'Content-Type: application/json',
                            ];
                        
                            $payload = [
                                "message" => [
                                    "token" => $user->fcm_token,// single token
                                    "notification" => [
                                        "title" => $title,
                                        "body" => $body,
                                    ],
                                ],
                            ];
                        
                            // Send HTTP request
                            $ch = curl_init();
                            curl_setopt_array($ch, [
                                CURLOPT_URL => $url,
                                CURLOPT_POST => true,
                                CURLOPT_RETURNTRANSFER => true,
                                CURLOPT_POSTFIELDS => json_encode($payload),
                                CURLOPT_HTTPHEADER => $headers,
                            ]);
                            
                            $response = curl_exec($ch);
                            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                            curl_close($ch);
                        
                            // Save Notification in DB
                            Notification::create([
                                'user_id' => $user->id,
                                'title' => $title,
                                'content' => $body,
                                'image_url' => null,
                                'status' => $httpCode == 200 ? 1 : 0,
                            ]);
                        }
                    }
                }
            }

            //Tracking ID update reminder
            foreach ($trackingUnUpdatedOrders as $order) {
                if (empty($order->order_tracking_id)) {

                    $reminderTime = Carbon::parse($order->created_at)
                                        ->addHours($trackReminderTime);
                
                    // Only proceed if current time >= reminder time
                    if (Carbon::now()->greaterThanOrEqualTo($reminderTime)) {
                
                        // Check if this reminder was already sent for this order
                        $checkIfSent = Notification::where('user_id', $order->user_id)
                            ->where('order_id', $order->id)
                            ->whereIn('title', [
                                'Tracking Update Reminder!',
                                'Tracking Update Needed 📦',
                                'Shipping ID Pending 🚚',
                                'Order Waiting For Tracking ⏳',
                                'Action Needed: Tracking ID ⚡',
                                'Quick Reminder: Update Tracking 🔔',
                            ])
                            ->exists();
                
                        if (!$checkIfSent) {
                
                            $user = User::find($order->user_id);
                
                            if ($user && $user->fcm_token) {
                                $messagePayload = $this->buildCronTrackingReminderMessage($order);
                                $title = $messagePayload['title'];
                                $body = $messagePayload['body'];
                
                                // Send Push Notification
                                $accessToken = $this->getAccessToken();
                                $url = "https://fcm.googleapis.com/v1/projects/mintzer-e14bd/messages:send";
                
                                $headers = [
                                    'Authorization: Bearer ' . $accessToken,
                                    'Content-Type: application/json',
                                ];
                
                                $payload = [
                                    "message" => [
                                        "token" => $user->fcm_token,
                                        "notification" => [
                                            "title" => $title,
                                            "body" => $body,
                                        ],
                                    ],
                                ];
                
                                $ch = curl_init();
                                curl_setopt_array($ch, [
                                    CURLOPT_URL => $url,
                                    CURLOPT_POST => true,
                                    CURLOPT_RETURNTRANSFER => true,
                                    CURLOPT_POSTFIELDS => json_encode($payload),
                                    CURLOPT_HTTPHEADER => $headers,
                                ]);
                
                                $response = curl_exec($ch);
                                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                                curl_close($ch);
                
                                // Save Notification in DB
                                Notification::create([
                                    'user_id' => $user->id,
                                    'order_id' => $order->id,
                                    'title'   => $title,
                                    'content' => $body,
                                    'image_url' => null,
                                    'status' => $httpCode == 200 ? 1 : 0,
                                ]);
                            }
                        }
                    }
                }
            }

            // V3 Flutter — drain scheduled follow-ups + multi-day still-live (soft-fail).
            try {
                \App\Services\V3Push\V3OutboxDrainService::drain(80);
                \App\Services\V3Push\V3StillLiveService::tick();
            } catch (\Throwable $e) {
                // never break V2 cron
            }

        } catch (Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), 1, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }
}
