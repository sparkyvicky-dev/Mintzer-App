@extends('layouts.main_master')
@section('title')
    Mintzer | Order {{ $order->order_number }}
@endsection

@section('content')
<div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
        <h4 class="fw-bold mb-0">
            Order <span class="text-primary">{{ $order->order_number }}</span>
            <span class="badge bg-label-secondary ms-1">{{ $order->order_status }}</span>
        </h4>
        <div class="d-flex gap-2">
            @if(!empty($order->user_id))
                <a class="btn btn-sm btn-outline-primary" href="{{ url('orders?user=' . $order->user_id) }}">User orders</a>
            @endif
            <a class="btn btn-sm btn-outline-secondary" href="{{ url('orders') }}">All orders</a>
            <a class="btn btn-sm btn-outline-secondary" href="{{ url('tickets') }}">Tickets</a>
        </div>
    </div>

    <div class="row g-3">
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header py-2"><strong>Holder</strong></div>
                <div class="card-body small">
                    <div class="mb-1"><b>Name:</b>
                        @if(!empty($order->user_id))
                            <a href="{{ url('orders?user=' . $order->user_id) }}">{{ $order->user_name ?: 'User' }}</a>
                        @else
                            {{ $order->user_name ?: '-' }}
                        @endif
                    </div>
                    <div class="mb-1"><b>Phone:</b> {{ $order->user_mobile ?: '-' }}</div>
                    <div class="mb-1"><b>Email:</b> {{ $order->user_email ?: '-' }}</div>
                    <div class="mb-1"><b>PAN:</b> {{ $order->user_pan ?: '-' }} · {{ $order->user_pan_name ?: '-' }}</div>
                    <div class="mb-1"><b>City:</b> {{ $order->user_city ?: '-' }}</div>
                    <div class="mb-1"><b>Wallet:</b> ₹{{ number_format((float) ($order->user_wallet ?? 0), 2) }}</div>
                    <hr class="my-2">
                    <div class="mb-1"><b>Bank:</b> {{ $order->user_bank_name ?: '-' }}</div>
                    <div class="mb-1"><b>Payee:</b> {{ $order->user_bank_full_name ?: '-' }}</div>
                    <div class="mb-1"><b>Account:</b> {{ $order->user_bank_account ?: '-' }}</div>
                    <div class="mb-1"><b>IFSC:</b> {{ $order->user_bank_ifsc ?: '-' }}</div>
                    <div class="mb-1"><b>UPI:</b> {{ $order->user_upi ?: '-' }}</div>
                </div>
            </div>
        </div>

        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header py-2"><strong>Deal / money</strong></div>
                <div class="card-body small">
                    <div class="mb-1"><b>Product:</b> {{ $order->order_deal_name ?: ($order->deal_name ?: '-') }}</div>
                    <div class="mb-1"><b>Color:</b> {{ $order->deal_color ?: '-' }}</div>
                    <div class="mb-1"><b>Store:</b> {{ $order->store_name ?: '-' }}</div>
                    <div class="mb-1"><b>Card:</b> {{ $order->card_name ?: '-' }}</div>
                    <hr class="my-2">
                    <div class="mb-1"><b>Product price:</b> ₹{{ number_format((float) ($order->product_price ?? $order->total_amount ?? 0), 2) }}</div>
                    <div class="mb-1"><b>You pay (card):</b> ₹{{ number_format((float) ($order->card_holder_spend ?? $order->order_amount ?? 0), 2) }}</div>
                    <div class="mb-1"><b>Mintzer payout (Total receive):</b> ₹{{ number_format((float) ($order->card_holder_receive ?? $order->to_card_holder ?? 0), 2) }}</div>
                    <div class="mb-1"><b>You earn:</b> ₹{{ number_format((float) ($order->card_holder_earn ?? $order->earnings ?? 0), 2) }}</div>
                    <div class="mb-1"><b>Bank cashback:</b> ₹{{ number_format((float) ($order->cashback ?? 0), 2) }}</div>
                    <div class="mb-1"><b>Discount:</b> ₹{{ number_format((float) ($order->discount ?? 0), 2) }}</div>
                    <div class="mb-1"><b>TDS:</b> ₹{{ number_format((float) ($order->tds_amount ?? 0), 2) }}</div>
                </div>
            </div>
        </div>

        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header py-2"><strong>Store / shipping</strong></div>
                <div class="card-body small">
                    <div class="mb-1"><b>Mintzer order:</b> {{ $order->order_number }}</div>
                    <div class="mb-1"><b>Store Order ID:</b> {{ $order->store_order_id ?: '-' }}</div>
                    <div class="mb-1"><b>Store Order at:</b> {{ $order->store_order_at ?: '-' }}</div>
                    <div class="mb-1"><b>Tracking:</b> {{ $order->order_tracking_id ?: '-' }}</div>
                    <div class="mb-1"><b>Courier:</b> {{ $order->delivery_partner_name ?: '-' }}</div>
                    <div class="mb-1"><b>OTP:</b> {{ $order->order_delivery_otp ?: '-' }}</div>
                    <div class="mb-1"><b>Delivery phone last 4:</b> {{ $order->account_mobile_number ?: '-' }}</div>
                    <div class="mb-1"><b>GST on order:</b> {{ $order->order_gst ?: '-' }}</div>
                </div>
            </div>
        </div>

        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header py-2"><strong>Dates / status</strong></div>
                <div class="card-body small">
                    <div class="mb-1"><b>Status:</b> {{ $order->order_status }}</div>
                    <div class="mb-1"><b>Placed / order date:</b> {{ $order->order_date ?: $order->created_at }}</div>
                    <div class="mb-1"><b>Shipped:</b> {{ $order->shipped_date ?: '-' }}</div>
                    <div class="mb-1"><b>Out for delivery:</b> {{ $order->out_for_delivery_date ?: '-' }}</div>
                    <div class="mb-1"><b>Delivered:</b> {{ $order->delivery_date ?: '-' }}</div>
                    <div class="mb-1"><b>Invoice uploaded:</b> {{ $order->invoice_upload_date ?: '-' }}</div>
                    <div class="mb-1"><b>Window:</b> {{ $order->order_start ?: '-' }} → {{ $order->order_end ?: '-' }}</div>
                    <div class="mb-1"><b>Updated:</b> {{ $order->updated_at }}</div>
                    @if(!empty($order->is_admin_cancelled) || !empty($order->cancel_reason))
                        <div class="mb-1 text-danger"><b>Cancel:</b> {{ $order->cancel_reason ?: 'yes' }}</div>
                    @endif
                </div>
            </div>
        </div>

        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header py-2"><strong>Payout</strong></div>
                <div class="card-body small">
                    <div class="mb-1"><b>Paid:</b> {{ (int) $order->is_payout === 1 ? 'Yes' : 'No' }}</div>
                    <div class="mb-1"><b>Ready for payout:</b> {{ (int) $order->is_ready_for_payout === 1 ? 'Yes' : 'No' }}</div>
                    <div class="mb-1"><b>Payout requested:</b> {{ (int) $order->is_payout_requested === 1 ? 'Yes' : 'No' }}</div>
                    <div class="mb-1"><b>UTR / Transaction:</b> {{ $order->transaction_id ?: '-' }}</div>
                    <div class="mb-1"><b>Payout note:</b> {{ $order->payout_notes ?: '-' }}</div>
                    @if(!empty($order->transaction_file))
                        <div class="mb-1"><b>Txn file:</b> <a href="{{ asset($order->transaction_file) }}" target="_blank" rel="noopener">Open</a></div>
                    @endif
                </div>
            </div>
        </div>

        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header py-2"><strong>Proof files</strong></div>
                <div class="card-body small">
                    <div class="mb-1"><b>Invoice:</b>
                        @if(!empty($order->account_order_pdf))
                            <a href="{{ asset($order->account_order_pdf) }}" target="_blank" rel="noopener">Open</a>
                        @else
                            -
                        @endif
                    </div>
                    <div class="mb-1"><b>Order screenshot:</b>
                        @if(!empty($order->account_order_screenshot))
                            <a href="{{ asset($order->account_order_screenshot) }}" target="_blank" rel="noopener">Open</a>
                        @else
                            -
                        @endif
                    </div>
                    <div class="mb-1"><b>Payment screenshot:</b>
                        @if(!empty($order->payment_screenshot))
                            <a href="{{ asset($order->payment_screenshot) }}" target="_blank" rel="noopener">Open</a>
                        @else
                            -
                        @endif
                    </div>
                    <div class="mb-1"><b>Payment verified:</b> {{ (int) $order->is_payment_verified === 1 ? 'Yes' : 'No' }}</div>
                    <div class="mb-1"><b>Pine Lab:</b> {{ (int) $order->is_pine_lab_deal === 1 ? 'Yes' : 'No' }}</div>
                    <div class="mb-1"><b>Verification status:</b> {{ $order->verification_status ?: '-' }}</div>
                    @if(!empty($order->deal_image))
                        <div class="mt-2">
                            <img src="{{ asset($order->deal_image) }}" alt="" style="max-width:120px;border-radius:8px;border:1px solid #e4e8f1;">
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
