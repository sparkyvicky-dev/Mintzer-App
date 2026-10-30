(function () {
    const form = document.getElementById("dealV2");
    if (!form) return;
    const GST_KEY = "mintzer_gst_pairs";
    let products = [];
    let chosen = null;
    let step = 0;
    let slide = 0;
    let gstPairs = [];

    const $ = (id) => document.getElementById(id);
    function esc(s) {
        return String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
    }
    function num(v) {
        if (v === null || v === undefined || v === "") return "";
        const n = Number(v);
        if (!Number.isFinite(n)) return "";
        return Number.isInteger(n) ? String(n) : String(Math.round(n * 100) / 100);
    }
    function inr(v) {
        if (v === "" || v === null || v === undefined) return "—";
        return "₹" + Math.round(Number(v) || 0).toLocaleString("en-IN");
    }
    function labelOf(id) {
        const el = $(id);
        if (!el || el.selectedIndex < 0) return "—";
        const text = el.options[el.selectedIndex].text;
        return el.value ? text : "—";
    }
    function photosOf() {
        if (!chosen) return [];
        return chosen.photos || [];
    }
    function loadGst() {
        try { gstPairs = JSON.parse(localStorage.getItem(GST_KEY) || "[]"); } catch (e) { gstPairs = []; }
        if (!Array.isArray(gstPairs)) gstPairs = [];
    }
    function saveGst() {
        localStorage.setItem(GST_KEY, JSON.stringify(gstPairs.slice(0, 25)));
    }
    function renderGst() {
        const sel = $("gstPick");
        const current = sel.value;
        sel.innerHTML = '<option value="">Off</option>' + gstPairs.map((p, i) => `<option value="${i}">${esc(p.company_name)}</option>`).join("");
        if ([...sel.options].some((o) => o.value === current)) sel.value = current;
    }
    function applyGst(index) {
        if (index === "" || index === null) {
            $("txtCompanyName").value = "";
            $("txtGSTNumber").value = "";
        } else {
            const pair = gstPairs[Number(index)];
            $("txtCompanyName").value = pair ? pair.company_name : "";
            $("txtGSTNumber").value = pair ? pair.gst_number : "";
        }
        paint();
    }
    function setVal(id, value) {
        const el = $(id);
        if (el) el.value = value ?? "";
    }
    function fillFrom(row) {
        setVal("txtDealName", row.name || "");
        setVal("txtcolor", row.color || "");
        setVal("ddlStoreID", row.store_id || "");
        setVal("ddlBankCardId", row.bank_card_id || "");
        setVal("ddlDealerId", row.dealer_id || "");
        setVal("txtOrderQty", num(row.order_qty));
        setVal("txtOfferLink1", row.offer_link1 || "");
        setVal("txtDealerPrice", num(row.product_price));
        setVal("txtDiscount", num(row.discount));
        setVal("txtPlatformFee", num(row.platform_fee));
        setVal("txtCardFee", num(row.card_fee));
        setVal("txtCashback", num(row.cashback));
        setVal("txtCashReward", num(row.cash_reward));
        setVal("txtCardHolderSpend", num(row.card_holder_spend));
        setVal("txtTotalReceive", num(row.card_holder_recieve));
        setVal("txtCardHolderEarn", num(row.card_holder_earn));
        const company = (row.company_name || "").trim();
        const gst = (row.gst_number || "").trim();
        if (company && gst) {
            let idx = gstPairs.findIndex((p) => (p.company_name || "").toLowerCase() === company.toLowerCase() && (p.gst_number || "").toLowerCase() === gst.toLowerCase());
            if (idx < 0) {
                gstPairs.unshift({ company_name: company, gst_number: gst });
                saveGst();
                idx = 0;
            }
            renderGst();
            $("gstPick").value = String(idx);
            applyGst(String(idx));
        } else {
            $("gstPick").value = "";
            applyGst("");
        }
        $("fromLast").style.display = "block";
        $("deal_images").value = "";
    }
    function paint() {
        const name = $("txtDealName").value || "Pick a product";
        $("phName").textContent = name;
        $("phColor").textContent = $("txtcolor").value || "";
        $("phStore").textContent = labelOf("ddlStoreID");
        $("phCard").textContent = labelOf("ddlBankCardId");
        $("phSpend").textContent = inr($("txtCardHolderSpend").value);
        $("phReceive").textContent = inr($("txtTotalReceive").value);
        $("phEarn").textContent = $("txtCardHolderEarn").value === "" ? "Earn" : "Earn " + inr($("txtCardHolderEarn").value);
        $("phEarn2").textContent = inr($("txtCardHolderEarn").value);
        $("phGst").classList.toggle("on", $("txtGSTNumber").value.trim() !== "");
        const urls = photosOf();
        const slides = $("slides");
        const key = urls.join("|");
        if (slides.dataset.key !== key) {
            slides.dataset.key = key;
            slides.innerHTML = "";
            urls.forEach((url) => {
                const img = document.createElement("img");
                img.src = url;
                img.alt = "";
                slides.appendChild(img);
            });
            slide = 0;
            slides.scrollLeft = 0;
        }
        const n = urls.length;
        const fileN = $("deal_images").files.length;
        $("photoNote").textContent = fileN ? fileN + " new photo" + (fileN === 1 ? "" : "s") + " for this deal." : (n ? n + " saved photo" + (n === 1 ? "" : "s") + " on the phone. Save copies them into a new file." : "Add at least one photo.");
    }
    function showPart() {
        document.querySelectorAll("[data-part]").forEach((el) => {
            el.style.display = Number(el.dataset.part) === step ? "block" : "none";
        });
        document.querySelectorAll(".v2-rail button").forEach((btn, i) => btn.classList.toggle("on", i === step));
        $("v2Back").style.visibility = step === 0 ? "hidden" : "visible";
        $("v2Next").textContent = step === 2 ? "Save deal" : (step === 0 ? "Pricing" : "GST");
    }
    function absUrl(path) {
        if (!path) return "";
        if (/^https?:/i.test(path)) return path;
        return window.location.origin + "/" + String(path).replace(/^\/+/, "");
    }
    async function loadPhotos(row) {
        const urls = [];
        const main = absUrl(row.image);
        if (main) urls.push(main);
        try {
            const res = await fetch("/deals/search?term=" + encodeURIComponent(row.name) + "&per_page=20", { headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }, credentials: "same-origin" });
            if (res.ok) {
                const list = await res.json();
                const hit = (list || []).find((item) => String(item.id) === String(row.id)) || null;
                if (hit) {
                    if (hit.image_url && urls.indexOf(hit.image_url) < 0) urls.unshift(hit.image_url);
                    (hit.additional_images || []).forEach((img) => {
                        const url = img.url || absUrl(img.path);
                        if (url && urls.indexOf(url) < 0) urls.push(url);
                    });
                }
            }
        } catch (e) { /* main photo still shows */ }
        chosen.photos = urls;
        paint();
    }
    function pickRow(row) {
        chosen = { id: row.id, name: row.name, photos: [], fresh: false };
        fillFrom(row);
        paint();
        loadPhotos(row);
    }
    async function loadProducts() {
        const res = await fetch("/deals-data/0?draw=1&start=0&length=1000", { headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }, credentials: "same-origin" });
        if (!res.ok) throw new Error("list");
        const json = await res.json();
        const seen = {};
        products = [];
        (json.data || []).forEach((row) => {
            const name = (row.name || "").trim();
            if (!name || seen[name]) return;
            seen[name] = true;
            products.push(row);
        });
        const sel = $("productPick");
        sel.innerHTML = '<option value="">Choose</option>' + products.map((row, i) => `<option value="${i}">${esc(row.name)}</option>`).join("");
    }
    function readFiles(files) {
        return Promise.all([...files].map((file) => new Promise((resolve) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.readAsDataURL(file);
        })));
    }
    async function copySavedPhotos() {
        const input = $("deal_images");
        if (input.files.length) return;
        const urls = photosOf().filter((url) => /^https?:/i.test(url));
        if (!urls.length) return;
        const dt = new DataTransfer();
        for (let i = 0; i < urls.length; i++) {
            const res = await fetch(urls[i], { credentials: "same-origin" });
            if (!res.ok) throw new Error("photo");
            const blob = await res.blob();
            const type = blob.type && blob.type.indexOf("image/") === 0 ? blob.type : "image/jpeg";
            const ext = type.indexOf("png") >= 0 ? "png" : type.indexOf("gif") >= 0 ? "gif" : type.indexOf("webp") >= 0 ? "webp" : "jpg";
            dt.items.add(new File([blob], "deal-" + (i + 1) + "." + ext, { type }));
        }
        input.files = dt.files;
    }
    $("productPick").onchange = () => {
        $("v2Msg").textContent = "";
        if ($("productPick").value === "") {
            chosen = null;
            $("fromLast").style.display = "none";
            paint();
            return;
        }
        pickRow(products[Number($("productPick").value)]);
    };
    $("showAdd").onclick = () => { $("addBox").style.display = $("addBox").style.display === "none" ? "block" : "none"; };
    $("useNew").onclick = async () => {
        const name = $("newName").value.trim();
        const files = $("newPhotos").files;
        if (!name || !files.length) { $("v2Msg").textContent = "Add a name and at least one photo."; return; }
        const dt = new DataTransfer();
        [...files].forEach((file) => dt.items.add(file));
        $("deal_images").files = dt.files;
        chosen = { name, photos: await readFiles(files), fresh: true };
        setVal("txtDealName", name);
        setVal("txtOfferLink1", $("newLink").value.trim());
        setVal("txtcolor", "");
        $("fromLast").style.display = "none";
        $("productPick").value = "";
        $("addBox").style.display = "none";
        $("v2Msg").textContent = "";
        paint();
    };
    $("deal_images").onchange = async () => {
        if (!$("deal_images").files.length) { paint(); return; }
        if (!chosen) chosen = { name: $("txtDealName").value, photos: [], fresh: true };
        chosen.fresh = true;
        chosen.photos = await readFiles($("deal_images").files);
        paint();
    };
    ["txtcolor", "ddlStoreID", "ddlBankCardId", "ddlDealerId", "txtOrderQty", "txtOfferLink1", "txtDealerPrice", "txtDiscount", "txtPlatformFee", "txtCardFee", "txtCashback", "txtCashReward", "txtCardHolderSpend", "txtTotalReceive", "txtCardHolderEarn"].forEach((id) => {
        $(id).addEventListener("input", paint);
        $(id).addEventListener("change", paint);
    });
    $("gstPick").onchange = () => applyGst($("gstPick").value);
    $("showGst").onclick = () => { $("gstAdd").style.display = $("gstAdd").style.display === "none" ? "block" : "none"; };
    $("saveGst").onclick = () => {
        const company = $("gstCo").value.trim();
        const gst = $("gstNo").value.trim();
        if (!company || !gst) return;
        gstPairs.unshift({ company_name: company, gst_number: gst });
        saveGst();
        renderGst();
        $("gstPick").value = "0";
        applyGst("0");
        $("gstAdd").style.display = "none";
    };
    document.querySelectorAll(".v2-rail button").forEach((btn) => {
        btn.onclick = () => {
            if (Number(btn.dataset.step) > 0 && !$("txtDealName").value.trim()) return;
            step = Number(btn.dataset.step);
            showPart();
        };
    });
    $("v2Back").onclick = () => { if (step > 0) { step -= 1; showPart(); } };
    $("v2Next").onclick = async () => {
        $("v2Msg").textContent = "";
        if (step === 0 && !$("txtDealName").value.trim()) { $("v2Msg").textContent = "Choose a product."; return; }
        if (step < 2) { step += 1; showPart(); return; }
        $("v2Next").disabled = true;
        try {
            if (!chosen || !chosen.fresh) await copySavedPhotos();
            if (!$("deal_images").files.length) {
                $("v2Msg").textContent = "Add at least one photo.";
                $("v2Next").disabled = false;
                return;
            }
            form.submit();
        } catch (e) {
            $("v2Msg").textContent = "The saved photo could not be copied. Choose photos for this deal.";
            $("v2Next").disabled = false;
        }
    };
    setInterval(() => {
        const slides = $("slides");
        const n = slides.children.length;
        if (n < 2 || !slides.clientWidth) return;
        slide = (slide + 1) % n;
        slides.scrollTo({ left: slide * slides.clientWidth, behavior: "smooth" });
    }, 3800);
    loadGst();
    renderGst();
    showPart();
    paint();
    loadProducts().catch(() => { $("v2Msg").textContent = "The product list did not load. Use the old form."; });
})();
