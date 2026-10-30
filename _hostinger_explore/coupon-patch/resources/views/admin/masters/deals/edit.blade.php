@extends('layouts.main_master')
@section('content')
@section('title')
    Mintzer | Deal
@endsection

<!-- Content -->
<div class="container-xxl flex-grow-1 container-p-y">
    <h4 class="fw-bold py-3 mb-4">{{ $type == 1 ? 'PineLab' : '' }} Deal<span class="text-muted fw-light"> /Update</span>
    </h4>
    <form action="{{ route('deal-store') }}" method="POST" enctype="multipart/form-data" name="deal_form">
        @csrf
        <input type="hidden" name="ddlDealID" value="{{ $deal->id }}">
        <div class="card mb-4">
            {{-- <div class="card-header">
                <div class="row">
                    <div class="col-10">Deal</div>
                    <div class="col-2">
                        <label class="switch" id="allDealer">
                            <input type="checkbox" class="switch-input" name="allDealer"/>
                            <span class="switch-toggle-slider">
                                <span class="switch-on"></span>
                                <span class="switch-off"></span>
                            </span>
                            <span class="switch-label">All Dealer</span>
                        </label>
                    </div>
                </div>
                
            </div> --}}
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
                                        {{ old('ddlStoreID', $deal->store_id) == $store->id ? 'selected' : '' }}>
                                        {{ $store->name }}</option>
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
                        <select class="select2 form-select form-select-lg" id="ddlDealerId" name="ddlDealerId">
                            {{-- <option value="" disabled>Select Dealer</option> --}}
                            @foreach ($dealers as $dealer)
                                <option value="{{ $dealer->id }}"
                                    {{ old('ddlDealerId', $deal->dealer_id) == $dealer->id ? 'selected' : '' }}>
                                    {{ $dealer->display_name }}
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
                                        {{ old('ddlBankCardId', $deal->bank_card_id) == $bankCard->id ? 'selected' : '' }}>
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
                            value="{{ $deal->name }}" />
                        @error('txtDealName')
                            <span class="text-danger">{{ $errors->first('txtDealName') }}</span>
                        @enderror
                        <span class="error" id="txtDealName_error"></span>
                    </div>
                    @if ($type == 0)
                        <div class="col-4 mb-3">
                            <label for="txtcolor" class="form-label">Color <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="txtcolor" name="txtcolor" required
                                value="{{ $deal->color }}" />
                            @error('txtcolor')
                                <span class="text-danger">{{ $errors->first('txtcolor') }}</span>
                            @enderror
                            <span class="error" id="txtcolor_error"></span>
                        </div>
                        {{-- <div class="col-8 mb-3">
                        <label for="txtDiscription" class="form-label">Description <span
                                class="text-danger">*</span></label>
                        <textarea type="text" rows="1" class="form-control" id="txtDiscription" name="txtDiscription" required>{{ $deal->description }}</textarea>
                        @error('txtDiscription')
                            <span class="text-danger">{{ $errors->first('txtDiscription') }}</span>
                        @enderror
                        <span class="error" id="txtDiscription_error"></span>
                    </div> --}}
                        <div class="col-4 mb-3">
                            <label for="txtOrderQty" class="form-label">Order Quantity <span
                                    class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="txtOrderQty" name="txtOrderQty" required
                                value="{{ $deal->order_qty }}" />
                            @error('txtOrderQty')
                                <span class="text-danger">{{ $errors->first('txtOrderQty') }}</span>
                            @enderror
                            <span class="error" id="txtOrderQty_error"></span>
                        </div>
                    @endif
                    <!-- Image Upload Section (Same for Create & Edit) -->
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

                        <!-- New Uploads Preview (same row as existing images) -->
                        <div class="mt-3">
                            <div class="row g-3 align-items-start" id="image-preview"></div>
                        </div>

                        <!-- Current Images (on edit) - keep exactly as below -->
                        @if ($deal->image || $deal->dealImages->count() > 0)
                            <div class="mt-3">
                                <div class="row g-3 align-items-start" id="current-images-preview">
                                    @if ($deal->image)
                                        <div class="col-4 col-md-3 position-relative image-item">
                                            <img src="{{ asset($deal->image) }}" class="img-fluid rounded border"
                                                style="height:100px;width:100px;object-fit:cover;">
                                            <button type="button"
                                                class="btn btn-danger btn-sm position-absolute top-0 end-0 rounded-circle p-1 remove-current-image"
                                                style="width:28px;height:28px;line-height:1;">×</button>
                                            <input type="hidden" name="keep_images[]" value="{{ $deal->image }}">
                                        </div>
                                    @endif

                                    @foreach ($deal->dealImages as $img)
                                        @if ($img->image !== $deal->image)
                                            <div class="col-4 col-md-3 position-relative image-item">
                                                <img src="{{ asset($img->image) }}" class="img-fluid rounded border"
                                                    style="height:100px;width:100px;object-fit:cover;">
                                                <button type="button"
                                                    class="btn btn-danger btn-sm position-absolute top-0 end-0 rounded-circle p-1 remove-current-image"
                                                    style="width:28px;height:28px;line-height:1;">×</button>
                                                <input type="hidden" name="keep_images[]"
                                                    value="{{ $img->image }}">
                                            </div>
                                        @endif
                                    @endforeach
                                </div>
                            </div>
                        @endif
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
                            value="{{ $deal->offer_tittle }}" />
                        @error('txtOfferTitle')
                            <span class="text-danger">{{ $errors->first('txtOfferTitle') }}</span>
                        @enderror
                        <span class="error" id="txtOfferTitle_error"></span>
                    </div> --}}
                        <div class="col-4 mb-3">
                            <label for="txtOfferText" class="form-label">Offer Text <span
                                    class="text-danger">*</span></label>
                            <textarea type="text" class="form-control" id="txtOfferText" name="txtOfferText" rows="1" required>{{ $deal->offer_text }}</textarea>
                            @error('txtOfferText')
                                <span class="text-danger">{{ $errors->first('txtOfferText') }}</span>
                            @enderror
                            <span class="error" id="txtOfferText_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtCouponCode" class="form-label">Coupon code</label>
                            <input type="text" class="form-control" id="txtCouponCode" name="txtCouponCode"
                                maxlength="40" placeholder="Leave empty to hide in the app"
                                value="{{ old('txtCouponCode', $deal->coupon_code ?? '') }}" />
                            <span class="error" id="txtCouponCode_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtOfferLink1" class="form-label">Offer Link 1<span
                                    class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="txtOfferLink1" name="txtOfferLink1"
                                required value="{{ $deal->offer_link1 }}" />
                            @error('txtOfferLink1')
                                <span class="text-danger">{{ $errors->first('txtOfferLink1') }}</span>
                            @enderror
                            <span class="error" id="txtOfferLink1_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtOfferLink2" class="form-label">Offer Link 2</label>
                            <input type="text" class="form-control" id="txtOfferLink2" name="txtOfferLink2"
                                value="{{ $deal->offer_link2 }}" />
                            @error('txtOfferLink2')
                                <span class="text-danger">{{ $errors->first('txtOfferLink2') }}</span>
                            @enderror
                            <span class="error" id="txtOfferLink2_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtOfferLink3" class="form-label">Offer Link 3</label>
                            <input type="text" class="form-control" id="txtOfferLink3" name="txtOfferLink3"
                                value="{{ $deal->offer_link3 }}" />
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
                                required value="{{ $deal->product_price }}" />
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
                                value="{{ $deal->discount }}" />
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
                                value="{{ $deal->cash_reward }}" />
                            @error('txtCashReward')
                                <span class="text-danger">{{ $errors->first('txtCashReward') }}</span>
                            @enderror
                            <span class="error" id="txtCashReward_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtCashback" class="form-label">Cashback
                                {{-- <span class="text-danger">*</span> <span class="badge bg-secondary">If no Cashback, put value is 0.</span> --}}
                            </label>
                            <input type="number" class="form-control" name="txtCashback" id="txtCashback"
                                value="{{ $deal->cashback }}" />
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
                            value="{{ $deal->maximum_discount }}" />
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
                        <input type="number" class="form-control" id="txtCardHolderWillSpend"
                            name="txtCardHolderSpend" required value="{{ $deal->card_holder_spend }}" />
                        @error('txtCardHolderSpend')
                            <span class="text-danger">{{ $errors->first('txtCardHolderSpend') }}</span>
                        @enderror
                        <span class="error" id="txtCardHolderSpend_error"></span>
                    </div>
                    <div class="col-4 mb-3">
                        <label for="txtCardHolderEarn" class="form-label">Card holder will earn <span
                                class="text-danger">*</span></label>
                        <input type="number" class="form-control" id="txtCardHolderEarn" name="txtCardHolderEarn"
                            required value="{{ $deal->card_holder_earn }}" />
                        @error('txtCardHolderEarn')
                            <span class="text-danger">{{ $errors->first('txtCardHolderEarn') }}</span>
                        @enderror
                        <span class="error" id="txtCardHolderEarn_error"></span>
                    </div>
                    <div class="col-4 mb-3">
                        <label for="txtTotalReceive" class="form-label">Total card holder will receive <span
                                class="text-danger">*</span></label>
                        <input type="number" class="form-control" name="txtTotalReceive" id="txtTotalReceive"
                            required value="{{ $deal->card_holder_recieve }}" />
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
                            <input type="text" name="txtGSTNumber" class="form-control" id="txtGSTNumber"
                                value="{{ $deal->gst_number }}" />
                            @error('txtGSTNumber')
                                <span class="text-danger">{{ $errors->first('txtGSTNumber') }}</span>
                            @enderror
                            <span class="error" id="txtGSTNumber_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtCompanyName" class="form-label">GST Business Name</label>
                            <input type="text" class="form-control" name="txtCompanyName" id="txtCompanyName"
                                value="{{ $deal->company_name }}" />
                            @error('txtCompanyName')
                                <span class="text-danger">{{ $errors->first('txtCompanyName') }}</span>
                            @enderror
                            <span class="error" id="txtCompanyName_error"></span>
                        </div>
                        <div class="col-4 mb-3">
                            <label for="txtGSTContent" class="form-label">GST Content </label>
                            <input type="text" name="txtGSTContent" class="form-control" id="txtGSTContent"
                                value="{{ old('txtGSTContent', $deal->gst_content) }}" />
                            @error('txtGSTContent')
                                <span class="text-danger">{{ $errors->first('txtGSTContent') }}</span>
                            @enderror
                            <span class="error" id="txtGSTContent_error"></span>
                        </div>
                    @endif
                    {{-- <div class="col-8 mb-3">
                        <label for="txtGSTMessage" class="form-label">GST Message</label>
                        <textarea class="form-control" name="txtGSTMessage" id="txtGSTMessage" rows="1">{{ $deal->gst_message }}</textarea>
                        @error('txtGSTMessage')
                            <span class="text-danger">{{ $errors->first('txtGSTMessage') }}</span>
                        @enderror
                        <span class="error" id="txtGSTMessage_error"></span>
                    </div> --}}
                    <div class="col-6 mb-3">
                        <label for="txtInstruction" class="form-label">Instruction <span
                                class="text-danger">*</span></label>
                        <textarea class="form-control" name="txtInstruction" id="txtInstruction" required>{{ $deal->instruction }}</textarea>
                        @error('txtInstruction')
                            <span class="text-danger">{{ $errors->first('txtInstruction') }}</span>
                        @enderror
                        <span class="error" id="txtInstruction_error"></span>
                    </div>
                    <div class="col-6 mb-3">
                        <label for="txtExtraNotes" class="form-label">Extra Notes <span
                                class="text-danger">*</span></label>
                        <textarea class="form-control" name="txtExtraNotes" id="txtExtraNotes" required>{{ $deal->extra_note }}</textarea>
                        @error('txtExtraNotes')
                            <span class="text-danger">{{ $errors->first('txtExtraNotes') }}</span>
                        @enderror
                        <span class="error" id="txtExtraNotes_error"></span>
                    </div>
                    @if ($deal->pine_lab_url)
                        <div class="col-6 mb-3">
                            <label class="form-label">Pine Lab Link <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="txtPineLabLink"
                                value="{{ $deal->pine_lab_url }}" />
                        </div>
                        <div class="col-6 mb-3">
                        </div>
                    @endif
                    <div class="col-6 mb-3"></div>
                    <div class="col-6 mb-3 ">
                        <div class="demo-inline-spacing float-end">
                            <button type="submit" class="btn btn-success waves-effect waves-light">Update</button>
                            <button type="reset" onclick="cancel();"
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
<script src="{{ asset('assets/js/admin/admindashboard/dashboard.js') }}"></script>
{{-- <script src="{{ asset('assets/js/admin/masters/deal.js') }}"></script> --}}
@endsection

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const fileInput = document.getElementById('deal_images');
        const previewContainer = document.getElementById('image-preview');
        const currentPreview = document.getElementById('current-images-preview');

        // This array holds ONLY the new files user uploaded in this session
        let uploadedFiles = [];

        // Create preview for new uploaded image
        function addNewImagePreview(file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                const col = document.createElement('div');
                col.className = 'col-4 col-md-3 position-relative image-item mb-3';

                const wrapper = document.createElement('div');
                wrapper.className = 'border rounded overflow-hidden position-relative';

                const img = document.createElement('img');
                img.src = e.target.result;
                img.className = 'img-fluid';
                img.style.height = '100px';
                img.style.width = '100px';
                img.style.objectFit = 'cover';

                // Main badge only on first image (old or new)
                if (document.querySelectorAll('.image-item').length === 0) {
                    const badge = document.createElement('span');
                    badge.className = 'position-absolute top-0 start-0 badge bg-primary z-3';
                    badge.textContent = 'Main';
                    wrapper.appendChild(badge);
                }

                const removeBtn = document.createElement('button');
                removeBtn.type = 'button';
                removeBtn.className =
                    'btn btn-danger btn-sm position-absolute top-0 end-0 rounded-circle d-flex align-items-center justify-content-center';
                removeBtn.innerHTML = '×';
                removeBtn.style.width = '28px';
                removeBtn.style.height = '28px';
                removeBtn.style.fontSize = '18px';
                removeBtn.onclick = function() {
                    // Remove from array
                    const index = uploadedFiles.indexOf(file);
                    if (index > -1) uploadedFiles.splice(index, 1);

                    // Update file input
                    const dt = new DataTransfer();
                    uploadedFiles.forEach(f => dt.items.add(f));
                    fileInput.files = dt.files;

                    // Remove preview
                    col.remove();
                };

                wrapper.appendChild(img);
                wrapper.appendChild(removeBtn);
                col.appendChild(wrapper);
                previewContainer.appendChild(col);
            };
            reader.readAsDataURL(file);
        }

        // When user selects new images
        fileInput.addEventListener('change', function() {
            if (!this.files) return;

            Array.from(this.files).forEach(file => {
                if (file.type.match('image.*')) {
                    uploadedFiles.push(file);
                    addNewImagePreview(file);
                }
            });

            // Update the actual file input so Laravel receives all files
            const dt = new DataTransfer();
            uploadedFiles.forEach(f => dt.items.add(f));
            fileInput.files = dt.files;
        });

        // Remove existing (old) images
        document.querySelectorAll('.remove-current-image').forEach(btn => {
            btn.addEventListener('click', function() {
                const item = this.closest('.image-item');
                if (item) {
                    item.querySelector('input[name="keep_images[]"]')?.remove();
                    item.remove();
                }
            });
        });

        // Optional: Add "Main" badge to first old image if no new ones added yet
        const firstImage = document.querySelector('.image-item');
        if (firstImage && !firstImage.querySelector('.badge')) {
            const badge = document.createElement('span');
            badge.className = 'position-absolute top-0 start-0 badge bg-primary z-3';
            badge.textContent = 'Main';
            firstImage.querySelector('.border').appendChild(badge);
        }
    });
</script>
