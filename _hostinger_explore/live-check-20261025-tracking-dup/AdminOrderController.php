<?php

namespace App\Http\Controllers\Admin\Order;

use App\Enums\LogType;
use App\Http\Controllers\Controller;
use App\Models\BusinessSettings;
use App\Models\Notification;
use App\Models\Order;
use App\Models\User;
use App\Models\UserReferralHistory;
use App\Services\AdminApp\HolderNotifyService;
use App\Traits\Common;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class OrderController extends Controller
{
    use Common;
    public function orderList($status = null)
    {
        try {
            $formattedStatus = null;
            if ($status) {
                $formattedStatus = str_replace(['-', '_'], ' ', $status);
                $formattedStatus = ucwords($formattedStatus);
            }
            $reasonList = $this->getAdminCancelReasons();
            $holder = null;
            $holderId = (int) request()->query('user', 0);
            if ($holderId > 0) {
                $holder = User::find($holderId);
            }
            return view('admin.orders.list', compact('formattedStatus', 'reasonList', 'holder'));
        }
        catch (Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }

    private function getAdminCancelReasons()
    {
        return collect([
            (object) ['content' => 'Wrong variant'],
            (object) ['content' => 'Duplicate order'],
            (object) ['content' => 'No info given'],
            (object) ['content' => 'Cancelled by store'],
            (object) ['content' => 'Other'],
        ]);
    }

    public function getOrderData(Request $request)
    {
        try {
            $status = $request->status;
            $invoiceStatus = $request->invoice_status;
            $startdate = $request->startdate;
            $enddate = $request->enddate;
            $holderId = (int) $request->input('user_id', 0);

            $orders = Order::select('orders.*', 'users.display_name as user_name', 'deals.name as deal_name', 'deals.card_holder_recieve', 'order_deal.card_holder_receive as order_deal_card_holder_recieve', 'order_deal.name as order_deal_name', 'logistics.logistic_name as delivery_partner_name')
                ->join('users', 'users.id', 'orders.user_id')
                ->join('deals', 'deals.id', 'orders.deal_id')
                ->leftJoin('logistics', 'logistics.id', 'orders.delivery_partner_id')
                ->leftJoin('order_deal', 'order_deal.order_id', 'orders.id')
                ->where('is_pine_lab_deal', 0)
                ->whereNull('orders.deleted_at')
                ->whereNotNull('orders.store_order_id')
                ->where('orders.store_order_id', '!=', '')
                ->when($holderId > 0, function ($q) use ($holderId) {
                $q->where('orders.user_id', $holderId);
            })
                ->when($startdate && $enddate, function ($q) use ($startdate, $enddate) {
                $q->whereDate('orders.order_date', '>=', $startdate)
                    ->whereDate('orders.order_date', '<=', $enddate);
            })
                ->when($status, function ($query) use ($status) {
                $query->where('orders.order_status', $status);
            })
                ->when(!$status, function ($query) {
                $query->where('orders.order_status', '!=', 'Cancelled');
            })
                ->when($invoiceStatus && $invoiceStatus != "All", function ($query) use ($invoiceStatus) {
                if ($invoiceStatus == "not-upload") {
                    $query->whereNull('orders.account_order_pdf');
                }
                if ($invoiceStatus == "re-upload") {
                    $query->where('orders.verification_status', 'Re-Upload');
                }
            })
                ->orderBy('id', 'DESC')
                ->get();
            $payoutPendingCount = $orders->filter(function ($order) {
                $isDelivered = $order->order_status === 'Delivered';
                $isVerified = $order->verification_status === 'Verified';
                $hasOtp = !empty(trim((string) $order->order_delivery_otp));
                $isPayoutDone = (int) $order->is_payout === 1;

                // Payout pending = all completion details done but payout not processed yet
                return $isDelivered && $isVerified && $hasOtp && !$isPayoutDone;
            })->count();

            $outForDeliveryCount = $orders->filter(function ($order) {
                $isOutForDelivery = $order->order_status === 'Out For Delivery';
                $isPayoutDone = (int) $order->is_payout === 1;
                $hasOtp = !empty(trim((string) $order->order_delivery_otp));

                // Out for delivery focus = currently in delivery stage, OTP collected, payout not done
                return $isOutForDelivery && $hasOtp && !$isPayoutDone;
            })->count();

            $orderedValue = (int) round($orders->filter(function ($order) {
                return in_array($order->order_status, ['Placed', 'Shipped'], true);
            })->sum(function ($order) {
                return (float) ($order->order_amount ?? 0);
            }));

            $payoutPendingValue = (int) round($orders->filter(function ($order) {
                $isDelivered = $order->order_status === 'Delivered';
                $isVerified = $order->verification_status === 'Verified';
                $hasOtp = !empty(trim((string) $order->order_delivery_otp));
                $isPayoutDone = (int) $order->is_payout === 1;

                return $isDelivered && $isVerified && $hasOtp && !$isPayoutDone;
            })->sum(function ($order) {
                $amount = (float) ($order->order_deal_card_holder_recieve ?? $order->card_holder_recieve ?? 0);
                $tds = (float) ($order->tds_amount ?? 0);
                if ($tds > 0) {
                    $amount -= $tds;
                }
                return $amount;
            }));

            return datatables()
                ->of($orders)
                ->with([
                    'payout_pending_count' => $payoutPendingCount,
                    'out_for_delivery_count' => $outForDeliveryCount,
                    'ordered_value' => $orderedValue,
                    'payout_pending_value' => $payoutPendingValue,
                ])
                ->toJson();
        }
        catch (Exception $e) {
            // dd($e);
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }

    public function pinelabeOrderList()
    {
        try {
            return view('admin.orders.pinelab_list');
        }
        catch (Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }

    public function getPinelabeOrderData(Request $request)
    {
        $payment_status = $request->payment_status;
        $startdate = $request->startdate;
        $enddate = $request->enddate;

        $orders = Order::select('orders.*', 'users.display_name as user_name', 'deals.name as deal_name', 'deals.card_holder_recieve')
            ->join('users', 'users.id', 'orders.user_id')
            ->join('deals', 'deals.id', 'orders.deal_id')
            ->where('order_status', '!=', 'Declined')
            ->where('is_pine_lab_deal', 1)
            ->whereNull('orders.deleted_at')
            ->when($startdate && $enddate, function ($q) use ($startdate, $enddate) {
            $q->whereDate('orders.order_date', '>=', $startdate)
                ->whereDate('orders.order_date', '<=', $enddate);
        })
            ->when($payment_status !== null && $payment_status !== 'All', function ($q) use ($payment_status) {
            $q->where('orders.is_payment_verified', $payment_status);
        })
            ->orderBy('id', 'DESC')
            ->get();

        return datatables()->of($orders)->toJson();
    }

    public function getBankData(Request $request)
    {
        $order = Order::where('id', $request->id)->first();
        $customers = User::where('id', $order->user_id)->first();
        $order_list = [
            'transaction_id' => $order->transaction_id,
            'transaction_file' => $customers->transaction_file,
            'payout_notes' => $customers->payout_notes,
            'order_number' => $order->order_number,
        ];
        return response()->json(['customer' => $customers, 'order_list' => $order_list]);
    }

    public function trackingSendNotify(Request $request, $orderId)
    {
        $pushNotificationKey = BusinessSettings::where('key', 'push_notification_key')->first()->value;
        $order = Order::find($orderId);

        if (!$order) {
            return response()->json(['error' => 'Order not found'], 404);
        }

        $user = User::find($order->user_id);

        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }

        $fcmToken = $user->fcm_token;
        $messagePayload = $this->buildTrackingReminderMessage($order);
        $title = $messagePayload['title'];
        $body = $messagePayload['body'];

        // Send Push Notification
        $response = $this->sendVerificationPushNotify($fcmToken, $title, $body, $pushNotificationKey, $order->id);

        // Save Notification
        $notification = new Notification();
        $notification->user_id = $order->user_id;
        $notification->title = $title;
        $notification->content = $body;
        if ($response !== false) {
            $responseData = json_decode($response, true);
            $notification->status = 1;
        }
        $notification->save();

        $notification = array(
            'message' => 'Reminder Notification sent successfully',
            'type' => 'success'
        );

        return response()->json($notification);
    }

    private function buildTrackingReminderMessage(Order $order): array
    {
        $dealName = optional($order->deal)->name ?: 'your order';
        $orderId = $order->store_order_id ?: $order->order_number ?: ('#' . $order->id);

        $titles = [
            'Tracking Update Needed 📦',
            'Shipping ID Pending 🚚',
            'Order Waiting For Tracking ⏳',
            'Action Needed: Tracking ID ⚡',
            'Quick Reminder: Update Tracking 🔔',
            'Dispatch Update Required 🎯',
            'Tracking ID Alert 🚀',
            'Update Shipping Details Now 🛍️',
        ];

        $bodies = [
            "{$dealName} (Order {$orderId}) is waiting for tracking ID. Please update now.",
            "Please add tracking details for {$dealName} - Order {$orderId}.",
            "Order {$orderId} is accepted. Upload tracking ID to continue delivery.",
            "{$dealName} dispatch is pending. Add tracking ID now to avoid delay.",
            "Shipping update needed for Order {$orderId}. Please submit tracking ID.",
            "Your accepted order {$orderId} needs tracking details. Update now.",
            "Tracking ID missing for {$dealName}. Please update shipping info.",
            "Order {$orderId} is ready to move. Add tracking ID now.",
        ];

        return [
            'title' => $titles[array_rand($titles)],
            'body' => $bodies[array_rand($bodies)],
        ];
    }

    public function otpSendNotify(Request $request, $orderId)
    {
        $pushNotificationKey = BusinessSettings::where('key', 'push_notification_key')->first()->value;
        $order = Order::find($orderId);

        if (!$order) {
            return response()->json(['error' => 'Order not found'], 404);
        }

        $user = User::find($order->user_id);

        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }

        $fcmToken = $user->fcm_token;
        $messagePayload = $this->buildOtpReminderMessage($order);
        $title = $messagePayload['title'];
        $body = $messagePayload['body'];

        // Send Push Notification
        $response = $this->sendVerificationPushNotify($fcmToken, $title, $body, $pushNotificationKey, $order->id);

        // Save Notification
        $notification = new Notification();
        $notification->user_id = $order->user_id;
        $notification->title = $title;
        $notification->content = $body;
        if ($response !== false) {
            $responseData = json_decode($response, true);
            $notification->status = 1;
        }
        $notification->save();

        $notification = array(
            'message' => 'Reminder Notification sent successfully',
            'type' => 'success'
        );

        return response()->json($notification);
    }

    private function buildOtpReminderMessage(Order $order): array
    {
        $dealName = optional($order->deal)->name ?: 'your order';
        $orderId = $order->store_order_id ?: $order->order_number ?: ('#' . $order->id);

        $titles = [
            'Delivery Boy Is Waiting 🚚',
            'Quick OTP Update Needed 🔐',
            'Share OTP To Complete Delivery 📦',
            'Friendly Reminder: OTP Pending 😊',
            'Almost Done! Send OTP ⚡',
            'Order Delivery In Progress 🛵',
            'Please Update OTP Now ⏳',
            'Final Step: OTP & Mobile 📲',
        ];

        $bodies = [
            "Delivery partner is waiting for Order {$orderId}. Please update OTP now.",
            "Your {$dealName} delivery is at final step. Share OTP and mobile number.",
            "Order {$orderId} is ready to complete. Please add OTP quickly.",
            "Hey! {$dealName} is on the way. Update OTP so delivery can finish smoothly.",
            "Just one step left for Order {$orderId} - please provide OTP now.",
            "Friendly reminder: delivery rider is waiting. Add OTP for {$dealName}.",
            "Please update OTP and contact number for Order {$orderId}.",
            "Your order is almost delivered. Share OTP now to avoid delay.",
            "Delivery attempt is active for {$dealName}. Add OTP and mobile details now.",
            "Order {$orderId} completion is pending on OTP. Please update now.",
        ];

        return [
            'title' => $titles[array_rand($titles)],
            'body' => $bodies[array_rand($bodies)],
        ];
    }

    private function buildVerificationStatusMessage(string $status): array
    {
        if ($status === "Verified") {
            $templates = [
                ['title' => 'Invoice Verified ✅', 'body' => 'Great news! Your invoice is verified. Payment step is next.'],
                ['title' => 'Verification Done 🎉', 'body' => 'Invoice check completed successfully. Your order is moving to payment stage.'],
                ['title' => 'Verification Complete 📄', 'body' => 'Your invoice is approved. Payment processing will follow.'],
                ['title' => 'Invoice Approved 👍', 'body' => 'Your invoice is approved and your order is now in payment queue.'],
                ['title' => 'Check Complete ✅', 'body' => 'Invoice verification finished successfully. Payment update will follow shortly.'],
            ];
            return $templates[array_rand($templates)];
        }

        if ($status === "Re-Upload") {
            $templates = [
                ['title' => 'Quick Re-Upload Needed 📄', 'body' => 'Your invoice is not clear. Please re-upload a clear image to continue.'],
                ['title' => 'Invoice Needs Update ⚠️', 'body' => 'Please upload the invoice again with better clarity.'],
                ['title' => 'Action Needed: Re-Upload', 'body' => 'Invoice check failed due to quality. Re-upload now to avoid delay.'],
                ['title' => 'Re-Upload Required 🔁', 'body' => 'We could not verify your invoice. Please upload a clear invoice image again.'],
                ['title' => 'Invoice Not Clear 👀', 'body' => 'Please re-upload your invoice in clear format so we can verify quickly.'],
            ];
            return $templates[array_rand($templates)];
        }

        $templates = [
            ['title' => 'Upload Invoice Reminder 🔔', 'body' => 'Your order is waiting for invoice upload. Please upload now.'],
            ['title' => 'Invoice Pending ⏳', 'body' => 'Please upload your invoice so verification can be completed.'],
            ['title' => 'Final Step Left 📌', 'body' => 'Upload invoice now to keep your order moving smoothly.'],
            ['title' => 'Invoice Needed 📤', 'body' => 'Please upload invoice to start verification and payment processing.'],
            ['title' => 'Order Waiting For Invoice', 'body' => 'Your order is paused until invoice is uploaded. Please update now.'],
        ];
        return $templates[array_rand($templates)];
    }

    private function buildPaymentVerifiedMessage(): array
    {
        $templates = [
            ['title' => 'Amount Credited ✅', 'body' => 'Success! Your amount has been returned to your account.'],
            ['title' => 'Payment Sent 🎉', 'body' => 'Good news! Your payment has been processed and sent successfully.'],
            ['title' => 'Money Returned 💸', 'body' => 'Your return amount is completed. Please check your account balance.'],
            ['title' => 'Payout Completed 🚀', 'body' => 'Done! Your payment return is successfully completed.'],
            ['title' => 'Return Processed ✅', 'body' => 'Your returned amount has been processed successfully.'],
            ['title' => 'Amount Transfer Complete 💰', 'body' => 'Payment return is complete. Please check your bank/wallet balance.'],
            ['title' => 'Credited Successfully 🎉', 'body' => 'Great! Your return amount is credited successfully.'],
            ['title' => 'Payment Returned 👍', 'body' => 'Your order return amount has been sent to your account.'],
            ['title' => 'Payout Success 💸', 'body' => 'Your payout is completed. Kindly verify your credited amount.'],
            ['title' => 'Money Sent ✅', 'body' => 'Return amount has been sent successfully. Check your account now.'],
            ['title' => 'Transfer Completed 🚀', 'body' => 'Your payment return transfer is now complete.'],
            ['title' => 'Amount Received Update 📌', 'body' => 'Your return amount is successfully processed and credited.'],
        ];

        return $templates[array_rand($templates)];
    }

    public function verificationStatusUpdate(Request $request, $id)
    {
        try {
            $order = Order::find($id);
            if ($order) {
                if ($request->status == "Verified") {
                    $order->verification_status = $request->status;
                    $order->is_ready_for_payout = 1;
                    $order->is_payout_requested = 1;
                } elseif ($request->status == "Re-Upload") {
                    $order->verification_status = $request->status;
                } else {
                    $order->verification_status = $request->status;
                }
                $order->update();

                // V3 banks: invoice_verified / invoice_reupload (100) / invoice_needed
                try {
                    HolderNotifyService::verificationUpdated((int) $order->id, (string) $request->status);
                } catch (\Throwable $e) {
                    \Log::warning('Holder notify after verificationStatusUpdate failed', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage(),
                    ]);
                }

                $notification = [
                    'message' => 'Verification Status Updated for order ' . $order->store_order_id . ' to ' . $request->status . '.',
                    'type' => 'success'
                ];
            }
        }
        catch (\Throwable $th) {
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            $notification = [
                'message' => 'Something Went Wrong',
                'type' => 'error'
            ];
        }

        return response()->json([
            'notification' => $notification,
        ]);
    }

    public function orderStatusUpdate(Request $request, $id)
    {
        try {
            $order = Order::find($id);
            if ($order) {
                $order->order_status = $request->status;
                $order->delivery_date = now()->format('Y-m-d H:i:s');
                $order->order_end = now()->format('Y-m-d');
                $order->update();

                //check user referral in user referral histories
                $referral_user = UserReferralHistory::where('user_id', $order->user_id)->first();

                if ($referral_user) {
                    //Check first order delivered to customer and if he has used referral when signup then update the referral points to him
                    $order_delivered_count = Order::where('user_id', $order->user_id)
                        ->where('order_status', 'Delivered')->count();
                    // dd($order_delivered_count);
                    if ($order_delivered_count == 1) {
                        $this->addReferralWallet($order->user_id);
                        $this->addReferrerWallet($order->user_id);
                    }
                }

                $notification = array(
                    'message' => 'Order Status Updated to ' . $request->status . '.',
                    'type' => 'success'
                );
            }
        }
        catch (\Throwable $th) {
            // dd($th);
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            $notification = array(
                'message' => 'Something Went Wrong',
                'type' => 'error'
            );
        }

        return response()->json([
            'notification' => $notification,
        ]);
    }

    public function approvePayout(Request $request)
    {
        $validatedData = $request->validate([
            'transaction_id' => 'required',
            'transaction_file' => 'nullable|file',
            'payout_notes' => 'nullable|string',
            'hdOrderId' => 'required'
        ]);

        $order = Order::find($request->hdOrderId);

        if (!$order) {
            return response()->json([
                'status' => false,
                'message' => 'Order not found'
            ], 404);
        }

        if ($request->hasFile('transaction_file')) {
            $path = public_path('upload/transaction_file');

            if (!file_exists($path)) {
                mkdir($path, 0777, true);
            }

            $filename = $order->order_number . '_transaction_file.' .
                $request->file('transaction_file')->getClientOriginalExtension();

            $request->file('transaction_file')->move($path, $filename);

            $order->transaction_file = 'upload/transaction_file/' . $filename;
        }

        $order->transaction_id = $request->transaction_id;
        $order->payout_notes = $request->payout_notes;
        $order->is_payout = 1;
        $order->save();

        // V3 — ₹ to bank push (soft-fail). Locked money rule.
        try {
            \App\Services\V3Push\V3PayoutNotifyService::notifyPayoutSent((int) $order->id);
        } catch (\Throwable $e) {
            // never block admin payout save
        }

        return response()->json([
            'status' => true,
            'message' => 'Payout detail updated successfully.'
        ]);
    }

    public function orderCancel(Request $request)
    {
        try {
            $order = Order::find($request->hdOrderId);

            if (!$order) {
                return response()->json([
                    'status' => false,
                    'message' => 'Order not found'
                ]);
            }

            if (in_array($order->order_status, ['Delivered', 'Declined', 'Cancelled'])) {
                return response()->json([
                    'status' => false,
                    'message' => 'Order already ' . $order->order_status
                ]);
            }

            $cancelReason = $request->cancelReason === 'Other'
                ? $request->otherReason
                : $request->cancelReason;

            $order->update([
                'order_status' => 'Cancelled',
                'cancel_reason' => $cancelReason,
                'is_admin_cancelled' => 1,
                'order_end' => now()->format('Y-m-d')
            ]);

            $this->orderCancelPushNotify($order, $cancelReason);

            return response()->json([
                'status' => true,
                'message' => "Order {$order->store_order_id} cancelled successfully."
            ]);

        }
        catch (\Throwable $th) {
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong while cancelling order'
            ], 500);
        }
    }

    public function paymentStatusUpdate(Request $request, $id)
    {
        try {
            $order = Order::find($id);
            if ($order) {
                $order->is_payment_verified = 1;
                $order->is_ready_for_payout = 1;
                $order->is_payout_requested = 1;
                $order->update();

                // V3 bank: payment_verified (100 variants)
                try {
                    HolderNotifyService::paymentVerified((int) $order->id);
                } catch (\Throwable $e) {
                    \Log::warning('Holder notify after paymentStatusUpdate failed', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage(),
                    ]);
                }

                $notification = [
                    'message' => 'Payment verification process completed.',
                    'type' => 'success'
                ];
            }
        }
        catch (\Throwable $th) {
            $this->Log(__FUNCTION__, "GET", $th->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            $notification = [
                'message' => 'Something Went Wrong',
                'type' => 'error'
            ];
        }

        return response()->json([
            'notification' => $notification,
        ]);
    }
    public function updateOrderField(Request $request)
    {
        $orderId = $request->input('order_id');
        $fieldName = $request->input('field');
        $fieldValue = $request->input('value');

        $order = Order::find($orderId);
        if (!$order) {
            return response()->json(['error' => 'Order not found'], 404);
        }

        if (!in_array($fieldName, ['store_order_id', 'order_tracking_id', 'order_delivery_otp'])) {
            return response()->json(['error' => 'Invalid field name'], 400);
        }

        if ($fieldName === 'store_order_id') {
            $existingOrder = Order::where('store_order_id', $fieldValue)->first();
            if ($existingOrder) {
                return response()->json(['error' => 'Order ID already exists. Please enter a valid Order ID.'], 400);
            }
        }

        if ($fieldName === 'order_tracking_id') {
            $trackingId = trim((string) $fieldValue);
            if ($trackingId !== '') {
                $existingTracking = Order::where('order_tracking_id', $trackingId)
                    ->where('id', '!=', $order->id)
                    ->first();
                if ($existingTracking) {
                    return response()->json(['error' => 'Tracking ID already exists. Please enter a valid Tracking ID.'], 400);
                }
            }
            $fieldValue = $trackingId;
        }

        $order->$fieldName = $fieldValue;
        $hasValue = trim((string) $fieldValue) !== '';
        if ($hasValue && $fieldName === 'store_order_id' && empty($order->store_order_at)
            && \Illuminate\Support\Facades\Schema::hasColumn('orders', 'store_order_at')) {
            $order->store_order_at = now()->format('Y-m-d H:i:s');
        }
        if ($hasValue && $fieldName === 'order_tracking_id' && empty($order->shipped_date)) {
            $order->shipped_date = now()->format('Y-m-d H:i:s');
        }
        $order->save();

        return response()->json(['success' => 'Order updated successfully']);
    }
}
