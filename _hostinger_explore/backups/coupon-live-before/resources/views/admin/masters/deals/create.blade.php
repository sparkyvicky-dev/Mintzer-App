@extends('layouts.main_master')
@section('content')
@section('title')
    Mintzer | Deal
@endsection
@php
    $formMode = $formMode ?? 'create';
    $deal = $deal ?? null;
    $isEdit = $formMode === 'edit';
    $isCopy = $formMode === 'copy';
    $pageAction = $isEdit ? 'Update' : ($isCopy ? 'Copy' : 'Create');
    $selectedDealerIds = old('ddlDealerId', $isCopy && $deal ? [$deal->dealer_id] : ($isEdit && $deal ? $deal->dealer_id : []));
    if (!is_array($selectedDealerIds)) {
        $selectedDealerIds = [$selectedDealerIds];
    }
@endphp
<style>
    .container-xxl .card {
        border: 1px solid #eceff5;
        border-radius: 10px;
        box-shadow: 0 1px 2px rgba(16, 24, 40, 0.04);
    }
    .container-xxl .card-header {
        background: #f9faff;
        border-bottom: 1px solid #eceff5;
        font-weight: 600;
        font-size: 13px;
        color: #37405f;
        padding: 10px 14px;
    }
    .container-xxl .card-body {
        padding: 12px 14px;
    }
    .container-xxl .form-label {
        font-size: 12px;
        font-weight: 600;
        color: #4b5578;
        margin-bottom: 6px;
    }
    .container-xxl .form-control,
    .container-xxl .form-select {
        min-height: 38px;
        font-size: 13px;
        border-color: #dce1ee;
    }
    .container-xxl textarea.form-control {
        min-height: 44px;
        line-height: 1.4;
    }
    .container-xxl .mb-3 {
        margin-bottom: 10px !important;
    }
    .container-xxl .select2-container .select2-selection--single,
    .container-xxl .select2-container .select2-selection--multiple {
        min-height: 38px !important;
        border-color: #dce1ee !important;
    }
    .container-xxl .select2-container .select2-selection--single .select2-selection__rendered {
        line-height: 36px !important;
    }
    .container-xxl .select2-container .select2-selection--single .select2-selection__arrow {
        height: 36px !important;
    }
    .deal-helper-row {
        display: flex;
        align-items: center;
        gap: 8px;
        flex-wrap: wrap;
        margin-top: 6px;
        margin-bottom: 6px;
    }
    .deal-helper-row .form-control-sm,
    .deal-helper-row .form-select-sm,
    .deal-helper-row .btn-sm {
        height: 30px;
        padding-top: 4px;
        padding-bottom: 4px;
    }
    .deal-helper-chip {
        border: 1px solid #d9dcec;
        background: #f7f8ff;
        color: #464d6e;
        border-radius: 999px;
        font-size: 12px;
        padding: 4px 10px;
        cursor: pointer;
    }
    .deal-helper-chip:hover {
        background: #ecefff;
        border-color: #bbc4ff;
        color: #2c3c92;
    }
    .deal-helper-select {
        max-width: 260px;
        min-width: 220px;
        flex: 1 1 220px;
    }
    .deal-resizable-textarea {
        resize: vertical;
        min-height: 120px;
    }
    #gstProfileSelect {
        flex: 1 1 280px;
        min-width: 280px;
        max-width: 100%;
    }
    #deleteGstPair {
        width: 30px;
        min-width: 30px;
        padding-left: 0;
        padding-right: 0;
    }
    #gstAddPanel {
        width: 100%;
    }
    #gstAddPanel #newGstCompanyName,
    #gstAddPanel #newGstNumber {
        flex: 1 1 220px;
        min-width: 180px;
        max-width: 100%;
    }
    #instructionTemplateSelect {
        flex: 1 1 260px;
        min-width: 220px;
    }
    #saveInstructionTemplate {
        white-space: nowrap;
    }
    #txtInstruction,
    #txtExtraNotes {
        min-height: 150px;
    }
    .deal-helper-chip {
        font-size: 11px;
        padding: 4px 9px;
    }
    .demo-inline-spacing.float-end {
        display: flex;
        align-items: center;
        gap: 8px;
        margin-top: 0 !important;
    }
    .demo-inline-spacing.float-end > .btn {
        height: 36px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 0 14px;
    }
    .demo-inline-spacing.float-end > .btn > a {
        display: inline-flex;
        align-items: center;
        height: 100%;
    }
</style>

<!-- Content -->
<div class="container-xxl flex-grow-1 pt-2 pb-2">
    <h4 class="fw-bold py-3 mb-4">{{ $type == 1 ? 'PineLab' : '' }} Deal<span class="text-muted fw-light"> /{{ $pageAction }}</span></h4>
    <form action="{{ route('deal-store') }}" method="POST" enctype="multipart/form-data" name="deal_form">
        @csrf
        <input type="hidden" name="ddlDealID" value="{{ $isEdit && $deal ? $deal->id : '' }}">
        <input type="hidden" name="is_copy" id="is_copy" value="{{ $isCopy ? 1 : 0 }}">
        <input type="hidden" id="deal_form_mode" value="{{ $formMode }}">
        <input type="hidden" id="deal_list_url" value="{{ route('deals') }}">
        <input type="hidden" name="deal_type" value="{{ $type }}">
        <div class="card mb-4">
            <div class="card-header">
                <div class="row">
                    <div class="col-10">Deal</div>
                    @if (!$isEdit)
                    <div class="col-2">
                        <label class="switch" id="allDealer">
                            <input type="checkbox" class="switch-input" name="allDealer" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on"></span>
                                <span class="switch-off"></span>
                            </span>
                            <span class="switch-label">All Dealer</span>
                        </label>
                    </div>
                    @endif
                </div>

            </div>
            <div class="card-body">
                <div class="row">
                    @if ($type == 0)
                        <div class="col-4 mb-3">
                            <label for="ddlStore" class="form-label">Store <span class="text-danger">*</span></label>
                            <select class="select2 form-select form-select-lg" id="ddlStoreID" name="ddlStoreID">
                                <option value="">Select Store</option>
                                {{-- Loop through your stores data --}}
                                @foreach ($stores as $store)
                                    <option value="{{ $store->id }}"
                                        {{ old('ddlStoreID', $deal->store_id ?? null) == $store->id ? 'selected' : '' }}>{{ $store->name }}
                                    </option>
                                @endforeach
                            </select>
                            @error('ddlStoreID')
                                <span class="text-danger">{{ $errors->first('ddlStoreID') }}</span>
                            @enderror
                            <span class="error" id="ddlStoreID_error"></span>

                        </div>
                    @endif
                    <div class="col-4 mb-3">
                        <label for="ddlDealerId" class="form-label">Dealers <span class="text-danger">*</span></label>
                        <select class="select2 form-select form-select-lg" id="ddlDealerId"
                            name="{{ $isEdit ? 'ddlDealerId' : 'ddlDealerId[]' }}" {{ $isEdit ? '' : 'multiple' }}>
                            @foreach ($dealers as $dealer)
                                <option value="{{ $dealer->id }}"
                                    {{ in_array($dealer->id, $selectedDealerIds) ? 'selected' : '' }}
                                    title="Total: {{ $dealer->total_addresses ?? 0 }}, Used: {{ $dealer->used_addresses ?? 0 }}, Left: {{ $dealer->left_addresses ?? 0 }}">
                                    {{ $dealer->display_name }} (Left: {{ $dealer->left_addresses ?? 0 }})
                                </option>
                            @endforeach
                        </select>
                        @error('ddlDealerId')
                            <span class="text-danger">{{ $errors->first('ddlDealerId') }}</span>
                        @enderror
                        <span class="error" id="ddlDealerId_error"></span>

                    </div>
                    @if ($type == 0)
                        <div class="col-4 mb-3">
                            <label for="ddlBankCardId" class="form-label">Bank Card <span
                                    class="text-danger">*</span></label>
                            <select class="select2 form-select form-select-lg" id="ddlBankCardId" name="ddlBankCardId">
                                <option value="">Select Bank Card</option>
                                {{-- Loop through your bank cards data --}}
                                @foreach ($bankCards as $bankCard)
                                    <option value="{{ $bankCard->id }}"
                                        {{ old('ddlBankCardId', $deal->bank_card_id ?? null) == $bankCard->id ? 'selected' : '' }}>
                                        {{ $bankCard->name }}</option>
                                @endforeach
                            </select>
                            @error('ddlBankCardId')
                                <span class="text-danger">{{ $errors->first('ddlBankCardId') }}</span>
                            @enderror
                            <span class="error" id="ddlBankCardId_error"></span>
                        </div>
                    @endif
                    <div class="col-4 mb-3">
                        <label for="txtDealName" class="form-label">Name <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="txtDealName" name="txtDealName" required
                            autocomplete="off" value="{{ old('txtDealName', $deal->name ?? '') }}" />
                        @error('txtDealName')
                            <span class="text-danger">{{ $errors->first('txtDealName') }}</span>
                        @enderror
                        <span class="error" id="txtDealName_error"></span>
                        <!-- Search suggestions container -->
                        <div id="dealSuggestions" class="list-group position-relative"
                            style="z-index:9999; display:none;
                             max-height:220px; overflow:auto; margin-top:6px;">
                        </div>
                    </div>
                    @if ($type == 0)
                        <div class="col-4 mb-3">
                            <label for="txtcolor" class="form-label">Color <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="txtcolor" name="txtcolor" required
                                value="{{ old('txtcolor', $deal->color ?? '') }}" />
                            @error('txtcolor')
                                <span class="text-danger">{{ $errors->first('txtcolor') }}</span>
                            @enderror
                            <span class="error" id="txtcolor_error"></span>
                        </div>
                        {{-- <div class="col-8 mb-3">
                        <label for="txtDiscription" class="form-label">Description <span
                                class="text-danger">*</span></label>
                        <textarea type="text" rows="1" class="form-control" id="txtDiscription" name="txtDiscription" required>{{ old('txtDiscription') }}</textarea>
                        @error('txtDiscription')
                            <span class="text-danger">{{ $errors->first('txtDiscription') }}</span>
                        @enderror
                        <span class="error" id="txtDiscription_error"></span>
                    </div> --}}
                        <div class="col-4 mb-3">
                            <label for="txtOrderQty" class="form-label">Order Quantity <span
                                    class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="txtOrderQty" name="txtOrderQty" required
                                value="{{ old('txtOrderQty', $deal->order_qty ?? '') }}" />
                            @error('txtOrderQty')
                                <span class="text-danger">{{ $errors->first('txtOrderQty') }}</span>
                            @enderror
                            <span class="error" id="txtOrderQty_error"></span>
                        </div>
                    @endif
                    <div class="col-4 mb-3">
                        <label for="deal_images" class="form-label">
                            Images <span class="text-danger">*</span>
                        </label>

                        <!-- File Input -->
                        <input type="file" class="form-control " id="deal_images" name="deal_images[]" multiple
                            accept="image/*">

                        @error('deal_images')
                            <span class="text-danger d-block mt-1">{{ $message }}</span>
                        @enderror
                        @error('deal_images.*')
                            <span class="text-danger d-block mt-1">{{ $message }}</span>
                        @enderror
                        <span class="error d-block mt-1" id="deal_images_error"></span>

                        <!-- Live Preview Container -->
                        <div id="image-preview-container" class="mt-3">
                            <!-- suggestion images (existing deal images) -->
                            <div class="row g-3" id="suggestion-image-preview">
                                @if ($deal && ($isEdit || $isCopy))
                                    @if ($deal->image)
                                        <div class="col-4 col-md-3 position-relative mb-3 existing-image-item">
                                            <div class="border rounded overflow-hidden position-relative">
                                                <img src="{{ asset($deal->image) }}" class="img-fluid"
                                                    style="height:100px;width:100px;object-fit:cover;">
                                                <button type="button"
                                                    class="btn btn-danger btn-sm position-absolute top-0 end-0 rounded-circle d-flex align-items-center justify-content-center remove-existing-image"
                                                    style="width:28px;height:28px;font-size:16px;z-index:10;">&times;</button>
                                            </div>
                                            <input type="hidden" name="keep_images[]" value="{{ $deal->image }}">
                                        </div>
                                    @endif
                                    @foreach ($deal->dealImages as $img)
                                        @if ($img->image !== $deal->image)
                                            <div class="col-4 col-md-3 position-relative mb-3 existing-image-item">
                                                <div class="border rounded overflow-hidden position-relative">
                                                    <img src="{{ asset($img->image) }}" class="img-fluid"
                                                        style="height:100px;width:100px;object-fit:cover;">
                                                    <button type="button"
                                                        class="btn btn-danger btn-sm position-absolute top-0 end-0 rounded-circle d-flex align-items-center justify-content-center remove-existing-image"
                                                        style="width:28px;height:28px;font-size:16px;z-index:10;">&times;</button>
                                                </div>
                                                <input type="hidden" name="keep_images[]" value="{{ $img->image }}">
                                            </div>
                                        @endif
                                    @endforeach
                                @endif
                            </div>
                            <!-- uploaded images (user selected files) -->
                            <div class="row g-3" id="uploaded-image-preview"></div>
                            <div id="keep-images-container"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        @if ($type == 0)
            <div class="card mb-4">
                <div class="card-header">Offers & Price</div>
                <div class="card-body">
                    <div class="row">
                        {{-- <div class="col-4 mb-3">
                        <label for="txtOfferTitle" class="form-label">Offer Title <span
                                class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="txtOfferTitle" name="txtOfferTitle" required
                            value="{{ old('txtOfferTitle') }}" />
                        @error('txtOfferTitle')
                            <span class="text-danger">{{ $errors->first('txtOfferTitle') }}</span>
                        @enderror
                        <span class="error" id="txtOfferTitle_error"></span>
                    </div> --}}
                        <div class="col-4 mb-3">
                            <label for="txtOfferText" class="form-label">Offer Text <span
                                    class="text-danger">*</span></label>
                            <textarea type="text" class="form-control" id="txtOfferText" name="txtOfferText" rows="1" required>{{ old('txtOfferText', $deal->offer_text ?? '') }}</textarea>
                            @error('txtOfferText')
                                <span class="text-danger">{{ $errors->first('txtOfferText') }}</span>
                            @enderror
                            <span class="error" id="txtOfferText_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtOfferLink1" class="form-label">Offer Link 1<span
                                    class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="txtOfferLink1" name="txtOfferLink1"
                                required value="{{ old('txtOfferLink1', $deal->offer_link1 ?? '') }}" />
                            @error('txtOfferLink1')
                                <span class="text-danger">{{ $errors->first('txtOfferLink1') }}</span>
                            @enderror
                            <span class="error" id="txtOfferLink1_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtOfferLink2" class="form-label">Offer Link 2</label>
                            <input type="text" class="form-control" id="txtOfferLink2" name="txtOfferLink2"
                                value="{{ old('txtOfferLink2', $deal->offer_link2 ?? '') }}" />
                            @error('txtOfferLink2')
                                <span class="text-danger">{{ $errors->first('txtOfferLink2') }}</span>
                            @enderror
                            <span class="error" id="txtOfferLink2_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtOfferLink3" class="form-label">Offer Link 3</label>
                            <input type="text" class="form-control" id="txtOfferLink3" name="txtOfferLink3"
                                value="{{ old('txtOfferLink3', $deal->offer_link3 ?? '') }}" />
                            @error('txtOfferLink3')
                                <span class="text-danger">{{ $errors->first('txtOfferLink3') }}</span>
                            @enderror
                            <span class="error" id="txtOfferLink3_error"></span>
                        </div>
                        @include('admin.masters.deals._popup_fields')
                        <div class="col-4 mb-3">
                            <label for="txtDealerPrice" class="form-label">Dealer price(Product price)<span
                                    class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="txtDealerPrice" name="txtDealerPrice"
                                required value="{{ old('txtDealerPrice', $deal->product_price ?? '') }}" />
                            @error('txtDealerPrice')
                                <span class="text-danger">{{ $errors->first('txtDealerPrice') }}</span>
                            @enderror
                            <span class="error" id="txtDealerPrice_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtDiscount" class="form-label">Discount
                                {{-- <span class="text-danger">*</span> <span class="badge bg-secondary">If no Discount, put value is 0.</span> --}}
                            </label>
                            <input type="number" class="form-control" id="txtDiscount" name="txtDiscount"
                                value="{{ old('txtDiscount', $deal->discount ?? 0) }}" />
                            @error('txtDiscount')
                                <span class="text-danger">{{ $errors->first('txtDiscount') }}</span>
                            @enderror
                            <span class="error" id="txtDiscount_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtCashReward" class="form-label">Cash Reward
                                {{-- <span class="text-danger">*</span> <span class="badge bg-secondary">If no Cash reward, put value is 0.</span> --}}
                            </label>
                            <input type="text" class="form-control" id="txtCashReward" name="txtCashReward"
                                value="{{ old('txtCashReward', $deal->cash_reward ?? 0) }}" />
                            @error('txtCashReward')
                                <span class="text-danger">{{ $errors->first('txtCashReward') }}</span>
                            @enderror
                            <span class="error" id="txtCashReward_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtCashback" class="form-label">Cashback
                                {{-- <span class="text-danger">*</span> <span class="badge bg-secondary">If no Cashback, put value is 0.</span>  --}}
                            </label>
                            <input type="number" class="form-control" name="txtCashback" id="txtCashback"
                                value="{{ old('txtCashback', $deal->cashback ?? 0) }}" />
                            @error('txtCashback')
                                <span class="text-danger">{{ $errors->first('txtCashback') }}</span>
                            @enderror
                            <span class="error" id="txtCashback_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtPlatformFee" class="form-label">Platform fee</label>
                            <input type="number" class="form-control" name="txtPlatformFee" id="txtPlatformFee"
                                step="0.01" min="0" value="{{ old('txtPlatformFee', $deal->platform_fee ?? 0) }}" />
                            @error('txtPlatformFee')
                                <span class="text-danger">{{ $errors->first('txtPlatformFee') }}</span>
                            @enderror
                            <span class="error" id="txtPlatformFee_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtCardFee" class="form-label">Card fee</label>
                            <input type="number" class="form-control" name="txtCardFee" id="txtCardFee"
                                step="0.01" min="0" value="{{ old('txtCardFee', $deal->card_fee ?? 0) }}" />
                            @error('txtCardFee')
                                <span class="text-danger">{{ $errors->first('txtCardFee') }}</span>
                            @enderror
                            <span class="error" id="txtCardFee_error"></span>
                        </div>
                        {{-- <div class="col-4 mb-3">
                        <label for="txtMaximumCount" class="form-label">Maximum Count</label>
                        <input type="text" class="form-control" name="txtMaximumCount" id="txtMaximumCount"
                            value="{{ old('txtMaximumCount') }}" />
                        @error('txtMaximumCount')
                            <span class="text-danger">{{ $errors->first('txtMaximumCount') }}</span>
                        @enderror
                        <span class="error" id="txtMaximumCount_error"></span>
                    </div> --}}
                    </div>
                </div>
            </div>
        @endif

        <div class="card mb-4">
            <div class="card-header">Card Details</div>
            <div class="card-body">
                <div class="row">
                    <div class="col-4 mb-3">
                        <label for="txtCardHolderSpend" class="form-label">Card holder will spend <span
                                class="text-danger">*</span></label>
                        <input type="number" class="form-control" id="txtCardHolderSpend" name="txtCardHolderSpend"
                            required step="0.01" min="0" value="{{ old('txtCardHolderSpend', $deal->card_holder_spend ?? '') }}" />
                        @error('txtCardHolderSpend')
                            <span class="text-danger">{{ $errors->first('txtCardHolderSpend') }}</span>
                        @enderror
                        <span class="error" id="txtCardHolderSpend_error"></span>
                    </div>
                    <div class="col-4 mb-3">
                        <label for="txtCardHolderEarn" class="form-label">Card holder will earn <span
                                class="text-danger">*</span></label>
                        <input type="number" class="form-control" id="txtCardHolderEarn" name="txtCardHolderEarn"
                            required step="0.01" min="0" value="{{ old('txtCardHolderEarn', $deal->card_holder_earn ?? '') }}" />
                        @error('txtCardHolderEarn')
                            <span class="text-danger">{{ $errors->first('txtCardHolderEarn') }}</span>
                        @enderror
                        <span class="error" id="txtCardHolderEarn_error"></span>
                    </div>
                    <div class="col-4 mb-3">
                        <label for="txtTotalReceive" class="form-label">Total card holder will receive <span
                                class="text-danger">*</span></label>
                        <input type="number" class="form-control" name="txtTotalReceive" id="txtTotalReceive"
                            required step="0.01" min="0" value="{{ old('txtTotalReceive', $deal->card_holder_recieve ?? '') }}" />
                        @error('txtTotalReceive')
                            <span class="text-danger">{{ $errors->first('txtTotalReceive') }}</span>
                        @enderror
                        <span class="error" id="txtTotalReceive_error"></span>
                    </div>

                </div>
            </div>
        </div>

        <div class="card mb-4">
            <div class="card-header">GST & Notes</div>
            <div class="card-body">
                <div class="row">
                    @if ($type == 0)
                        <div class="col-4 mb-3">
                            <label for="txtGSTNumber" class="form-label">GST Number </label>
                            <div class="deal-helper-row">
                                <select id="gstProfileSelect" class="form-select form-select-sm deal-helper-select">
                                    <option value="">Select GST Profile (Company Name)</option>
                                </select>
                                <button type="button" class="btn btn-sm btn-outline-danger" id="deleteGstPair" title="Delete selected GST">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </div>
                            <div id="gstAddPanel" class="deal-helper-row" style="display:none;">
                                <input type="text" id="newGstCompanyName" class="form-control form-control-sm" placeholder="Company Name" style="max-width: 220px;">
                                <input type="text" id="newGstNumber" class="form-control form-control-sm" placeholder="GST Number" style="max-width: 220px;">
                                <button type="button" class="btn btn-sm btn-outline-primary" id="saveNewGstFromPanel">Save GST</button>
                                <button type="button" class="btn btn-sm btn-outline-secondary" id="cancelNewGstFromPanel">Cancel</button>
                            </div>
                            <input type="text" name="txtGSTNumber" class="form-control" id="txtGSTNumber"
                                value="{{ old('txtGSTNumber', $deal->gst_number ?? '') }}" />
                            @error('txtGSTNumber')
                                <span class="text-danger">{{ $errors->first('txtGSTNumber') }}</span>
                            @enderror
                            <span class="error" id="txtGSTNumber_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtCompanyName" class="form-label">GST Business Name</label>
                            <input type="text" class="form-control" name="txtCompanyName" id="txtCompanyName"
                                value="{{ old('txtCompanyName', $deal->company_name ?? '') }}" />
                            @error('txtCompanyName')
                                <span class="text-danger">{{ $errors->first('txtCompanyName') }}</span>
                            @enderror
                            <span class="error" id="txtCompanyName_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtGSTContent" class="form-label">GST Content </label>
                            <input type="text" name="txtGSTContent" class="form-control" id="txtGSTContent"
                                value="{{ old('txtGSTContent', $deal->gst_content ?? '') }}" />
                            @error('txtGSTContent')
                                <span class="text-danger">{{ $errors->first('txtGSTContent') }}</span>
                            @enderror
                            <span class="error" id="txtGSTContent_error"></span>
                        </div>
                    @endif
                    {{-- <div class="col-8 mb-3">
                        <label for="txtGSTMessage" class="form-label">GST Message</label>
                        <textarea class="form-control" name="txtGSTMessage" id="txtGSTMessage" rows="1">{{ old('txtGSTMessage') }}</textarea>
                        @error('txtGSTMessage')
                            <span class="text-danger">{{ $errors->first('txtGSTMessage') }}</span>
                        @enderror
                        <span class="error" id="txtGSTMessage_error"></span>
                    </div> --}}
                    <div class="col-6 mb-3">
                        <label for="txtInstruction" class="form-label">Instruction <span
                                class="text-danger">*</span></label>
                        <div class="deal-helper-row">
                            <select id="instructionTemplateSelect" class="form-select form-select-sm">
                                <option value="">Instruction Template</option>
                                <option value="standard_flow">Template 1 - Standard Flow</option>
                                <option value="amazon_iphone">Template 2 - Amazon / iPhone</option>
                            </select>
                            <button type="button" class="btn btn-sm btn-outline-primary" id="saveInstructionTemplate">Save as New Template</button>
                        </div>
                        <textarea class="form-control deal-resizable-textarea" name="txtInstruction" id="txtInstruction" required>{{ old('txtInstruction', $deal->instruction ?? '') }}</textarea>
                        @error('txtInstruction')
                            <span class="text-danger">{{ $errors->first('txtInstruction') }}</span>
                        @enderror
                        <span class="error" id="txtInstruction_error"></span>
                    </div>
                    <div class="col-6 mb-3">
                        <label for="txtExtraNotes" class="form-label">Extra Notes <span
                                class="text-danger">*</span></label>
                        <textarea class="form-control deal-resizable-textarea" name="txtExtraNotes" id="txtExtraNotes" required>{{ old('txtExtraNotes', $deal->extra_note ?? '') }}</textarea>
                        <div class="deal-helper-row">
                            <button type="button" class="deal-helper-chip" data-extra-note="Apply Coupon : ">Apply Coupon</button>
                            <button type="button" class="deal-helper-chip" id="insertCheckoutPrice">Checkout price from spend</button>
                            <button type="button" class="deal-helper-chip" data-extra-note="📱 iPhone Deal Notice (Amazon)">iPhone notice title</button>
                            <button type="button" class="deal-helper-chip" id="insertIphoneNoteBlock">Insert iPhone notice block</button>
                            <button type="button" class="deal-helper-chip" id="insertFlipkartIphoneNoteBlock">Flipkart iPhone info</button>
                            <button type="button" class="deal-helper-chip" id="clearExtraNotes">Clear Notes</button>
                        </div>
                        @error('txtExtraNotes')
                            <span class="text-danger">{{ $errors->first('txtExtraNotes') }}</span>
                        @enderror
                        <span class="error" id="txtExtraNotes_error"></span>
                    </div>
                    @if ($type == 1 || ($deal && $deal->pine_lab_url))
                        <div class="col-6 mb-3">
                            <label class="form-label">Pine Lab Link <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="txtPineLabLink"
                                value="{{ old('txtPineLabLink', $deal->pine_lab_url ?? '') }}" />
                        </div>
                        <div class="col-6 mb-3">
                        </div>
                    @endif
                    <div class="col-6 mb-3"></div>
                    <div class="col-6 mb-3 ">
                        <div class="demo-inline-spacing float-end">
                            <button type="submit" class="btn btn-success waves-effect waves-light">{{ $isEdit ? 'Update' : 'Submit' }}</button>
                            <button type="button" onclick="cancelDealForm();"
                                class="btn btn-danger waves-effect waves-light">Cancel</button>
                            <button type="button" class="btn btn-primary waves-effect waves-light"><a
                                    href="{{ route('deals') }}" class="text-white">Go to list</a></button>
                        </div>
                    </div>
                </div>
            </div>
        </div>




    </form>


</div>
<!-- / Content -->

@endsection
@section('footer')
<script src="{{ asset('assets/js/dashboards-crm.js') }}"></script>
<script src="{{ asset('assets/js/admin/masters/deal.js?v=3.0') }}"></script>
@endsection

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const fileInput = document.getElementById('deal_images');
        const previewContainer = document.getElementById('uploaded-image-preview');

        // This will hold only the files that are currently visible
        let currentFiles = [];

        // simple id generator for previews
        function genId() {
            return 'f_' + Math.random().toString(36).substr(2, 9);
        }

        // Allow external code to remove uploaded files by id
        window.removeUploadedFileById = function(previewId) {
            const idx = currentFiles.findIndex(f => f._previewId === previewId);
            if (idx === -1) return;
            currentFiles.splice(idx, 1);
            renderPreview();
            updateFileInput();
        }

        function renderPreview() {
            previewContainer.innerHTML = '';

            currentFiles.forEach((file, index) => {
                const reader = new FileReader();
                reader.onload = function(e) {
                    const col = document.createElement('div');
                    col.className = 'col-4 col-md-3 position-relative mb-3';

                    const wrapper = document.createElement('div');
                    wrapper.className = 'border rounded overflow-hidden position-relative';

                    const img = document.createElement('img');
                    img.src = e.target.result;
                    img.className = 'img-fluid';
                    img.style.height = '100px';
                    img.style.width = '100px';
                    img.style.objectFit = 'cover';

                    // ensure preview id exists on file
                    if (!file._previewId) file._previewId = genId();
                    col.setAttribute('data-new-id', file._previewId);

                    // Remove button
                    const removeBtn = document.createElement('button');
                    removeBtn.type = 'button';
                    removeBtn.className =
                        'btn btn-danger btn-sm position-absolute top-0 end-0 rounded-circle d-flex align-items-center justify-content-center';
                    removeBtn.innerHTML = '&times;';
                    removeBtn.style.width = '28px';
                    removeBtn.style.height = '28px';
                    removeBtn.style.fontSize = '16px';
                    removeBtn.style.zIndex = '10';

                    // Remove this image from array and re-render
                    removeBtn.onclick = function() {
                        window.removeUploadedFileById(file._previewId);
                    };

                    wrapper.appendChild(img);
                    wrapper.appendChild(removeBtn);
                    col.appendChild(wrapper);
                    previewContainer.appendChild(col);
                };
                reader.readAsDataURL(file);
            });
        }

        // expose helpers so shared JS can interact with uploaded-file state
        window._deal_renderPreview = renderPreview;

        // When user selects new files
        fileInput.addEventListener('change', function() {
            const newFiles = Array.from(fileInput.files);
            // assign preview ids to new files
            newFiles.forEach(f => {
                if (!f._previewId) f._previewId = genId();
            });
            currentFiles = [...currentFiles, ...newFiles]; // Add new ones
            renderPreview();
            updateFileInput();
        });

        // Update the real <input type="file"> so only currentFiles are sent
        function updateFileInput() {
            const dataTransfer = new DataTransfer();
            currentFiles.forEach(file => dataTransfer.items.add(file));
            fileInput.files = dataTransfer.files;

            // Optional: Show how many files are selected (for debugging)
            console.log('Currently selected files:', fileInput.files.length);
        }

        window._deal_updateFileInput = updateFileInput;

        window._deal_clearUploadedFiles = function() {
            currentFiles = [];
            updateFileInput();
            renderPreview();
        }

        // Clear everything on form reset
        document.querySelector('form').addEventListener('reset', function() {
            currentFiles = [];
            // clear both uploaded and suggestion previews
            const suggestion = document.getElementById('suggestion-image-preview');
            if (suggestion) suggestion.innerHTML = '';
            previewContainer.innerHTML = '';
            fileInput.value = '';
        });

        // Remove existing images on edit/copy
        document.querySelectorAll('.remove-existing-image').forEach(function(btn) {
            btn.addEventListener('click', function() {
                const item = this.closest('.existing-image-item');
                if (item) {
                    item.remove();
                }
            });
        });
    });
</script>
