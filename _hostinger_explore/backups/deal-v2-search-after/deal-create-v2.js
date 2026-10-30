(function () {
    const form = document.getElementById("dealV2");
    if (!form) return;
    const GST_KEY = "mintzer_gst_pairs";
    let products = [];
    let chosen = null;
    let shots = [];
    let step = 0;
    let slide = 0;
    let gstPairs = [];
    let photoToken = 0;
    let shotStamp = 0;

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
    function loadGst() {
        try { gstPairs = JSON.parse(localStorage.getItem(GST_KEY) || "[]"); } catch (e) { gstPairs = []; }
        if (!Array.isArray(gstPairs)) gstPairs = [];
    }
    function saveGst() {
        localStorage.setItem(GST_KEY, JSON.stringify(gstPairs.slice(0, 25)));
    }
    function syncOne(input, select) {
        if (!input || !select) return;
        if (select.id === "productPick" && !select.value) {
            input.value = $("txtDealName").value || "";
            return;
        }
        const opt = select.options[select.selectedIndex];
        if (!opt || select.selectedIndex < 0 || (!select.value && select.id !== "gstPick")) {
            input.value = "";
            return;
        }
        input.value = opt.textContent;
    }
    function syncComboLabels() {
        document.querySelectorAll("[data-combo]").forEach((input) => syncOne(input, $(input.dataset.combo)));
    }
    function mountCombo(input) {
        const select = $(input.dataset.combo);
        const box = input.parentElement.querySelector(".v2-suggest");
        if (!select || !box) return;
        let hi = -1;
        let items = [];
        function close() { box.hidden = true; hi = -1; }
        function draw(query) {
            const q = query.trim().toLowerCase();
            const all = [...select.options].filter((o) => o.value !== "" || select.id === "gstPick").map((o) => ({ value: o.value, label: o.textContent }));
            const matched = all.filter((it) => !q || it.label.toLowerCase().includes(q));
            items = matched.slice(0, 8);
            box.innerHTML = "";
            if (!items.length) {
                box.innerHTML = '<div class="v2-empty">No match</div>';
            } else {
                items.forEach((it, i) => {
                    const b = document.createElement("button");
                    b.type = "button";
                    b.textContent = it.label;
                    if (i === hi) b.className = "on";
                    b.addEventListener("mousedown", (e) => { e.preventDefault(); choose(it); });
                    box.appendChild(b);
                });
                if (matched.length > items.length) {
                    const more = document.createElement("div");
                    more.className = "v2-empty";
                    more.textContent = "Keep typing";
                    box.appendChild(more);
                }
            }
            const space = window.innerHeight - input.getBoundingClientRect().bottom;
            box.classList.toggle("up", space < 240);
            box.hidden = false;
        }
        function choose(it) {
            select.value = it.value;
            input.value = it.label;
            close();
            select.dispatchEvent(new Event("change"));
        }
        input.addEventListener("focus", () => { hi = -1; draw(""); });
        input.addEventListener("input", () => { hi = -1; draw(input.value); });
        input.addEventListener("keydown", (e) => {
            if (e.key === "ArrowDown") { e.preventDefault(); if (!items.length) draw(input.value); hi = Math.min(hi + 1, items.length - 1); draw(input.value); return; }
            if (e.key === "ArrowUp") { e.preventDefault(); hi = Math.max(hi - 1, 0); draw(input.value); return; }
            if (e.key === "Enter") { e.preventDefault(); if (items[hi]) choose(items[hi]); else if (items.length === 1) choose(items[0]); return; }
            if (e.key === "Escape") close();
        });
        input.addEventListener("blur", () => setTimeout(() => { close(); syncOne(input, select); }, 140));
    }
    function renderGst() {
        const sel = $("gstPick");
        const current = sel.value;
        sel.innerHTML = '<option value="">Off</option>' + gstPairs.map((p, i) => `<option value="${i}">${esc(p.company_name)}</option>`).join("");
        if ([...sel.options].some((o) => o.value === current)) sel.value = current;
        syncComboLabels();
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
        syncComboLabels();
    }
    function renderShots() {
        const box = $("thumbs");
        box.innerHTML = "";
        shots.forEach((shot, i) => {
            const wrap = document.createElement("div");
            wrap.className = "v2-shot" + (i === 0 ? " main" : "");
            wrap.title = i === 0 ? "Main photo" : "Tap to make this the main photo";
            const img = document.createElement("img");
            img.src = shot.url;
            img.alt = "";
            wrap.appendChild(img);
            if (i === 0) {
                const tag = document.createElement("span");
                tag.className = "tag";
                tag.textContent = "Main";
                wrap.appendChild(tag);
            }
            const x = document.createElement("button");
            x.type = "button";
            x.className = "v2-x";
            x.textContent = "×";
            x.title = "Remove from this new deal";
            x.onclick = (e) => {
                e.stopPropagation();
                shotStamp += 1;
                shots.splice(i, 1);
                renderShots();
            };
            wrap.appendChild(x);
            wrap.onclick = () => {
                if (i === 0) return;
                shotStamp += 1;
                const picked = shots.splice(i, 1)[0];
                shots.unshift(picked);
                renderShots();
            };
            box.appendChild(wrap);
        });
        $("slides").dataset.key = "";
        paint();
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
        const urls = shots.map((shot) => shot.url);
        const slides = $("slides");
        const key = urls.join("|");
        if (slides.dataset.key !== key) {
            slides.dataset.key = key;
            slides.innerHTML = "";
            if (!urls.length) {
                const empty = document.createElement("div");
                empty.className = "v2-empty-slide";
                empty.textContent = "No photo";
                slides.appendChild(empty);
            }
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
        $("phCount").textContent = n ? n + (n === 1 ? " photo" : " photos") : "";
        const saved = shots.some((shot) => !shot.file);
        $("photoNote").textContent = !n
            ? ($("txtDealName").value ? "Add at least one photo." : "Choose a product. Its photos come with it.")
            : (saved
                ? "Already saved. Tap a photo to make it first. × removes it from this new deal only."
                : n + " new photo" + (n === 1 ? "" : "s") + ".");
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
    function hasUrl(list, url) {
        const path = (value) => {
            try { return new URL(value, window.location.origin).pathname; } catch (e) { return value; }
        };
        const next = path(url);
        return list.some((item) => path(item) === next);
    }
    async function loadPhotos(row) {
        const token = ++photoToken;
        const stamp = shotStamp;
        const urls = [];
        const main = absUrl(row.image);
        if (main) urls.push(main);
        if (token === photoToken && stamp === shotStamp) {
            shots = urls.map((url) => ({ url, file: null }));
            renderShots();
        }
        try {
            const res = await fetch("/deals/search?term=" + encodeURIComponent(row.name) + "&per_page=20", { headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }, credentials: "same-origin" });
            if (res.ok) {
                const list = await res.json();
                const hit = (list || []).find((item) => String(item.id) === String(row.id)) || null;
                if (hit) {
                    if (hit.image_url && !hasUrl(urls, hit.image_url)) urls.unshift(hit.image_url);
                    (hit.additional_images || []).forEach((img) => {
                        const url = img.url || absUrl(img.path);
                        if (url && !hasUrl(urls, url)) urls.push(url);
                    });
                }
            }
        } catch (e) { /* main photo still shows */ }
        if (token !== photoToken || stamp !== shotStamp) return;
        shots = urls.map((url) => ({ url, file: null }));
        renderShots();
    }
    function pickRow(row) {
        chosen = { id: row.id, name: row.name };
        shotStamp += 1;
        fillFrom(row);
        loadPhotos(row);
    }
    async function loadProducts() {
        const search = $("productSearch");
        search.disabled = true;
        search.placeholder = "Loading products…";
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
        search.disabled = false;
        search.placeholder = "Type a product";
        syncComboLabels();
    }
    function readFiles(files) {
        return Promise.all([...files].map((file) => new Promise((resolve) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.readAsDataURL(file);
        })));
    }
    async function buildUpload() {
        const input = $("deal_images");
        const dt = new DataTransfer();
        for (let i = 0; i < shots.length; i++) {
            const shot = shots[i];
            if (shot.file) {
                dt.items.add(shot.file);
                continue;
            }
            const res = await fetch(shot.url, { credentials: "same-origin" });
            if (!res.ok) throw new Error("photo");
            const blob = await res.blob();
            const type = blob.type && blob.type.indexOf("image/") === 0 ? blob.type : "image/jpeg";
            const ext = type.indexOf("png") >= 0 ? "png" : type.indexOf("gif") >= 0 ? "gif" : type.indexOf("webp") >= 0 ? "webp" : "jpg";
            dt.items.add(new File([blob], "deal-" + (i + 1) + "." + ext, { type }));
        }
        input.files = dt.files;
    }
    document.querySelectorAll("[data-combo]").forEach(mountCombo);
    $("productPick").onchange = () => {
        $("v2Msg").textContent = "";
        if ($("productPick").value === "") return;
        pickRow(products[Number($("productPick").value)]);
    };
    $("showAdd").onclick = () => { $("addBox").style.display = $("addBox").style.display === "none" ? "grid" : "none"; };
    $("useNew").onclick = async () => {
        const name = $("newName").value.trim();
        const files = $("newPhotos").files;
        if (!name || !files.length) { $("v2Msg").textContent = "Add a name and at least one photo."; return; }
        const urls = await readFiles(files);
        shotStamp += 1;
        shots = [...files].map((file, i) => ({ url: urls[i], file }));
        chosen = { name };
        setVal("txtDealName", name);
        setVal("txtOfferLink1", $("newLink").value.trim());
        setVal("txtcolor", "");
        $("fromLast").style.display = "none";
        $("productPick").value = "";
        $("addBox").style.display = "none";
        $("v2Msg").textContent = "";
        syncComboLabels();
        renderShots();
    };
    $("addPhoto").onchange = async () => {
        const files = [...$("addPhoto").files];
        $("addPhoto").value = "";
        if (!files.length) return;
        const urls = await readFiles(files);
        shotStamp += 1;
        files.forEach((file, i) => shots.push({ url: urls[i], file }));
        renderShots();
    };
    ["txtcolor", "ddlStoreID", "ddlBankCardId", "ddlDealerId", "txtOrderQty", "txtOfferLink1", "txtDealerPrice", "txtDiscount", "txtPlatformFee", "txtCardFee", "txtCashback", "txtCashReward", "txtCardHolderSpend", "txtTotalReceive", "txtCardHolderEarn"].forEach((id) => {
        $(id).addEventListener("input", paint);
        $(id).addEventListener("change", paint);
    });
    $("gstPick").onchange = () => applyGst($("gstPick").value);
    $("showGst").onclick = () => { $("gstAdd").style.display = $("gstAdd").style.display === "none" ? "grid" : "none"; };
    $("saveGst").onclick = () => {
        const company = $("gstCo").value.trim();
        const gst = $("gstNo").value.trim();
        if (!company || !gst) return;
        gstPairs.unshift({ company_name: company, gst_number: gst });
        saveGst();
        renderGst();
        $("gstPick").value = "0";
        applyGst("0");
        syncComboLabels();
        $("gstAdd").style.display = "none";
        $("gstCo").value = "";
        $("gstNo").value = "";
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
        if (!shots.length) { $("v2Msg").textContent = "Add at least one photo."; step = 0; showPart(); return; }
        $("v2Next").disabled = true;
        try {
            await buildUpload();
            if (!$("deal_images").files.length) {
                $("v2Msg").textContent = "Add at least one photo.";
                $("v2Next").disabled = false;
                return;
            }
            form.submit();
        } catch (e) {
            $("v2Msg").textContent = "A saved photo could not be copied. Add it again with +.";
            $("v2Next").disabled = false;
        }
    };
    setInterval(() => {
        const slides = $("slides");
        const n = slides.querySelectorAll("img").length;
        if (n < 2 || !slides.clientWidth) return;
        slide = (slide + 1) % n;
        slides.scrollTo({ left: slide * slides.clientWidth, behavior: "smooth" });
    }, 3800);
    loadGst();
    renderGst();
    showPart();
    paint();
    loadProducts().catch(() => {
        $("productSearch").disabled = false;
        $("productSearch").placeholder = "Type a product";
        $("v2Msg").textContent = "The product list did not load. Use the old form.";
    });
})();
