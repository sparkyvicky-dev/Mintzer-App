@extends('layouts.main_master')
@section('content')
@section('title')
Mintzer | Business Settings
@endsection

<!-- Content -->
<div class="container-xxl flex-grow-1 container-p-y">
    <h4 class="fw-bold py-3 mb-4">Business Settings</h4>
    <?php

    use App\Models\BusinessSettings;

    $appNotes = BusinessSettings::where('key', 'appNotes')->first();
    $businessName = BusinessSettings::where('key', 'business_name')->first();
    $businessMobile = BusinessSettings::where('key', 'mobile')->first();
    $whatsappLink = BusinessSettings::where('key', 'whatsapp_link')->first();
    $whatsappGroupLink = BusinessSettings::where('key', 'whatsapp_group_link')->first();
    $telegramLink = BusinessSettings::where('key', 'telegram_link')->first();
    $youtubeLink = BusinessSettings::where('key', 'youtube_link')->first();
    $autoCancelOrderDuration = BusinessSettings::where('key', 'auto_cancel_order_duration')->first();
    $trackingReminderUpdateTime = BusinessSettings::where('key', 'tracking_reminder_update_time')->first();
    // $refferalLimit = BusinessSettings::where('key', 'refferal_limit')->first();
    $minWithdrawReqAmt = BusinessSettings::where('key', 'min_witdraw_request_amount')->first();
    // $pushNotificationKey = BusinessSettings::where('key', 'push_notification_key')->first();
    $dealYoutubeVideo = BusinessSettings::where('key', 'deal_youtube_video')->first();
    $tdsPercent = BusinessSettings::where('key', 'tds_percent')->first();
    $socialOn = BusinessSettings::where('key', 'home_social_proof_enabled')->first();
    $socialSource = BusinessSettings::where('key', 'home_social_proof_source')->first();
    $socialEarned = BusinessSettings::where('key', 'home_social_proof_earned')->first();
    $socialOrders = BusinessSettings::where('key', 'home_social_proof_orders')->first();
    $socialLive = \App\Http\Controllers\API\ConfigController::liveHomeLine();
    ?>

    <div class="card mb-4">
        <div class="card-body">
            <form action="{{ route('update-bussiness-settings') }}" method="POST">
                @csrf
                <div class="row">
                    <div class="col-4 mb-5">
                        <label for="businessName" class="form-label">Business Name </label>
                        <input type="text" class="form-control" id="business_name" name="business_name" required
                            value="{{ $businessName ? $businessName->value : '' }}" />
                    </div>
                    <div class="col-4 mb-3">
                        <label for="businessMobile" class="form-label">Mobile </label>
                        <input type="text" class="form-control" id="mobile" name="mobile" required
                            value="{{ $businessMobile ? $businessMobile->value : '' }}" />
                    </div>
                    <div class="col-4 mb-3">
                        <label for="whatsappLink" class="form-label">Whatsapp Link </label>
                        <input type="text" class="form-control" id="whatsapp_link" name="whatsapp_link" required
                            value="{{ $whatsappLink ? $whatsappLink->value : '' }}" />
                    </div>
                    <div class="col-4 mb-3">
                        <label for="whatsappGroupLink" class="form-label">Whatsapp Group Link </label>
                        <input type="text" class="form-control" id="whatsapp_group_link" name="whatsapp_group_link"
                            required value="{{ $whatsappGroupLink ? $whatsappGroupLink->value : '' }}" />
                    </div>
                    <div class="col-4 mb-5">
                        <label for="telegramLink" class="form-label">Telegram Link </label>
                        <input type="text" class="form-control" id="telegram_link" name="telegram_link" required
                            value="{{ $telegramLink ? $telegramLink->value : '' }}" />
                    </div>
                    <div class="col-4 mb-5">
                        <label for="youtubeLink" class="form-label">Youtube Link </label>
                        <input type="text" class="form-control" id="youtube_link" name="youtube_link" required
                            value="{{ $youtubeLink ? $youtubeLink->value : '' }}" />
                    </div>
                    {{-- <div class="col-4 mb-5">
                            <label for="refferalLimit" class="form-label">Refferal Limit </label>
                            <input type="text" class="form-control" id="refferal_limit" name="refferal_limit" required
                                value="{{ $refferalLimit ? $refferalLimit->value : '' }}" />
                </div> --}}
                <div class="col-4 mb-5">
                    <label for="minWithdrawReqAmt" class="form-label">Minimum Withdraw Request Amount </label>
                    <input type="text" class="form-control" id="min_witdraw_request_amount"
                        name="min_witdraw_request_amount" required
                        value="{{ $minWithdrawReqAmt ? $minWithdrawReqAmt->value : '' }}" />
                </div>
                <div class="col-4 mb-5">
                    <label for="autoCancelOrderDuration" class="form-label">Auto Cancel Order Duration
                        <span class="ms-1 text-secondary" data-bs-toggle="tooltip" data-bs-placement="top"
                            title="Value as a Minutes." style="cursor: help;">&#9432;</span>
                    </label>
                    <input type="text" class="form-control" id="auto_cancel_order_duration"
                        name="auto_cancel_order_duration" required
                        value="{{ $autoCancelOrderDuration ? $autoCancelOrderDuration->value : '' }}" />
                </div>
                <div class="col-4 mb-5">
                    <label for="trackingReminderUpdateTime" class="form-label">Tracking Update Reminder (Hrs)
                        <span class="ms-1 text-secondary" data-bs-toggle="tooltip" data-bs-placement="top"
                            title="The reminder sends after the given hours of order placement."
                            style="cursor: help;">&#9432;</span>
                    </label>
                    <input type="text" class="form-control" id="tracking_reminder_update_time"
                        name="tracking_reminder_update_time" required
                        value="{{ $trackingReminderUpdateTime ? $trackingReminderUpdateTime->value : '' }}" />
                </div>
                <div class="col-4 mb-5">
                    <label for="dealYoutubeVideo" class="form-label">Deal FAQ video link <span class="ms-1 text-secondary" data-bs-toggle="tooltip" data-bs-placement="top"
                            title="YouTube tutorial link for accepting a deal (shown on the deal detail page)."
                            style="cursor: help;">&#9432;</span></label>
                    <input type="text" class="form-control" id="deal_youtube_video" name="deal_youtube_video"
                        required value="{{ $dealYoutubeVideo ? $dealYoutubeVideo->value : '' }}" />
                </div>
                <div class="col-4 mb-5">
                    <label for="tdsPercent" class="form-label">TDS Percent
                        <span class="ms-1 text-secondary" data-bs-toggle="tooltip" data-bs-placement="top"
                            title="Value as a percent." style="cursor: help;">&#9432;</span>
                    </label>
                    <input type="text" class="form-control" id="tds_percent"
                        name="tds_percent" required
                        value="{{ $tdsPercent ? $tdsPercent->value : '' }}" />
                </div>
                <div class="col-12 mb-2">
                    <label class="form-label mb-0">Home line under the banners</label>
                    <div class="text-muted small">Off until you turn it on. Real orders right now: ₹{{ $socialLive['earned'] }} earned this week · {{ $socialLive['orders'] }} orders today. Cancelled orders are not counted. This week starts Monday. Empty typed boxes use these real numbers.</div>
                </div>
                <div class="col-4 mb-5">
                    <label for="home_social_proof_enabled" class="form-label">Show on Home</label>
                    <select class="form-control" id="home_social_proof_enabled" name="home_social_proof_enabled">
                        <option value="0" {{ ($socialOn && $socialOn->value === '1') ? '' : 'selected' }}>Off</option>
                        <option value="1" {{ ($socialOn && $socialOn->value === '1') ? 'selected' : '' }}>On</option>
                    </select>
                </div>
                <div class="col-4 mb-5">
                    <label for="home_social_proof_source" class="form-label">Numbers from</label>
                    <select class="form-control" id="home_social_proof_source" name="home_social_proof_source">
                        <option value="live" {{ ($socialSource && $socialSource->value === 'custom') ? '' : 'selected' }}>Real orders</option>
                        <option value="custom" {{ ($socialSource && $socialSource->value === 'custom') ? 'selected' : '' }}>Type my own</option>
                    </select>
                </div>
                <div class="col-4 mb-5">
                    <label for="home_social_proof_earned" class="form-label">Earned this week
                        <span class="ms-1 text-secondary" data-bs-toggle="tooltip" data-bs-placement="top"
                            title="Used only when Numbers from is Type my own. Example: 8.2L+" style="cursor: help;">&#9432;</span>
                    </label>
                    <input type="text" class="form-control" id="home_social_proof_earned" name="home_social_proof_earned"
                        placeholder="8.2L+" value="{{ $socialEarned ? $socialEarned->value : '' }}" />
                </div>
                <div class="col-4 mb-5">
                    <label for="home_social_proof_orders" class="form-label">Orders today</label>
                    <input type="text" class="form-control" id="home_social_proof_orders" name="home_social_proof_orders"
                        placeholder="42" value="{{ $socialOrders ? $socialOrders->value : '' }}" />
                </div>
        <div class="col-12">
        <button type="submit" class="btn btn-primary mt-3 float-end">Update</button>
    </div>
</div>
</form>

</div>
</div>



</div>
<!-- / Content -->

@endsection
@section('footer')
<script src="{{ asset('assets/js/dashboards-crm.js') }}"></script>
<script src="{{ asset('assets/js/admin/admindashboard/dashboard.js') }}"></script>
<script src="{{ asset('assets/js/admin/masters/bank.js') }}"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function(el) {
            return new bootstrap.Tooltip(el);
        });
    });
</script>
@endsection