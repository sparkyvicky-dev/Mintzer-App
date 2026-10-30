@extends('layouts.main_master')
@section('title')
    Mintzer | Create deal
@endsection
@section('content')
<style>
    body.v2-lock, body.v2-lock .layout-page, body.v2-lock .content-wrapper { overflow: hidden !important; }
    body.v2-lock .content-footer { display: none !important; }
    .v2-fit { height: calc(100vh - 78px); max-height: calc(100vh - 78px); overflow: hidden; display: flex; flex-direction: column; padding-top: 6px !important; padding-bottom: 6px !important; }
    .v2-fit form { flex: 1; min-height: 0; display: flex; }
    .v2 { flex: 1; min-height: 0; width: 100%; display: grid; grid-template-columns: minmax(0, 1fr) minmax(220px, 270px); gap: 12px; }
    .v2-side { min-height: 0; display: flex; flex-direction: column; overflow: visible; }
    .v2-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
    .v2-head h4 { margin: 0; font-size: 18px; }
    .v2-pill { font-size: 11px; font-weight: 600; color: #7B61FF; background: #f3efff; border-radius: 999px; padding: 2px 8px; margin-left: 6px; vertical-align: 2px; }
    .v2-rail { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 4px; margin-bottom: 8px; background: #fff; border: 1px solid #ece7f5; border-radius: 12px; padding: 4px; }
    .v2-rail button { border: 0; background: transparent; border-radius: 9px; text-align: left; padding: 7px 10px; color: #5c5668; font-size: 13px; font-weight: 600; }
    .v2-rail button span { display: inline-grid; place-items: center; width: 18px; height: 18px; margin-right: 6px; border-radius: 50%; background: #efeaff; color: #7B61FF; font-size: 11px; }
    .v2-rail button.on { background: #7B61FF; color: #fff; }
    .v2-rail button.on span { background: rgba(255,255,255,.24); color: #fff; }
    .v2-card { flex: 1; min-height: 0; overflow: visible; background: #fff; border: 1px solid #ece7f5; border-radius: 16px; padding: 12px 14px; display: flex; flex-direction: column; box-shadow: 0 8px 24px rgba(40, 24, 80, .04); }
    .v2-fit .form-label { font-size: 11px; font-weight: 600; color: #6d6578; margin: 0 0 3px; }
    .v2-fit .form-control, .v2-fit .form-select { padding: 4px 8px; font-size: 13px; min-height: 34px; border-radius: 8px; border-color: #e4dff0; }
    .v2-fit .form-control:focus { border-color: #7B61FF; box-shadow: 0 0 0 3px rgba(123, 97, 255, .16); }
    .v2-note { color: #6d655c; font-size: 12px; line-height: 1.35; }
    .v2-3 { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px 10px; }
    .v2-span { grid-column: span 2; }
    .v2-actions { margin-top: auto; padding-top: 8px; }
    .v2-actions .btn-dark { background: #7B61FF; border-color: #7B61FF; }
    .v2-combo { position: relative; }
    .v2-suggest { position: absolute; z-index: 40; left: 0; right: 0; top: calc(100% + 4px); background: #fff; border: 1px solid #ece7f5; border-radius: 10px; box-shadow: 0 10px 28px rgba(40, 24, 80, .12); max-height: 220px; overflow: auto; }
    .v2-suggest.up { top: auto; bottom: calc(100% + 4px); }
    .v2-suggest button { display: block; width: 100%; text-align: left; background: #fff; border: 0; padding: 7px 10px; font-size: 13px; color: #1c1915; }
    .v2-suggest button.on, .v2-suggest button:hover { background: #f6f3ff; }
    .v2-suggest button.v2-add { color: #7B61FF; font-weight: 600; }
    .v2-empty { padding: 7px 10px; color: #8a8496; font-size: 12px; }
    .v2-native { position: absolute !important; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); border: 0; }
    .v2-colors { display: none; gap: 6px; align-items: center; margin-top: 8px; overflow-x: auto; }
    .v2-colors-label { font-size: 11px; font-weight: 600; color: #6d6578; flex: 0 0 auto; }
    .v2-colors button { border: 1px solid #e4dff0; background: #fff; color: #1c1915; border-radius: 999px; padding: 3px 10px; font-size: 12px; white-space: nowrap; }
    .v2-colors button.on { background: #7B61FF; border-color: #7B61FF; color: #fff; }
    .v2-photos { margin-top: 8px; }
    .v2-photo-row { display: flex; align-items: center; gap: 8px; }
    .v2-thumbs { display: flex; gap: 6px; min-width: 0; overflow-x: auto; }
    .v2-shot { position: relative; width: 52px; height: 52px; flex: 0 0 52px; border-radius: 10px; overflow: hidden; border: 1px solid #e4dff0; background: #faf8ff; cursor: pointer; }
    .v2-shot img { width: 100%; height: 100%; object-fit: cover; display: block; }
    .v2-shot.main { border-color: #7B61FF; }
    .v2-shot .tag { position: absolute; left: 0; bottom: 0; background: #7B61FF; color: #fff; font-size: 9px; line-height: 1; padding: 2px 4px; }
    .v2-x { position: absolute; top: 0; right: 0; width: 16px; height: 16px; border: 0; background: #1c1915; color: #fff; font-size: 12px; line-height: 14px; padding: 0; }
    .v2-plus { width: 52px; height: 52px; flex: 0 0 52px; border-radius: 10px; border: 1px dashed #c9bee8; background: #faf8ff; color: #7B61FF; display: grid; place-items: center; font-size: 22px; line-height: 1; cursor: pointer; margin: 0; }
    .v2-key input { background: #faf8ff; border-color: #ddd4ff; }
    .v2-phone { min-height: 0; background: #16141c; border-radius: 24px; padding: 8px; box-shadow: 0 10px 24px rgba(22, 20, 28, .18); }
    .v2-screen { background: #f6f5f8; border-radius: 18px; height: 100%; overflow: hidden; display: flex; flex-direction: column; }
    .v2-bar { background: #fff; display: flex; justify-content: space-between; align-items: center; padding: 7px 10px; font-size: 12px; }
    .v2-slides { position: relative; display: flex; height: 30%; min-height: 96px; overflow-x: auto; scroll-snap-type: x mandatory; background: #fff; }
    .v2-slides img { flex: 0 0 100%; height: 100%; object-fit: contain; scroll-snap-align: center; }
    .v2-empty-slide { flex: 0 0 100%; height: 100%; display: grid; place-items: center; color: #8a8496; font-size: 12px; }
    .v2-body { padding: 8px 10px; overflow: hidden; }
    .v2-line { display: flex; justify-content: space-between; gap: 8px; font-size: 12px; line-height: 1.4; }
    .v2-earn { margin-top: 4px; background: #e6f4ea; border-radius: 8px; padding: 5px 8px; display: flex; justify-content: space-between; font-size: 12px; }
    .v2-gst { display: none; margin-top: 6px; background: #e0f2f1; color: #00796b; border-radius: 8px; padding: 4px 8px; font-size: 11px; }
    .v2-gst.on { display: block; }
</style>
<script>document.body.classList.add("v2-lock");</script>
<div class="container-xxl v2-fit">
    <div class="v2-head">
        <h4 class="fw-bold">Create deal <span class="v2-pill">v3</span></h4>
        <a class="btn btn-sm btn-label-secondary" href="{{ route('deal-create', ['type' => 0]) }}">Old form</a>
    </div>
    @if ($errors->any())
        <div class="alert alert-danger py-1 mb-1">
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
        <input class="v2-native" id="deal_images" name="deal_images[]" type="file" accept="image/*" multiple>
        <div class="v2">
            <div class="v2-side">
                <div class="v2-rail">
                    <button type="button" data-step="0"><span>1</span>Product</button>
                    <button type="button" data-step="1"><span>2</span>Pricing</button>
                    <button type="button" data-step="2"><span>3</span>GST</button>
                </div>
                <div class="v2-card">
                    <div data-part="0">
                        <label class="form-label" for="productSearch">Product</label>
                        <div class="d-flex gap-2">
                            <div class="v2-combo flex-grow-1">
                                <input class="form-control" id="productSearch" data-combo="productPick" type="text" placeholder="Type a product" autocomplete="off" spellcheck="false">
                                <div class="v2-suggest" hidden></div>
                                <select id="productPick" class="v2-native"></select>
                            </div>
                            <button class="btn btn-label-primary" id="showAdd" type="button">Add</button>
                        </div>
                        <div id="fromLast" class="v2-note mt-1" style="display:none">From the last deal. The old deal is not changed.</div>
                        <div id="addBox" class="v2-3 mt-2" style="display:none">
                            <div><label class="form-label">Name</label><input id="newName" class="form-control" type="text" autocomplete="off"></div>
                            <div><label class="form-label">Photos</label><input id="newPhotos" class="form-control" type="file" accept="image/*" multiple></div>
                            <div><label class="form-label">Offer link</label><input id="newLink" class="form-control" type="url"></div>
                            <div><button class="btn btn-sm btn-label-primary" id="useNew" type="button">Use this product</button></div>
                        </div>
                        <div class="v2-3 mt-2">
                            <div>
                                <label class="form-label" for="txtcolor">Color</label>
                                <input class="form-control" id="txtcolor" name="txtcolor" value="{{ old('txtcolor') }}" autocomplete="off">
                            </div>
                            <div>
                                <label class="form-label" for="storeSearch">Store</label>
                                <div class="v2-combo">
                                    <input class="form-control" id="storeSearch" data-combo="ddlStoreID" type="text" placeholder="Type a store" autocomplete="off" spellcheck="false">
                                    <div class="v2-suggest" hidden></div>
                                    <select class="v2-native" id="ddlStoreID" name="ddlStoreID">
                                        <option value="">Choose</option>
                                        @foreach ($stores as $store)
                                            <option value="{{ $store->id }}" {{ old('ddlStoreID') == $store->id ? 'selected' : '' }}>{{ $store->name }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label class="form-label" for="cardSearch">Card</label>
                                <div class="v2-combo">
                                    <input class="form-control" id="cardSearch" data-combo="ddlBankCardId" type="text" placeholder="Type a card" autocomplete="off" spellcheck="false">
                                    <div class="v2-suggest" hidden></div>
                                    <select class="v2-native" id="ddlBankCardId" name="ddlBankCardId">
                                        <option value="">Choose</option>
                                        @foreach ($bankCards as $bankCard)
                                            <option value="{{ $bankCard->id }}" {{ old('ddlBankCardId') == $bankCard->id ? 'selected' : '' }}>{{ $bankCard->name }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label class="form-label" for="dealerSearch">Dealer</label>
                                <div class="v2-combo">
                                    <input class="form-control" id="dealerSearch" data-combo="ddlDealerId" type="text" placeholder="Type a dealer" autocomplete="off" spellcheck="false">
                                    <div class="v2-suggest" hidden></div>
                                    <select class="v2-native" id="ddlDealerId" name="ddlDealerId[]">
                                        <option value="">Choose</option>
                                        @foreach ($dealers as $dealer)
                                            <option value="{{ $dealer->id }}" {{ old('ddlDealerId.0') == $dealer->id ? 'selected' : '' }}>{{ $dealer->display_name }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label class="form-label" for="txtOrderQty">Order qty</label>
                                <input class="form-control" id="txtOrderQty" name="txtOrderQty" type="number" value="{{ old('txtOrderQty') }}">
                            </div>
                            <div class="v2-span">
                                <label class="form-label" for="txtOfferLink1">Offer link</label>
                                <input class="form-control" id="txtOfferLink1" name="txtOfferLink1" type="url" placeholder="For ordering" value="{{ old('txtOfferLink1') }}">
                            </div>
                        </div>
                        <div class="v2-photos">
                            <label class="form-label" for="photoLink">Photo link</label>
                            <input class="form-control" id="photoLink" type="url" placeholder="Paste a Flipkart, Amazon, or iQOO link to get photos" autocomplete="off">
                            <label class="form-label mt-2">Photos</label>
                            <div class="v2-photo-row">
                                <div class="v2-thumbs" id="thumbs"></div>
                                <label class="v2-plus" title="Add photo">+<input id="addPhoto" type="file" accept="image/*" multiple hidden></label>
                            </div>
                            <div class="v2-note mt-1" id="photoNote">Choose a product. Its photos come with it.</div>
                        </div>
                    </div>
                    <div data-part="1" style="display:none">
                        <div class="v2-3">
                            <div><label class="form-label">Dealer price</label><input class="form-control" id="txtDealerPrice" name="txtDealerPrice" type="number" step="0.01" value="{{ old('txtDealerPrice') }}"></div>
                            <div><label class="form-label">Discount</label><input class="form-control" id="txtDiscount" name="txtDiscount" type="number" step="0.01" value="{{ old('txtDiscount') }}"></div>
                            <div><label class="form-label">Platform fee</label><input class="form-control" id="txtPlatformFee" name="txtPlatformFee" type="number" step="0.01" value="{{ old('txtPlatformFee') }}"></div>
                            <div><label class="form-label">Card fee</label><input class="form-control" id="txtCardFee" name="txtCardFee" type="number" step="0.01" value="{{ old('txtCardFee') }}"></div>
                            <div><label class="form-label">Cashback</label><input class="form-control" id="txtCashback" name="txtCashback" type="number" step="0.01" value="{{ old('txtCashback') }}"></div>
                            <div><label class="form-label">Cash reward</label><input class="form-control" id="txtCashReward" name="txtCashReward" type="number" step="0.01" value="{{ old('txtCashReward') }}"></div>
                            <div class="v2-key"><label class="form-label">Card holder will spend</label><input class="form-control" id="txtCardHolderSpend" name="txtCardHolderSpend" type="number" step="0.01" value="{{ old('txtCardHolderSpend') }}"></div>
                            <div class="v2-key"><label class="form-label">Total card holder will receive</label><input class="form-control" id="txtTotalReceive" name="txtTotalReceive" type="number" step="0.01" value="{{ old('txtTotalReceive') }}"></div>
                            <div class="v2-key"><label class="form-label">Card holder will earn</label><input class="form-control" id="txtCardHolderEarn" name="txtCardHolderEarn" type="number" step="0.01" value="{{ old('txtCardHolderEarn') }}"></div>
                        </div>
                    </div>
                    <div data-part="2" style="display:none">
                        <label class="form-label" for="gstSearch">Saved company</label>
                        <div class="v2-combo">
                            <input class="form-control" id="gstSearch" data-combo="gstPick" type="text" placeholder="Off, or pick a company" autocomplete="off" spellcheck="false">
                            <div class="v2-suggest" hidden></div>
                            <select id="gstPick" class="v2-native"><option value="">Off</option></select>
                        </div>
                        <div class="v2-3 mt-2">
                            <div class="v2-span"><label class="form-label" for="txtCompanyName">Company name</label><input class="form-control" name="txtCompanyName" id="txtCompanyName" value="{{ old('txtCompanyName') }}" autocomplete="off"></div>
                            <div><label class="form-label" for="txtGSTNumber">GST number</label><input class="form-control" name="txtGSTNumber" id="txtGSTNumber" value="{{ old('txtGSTNumber') }}" autocomplete="off"></div>
                        </div>
                        <button class="btn btn-label-primary mt-2" id="saveGst" type="button">Save company</button>
                        <div class="v2-note mt-2">Off leaves both empty. The app only says a GST invoice is needed.</div>
                    </div>
                    <div class="d-flex justify-content-between v2-actions">
                        <button class="btn btn-label-secondary" id="v2Back" type="button">Back</button>
                        <button class="btn btn-dark" id="v2Next" type="button">Pricing</button>
                    </div>
                    <div class="text-danger mt-1" id="v2Msg"></div>
                </div>
            </div>
            <div class="v2-phone"><div class="v2-screen">
                <div class="v2-bar"><b>Deal detail</b><span id="phCount"></span></div>
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
<script src="{{ asset('assets/js/admin/masters/deal-create-v3.js?v=7') }}"></script>
@endsection
