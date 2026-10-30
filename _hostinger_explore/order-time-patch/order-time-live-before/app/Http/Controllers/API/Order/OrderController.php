<?php

namespace App\Http\Controllers\API\Order;

use App\Enums\LogType;
use App\Http\Controllers\Controller;
use App\Models\BusinessSettings;
use App\Models\CancelReason;
use App\Models\Deal;
use App\Models\DealerAddress;
use App\Models\Logistic;
use App\Models\Order;
use App\Models\OrderDeal;
use App\Models\WithdrawRequest;
use App\Traits\Common;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    use Common;
    public function acceptOrder(Request $request)
    {
        $rules = [
            'deal_id' => 'required|string',
            'address_id' => 'string',
            'order_amount' => 'required|string'
        ];
        $messages = [
            'deal_id.required' => 'deal_id is required.',
            'order_amount.required' => 'order_amount is required.'
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }
        try {
            DB::beginTransaction();
            \App\Models\User::where('id', Auth::id())->lockForUpdate()->first();
            if ($this->userHasOpenPlacement()) {
                DB::rollBack();
                return response()->json([
                    'status' => false,
                    'message' => 'Finish your current order first.',
                ], 409);
            }
            $deal = Deal::where('id', $request->deal_id)->first();
            do {
                $numbers = substr(str_shuffle('0123456789'), 0, 3);
                $letters = strtoupper(Str::random(4));
                $randomPart = str_shuffle($numbers . $letters);
                $orderNumber = 'ORD' . $randomPart;
            } while (Order::where('order_number', $orderNumber)->exists());
            $isPineLab = 0;
            $paymentScreenShot = null;
            $dealerAddress = null;
            if ($deal->is_pine_lab == 1) {
                $isPineLab = 1;
                //Pine Lab screenshot
                if ($request->hasFile('payment_screenshot')) {
                    $path = public_path('upload/payment/screenshot/');
                    $filename = $orderNumber . '_' . 'screenshot' . '.' . $request->file('payment_screenshot')->getClientOriginalExtension();
                    $request->file('payment_screenshot')->move($path, $filename);

                    $paymentScreenShot = 'upload/payment/screenshot/' . $filename;
                }
            } else {
                $autoCancelOrderDuration = BusinessSettings::where('key', 'auto_cancel_order_duration')->first();
                $dealerAddress = DealerAddress::find($request->address_id);
                $dealerAddress->is_reserved = 1;
                $dealerAddress->reserved_date_time = Carbon::now()->addMinutes($autoCancelOrderDuration->value);
                $dealerAddress->save();
            }
            $tdsPercent = BusinessSettings::where('key', 'tds_percent')->value('value');
            $tdsAmount = $deal->card_holder_earn * $tdsPercent / 100;
            $toCardHolder = $deal->card_holder_earn - $tdsAmount;
            $order = Order::create([
                'order_number' => $orderNumber,
                'user_id' => Auth::user()->id,
                'deal_id' => $request->deal_id,
                'address_id' => $request->address_id,
                'order_amount' => $request->order_amount,
                'total_amount' => $deal->product_price,
                'to_card_holder' => $toCardHolder,
                'tds_amount' => $tdsAmount,
                'earnings' => $deal->card_holder_earn,
                'order_date' => Carbon::now()->format('Y-m-d H:i:s'),
                'order_start' => Carbon::now()->format('Y-m-d'),
                'is_pine_lab_deal' => $isPineLab,
                'payment_screenshot' => $paymentScreenShot,
                'created_at' => now(),
            ]);
            try {
                OrderDeal::create([
                    'order_id' => $order->id,
                    'name' => $deal->name ?? '',
                    'image' => $deal->image,
                    'color' => $deal->color,
                    'gst_number' => $deal->gst_number,
                    'pin_code' => $deal->pin_code,
                    'card_holder_earn' => $deal->card_holder_earn ?? 0,
                    'gst_content' => $deal->gst_content,
                    'status' =>  $deal->status ?? 1,
                    'description' =>  $deal->description,
                    'store_id' =>  $deal->store_id,
                    'dealer_id' =>  $deal->dealer_id,
                    'bank_card_id' =>  $deal->bank_card_id,
                    'order_qty' =>  $deal->order_qty ?? 0,
                    'offer_tittle' =>  $deal->offer_tittle,
                    'offer_text' =>  $deal->offer_text,
                    'offer_link1' =>  $deal->offer_link1,
                    'offer_link2' =>  $deal->offer_link2,
                    'offer_link3' =>  $deal->offer_link3,
                    'product_price' =>  $deal->product_price ?? 0,
                    'dealer_price' =>  $deal->dealer_price ?? 0,
                    'discount' =>  $deal->discount ?? 0,
                    'cash_reward' =>  $deal->cash_reward ?? 0,
                    'cashback' =>  $deal->cashback ?? 0,
                    'card_holder_spend' =>  $deal->card_holder_spend ?? 0,
                    'card_holder_receive' =>  $deal->card_holder_recieve,
                    'deal_status' =>  $deal->deal_status ?? 0,
                    'maximum_discount' =>  $deal->maximum_discount,
                    'company_name' =>  $deal->company_name,
                    'gst_message' =>  $deal->gst_message,
                    'instruction' =>  $deal->instruction,
                    'extra_note' =>  $deal->extra_note,
                    'is_pine_lab' =>  $deal->is_pine_lab ?? 0,
                    'pine_lab_url' =>  $deal->pine_lab_url,
                    'deleted_at' =>  $deal->deleted_at,
                    'created_by' =>  $deal->created_by,
                    'updated_by' =>  $deal->updated_by
                ]);
            } catch (Exception $dealException) {
                $this->Log(__FUNCTION__, request()->method(), 'OrderDeal Creation Error: ' . $dealException->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 1, LogType::Error);
                throw new Exception('Failed to create OrderDeal: ' . $dealException->getMessage());
            }

            $response = [
                'message' => $deal->is_pine_lab == 1 ? "Payment has been updated successfully. Please wait for approval." : "Order Accepted Successfully",
                'accept_order_id' => $order->id,
                'reserved_date_time' => $dealerAddress !== null ? $dealerAddress->reserved_date_time->format('Y-m-d H:i:s') : null, // Format the datetime
            ];
            $this->Log(__FUNCTION__, request()->method(), 'Order Accepted Successfully.', $order->user_id, request()->ip(), gethostname(), 1, LogType::Activity);
            // V3 — cancel scheduled deal view follow-ups after Accept (soft-fail).
            try {
                \App\Services\V3Push\V3ViewFollowUpService::cancelPending(
                    (int) Auth::id(),
                    (int) $request->deal_id
                );
            } catch (\Throwable $e) {
                // ignore
            }
            DB::commit();
            return response()->json($response, 200);
        } catch (Exception $e) {
            if (DB::transactionLevel() > 0) {
                DB::rollBack();
            }
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);
            $response = [
                'status' => false,
                'message' => 'Could not accept this deal. Try again.',
            ];
            return response()->json($response, 400);
        }
    }

    public function autoDeleteOrder(Request $request)
    {
        $rules = [
            'accept_order_id' => 'required|string'
        ];
        $messages = [
            'accept_order_id.required' => 'accept_order_id is required.'
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }
        try {
            //order
            $order = $this->orderForAuthUser($request->accept_order_id);

            if (!$order) {
                return $this->missingOrderResponse();
            }

            if ($order->store_order_id == null) {
                $addressId = $order->address_id;
                $order->delete();
                if (!empty($addressId)) {
                    $dealerAddress = DealerAddress::find($addressId);
                    if ($dealerAddress) {
                        $dealerAddress->is_reserved = 0;
                        $dealerAddress->reserved_date_time = null;
                        $dealerAddress->save();
                    }
                }
            }

            $response = [
                'message' => "Order auto Cancelled."
            ];
            $this->Log(__FUNCTION__, request()->method(), 'Order auto Cancelled!', $order->user_id, request()->ip(), gethostname(), 1, LogType::Activity);
            return response()->json($response, 200);
        } catch (Exception $e) {
            // dd($e);
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);
            return response()->json([
                'status' => false,
                'message' => 'Couldn’t cancel. Try again.',
            ], 500);
        }
    }

    public function cancelOrder(Request $request)
    {
        $rules = [
            'accept_order_id' => 'required|string'
        ];
        $messages = [
            'accept_order_id.required' => 'accept_order_id is required.'
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }
        try {
            //order
            $order = $this->orderForAuthUser($request->accept_order_id);
            if (!$order) {
                return $this->missingOrderResponse();
            }
            if ($order->order_status === 'Delivered' || $order->order_status === "Declined" || $order->order_status === "Cancelled") {
                return response()->json(['message' => 'Order can already be ' . $order->order_status . '.'], 400);
            }
            if ($request->reason) {
                $order->order_status = "Cancelled";
                $order->cancel_reason = $request->reason;
                $order->order_end = Carbon::now()->format('Y-m-d');
                $order->save();
            } else {
                $order->delete();
            }

            // Instant / missing address must not crash cancel (PHP 8 null→Error).
            if (!empty($order->address_id)) {
                $dealerAddress = DealerAddress::find($order->address_id);
                if ($dealerAddress) {
                    $dealerAddress->is_reserved = 0;
                    $dealerAddress->reserved_date_time = null;
                    $dealerAddress->save();
                }
            }

            $response = [
                'message' => "Order Cancelled Successfully"
            ];
            // User self-cancel: no push / bell — they already know.
            $this->Log(__FUNCTION__, request()->method(), 'Order Cancelled by the User.', $order->user_id, request()->ip(), gethostname(), 1, LogType::Activity);
            return response()->json($response, 200);
        } catch (Exception $e) {
            // dd($e);
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);
            return response()->json([
                'status' => false,
                'message' => 'Couldn’t cancel. Try again.',
            ], 500);
        }
    }

    public function updateOrderId(Request $request)
    {
        $rules = [
            'accept_order_id' => 'required|string',
            'store_order_id' => 'required|string'
        ];
        $messages = [
            'accept_order_id.required' => 'accept_order_id is required.',
            'store_order_id.required' => 'store_order_id is required.'
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }

        try {
            // Check for uniqueness of store_order_id
            $existingOrder = Order::where('store_order_id', $request->store_order_id)->first();
            if ($existingOrder) {
                return response()->json([
                    'status' => false,
                    'message' => 'Order ID already exists. Please enter a valid Order ID.'
                ], 400);
            }

            //order
            $order = $this->orderForAuthUser($request->accept_order_id);
            if (!$order) {
                return $this->missingOrderResponse();
            }
            $order->store_order_id = $request->store_order_id;
            if (empty($order->store_order_at) && \Illuminate\Support\Facades\Schema::hasColumn('orders', 'store_order_at')) {
                $order->store_order_at = Carbon::now()->format('Y-m-d H:i:s');
            }
            $order->save();

            $deal = Deal::where('id', $order->deal_id)->first();
            $deal->order_qty = $deal->order_qty - 1;
            $deal->save();

            //addresses
            $dealerAddress = DealerAddress::find($order->address_id);
            $dealerAddress->is_ordered = 1;
            $dealerAddress->save();

            $response = [
                'message' => "Order ID Updated Successfully"
            ];
            $this->Log(__FUNCTION__, request()->method(), 'Order ID Updated Successfully.', $order->user_id, request()->ip(), gethostname(), 1, LogType::Activity);
            return response()->json($response, 200);
        } catch (Exception $e) {
            // dd($e);
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);
            $response = [
                'message' => "Order ID Not Updated"
            ];
            return response()->json($response, 400);
        }
    }

    public function updateTrackingId(Request $request)
    {
        $rules = [
            'accept_order_id' => 'required|string',
            'order_tracking_id' => 'required|string',
            'delivery_partner_id' => 'required|string'
        ];
        $messages = [
            'accept_order_id.required' => 'accept_order_id is required.',
            'order_tracking_id.required' => 'order_tracking_id is required.',
            'delivery_partner_id.required' => 'delivery_partner_id is required.'
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }

        try {
            if ($request->delivery_partner_id == 4) {
                $logistic = Logistic::where('logistic_name', $request->logistic_name)->first();

                if ($logistic == null) {
                    $logistic = new Logistic();
                    $logistic->logistic_name = $request->logistic_name;
                    $logistic->save();
                }

                $order = $this->orderForAuthUser($request->accept_order_id);
                if (!$order) {
                    return $this->missingOrderResponse();
                }
                $order->order_tracking_id = $request->order_tracking_id;
                $order->delivery_partner_id = $logistic->id; // Assigning logistic_name ID
                $order->shipped_date = Carbon::now()->format('Y-m-d H:i:s');
                $order->order_status = 'Shipped';
                $order->save();
            } else {
                $order = $this->orderForAuthUser($request->accept_order_id);
                if (!$order) {
                    return $this->missingOrderResponse();
                }
                $order->order_tracking_id = $request->order_tracking_id;
                $order->delivery_partner_id = $request->delivery_partner_id;
                $order->shipped_date = Carbon::now()->format('Y-m-d H:i:s');
                $order->order_status = 'Shipped';
                $order->save();
            }

            $response = [
                'message' => "Tracking ID Updated Successfully"
            ];
            $this->Log(__FUNCTION__, request()->method(), 'Tracking ID Updated Successfully.', $order->user_id, request()->ip(), gethostname(), 1, LogType::Activity);

            // Ack push + bell from tracking_done bank (30 variants).
            try {
                \App\Services\AdminApp\HolderNotifyService::trackingDone((int) $order->id);
            } catch (\Throwable $e) {
                // soft-fail
            }

            return response()->json($response, 200);
        } catch (Exception $e) {
            // dd($e);
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);
            $response = [
                'message' => "Tracking ID Not Updated"
            ];
            return response()->json($response, 400);
        }
    }

    public function updateOutForDelivery(Request $request)
    {
        $rules = [
            'accept_order_id' => 'required|string',
            'order_delivery_otp' => 'required|string',
            'mobile_number' => 'required|string'
        ];
        $messages = [
            'accept_order_id.required' => 'accept_order_id is required.',
            'order_delivery_otp.required' => 'order_delivery_otp is required.',
            'account_mobile_number.required' => 'mobile_number is required.'
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }

        try {
            //order
            $order = $this->orderForAuthUser($request->accept_order_id);
            if (!$order) {
                return $this->missingOrderResponse();
            }
            $order->order_delivery_otp = $request->order_delivery_otp;
            $order->account_mobile_number = $request->mobile_number;
            $order->out_for_delivery_date = Carbon::now()->format('Y-m-d H:i:s');
            $order->order_status = 'Out For Delivery';
            $order->save();

            $response = [
                'message' => "Updated Successfully"
            ];
            $this->Log(__FUNCTION__, request()->method(), 'Mobile.No & OTP Updated Successfully.', $order->user_id, request()->ip(), gethostname(), 1, LogType::Activity);
            return response()->json($response, 200);
        } catch (Exception $e) {
            // dd($e);
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);
            $response = [
                'message' => "Not Updated"
            ];
            return response()->json($response, 400);
        }
    }

    public function updateInvoiceDelivery(Request $request)
    {
        $rules = [
            'accept_order_id' => 'required|string',
            'account_order_pdf' => 'required|file'
        ];
        $messages = [
            'accept_order_id.required' => 'accept_order_id is required.',
            'account_order_pdf.required' => 'account_order_pdf is required.',
            'account_order_pdf.file' => 'order_invoice must be a file.'
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }
        try {
            $order = $this->orderForAuthUser($request->accept_order_id);

            if (!$order) {
                $response = [
                    'status' => false,
                    'message' => 'Order not found.'
                ];
                return response()->json($response, 404);
            }

            if ($request->hasFile('account_order_pdf')) {
                $path = public_path('upload/invoice'); // Getting the absolute path to the public directory
                $filename = $order->order_number . '_' . 'invoice' . '.' . $request->file('account_order_pdf')->getClientOriginalExtension();
                $request->file('account_order_pdf')->move($path, $filename); // Using move() instead of storeAs()

                $order->account_order_pdf = 'upload/invoice/' . $filename; // Storing relative path
                $order->verification_status = null;
                $order->invoice_upload_date = Carbon::now()->format('Y-m-d H:i:s');
                $order->save();
            }

            $response = [
                'status' => true,
                'message' => 'Order invoice Updated successfully.'
            ];
            $this->Log(__FUNCTION__, request()->method(), 'Order Invoice Updated Successfully.', $order->user_id, request()->ip(), gethostname(), 1, LogType::Activity);
            return response()->json($response, 200);
        } catch (Exception $e) {
            // dd($e);
            $this->Log(__FUNCTION__, request()->method(), $e->getMessage(), 1, request()->ip(), gethostname(), 1, LogType::Error);
            $response = [
                'message' => "Not Updated"
            ];
            return response()->json($response, 400);
        }
    }

    public function payoutRequest(Request $request)
    {
        $rules = [
            'accept_order_id' => 'required|string'
        ];
        $messages = [
            'accept_order_id.required' => 'accept_order_id is required.'
        ];

        $validator = Validator::make($request->all(), $rules, $messages);

        if ($validator->fails()) {
            $response = [
                'status' => false,
                'message' => $validator->errors()->first(),
            ];
            return response()->json($response, 400);
        }

        try {
            //order
            $order = $this->orderForAuthUser($request->accept_order_id);
            if (!$order) {
                return $this->missingOrderResponse();
            }
            $order->is_payout_requested = 1;
            $order->updated_at = Carbon::now()->format('Y-m-d H:i:s');
            $order->save();

            $response = [
                'message' => "Payout Requested Successfully"
            ];
            return response()->json($response, 200);
        } catch (Exception $e) {
            // dd($e);
            $response = [
                'message' => "Payout Requested failed"
            ];
            return response()->json($response, 400);
        }
    }

    public function payoutHistory()
    {
        try {
            $payoutHistories = Order::select('orders.*', 'deals.name as deal_name', 'deals.image as deal_image', 'deals.card_holder_recieve')
                ->join('deals', 'orders.deal_id', '=', 'deals.id')
                ->where('user_id', Auth::user()->id)
                ->whereNull('orders.deleted_at')
                ->where('orders.is_payout_requested', 1)
                ->orderBy('orders.id', 'DESC')
                ->get();
            $withdrawHistories = WithdrawRequest::where('user_id', Auth::user()->id)->orderBy('id', 'DESC')->get();

            $data = $this->payoutHistoryDataFormat($payoutHistories, $withdrawHistories);

            return response()->json(['data' => empty($data) ? [] : $data], 200);
        } catch (Exception $e) {
            // dd($e);
        }
    }

    /**
     * For the signed-in user only: drop open Accepts past the placement window
     * (no store Order ID, not Instant/Pine). Mirrors app auto-delete when the
     * phone was closed so the timer never finished on-device.
     */
    private function expireStaleOpenPlacementsForAuthUser(): void
    {
        $userId = Auth::id();
        if (!$userId) {
            return;
        }
        $mins = (int) (BusinessSettings::where('key', 'auto_cancel_order_duration')->value('value') ?? 15);
        if ($mins < 1) {
            $mins = 15;
        }
        $cutoff = Carbon::now()->subMinutes($mins);
        $stale = Order::where('user_id', $userId)
            ->where('order_status', 'Placed')
            ->whereNull('store_order_id')
            ->where(function ($q) {
                $q->where('is_pine_lab_deal', 0)->orWhereNull('is_pine_lab_deal');
            })
            ->where(function ($q) use ($cutoff) {
                $q->where('order_date', '<', $cutoff->format('Y-m-d H:i:s'))
                    ->orWhere('created_at', '<', $cutoff);
            })
            ->get();
        foreach ($stale as $order) {
            $addressId = $order->address_id;
            $order->delete();
            if ($addressId) {
                $dealerAddress = DealerAddress::find($addressId);
                if ($dealerAddress) {
                    $dealerAddress->is_reserved = 0;
                    $dealerAddress->reserved_date_time = null;
                    $dealerAddress->save();
                }
            }
        }
    }

    public function getOrderList(Request $request)
    {
        try {
            // Only this user's stale open Accepts — no mass job, runs when they load orders.
            $this->expireStaleOpenPlacementsForAuthUser();

            $status = $request->input('status');
            $search = $request->input('search');
            $fromDate = $request->input('from_date');
            $toDate = $request->input('to_date');
            $orders = Order::select(
                'orders.*',
                'deals.name',
                'deals.image',
                'deals.card_holder_recieve as deal_card_holder_recieve',
                'stores.name as store_name',
                'stores.image as store_image',
                'deals.color',
                'deals.order_qty',
                'deals.gst_number',
                'deals.pin_code',
                'deals.coupon_code',
                'deals.card_holder_earn',
                'bank_cards.name as offer',
                'order_deal.name as order_deal_name',
                'order_deal.image as order_deal_image',
                'order_deal.color as order_deal_color',
                'order_deal.order_qty as order_deal_order_qty',
                'order_deal.gst_number as order_deal_gst_number',
                'order_deal.pin_code as order_deal_pin_code',
                'order_deal.card_holder_earn as order_deal_card_holder_earn',
                'order_deal.card_holder_receive as order_deal_card_holder_receive',
                'order_deal.cashback as order_deal_cashback',
                'deals.cashback as deal_cashback'
            )
                ->join('deals', 'orders.deal_id', '=', 'deals.id')
                ->join('stores', 'deals.store_id', '=', 'stores.id')
                ->leftJoin('bank_cards', 'deals.bank_card_id', '=', 'bank_cards.id')
                ->leftJoin('order_deal', 'orders.id', '=', 'order_deal.order_id')
                ->where('orders.user_id', Auth::user()->id)
                ->when($status, function ($query, $status) {
                    if ($status === 'ongoing') {
                        $query->where('orders.order_status', '!=', 'Rejected')
                            ->where('orders.order_status', '!=', 'Declined')
                            ->where('orders.order_status', '!=', 'Cancelled')
                            ->where('orders.is_payout', 0);
                    } elseif ($status === 'completed') {
                        $query->where(function ($q) {
                            $q->where('orders.is_payout', 1)
                                ->orWhere('orders.order_status', 'Rejected')
                                ->orWhere('orders.order_status', 'Cancelled');
                        });
                    }
                }, function ($query) {
                    $query->where('orders.order_status', '!=', 'Declined');
                })
                ->where(function ($query) use ($search) {
                    if (!empty($search)) {
                        $query->where('orders.order_number', 'LIKE', '%' . $search . '%')
                            ->orWhere('orders.order_tracking_id', 'LIKE', '%' . $search . '%')
                            ->orWhere('deals.name', 'LIKE', '%' . $search . '%')
                            ->orWhere('orders.store_order_id', 'LIKE', '%' . $search . '%');
                    }
                })
                ->when($fromDate && $toDate, function ($query) use ($fromDate, $toDate) {
                    $query->whereDate('orders.order_date', '>=', $fromDate)
                        ->whereDate('orders.order_date', '<=', $toDate);
                })
                ->orderBy('orders.id', 'DESC')
                ->paginate($request->input('pageSize', $this->recordsperpage));

            $data = $this->orderDataFormat($orders);
            $currentPageUrl = $orders->url($orders->currentPage());
            $prevPageUrl = $orders->previousPageUrl();
            $nextPageUrl = $orders->nextPageUrl();
            return response()->json([
                'data' => empty($data) ? [] : $data,
                'per_page_count' => $orders->perPage(),
                'total' => $orders->total(),
                'currentPage' => $orders->currentPage(),
                'lastPage' => $orders->lastPage(),
                'currentPageUrl' => $currentPageUrl,
                'prevPageUrl' => $prevPageUrl,
                'nextPageUrl' => $nextPageUrl,
            ], 200);
        } catch (Exception $e) {
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }

    public function getPinelabOrderList(Request $request)
    {
        try {
            $paymet_status = $request->input('paymet_status');
            $search = $request->input('search');
            $fromDate = $request->input('from_date');
            $toDate = $request->input('to_date');
            $orders = Order::select(
                'orders.*',
                'deals.name',
                'deals.image',
                'deals.card_holder_recieve as deal_card_holder_recieve',
                'stores.name as store_name',
                'stores.image as store_image',
                'deals.color',
                'deals.order_qty',
                'deals.gst_number',
                'deals.pin_code',
                'deals.card_holder_earn',
                'bank_cards.name as offer',
                'order_deal.name as order_deal_name',
                'order_deal.image as order_deal_image',
                'order_deal.color as order_deal_color',
                'order_deal.order_qty as order_deal_order_qty',
                'order_deal.gst_number as order_deal_gst_number',
                'order_deal.pin_code as order_deal_pin_code',
                'order_deal.card_holder_earn as order_deal_card_holder_earn',
                'order_deal.card_holder_receive as order_deal_card_holder_receive'
            )
                ->join('deals', 'orders.deal_id', '=', 'deals.id')
                ->join('stores', 'deals.store_id', '=', 'stores.id')
                ->leftJoin('bank_cards', 'deals.bank_card_id', '=', 'bank_cards.id')
                ->leftJoin('order_deal', 'orders.id', '=', 'order_deal.order_id')
                ->where('orders.user_id', Auth::user()->id)
                ->where('orders.is_pine_lab_deal', 1)
                ->when($paymet_status == 'pending', function ($query) {
                    return $query->where('orders.is_payment_verified', 0);
                })
                ->when($paymet_status == 'verified', function ($query) {
                    return $query->where('orders.is_payment_verified', 1);
                })
                ->where(function ($query) use ($search) {
                    if (!empty($search)) {
                        $query->where('orders.order_number', 'LIKE', '%' . $search . '%')
                            ->orWhere('orders.order_tracking_id', 'LIKE', '%' . $search . '%')
                            ->orWhere('deals.name', 'LIKE', '%' . $search . '%');
                    }
                })
                ->when($fromDate && $toDate, function ($query) use ($fromDate, $toDate) {
                    $query->whereDate('orders.order_date', '>=', $fromDate)
                        ->whereDate('orders.order_date', '<=', $toDate);
                })
                ->orderBy('orders.id', 'DESC')
                ->paginate($request->input('pageSize', $this->recordsperpage));

            $data = $this->orderDataFormat($orders);
            $currentPageUrl = $orders->url($orders->currentPage());
            $prevPageUrl = $orders->previousPageUrl();
            $nextPageUrl = $orders->nextPageUrl();
            return response()->json([
                'data' => empty($data) ? [] : $data,
                'per_page_count' => $orders->perPage(),
                'total' => $orders->total(),
                'currentPage' => $orders->currentPage(),
                'lastPage' => $orders->lastPage(),
                'currentPageUrl' => $currentPageUrl,
                'prevPageUrl' => $prevPageUrl,
                'nextPageUrl' => $nextPageUrl,
            ], 200);
        } catch (Exception $e) {
            $response = array(
                'message' => $this->errorMessage,
                'status' => false,
            );
            return response($response, 500);
        }
    }

    public function getPayoutStage(Request $request)
    {
        try {
            $acceptOrderId = $request->input('accept_order_id');

            $order = Order::select(
                    'orders.id',
                    'orders.deal_id',
                    'orders.address_id',
                    'orders.user_id',
                    'orders.order_number',
                    'orders.store_order_id',
                    'orders.is_payout',
                    'orders.delivery_partner_id',
                    'orders.order_tracking_id',
                    'orders.account_mobile_number',
                    'orders.order_delivery_otp',
                    'orders.order_status',
                    'orders.shipped_date',
                    'orders.out_for_delivery_date',
                    'orders.account_order_pdf',
                    'orders.verification_status',
                    'orders.order_amount',
                    'orders.total_amount',
                    'orders.to_card_holder',
                    'orders.tds_amount',
                    'deals.name as deal_name',
                    'deals.image as deal_image',
                    'deals.color as deal_color',
                    'deals.order_qty as deal_order_qty',
                    'deals.gst_number as deal_gst_number',
                    'deals.pin_code as deal_pin_code',
                    'deals.card_holder_earn as deal_card_holder_earn',
                    'order_deal.name as order_deal_name',
                    'order_deal.image as order_deal_image',
                    'order_deal.color as order_deal_color',
                    'order_deal.order_qty as order_deal_order_qty',
                    'order_deal.gst_number as order_deal_gst_number',
                    'order_deal.pin_code as order_deal_pin_code',
                    'order_deal.card_holder_earn as order_deal_card_holder_earn'
                )
                ->join('deals', 'orders.deal_id', '=', 'deals.id')
                ->leftJoin('order_deal', 'orders.id', '=', 'order_deal.order_id')
                ->where('orders.id', $acceptOrderId)
                ->where('orders.user_id', Auth::user()->id)
                ->whereNull('orders.deleted_at')
                ->where('orders.order_status', '!=', 'Declined')
                ->first();

            if (!$order) {
                return response()->json(['error' => 'Order not found'], 404);
            }

            $data = $this->payoutStageFormat($order);
            return response()->json(['data' => $data], 200);
        } catch (Exception $e) {
            // dd($e);
            return response()->json(['error' => 'Internal Server Error'], 500);
        }
    }

    function cancelReasons()
    {
        $data = [];
        $reasonList = CancelReason::all();
        foreach ($reasonList as $reason) {
            $data[] = [
                'id' => $reason->id,
                'reason' => $reason->content,
            ];
        }
        return response()->json(['status' => true, 'data' => $data], 200);
    }

    /**
     * Open placement only: still Placed, and the store Order ID (or Pine Labs screenshot) is not in yet.
     * Paid, shipped, cancelled, and already-confirmed orders do not block a new Accept.
     */
    private function userHasOpenPlacement(): bool
    {
        $userId = Auth::id();
        if (!$userId) {
            return false;
        }

        return Order::where('user_id', $userId)
            ->where('order_status', 'Placed')
            ->where(function ($query) {
                $query->where(function ($regular) {
                    $regular->where(function ($flag) {
                        $flag->where('is_pine_lab_deal', 0)->orWhereNull('is_pine_lab_deal');
                    })->whereNull('store_order_id');
                })->orWhere(function ($pine) {
                    $pine->where('is_pine_lab_deal', 1)->where(function ($shot) {
                        $shot->whereNull('payment_screenshot')->orWhere('payment_screenshot', '');
                    });
                });
            })
            ->exists();
    }

    private function orderForAuthUser($acceptOrderId)
    {
        if ($acceptOrderId === null || $acceptOrderId === '') {
            return null;
        }

        return Order::where('id', $acceptOrderId)
            ->where('user_id', Auth::id())
            ->first();
    }

    private function missingOrderResponse()
    {
        return response()->json([
            'status' => false,
            'message' => 'Order not found.',
        ], 404);
    }
}
