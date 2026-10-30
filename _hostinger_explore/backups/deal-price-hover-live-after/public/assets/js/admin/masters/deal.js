let dealType = 0;

function dealInr(value) {
    const amount = Number(value);
    if (!isFinite(amount)) return "₹0";
    const rounded = Math.round(amount * 100) / 100;
    if (rounded % 1 === 0) return "₹" + rounded.toLocaleString("en-IN");
    return "₹" + rounded.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

$(document).ready(function () {
    tblDealList = $("#tblDealList").DataTable({
        processing: true,
        serverSide: true,
        order: [[0, "DESC"]],
        ajax: `/deals-data/${dealType}`,
        fnRowCallback: serialNoCount,
        columns: [
            { data: "id" },
            {
                data: "image",
                render: function (data, type, row) {
                    return (
                        '<img src="' +
                        data +
                        '" alt="" style="width: 64px;height: 59px;" />'
                    );
                },
            },
            {
                data: "name",
                render: function (data, type, row) {
                    const dealLink = row.offer_link1 || row.pine_lab_url;
                    if (!dealLink) return data || "-";

                    return `<a href="${dealLink}" target="_blank" rel="noopener noreferrer">${data || "-"}</a>`;
                },
            },
            {
                data: "product_price",
                render: function (data, type, row) {
                    if (type !== "display") return data;
                    const other = Math.max(0, Number(row.accept_total || 0) - Number(row.accept_trying || 0) - Number(row.accept_delivered || 0) - Number(row.accept_cancelled || 0));
                    return `<span class="deal-price-tip" data-accepted="${Number(row.accept_total || 0)}" data-trying="${Number(row.accept_trying || 0)}" data-delivered="${Number(row.accept_delivered || 0)}" data-cancelled="${Number(row.accept_cancelled || 0)}" data-other="${other}" data-pay="${Number(row.card_holder_spend || 0)}" data-payout="${Number(row.card_holder_recieve || 0)}" data-earn="${Number(row.card_holder_earn || 0)}" data-bank="${Number(row.cashback || 0)}">${data ?? ""}</span>`;
                },
            },
            { data: "order_qty" },
            {
                data: "status",
                render: function (data, type, row) {
                    var isChecked = data == 1 ? "checked" : "";
                    return `<label class="switch">
                                <input id="chkDeal${row.id}" type="checkbox" class="switch-input" ${isChecked} onchange="doStatus(${row.id});" />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on"></span>
                                    <span class="switch-off"></span>
                                </span>
                            </label>`;
                },
            },
            {
                data: "created_at",
                render: function (data, type, row) {
                    if (!data) return "-";
                    return moment(data).format("DD-MM-YYYY hh:mm a");
                },
            },
            { data: "action", orderable: false, searchable: false },
        ],
    });
    $('#createDealBtn').off('click').on('click', function () {
        window.location.href = `/deal-create/${dealType}`;
    });
    // TAB CLICK EVENT
    $(".nav-tabs .nav-link").on("click", function () {
        $(".nav-tabs .nav-link").removeClass("active");
        $(this).addClass("active");

        dealType = $(this).data("type");

        // Reload DataTable based on tab
        tblDealList.ajax.url(`/deals-data/${dealType}`).load();
    });
    if (document.getElementById("dealPriceTip")) {
        const $dealPriceTip = $("#dealPriceTip");
        $(document).on("mouseenter", ".deal-price-tip", function () {
            const el = this;
            const bank = Number(el.getAttribute("data-bank") || 0);
            const other = Number(el.getAttribute("data-other") || 0);
            let html = `Accepted <b>${el.getAttribute("data-accepted")}</b> · Trying <b>${el.getAttribute("data-trying")}</b> · Delivered <b>${el.getAttribute("data-delivered")}</b> · Cancelled <b>${el.getAttribute("data-cancelled")}</b>`;
            if (other > 0) html += ` · Other <b>${other}</b>`;
            html += `<br>You pay <b>${dealInr(el.getAttribute("data-pay"))}</b> · Mintzer payout <b>${dealInr(el.getAttribute("data-payout"))}</b> · You earn <b>${dealInr(el.getAttribute("data-earn"))}</b>`;
            if (bank > 0) html += ` · Bank <b>${dealInr(bank)}</b>`;
            $dealPriceTip.html(html).addClass("show");
            const box = el.getBoundingClientRect();
            let left = box.left;
            $dealPriceTip.css({ left: left + "px", top: (box.bottom + 6) + "px" });
            const width = $dealPriceTip.outerWidth();
            if (left + width > window.innerWidth - 12) {
                $dealPriceTip.css("left", Math.max(12, window.innerWidth - width - 12) + "px");
            }
        });
        $(document).on("mouseleave", ".deal-price-tip", function () {
            $dealPriceTip.removeClass("show");
        });
    }
    $("button[type=reset]").click(function () {
        clearFields();
    });

    $("#allDealer").on("click", function () {
        var ddlDealer = $("#ddlDealerId");
        if ($(this).find(".switch-input").is(":checked")) {
            $("#ddlDealerId").find("option").prop("selected", true);
            // ddlDealer.prop('disabled', true);
        } else {
            $("#ddlDealerId").find("option").prop("selected", false);
            // ddlDealer.prop('disabled', false);
        }
        // Refresh select2 to reflect changes
        $("#ddlDealerId").trigger("change.select2");
    });

    // Deal-create page helpers (safe-guarded so list page is unaffected)
    if ($("#txtDealName").length) {
        const DEFAULT_DEALER_TEXT = "arun 612001 New";
        const templateStorageKey = "mintzer_instruction_templates";
        const gstPairsStorageKey = "mintzer_gst_pairs";
        const instructionHeightStorageKey = "mintzer_instruction_height";
        const extraNotesHeightStorageKey = "mintzer_extra_notes_height";
        const iphoneNoticeBlock = [
            "📱 iPhone Deal Notice (Amazon)",
            "",
            "🔍 Step 1: Open only in Incognito Mode",
            "🚫 Do not use Amazon app or normal tab",
            "",
            "🕵️ Step 2: Use a fresh/new account",
            "",
            "🆕 Step 3: Use a new mobile number in address section",
            "",
            "📞 Step 4: Place the order and exit",
            "🔁 Do not login again and check repeatedly",
            "",
            "🚫 No App | 🕵️ Incognito Only | 🆕 New Account Only",
        ].join("\n");
        const flipkartIphoneNoticeBlock = [
            "⚠️ iPhone Order Instructions (Flipkart)",
            "",
            "🕵️ Step 1: Open a NEW Incognito tab",
            "🚫 Do NOT use Flipkart App or normal browser tab",
            "",
            "🆕 Step 2: Use a fresh/new Flipkart account",
            "📞 Use a fresh mobile number for account creation",
            "",
            "🏷️ Step 3: Use random name details in address",
            "📱 Add a fresh number again in address section",
            "",
            "🛒 Step 4: Place only ONE iPhone order per account",
            "🔁 Avoid repeated attempts, logins, cancellations, or payment retries",
            "",
            "🚪 Step 5: After placing the order, close the Incognito tab immediately",
            "",
            "🌐 Prefer DuckDuckGo browser for better success rate",
            "",
            "🚫 NO APP | 🕵️ INCOGNITO ONLY | 🆕 NEW ACCOUNT ONLY",
        ].join("\n");

        const builtInTemplates = {
            standard_flow: [
                "1️⃣ Pick your deal",
                "2️⃣ Use the correct card",
                "3️⃣ Place the order",
                "4️⃣ Drop the Order ID",
                "5️⃣ Add tracking (once shipped)",
                "6️⃣ Enter OTP (Out for Delivery)",
                "7️⃣ Upload invoice — done 🎯",
            ].join("\n"),
            amazon_iphone: iphoneNoticeBlock,
        };

        function loadCustomTemplates() {
            try {
                return JSON.parse(localStorage.getItem(templateStorageKey) || "[]");
            } catch (e) {
                return [];
            }
        }

        function saveCustomTemplates(items) {
            localStorage.setItem(templateStorageKey, JSON.stringify(items));
        }

        function loadGstPairs() {
            const initialPair = {
                company_name: ($("#txtCompanyName").val() || "").trim(),
                gst_number: ($("#txtGSTNumber").val() || "").trim(),
            };
            let stored = [];
            try {
                stored = JSON.parse(localStorage.getItem(gstPairsStorageKey) || "[]");
            } catch (e) {
                stored = [];
            }
            if (initialPair.company_name && initialPair.gst_number) {
                const exists = stored.some(
                    (p) =>
                        (p.company_name || "").toLowerCase() === initialPair.company_name.toLowerCase() &&
                        (p.gst_number || "").toLowerCase() === initialPair.gst_number.toLowerCase()
                );
                if (!exists) stored.unshift(initialPair);
            }
            return stored.slice(0, 25);
        }

        function saveGstPairs(items) {
            localStorage.setItem(gstPairsStorageKey, JSON.stringify(items.slice(0, 25)));
        }

        function appendLineToTextarea($el, text) {
            const current = ($el.val() || "").trim();
            $el.val(current ? `${current}\n${text}` : text);
            $el.trigger("focus");
        }

        function escapeHtml(value) {
            return String(value ?? "")
                .replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/"/g, "&quot;")
                .replace(/'/g, "&#39;");
        }

        function initDefaultDealerSelection() {
            const formMode = document.getElementById('deal_form_mode')?.value || 'create';
            if (formMode !== 'create') return;
            const $dealer = $("#ddlDealerId");
            const selectedDealers = $dealer.val();
            if (!$dealer.length || (Array.isArray(selectedDealers) && selectedDealers.length)) return;
            let defaultValue = null;
            $dealer.find("option").each(function () {
                const label = ($(this).text() || "").toLowerCase();
                if (label.includes(DEFAULT_DEALER_TEXT.toLowerCase())) {
                    defaultValue = $(this).val();
                    return false;
                }
            });
            if (defaultValue) {
                $dealer.val([defaultValue]).trigger("change");
            }
        }

        function buildOfferText(cardName) {
            const amountFromDiscount = ($("#txtDiscount").val() || "").trim();
            const amount = amountFromDiscount && Number(amountFromDiscount) > 0 ? amountFromDiscount : "2000";
            return `Flat ₹${amount} offer on ${cardName}`;
        }

        function initOfferTextAutoFill() {
            const $offer = $("#txtOfferText");
            const $bank = $("#ddlBankCardId");
            if (!$offer.length || !$bank.length) return;

            if (($offer.val() || "").trim()) {
                $offer.data("offerAutoFilled", false);
            }

            $bank.on("change", function () {
                const cardName = ($(this).find("option:selected").text() || "").trim();
                if (!cardName || cardName.toLowerCase().includes("select bank card")) return;
                const current = ($offer.val() || "").trim();
                const wasAuto = $offer.data("offerAutoFilled") === true;
                if (!current || wasAuto) {
                    $offer.val(buildOfferText(cardName));
                    $offer.data("offerAutoFilled", true);
                }
            });

            $offer.on("input", function () {
                $(this).data("offerAutoFilled", false);
            });
        }

        function renderInstructionTemplateOptions() {
            const $select = $("#instructionTemplateSelect");
            if (!$select.length) return;
            $select.find("option[data-custom='1']").remove();
            loadCustomTemplates().forEach((t, idx) => {
                $select.append(
                    `<option data-custom="1" value="custom_${idx}">${escapeHtml(t.name)}</option>`
                );
            });
        }

        function getTemplateText(value) {
            if (builtInTemplates[value]) return builtInTemplates[value];
            if (!value.startsWith("custom_")) return "";
            const idx = Number(value.replace("custom_", ""));
            const templates = loadCustomTemplates();
            return templates[idx]?.content || "";
        }

        function initInstructionTemplates() {
            const $select = $("#instructionTemplateSelect");
            const $saveBtn = $("#saveInstructionTemplate");
            const $instruction = $("#txtInstruction");
            if (!$select.length || !$instruction.length) return;

            renderInstructionTemplateOptions();

            $select.on("change", function () {
                const value = $(this).val();
                const templateText = getTemplateText(value);
                if (templateText) {
                    $instruction.val(templateText).trigger("focus");
                }
            });

            $saveBtn.on("click", function () {
                const content = ($instruction.val() || "").trim();
                if (!content) {
                    toastr.error("Type instruction content first, then save template");
                    return;
                }
                Swal.fire({
                    title: "Save instruction template",
                    input: "text",
                    inputLabel: "Template name",
                    inputPlaceholder: "Example: Template 3 - iPhone Priority",
                    showCancelButton: true,
                    confirmButtonText: "Save",
                    width: "24%",
                    preConfirm: (name) => {
                        if (!name || !name.trim()) {
                            Swal.showValidationMessage("Template name is required");
                            return false;
                        }
                        return name.trim();
                    },
                }).then((result) => {
                    if (!result.isConfirmed) return;
                    const templates = loadCustomTemplates();
                    templates.push({
                        name: result.value,
                        content: content,
                    });
                    saveCustomTemplates(templates);
                    renderInstructionTemplateOptions();
                    toastr.success("Template saved");
                });
            });
        }

        function initGstPairHelpers() {
            const $gstProfileSelect = $("#gstProfileSelect");
            const $deleteBtn = $("#deleteGstPair");
            const $company = $("#txtCompanyName");
            const $number = $("#txtGSTNumber");
            const $gstAddPanel = $("#gstAddPanel");
            const $newCompany = $("#newGstCompanyName");
            const $newNumber = $("#newGstNumber");
            const $saveNewGst = $("#saveNewGstFromPanel");
            const $cancelNewGst = $("#cancelNewGstFromPanel");
            if (
                !$gstProfileSelect.length ||
                !$company.length ||
                !$number.length
            ) {
                return;
            }

            function renderGstOptions() {
                const pairs = loadGstPairs();
                $gstProfileSelect.find("option[data-gst='1']").remove();
                $gstProfileSelect.find("option[data-action='1']").remove();

                pairs.forEach((p, idx) => {
                    const business = p.company_name || `Business ${idx + 1}`;
                    const gst = p.gst_number || "-";
                    $gstProfileSelect.append(
                        `<option data-gst="1" value="${idx}">${escapeHtml(business)} - ${escapeHtml(gst)}</option>`
                    );
                });
                $gstProfileSelect.append(
                    `<option data-action="1" value="__add_new__">+ Add New GST...</option>`
                );
            }

            function applyGstPairByIndex(indexValue) {
                const idx = Number(indexValue);
                if (Number.isNaN(idx)) return;
                const pairs = loadGstPairs();
                const pair = pairs[idx];
                if (!pair) return;
                $company.val(pair.company_name || "");
                $number.val(pair.gst_number || "");
                $gstProfileSelect.val(String(idx));
            }

            $gstProfileSelect.on("change", function () {
                const value = $(this).val();
                if (!value) {
                    $gstAddPanel.hide();
                    return;
                }
                if (value === "__add_new__") {
                    $gstAddPanel.show();
                    $newCompany.val($company.val() || "");
                    $newNumber.val($number.val() || "");
                    $newCompany.trigger("focus");
                    return;
                }
                $gstAddPanel.hide();
                applyGstPairByIndex(value);
            });

            $deleteBtn.on("click", function () {
                const idx = Number($gstProfileSelect.val());
                if (Number.isNaN(idx)) return;
                const pairs = loadGstPairs();
                const target = pairs[idx];
                if (!target) return;
                Swal.fire({
                    title: "Delete GST profile?",
                    text: `This will remove ${target.company_name || "selected GST"} from suggestions`,
                    icon: "warning",
                    showCancelButton: true,
                    confirmButtonText: "Delete",
                    cancelButtonText: "Cancel",
                    width: "24%",
                }).then((result) => {
                    if (!result.isConfirmed) return;
                    pairs.splice(idx, 1);
                    saveGstPairs(pairs);
                    renderGstOptions();
                    $gstProfileSelect.val("");
                    toastr.success("GST profile deleted");
                });
            });

            $saveNewGst.on("click", function () {
                const company = ($newCompany.val() || "").trim();
                const gst = ($newNumber.val() || "").trim();
                if (!company || !gst) {
                    toastr.error("Enter both Company Name and GST Number");
                    return;
                }
                const pairs = loadGstPairs();
                const exists = pairs.some(
                    (p) =>
                        (p.company_name || "").toLowerCase() === company.toLowerCase() &&
                        (p.gst_number || "").toLowerCase() === gst.toLowerCase()
                );
                if (exists) {
                    toastr.info("This GST profile already exists");
                    return;
                }
                pairs.unshift({ company_name: company, gst_number: gst });
                saveGstPairs(pairs);
                renderGstOptions();
                $company.val(company);
                $number.val(gst);
                $gstProfileSelect.val("0");
                $gstAddPanel.hide();
                toastr.success("GST profile saved");
            });

            $cancelNewGst.on("click", function () {
                $gstAddPanel.hide();
                $gstProfileSelect.val("");
            });

            renderGstOptions();

            // Auto-select existing pair if current values already match
            const currentCompany = ($company.val() || "").trim().toLowerCase();
            const currentGst = ($number.val() || "").trim().toLowerCase();
            if (currentCompany || currentGst) {
                const pairs = loadGstPairs();
                const matchIdx = pairs.findIndex(
                    (p) =>
                        (p.company_name || "").trim().toLowerCase() === currentCompany &&
                        (p.gst_number || "").trim().toLowerCase() === currentGst
                );
                if (matchIdx >= 0) {
                    $gstProfileSelect.val(String(matchIdx));
                }
            }
        }

        function initTextareaSizeMemory() {
            const $instruction = $("#txtInstruction");
            const $extra = $("#txtExtraNotes");
            if ($instruction.length) {
                const savedH = localStorage.getItem(instructionHeightStorageKey);
                if (savedH) $instruction.css("height", savedH);
                $instruction.on("mouseup keyup", function () {
                    localStorage.setItem(instructionHeightStorageKey, `${this.offsetHeight}px`);
                });
            }
            if ($extra.length) {
                const savedH = localStorage.getItem(extraNotesHeightStorageKey);
                if (savedH) $extra.css("height", savedH);
                $extra.on("mouseup keyup", function () {
                    localStorage.setItem(extraNotesHeightStorageKey, `${this.offsetHeight}px`);
                });
            }
        }

        function initExtraNotesHelpers() {
            const $extra = $("#txtExtraNotes");
            if (!$extra.length) return;

            $(document).on("click", "[data-extra-note]", function () {
                const value = ($(this).data("extraNote") || "").toString();
                if (!value) return;
                appendLineToTextarea($extra, value);
            });

            $("#insertCheckoutPrice").on("click", function () {
                const spend = ($("#txtCardHolderSpend").val() || "").trim();
                const text = `Checkout price : ${spend || "XXXX"}`;
                appendLineToTextarea($extra, text);
            });

            $("#insertIphoneNoteBlock").on("click", function () {
                appendLineToTextarea($extra, iphoneNoticeBlock);
            });
            $("#insertFlipkartIphoneNoteBlock").on("click", function () {
                appendLineToTextarea($extra, flipkartIphoneNoticeBlock);
            });

            $("#clearExtraNotes").on("click", function () {
                $extra.val("").trigger("focus");
            });
        }

        initDefaultDealerSelection();
        initOfferTextAutoFill();
        initInstructionTemplates();
        initGstPairHelpers();
        initTextareaSizeMemory();
        initExtraNotesHelpers();
    }
});

(function () {
    // === Deal name on-type search + suggestion binding ===
    function debounce(fn, delay) {
        let t;
        return function () {
            clearTimeout(t);
            const args = arguments;
            t = setTimeout(() => fn.apply(this, args), delay);
        };
    }

    const inputSelector = '#txtDealName';
    const suggestionId = 'dealSuggestions';
    // suggestion previews will render into suggestion-image-preview
    const previewId = 'suggestion-image-preview';
    const keepContainerId = 'keep-images-container';

    function clearSuggestionPreviews() {
        const suggestion = document.getElementById(previewId);
        if (!suggestion) return;
        Array.from(suggestion.children).forEach((child) => {
            if (!child.classList.contains('existing-image-item')) {
                child.remove();
            }
        });
    }

    function ensureSuggestionContainer() {
        let el = document.getElementById(suggestionId);
        if (!el) {
            const input = document.querySelector(inputSelector);
            if (!input) return null;
            el = document.createElement('div');
            el.id = suggestionId;
            el.className = 'list-group position-relative';
            el.style.cssText = 'z-index:9999; display:none; max-height:220px; overflow:auto; margin-top:6px;';
            input.parentNode.appendChild(el);
        }
        return el;
    }

    function clearPreviewAndKeeps() {
        // Full clear: clear both suggestion and uploaded previews and keep inputs
        const suggestion = document.getElementById(previewId);
        if (suggestion) suggestion.innerHTML = '';
        const uploaded = document.getElementById('uploaded-image-preview');
        if (uploaded) uploaded.innerHTML = '';
        const keep = document.getElementById(keepContainerId);
        if (keep) keep.innerHTML = '';
        const fileInput = document.getElementById('deal_images');
        if (fileInput) fileInput.value = '';
        // clear uploaded-file state in the create page if available
        if (window._deal_clearUploadedFiles) {
            try { window._deal_clearUploadedFiles(); } catch (e) { /* ignore */ }
        }
    }

    function clearSuggestionAndKeeps() {
        // Only clear suggestion previews and keep inputs; preserve uploaded-file state
        clearSuggestionPreviews();
        const keep = document.getElementById(keepContainerId);
        if (keep) keep.innerHTML = '';
    }

    function addImagePreview(src, isMain) {
        const preview = document.getElementById(previewId);
        if (!preview) return;
        const col = document.createElement('div');
        col.className = 'col-4 col-md-3 position-relative mb-3';
        const wrapper = document.createElement('div');
        wrapper.className = 'border rounded overflow-hidden position-relative';
        const img = document.createElement('img');
        img.src = src;
        img.className = 'img-fluid';
        img.style.height = '100px';
        img.style.width = '100px';
        img.style.objectFit = 'cover';
        wrapper.appendChild(img);
        // Add delete button for both existing and newly uploaded previews
        const removeBtn = document.createElement('button');
        removeBtn.type = 'button';
        removeBtn.className = 'btn btn-danger btn-sm position-absolute top-0 end-0 rounded-circle d-flex align-items-center justify-content-center';
        removeBtn.innerHTML = '&times;';
        removeBtn.style.width = '28px';
        removeBtn.style.height = '28px';
        removeBtn.style.fontSize = '16px';
        removeBtn.style.zIndex = '10';

        // remove handler will be attached by caller via dataset attributes
        wrapper.appendChild(removeBtn);
        col.appendChild(wrapper);
        preview.appendChild(col);

        return {col, removeBtn};
    }

    function addKeepInput(path) {
        const keep = document.getElementById(keepContainerId);
        if (!keep) return;
        // avoid duplicates
        const exists = Array.from(keep.querySelectorAll('input[name="keep_images[]"]')).some(i => i.value === path);
        if (exists) return;
        const inp = document.createElement('input');
        inp.type = 'hidden';
        inp.name = 'keep_images[]';
        inp.value = path;
        keep.appendChild(inp);
    }

    function fillDealDetails(deal) {
        const origin = window.location.origin;
        const formMode = document.getElementById('deal_form_mode')?.value || 'create';
        const isEditMode = formMode === 'edit';
        function safeSet(id, val) { const el = document.getElementById(id); if (el) el.value = val ?? ''; }
        function clearField(id) {
            const el = document.getElementById(id);
            if (el) el.value = '';
        }

        safeSet('txtDealName', deal.name);
        if (window.$) {
            if (document.getElementById('ddlStoreID')) $('#ddlStoreID').val(deal.store_id).trigger('change');
            if (document.getElementById('ddlDealerId')) {
                const dealerValue = isEditMode ? deal.dealer_id : [deal.dealer_id];
                $('#ddlDealerId').val(dealerValue).trigger('change');
            }
            if (document.getElementById('ddlBankCardId')) $('#ddlBankCardId').val(deal.bank_card_id).trigger('change');
        }
        safeSet('txtcolor', deal.color);
        if (!isEditMode) {
            clearField('txtOrderQty');
        } else {
            safeSet('txtOrderQty', deal.order_qty);
        }
        safeSet('txtOfferTitle', deal.offer_tittle);
        safeSet('txtOfferText', deal.offer_text);
        safeSet('txtCouponCode', deal.coupon_code);
        safeSet('txtOfferLink1', deal.offer_link1);
        safeSet('txtOfferLink2', deal.offer_link2);
        safeSet('txtOfferLink3', deal.offer_link3);
        if (!isEditMode) {
            // Safety: do not auto-fill numeric amount fields from old deal suggestions on create/copy.
            clearField('txtDealerPrice');
            clearField('txtDiscount');
            clearField('txtCashReward');
            clearField('txtCashback');
            clearField('txtCardHolderSpend');
            clearField('txtCardHolderEarn');
            clearField('txtTotalReceive');
        } else {
            safeSet('txtDealerPrice', deal.product_price);
            safeSet('txtDiscount', deal.discount);
            safeSet('txtCashReward', deal.cash_reward);
            safeSet('txtCashback', deal.cashback);
            safeSet('txtCardHolderSpend', deal.card_holder_spend);
            safeSet('txtCardHolderEarn', deal.card_holder_earn);
            safeSet('txtTotalReceive', deal.card_holder_recieve);
        }
        safeSet('txtCompanyName', deal.company_name);
        safeSet('txtGSTNumber', deal.gst_number);
        safeSet('txtGSTContent', deal.gst_content);
        safeSet('txtGSTMessage', deal.gst_message);
        safeSet('txtInstruction', deal.instruction);
        safeSet('txtExtraNotes', deal.extra_note);
        safeSet('txtPineLabLink', deal.pine_lab_url);

        // Images
        // clear only suggestion previews and keep inputs (preserve uploaded files)
        clearSuggestionAndKeeps();
        // mark this form as a copy operation so server-side will use keep_images
        const isCopyInput = document.querySelector('input[name="is_copy"]');
        if (isCopyInput && !isEditMode) isCopyInput.value = 1;
        // helper to remove keep input by path
        function removeKeepByPath(path) {
            document.querySelectorAll('input[name="keep_images[]"]').forEach((input) => {
                if (input.value === path) {
                    input.remove();
                }
            });
            document.querySelectorAll('.existing-image-item').forEach((item) => {
                const input = item.querySelector('input[name="keep_images[]"]');
                if (input && input.value === path) {
                    item.remove();
                }
            });
        }

        // Do NOT display the main image in suggestion previews to avoid confusion
        // but still add its path to hidden keep inputs so it will be preserved on server when copying
        if (deal.image_path) {
            addKeepInput(deal.image_path);
        }
        if (Array.isArray(deal.additional_images)) {
            deal.additional_images.forEach(obj => {
                const url = obj.url || obj;
                const path = obj.path || obj;
                if (url) {
                    const r = addImagePreview(url, false);
                    if (path) {
                        addKeepInput(path);
                        if (r && r.removeBtn && r.col) {
                            r.removeBtn.addEventListener('click', function () {
                                removeKeepByPath(path);
                                r.col.remove();
                            });
                        }
                    }
                } else if (path) {
                    // no URL but have path -> still create hidden keep input
                    addKeepInput(path);
                }
            });
        }

        // re-render uploaded-file previews (so both suggestion and uploaded previews are visible)
        if (window._deal_renderPreview) {
            try { window._deal_renderPreview(); } catch (e) { /* ignore */ }
        }
    }

    let lastQuery = null;
    // Pagination state for suggestions
    let suggestionPage = 1;
    const SUGGESTION_PAGE_SIZE = 5;
    let suggestionLoading = false;
    let suggestionHasMore = true;
    let currentTerm = null;

    async function fetchSuggestions(term, reset = true) {
        if (!term || term.length < 1) {
            lastQuery = null;
            const c = document.getElementById(suggestionId);
            if (c) { c.style.display = 'none'; c.innerHTML = ''; }
            return;
        }

        // Don't search when user just typed a space (gap) — wait for next non-space char
        if (term.endsWith(' ')) return;

        const trimmed = term.trim();

        // If term changed, reset pagination
        if (reset || trimmed !== currentTerm) {
            suggestionPage = 1;
            suggestionHasMore = true;
            currentTerm = trimmed;
        }

        // Avoid redundant identical queries when no more results
        if (trimmed === lastQuery && !reset && !suggestionHasMore) return;

        // If already loading, skip
        if (suggestionLoading) return;

        lastQuery = trimmed;
        suggestionLoading = true;

        try {
            const url = `/deals/search?term=${encodeURIComponent(trimmed)}&page=${suggestionPage}&per_page=${SUGGESTION_PAGE_SIZE}`;
            const res = await fetch(url);
            if (!res.ok) { suggestionLoading = false; return; }
            const data = await res.json();

            // If resetting page 1, clear previous results
            renderSuggestions(data, suggestionPage > 1);

            // If fetched less than page size, no more results
            suggestionHasMore = Array.isArray(data) && data.length === SUGGESTION_PAGE_SIZE;

            suggestionPage++;
        } catch (e) {
            console.error('deal search error', e);
        } finally {
            suggestionLoading = false;
        }
    }

    function renderSuggestions(items, append = false) {
        const container = ensureSuggestionContainer();
        if (!container) return;
        if (!append) container.innerHTML = '';
        if (!items || items.length === 0) {
            // if no items and this is page 1, hide container
            if (!append) { container.style.display = 'none'; }
            return;
        }
        const origin = window.location.origin;
        items.forEach(item => {
            const a = document.createElement('a');
            a.href = 'javascript:void(0)';
            a.className = 'list-group-item list-group-item-action d-flex align-items-center';
            a.style.cursor = 'pointer';
            const img = document.createElement('img');
            img.src = item.image_url || '';
            img.style.width = '48px';
            img.style.height = '48px';
            img.style.objectFit = 'cover';
            img.className = 'me-2 rounded';
            const span = document.createElement('div');
            const storeName = item.store_name || item.store_id || '-';
            const dealerName = item.dealer_name || item.dealer_id || '-';
            span.innerHTML = `<strong>${item.name}</strong><div class="small text-muted">Store: ${storeName} | Dealer: ${dealerName}</div>`;
            a.appendChild(img);
            a.appendChild(span);
            a.addEventListener('click', function () { fillDealDetails(item); container.style.display = 'none'; });
            container.appendChild(a);
        });
        container.style.display = 'block';

        // attach infinite-scroll handler once
        if (!container._infiniteScrollAttached) {
            container._infiniteScrollAttached = true;
            container.addEventListener('scroll', function () {
                const threshold = 80; // px from bottom
                if (container.scrollHeight - container.scrollTop - container.clientHeight < threshold) {
                    if (suggestionHasMore && !suggestionLoading) {
                        fetchSuggestions(currentTerm, false);
                    }
                }
            });
        }
    }

    const debounced = debounce(function (e) { fetchSuggestions(e.target.value); }, 300);
    
    $(document).ready(function () {
        const input = $(inputSelector);
            if (input.length) {
            ensureSuggestionContainer();
            input.on('input', debounced);
            // also trigger suggestions on focus for the current value
            input.on('focus', function(e){ fetchSuggestions(e.target.value.trim()); });
            // hide suggestions on outside click
            $(document).on('click', function (ev) {
                const container = document.getElementById(suggestionId);
                if (!container) return;
                if (!container.contains(ev.target) && ev.target !== input[0]) {
                    container.style.display = 'none';
                }
            });
        }
    });
})();
function doStatus(id) {
    var status = $("#chkDeal" + id).prop("checked");
    Swal.fire({
        title: "Are you sure?",
        text: "You want to change status?",
        icon: status ? "warning" : "error",
        showCancelButton: true,
        confirmButtonText: status ? "Yes, Activate it!" : "Yes, Deactivate it!",
        customClass: {
            confirmButton: "btn btn-success me-3",
            cancelButton: "btn btn-danger",
        },
        buttonsStyling: false,
        width: '20%',
    }).then(function (result) {
        if (result.isConfirmed) {
            statusUpdate(id, "deal-status-change/", status ? 1 : 0);
            Swal.fire({
                icon: "success",
                title: "Updated!",
                text: "Status changed successfully.",
                customClass: {
                    confirmButton: "btn btn-success",
                },
                width: "20%",
            }).then(function () {
                var currentPageIndex = $("#tblDealList")
                    .DataTable()
                    .page.info().page;
                // Refresh the datatable
                $("#tblDealList")
                    .DataTable()
                    .ajax.reload(function () {
                        $("#tblDealList")
                            .DataTable()
                            .page(currentPageIndex)
                            .draw("page");
                    });
            });
        } else {
            $("#chkDeal" + id).prop("checked", !status);
        }
    });
}

function showDelete(id) {
 confirmDelete(id, "delete-deal/", "tblDealList");
}

function clearFields() {
    $("input[type=text], input[type=file], input[type=number], textarea").val(
        ""
    );
    $("select").val(null).trigger("change");
    $("#allDealer").find(".switch-input").prop("checked", false);

    $("#ddlDealerId").prop("disabled", false);

    $("#ddlDealerId").val(null).trigger("change");
    $("#ddlDealerId").val(null).trigger("change");
}

function cancelDealForm() {
    const listUrl = document.getElementById("deal_list_url")?.value || "/deals";
    window.location.href = listUrl;
}

function cancel() {
    cancelDealForm();
}

$(function () {
    const $dealForm = $("form[name='deal_form']");
    if (!$dealForm.length) {
        return;
    }

    const formMode = document.getElementById("deal_form_mode")?.value || "create";
    const isPineLab = Number($dealForm.find('input[name="deal_type"]').val() || 0) === 1;
    const isEdit = formMode === "edit";

    $dealForm.validate({
        ignore: [],
        rules: {
            ddlStoreID: {
                required: !isPineLab,
            },
            ddlDealerId: {
                required: true,
            },
            ddlBankCardId: {
                required: !isPineLab,
            },
            txtDealName: {
                required: true,
                maxlength: 255,
            },
            txtcolor: {
                required: !isPineLab,
                maxlength: 255,
            },
            txtOrderQty: {
                required: !isPineLab,
                digits: true,
            },
            txtOfferText: {
                required: false,
            },
            txtOfferLink1: {
                required: !isPineLab,
                url: !isPineLab,
            },
            txtOfferLink2: {
                url: true,
            },
            txtOfferLink3: {
                url: true,
            },
            txtCashReward: {
                required: !isPineLab,
                number: true,
            },
            txtDealerPrice: {
                required: !isPineLab,
                number: true,
            },
            txtCashback: {
                required: !isPineLab,
                number: true,
            },
            txtDiscount: {
                required: !isPineLab,
                number: true,
            },
            txtCardHolderSpend: {
                required: true,
                number: true,
            },
            txtCardHolderEarn: {
                required: true,
                number: true,
            },
            txtTotalReceive: {
                required: true,
                number: true,
            },
            txtInstruction: {
                required: false,
            },
            txtExtraNotes: {
                required: false,
            },
            txtPineLabLink: {
                required: isPineLab,
                url: isPineLab,
            },
        },
        messages: {
            ddlStoreID: {
                required: "The Store is required",
            },
            ddlDealerId: {
                required: "The Dealer is required",
            },
            ddlBankCardId: {
                required: "The Bank Card is required",
            },
            txtDealName: {
                required: "The Deal Name is required",
            },
            txtcolor: {
                required: "The Color is required",
            },
            txtOrderQty: {
                required: "The Order Quantity is required",
            },
            txtOfferText: {
                required: "The Offer Text is required",
            },
            txtOfferLink1: {
                required: "The Offer Link 1 is required",
                url: "Please enter a valid URL",
            },
            txtOfferLink2: {
                url: "Please enter a valid URL",
            },
            txtOfferLink3: {
                url: "Please enter a valid URL",
            },
            txtCashReward: {
                required: "The Cash Reward is required",
            },
            txtDealerPrice: {
                required: "The Dealer Price is required",
            },
            txtCashback: {
                required: "The Cashback is required",
            },
            txtDiscount: {
                required: "The Discount is required",
            },
            txtCardHolderSpend: {
                required: "Card holder spend is required",
            },
            txtCardHolderEarn: {
                required: "Card holder earn is required",
            },
            txtTotalReceive: {
                required: "Total receive is required",
            },
            txtInstruction: {
                required: "Instruction is required",
            },
            txtExtraNotes: {
                required: "Extra Notes is required",
            },
            txtPineLabLink: {
                required: "Pine Lab Link is required",
                url: "Please enter a valid URL",
            },
        },
        submitHandler: function (form) {
            const isCopy = formMode === "copy";
            if (isEdit || isCopy) {
                const hasKeepImages = document.querySelectorAll('input[name="keep_images[]"]').length > 0;
                const hasNewImages = document.getElementById("deal_images")?.files?.length > 0;
                if (!hasKeepImages && !hasNewImages) {
                    const errorSpan = document.getElementById("deal_images_error");
                    if (errorSpan) {
                        errorSpan.innerHTML = "At least one image is required for the deal.";
                    }
                    return false;
                }
            }
            form.submit();
        },
        errorPlacement: function (error, element) {
            const errorSpanId = element.attr("id") + "_error";
            const $errorSpan = $("#" + errorSpanId);
            if ($errorSpan.length) {
                $errorSpan.html(error);
            } else if (element.hasClass("select2-hidden-accessible")) {
                element.next(".select2-container").after(error);
            } else {
                error.insertAfter(element);
            }
        },
    });
});

function sendDealStockAlert(id) {
    Swal.fire({
        title: 'Stock is back?',
        text: 'This sends a stock alert about this deal. Each tap picks a different message for this product.',
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Yes, alert',
        cancelButtonText: 'Cancel',
        customClass: {
            confirmButton: 'btn btn-success me-2',
            cancelButton: 'btn btn-danger'
        },
        buttonsStyling: false,
        width: "20%",
    }).then((result) => {
        if (!result.isConfirmed) return;
        postDealPush(id, '/send-deal-notification', 'Sending stock alert', 'Stock alert sent', 'stock');
    });
}

function sendDealNotify(id) {
    Swal.fire({
        title: 'Send Notification?',
        text: 'This notifies app users about this deal.',
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Yes, Send',
        cancelButtonText: 'Cancel',
        customClass: {
            confirmButton: 'btn btn-success me-2',
            cancelButton: 'btn btn-danger'
        },
        buttonsStyling: false,
        width: "20%",
    }).then((result) => {
        if (!result.isConfirmed) return;
        postDealPush(id, '/send-deal-notification', 'Sending push notification', 'Notification sent', 'live');
    });
}

function postDealPush(id, url, processingText, successTitle, kind) {
        Swal.fire({
            title: 'Processing...',
            text: processingText,
            allowOutsideClick: false,
            allowEscapeKey: false,
            width: "20%",
            didOpen: () => {
                Swal.showLoading();
            },
        });

        $.ajax({
            url: url,
            type: 'POST',
            data: {
                deal_id: id,
                kind: kind || 'live',
                _token: $('meta[name="csrf-token"]').attr('content')
            },
            success: function (response) {
                Swal.close();
                if (response.success){
                     Swal.fire({
                         icon: "success",
                         title: successTitle,
                         text:
                             response.message ??
                             "Push notification sent successfully.",
                         confirmButtonText: "OK",
                         customClass: {
                             confirmButton: "btn btn-success",
                         },
                         buttonsStyling: false,
                         width: "20%",
                     });
                } else {
                    Swal.fire({
                        icon: "error",
                        title: "Failed",
                        text: (response && response.message) ? response.message : 'Something went wrong. Please try again.',
                        confirmButtonText: "OK",
                        customClass: {
                            confirmButton: "btn btn-danger",
                        },
                        buttonsStyling: false,
                        width: "20%",
                    });
                }
               
            },
            error: function (xhr) {
                Swal.close();

                let msg = 'Something went wrong. Please try again.';
                if (xhr.responseJSON && xhr.responseJSON.message) {
                    msg = xhr.responseJSON.message;
                }

                Swal.fire({
                    icon: 'error',
                    title: 'Failed',
                    text: msg,
                    confirmButtonText: 'OK',
                    customClass: {
                        confirmButton: 'btn btn-danger'
                    },
                    buttonsStyling: false,
                    width: "20%",
                });
            }
        });
}

