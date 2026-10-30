@extends('layouts.main_master')
@section('title')
    Mintzer | Create deal
@endsection
@section('content')
<style>
    .v2 { display: grid; grid-template-columns: minmax(420px, 1fr) 320px; gap: 22px; align-items: start; }
    .v2-rail { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; margin: 12px 0; }
    .v2-rail button { text-align: left; }
    .v2-rail button.on { background: #1c1915; color: #fff; }
    .v2-card { background: #fff; border: 1px solid #e7e0d6; border-radius: 16px; padding: 16px; }
    .v2-note { color: #6d655c; font-size: 13px; }
    .v2-grid, .v2-pair { display: grid; grid-template-columns: 1fr 1fr; gap: 10px 12px; }
    .v2-wide { grid-column: 1 / -1; }
    .v2-phone { position: sticky; top: 12px; width: 320px; background: #111; border-radius: 28px; padding: 10px; }
    .v2-screen { background: #f8f9fa; border-radius: 20px; height: 640px; overflow: auto; }
    .v2-bar { position: sticky; top: 0; background: #fff; display: flex; justify-content: space-between; padding: 10px; font-size: 13px; }
    .v2-slides { display: flex; height: 200px; overflow-x: auto; scroll-snap-type: x mandatory; background: #fff; }
    .v2-slides img { flex: 0 0 100%; height: 200px; object-fit: contain; scroll-snap-align: center; }
    .v2-body { padding: 12px; }
    .v2-line, .v2-calc { display: flex; justify-content: space-between; gap: 8px; font-size: 13px; }
    .v2-earn { margin-top: 8px; background: #e6f4ea; border-radius: 10px; padding: 8px 10px; display: flex; justify-content: space-between; }
    .v2-gst { display: none; margin-top: 10px; background: #e0f2f1; color: #00796b; border-radius: 10px; padding: 8px 10px; font-size: 12px; }
    .v2-gst.on { display: block; }
    @media (max-width: 991px) { .v2 { grid-template-columns: 1fr; } .v2-phone { position: static; } }
</style>
<div class="container-xxl flex-grow-1 pt-2 pb-4">
    <div class="d-flex justify-content-between align-items-center">
        <h4 class="fw-bold py-3 mb-0">Create deal <span class="text-muted fw-light">/ v2</span></h4>
        <a class="btn btn-label-secondary" href="{{ route('deal-create', ['type' => 0]) }}">Old form</a>
    </div>
    <p class="v2-note mb-2">This does not change the old Create deal page. Edit and Copy stay on the old form.</p>
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
            <div>
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
                        <div id="addBox" class="mt-3" style="display:none">
                            <label class="form-label">Name</label>
                            <input id="newName" class="form-control" type="text">
                            <label class="form-label mt-2">Photos</label>
                            <input id="newPhotos" class="form-control" type="file" accept="image/*" multiple>
                            <label class="form-label mt-2">Offer link</label>
                            <input id="newLink" class="form-control" type="url">
                            <button class="btn btn-label-primary mt-2" id="useNew" type="button">Use this product</button>
                        </div>
                        <label class="form-label mt-3" for="txtcolor">Color</label>
                        <input class="form-control" id="txtcolor" name="txtcolor" value="{{ old('txtcolor') }}">
                        <div class="v2-pair mt-3">
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
                        </div>
                        <label class="form-label mt-3" for="txtOfferLink1">Offer link</label>
                        <input class="form-control" id="txtOfferLink1" name="txtOfferLink1" type="url" value="{{ old('txtOfferLink1') }}">
                        <label class="form-label mt-3" for="deal_images">Photos for this deal</label>
                        <input class="form-control" id="deal_images" name="deal_images[]" type="file" accept="image/*" multiple>
                        <div class="v2-note mt-1" id="photoNote"></div>
                    </div>
                    <div data-part="1" style="display:none">
                        <div class="v2-grid">
                            <div><label class="form-label">Dealer price</label><input class="form-control" id="txtDealerPrice" name="txtDealerPrice" type="number" step="0.01" value="{{ old('txtDealerPrice') }}"></div>
                            <div><label class="form-label">Discount</label><input class="form-control" id="txtDiscount" name="txtDiscount" type="number" step="0.01" value="{{ old('txtDiscount') }}"></div>
                            <div><label class="form-label">Platform fee</label><input class="form-control" id="txtPlatformFee" name="txtPlatformFee" type="number" step="0.01" value="{{ old('txtPlatformFee') }}"></div>
                            <div><label class="form-label">Card fee</label><input class="form-control" id="txtCardFee" name="txtCardFee" type="number" step="0.01" value="{{ old('txtCardFee') }}"></div>
                            <div><label class="form-label">Cashback</label><input class="form-control" id="txtCashback" name="txtCashback" type="number" step="0.01" value="{{ old('txtCashback') }}"></div>
                            <div><label class="form-label">Cash reward</label><input class="form-control" id="txtCashReward" name="txtCashReward" type="number" step="0.01" value="{{ old('txtCashReward') }}"></div>
                            <div class="v2-wide"><label class="form-label">Card holder will spend</label><input class="form-control" id="txtCardHolderSpend" name="txtCardHolderSpend" type="number" step="0.01" value="{{ old('txtCardHolderSpend') }}"></div>
                            <div class="v2-wide"><label class="form-label">Total card holder will receive</label><input class="form-control" id="txtTotalReceive" name="txtTotalReceive" type="number" step="0.01" value="{{ old('txtTotalReceive') }}"></div>
                            <div class="v2-wide"><label class="form-label">Card holder will earn</label><input class="form-control" id="txtCardHolderEarn" name="txtCardHolderEarn" type="number" step="0.01" value="{{ old('txtCardHolderEarn') }}"></div>
                        </div>
                    </div>
                    <div data-part="2" style="display:none">
                        <label class="form-label">GST</label>
                        <select id="gstPick" class="form-select"><option value="">Off</option></select>
                        <button class="btn btn-label-secondary mt-2" id="showGst" type="button">Add company</button>
                        <div id="gstAdd" class="mt-2" style="display:none">
                            <label class="form-label">Company</label>
                            <input id="gstCo" class="form-control" type="text">
                            <label class="form-label mt-2">GST number</label>
                            <input id="gstNo" class="form-control" type="text">
                            <button class="btn btn-label-primary mt-2" id="saveGst" type="button">Save</button>
                        </div>
                        <input type="hidden" name="txtCompanyName" id="txtCompanyName" value="{{ old('txtCompanyName') }}">
                        <input type="hidden" name="txtGSTNumber" id="txtGSTNumber" value="{{ old('txtGSTNumber') }}">
                        <div class="v2-note mt-2">Off leaves GST empty. On saves the company and GST number.</div>
                    </div>
                    <div class="d-flex justify-content-between mt-3">
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
                    <div class="v2-gst" id="phGst">GST invoice needed. At checkout, enter the Company and GST No. shown in the delivery address.</div>
                </div>
            </div></div>
        </div>
    </form>
</div>
@endsection
@section('footer')
<script src="{{ asset('assets/js/admin/masters/deal-create-v2.js?v=1') }}"></script>
@endsection
