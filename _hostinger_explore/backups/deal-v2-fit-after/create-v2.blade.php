@extends('layouts.main_master')
@section('title')
    Mintzer | Create deal
@endsection
@section('content')
<style>
    body.v2-lock, body.v2-lock .layout-page, body.v2-lock .content-wrapper { overflow: hidden !important; }
    body.v2-lock .content-footer { display: none !important; }
    .v2-fit { height: calc(100vh - 78px); max-height: calc(100vh - 78px); overflow: hidden; display: flex; flex-direction: column; padding-top: 8px !important; padding-bottom: 8px !important; }
    .v2-fit form { flex: 1; min-height: 0; display: flex; }
    .v2 { flex: 1; min-height: 0; width: 100%; display: grid; grid-template-columns: minmax(0, 1fr) minmax(220px, 280px); gap: 12px; }
    .v2-side { min-height: 0; display: flex; flex-direction: column; }
    .v2-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
    .v2-head h4 { margin: 0; font-size: 18px; }
    .v2-rail { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 6px; margin-bottom: 8px; }
    .v2-rail button { text-align: left; padding: 6px 10px; }
    .v2-rail button.on { background: #1c1915; color: #fff; }
    .v2-card { flex: 1; min-height: 0; overflow: hidden; background: #fff; border: 1px solid #e7e0d6; border-radius: 14px; padding: 10px 12px; display: flex; flex-direction: column; }
    .v2-fit .form-label { font-size: 11px; margin: 0 0 2px; }
    .v2-fit .form-control, .v2-fit .form-select { padding: 4px 8px; font-size: 13px; min-height: 32px; }
    .v2-note { color: #6d655c; font-size: 12px; }
    .v2-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 6px 10px; }
    .v2-span { grid-column: span 2; }
    .v2-actions { margin-top: auto; padding-top: 8px; }
    .v2-phone { min-height: 0; background: #111; border-radius: 22px; padding: 8px; }
    .v2-screen { background: #f8f9fa; border-radius: 16px; height: 100%; overflow: hidden; display: flex; flex-direction: column; }
    .v2-bar { background: #fff; display: flex; justify-content: space-between; padding: 6px 8px; font-size: 12px; }
    .v2-slides { display: flex; height: 28%; min-height: 90px; overflow-x: auto; scroll-snap-type: x mandatory; background: #fff; }
    .v2-slides img { flex: 0 0 100%; height: 100%; object-fit: contain; scroll-snap-align: center; }
    .v2-body { padding: 8px; overflow: hidden; }
    .v2-line { display: flex; justify-content: space-between; gap: 8px; font-size: 12px; line-height: 1.35; }
    .v2-earn { margin-top: 4px; background: #e6f4ea; border-radius: 8px; padding: 4px 8px; display: flex; justify-content: space-between; font-size: 12px; }
    .v2-gst { display: none; margin-top: 6px; background: #e0f2f1; color: #00796b; border-radius: 8px; padding: 4px 8px; font-size: 11px; }
    .v2-gst.on { display: block; }
</style>
<script>document.body.classList.add("v2-lock");</script>
<div class="container-xxl v2-fit">
    <div class="v2-head">
        <h4 class="fw-bold">Create deal <span class="text-muted fw-light">/ v2</span></h4>
        <a class="btn btn-sm btn-label-secondary" href="{{ route('deal-create', ['type' => 0]) }}">Old form</a>
    </div>
    @if ($errors->any())
        <div class="alert alert-danger">
            @foreach ($errors->all() as $error)
                <div>{{ $error }}</div>
            @endforeach
        </div>
    @endif
    <form id="dealV2" action="{{ route('deal-store') }}" method="POST" enctype="multipart/form-data">
        @csrf
        <input type="hidden" name="ddlDealID" value="">
        <input type="hidden" name="is_copy" value="0">
        <input type="hidden" name="deal_type" value="0">
        <input type="hidden" name="txtDealName" id="txtDealName" value="{{ old('txtDealName') }}">
        <input type="hidden" name="txtOfferLink2" value="">
        <input type="hidden" name="txtOfferLink3" value="">
        <input type="hidden" name="txtOfferText" value="">
        <input type="hidden" name="txtCouponCode" value="">
        <input type="hidden" name="txtInstruction" value="">
        <input type="hidden" name="txtExtraNotes" value="">
        <input type="hidden" name="txtGSTContent" value="">
        <input type="hidden" name="txtGSTMessage" value="">
        <input type="hidden" name="txtMaximumCount" value="">
        <div class="v2">
            <div class="v2-side">
                <div class="v2-rail">
                    <button type="button" data-step="0"><small>Part 1</small><br><b>Product</b></button>
                    <button type="button" data-step="1"><small>Part 2</small><br><b>Pricing</b></button>
                    <button type="button" data-step="2"><small>Part 3</small><br><b>GST</b></button>
                </div>
                <div class="v2-card">
                    <div data-part="0">
                        <label class="form-label">Product</label>
                        <div class="d-flex gap-2">
                            <select id="productPick" class="form-select"></select>
                            <button class="btn btn-dark" id="showAdd" type="button">Add</button>
                        </div>
                        <div id="fromLast" class="v2-note mt-2" style="display:none">From the last deal. The old deal is not changed.</div>
                        <div id="addBox" class="v2-3 mt-2" style="display:none">
                            <div><label class="form-label">Name</label><input id="newName" class="form-control" type="text"></div>
                            <div><label class="form-label">Photos</label><input id="newPhotos" class="form-control" type="file" accept="image/*" multiple></div>
                            <div><label class="form-label">Offer link</label><input id="newLink" class="form-control" type="url"></div>
                            <div><button class="btn btn-sm btn-label-primary" id="useNew" type="button">Use this product</button></div>
                        </div>
                        <div class="v2-3 mt-2">
                            <div>
                                <label class="form-label" for="txtcolor">Color</label>
                                <input class="form-control" id="txtcolor" name="txtcolor" value="{{ old('txtcolor') }}">
                            </div>
                            <div>
                                <label class="form-label" for="ddlStoreID">Store</label>
                                <select class="form-select" id="ddlStoreID" name="ddlStoreID">
                                    <option value="">Choose</option>
                                    @foreach ($stores as $store)
                                        <option value="{{ $store->id }}" {{ old('ddlStoreID') == $store->id ? 'selected' : '' }}>{{ $store->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div>
                                <label class="form-label" for="ddlBankCardId">Card</label>
                                <select class="form-select" id="ddlBankCardId" name="ddlBankCardId">
                                    <option value="">Choose</option>
                                    @foreach ($bankCards as $bankCard)
                                        <option value="{{ $bankCard->id }}" {{ old('ddlBankCardId') == $bankCard->id ? 'selected' : '' }}>{{ $bankCard->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div>
                                <label class="form-label" for="ddlDealerId">Dealer</label>
                                <select class="form-select" id="ddlDealerId" name="ddlDealerId[]">
                                    <option value="">Choose</option>
                                    @foreach ($dealers as $dealer)
                                        <option value="{{ $dealer->id }}" {{ old('ddlDealerId.0') == $dealer->id ? 'selected' : '' }}>{{ $dealer->display_name }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div>
                                <label class="form-label" for="txtOrderQty">Order qty</label>
                                <input class="form-control" id="txtOrderQty" name="txtOrderQty" type="number" value="{{ old('txtOrderQty') }}">
                            </div>
                            <div class="v2-span">
                                <label class="form-label" for="txtOfferLink1">Offer link</label>
                                <input class="form-control" id="txtOfferLink1" name="txtOfferLink1" type="url" value="{{ old('txtOfferLink1') }}">
                            </div>
                            <div class="v2-span">
                                <label class="form-label" for="deal_images">Photos for this deal</label>
                                <input class="form-control" id="deal_images" name="deal_images[]" type="file" accept="image/*" multiple>
                            </div>
                        </div>
                        <div class="v2-note mt-1" id="photoNote"></div>
                    </div>
                    <div data-part="1" style="display:none">
                        <div class="v2-3">
                            <div><label class="form-label">Dealer price</label><input class="form-control" id="txtDealerPrice" name="txtDealerPrice" type="number" step="0.01" value="{{ old('txtDealerPrice') }}"></div>
                            <div><label class="form-label">Discount</label><input class="form-control" id="txtDiscount" name="txtDiscount" type="number" step="0.01" value="{{ old('txtDiscount') }}"></div>
                            <div><label class="form-label">Platform fee</label><input class="form-control" id="txtPlatformFee" name="txtPlatformFee" type="number" step="0.01" value="{{ old('txtPlatformFee') }}"></div>
                            <div><label class="form-label">Card fee</label><input class="form-control" id="txtCardFee" name="txtCardFee" type="number" step="0.01" value="{{ old('txtCardFee') }}"></div>
                            <div><label class="form-label">Cashback</label><input class="form-control" id="txtCashback" name="txtCashback" type="number" step="0.01" value="{{ old('txtCashback') }}"></div>
                            <div><label class="form-label">Cash reward</label><input class="form-control" id="txtCashReward" name="txtCashReward" type="number" step="0.01" value="{{ old('txtCashReward') }}"></div>
                            <div><label class="form-label">Card holder will spend</label><input class="form-control" id="txtCardHolderSpend" name="txtCardHolderSpend" type="number" step="0.01" value="{{ old('txtCardHolderSpend') }}"></div>
                            <div><label class="form-label">Total card holder will receive</label><input class="form-control" id="txtTotalReceive" name="txtTotalReceive" type="number" step="0.01" value="{{ old('txtTotalReceive') }}"></div>
                            <div><label class="form-label">Card holder will earn</label><input class="form-control" id="txtCardHolderEarn" name="txtCardHolderEarn" type="number" step="0.01" value="{{ old('txtCardHolderEarn') }}"></div>
                        </div>
                    </div>
                    <div data-part="2" style="display:none">
                        <label class="form-label">GST</label>
                        <select id="gstPick" class="form-select"><option value="">Off</option></select>
                        <button class="btn btn-label-secondary mt-2" id="showGst" type="button">Add company</button>
                        <div id="gstAdd" class="v2-3 mt-2" style="display:none">
                            <div><label class="form-label">Company</label><input id="gstCo" class="form-control" type="text"></div>
                            <div><label class="form-label">GST number</label><input id="gstNo" class="form-control" type="text"></div>
                            <div><button class="btn btn-sm btn-label-primary" id="saveGst" type="button">Save</button></div>
                        </div>
                        <input type="hidden" name="txtCompanyName" id="txtCompanyName" value="{{ old('txtCompanyName') }}">
                        <input type="hidden" name="txtGSTNumber" id="txtGSTNumber" value="{{ old('txtGSTNumber') }}">
                        <div class="v2-note mt-2">Off leaves GST empty. On saves the company and GST number.</div>
                    </div>
                    <div class="d-flex justify-content-between v2-actions">
                        <button class="btn btn-label-secondary" id="v2Back" type="button">Back</button>
                        <button class="btn btn-dark" id="v2Next" type="button">Pricing</button>
                    </div>
                    <div class="text-danger mt-2" id="v2Msg"></div>
                </div>
            </div>
            <div class="v2-phone"><div class="v2-screen">
                <div class="v2-bar"><b>Deal detail</b><span>Anything wrong?</span></div>
                <div class="v2-slides" id="slides"></div>
                <div class="v2-body">
                    <div class="v2-line"><b id="phName">Pick a product</b><b id="phEarn">Earn</b></div>
                    <div class="v2-note" id="phColor"></div>
                    <div class="v2-line"><span>Buy on</span><b id="phStore">—</b></div>
                    <div class="v2-line"><span>Pay using</span><b id="phCard">—</b></div>
                    <div class="v2-line"><span>You pay</span><b id="phSpend">—</b></div>
                    <div class="v2-line"><span>Mintzer payout</span><b id="phReceive">—</b></div>
                    <div class="v2-earn"><b>You earn</b><b id="phEarn2">—</b></div>
                    <div class="v2-gst" id="phGst">GST invoice needed at checkout.</div>
                </div>
            </div></div>
        </div>
    </form>
</div>
@endsection
@section('footer')
<script src="{{ asset('assets/js/admin/masters/deal-create-v2.js?v=2') }}"></script>
@endsection
