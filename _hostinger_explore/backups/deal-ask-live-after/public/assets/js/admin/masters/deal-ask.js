(function () {
    const root = document.getElementById("dealAsk");
    const classic = document.getElementById("dealClassic");
    if (!root || !classic) return;
    if (document.querySelector(".text-danger")) return;

    classic.style.display = "none";
    root.innerHTML = `
      <div class="deal-ask-grid">
        <div>
          <div class="deal-ask-kicker" id="dealAskProgress"></div>
          <h1 class="deal-ask-title" id="dealAskTitle"></h1>
          <p class="deal-ask-lead">The last deal fills the next answers. Next if it is right.</p>
          <div class="deal-ask-card">
            <div id="dealAskStage"></div>
            <div class="deal-ask-from" id="dealAskFrom">From the last deal.</div>
            <div class="deal-ask-nav">
              <button type="button" class="btn btn-label-secondary" id="dealAskBack">Back</button>
              <button type="button" class="btn btn-primary" id="dealAskNext">Next</button>
            </div>
          </div>
        </div>
        <div class="deal-ask-phone">
          <div class="deal-ask-screen">
            <div class="deal-ask-bar"><b>Deal detail</b><span>Anything wrong?</span></div>
            <div class="deal-ask-hero" id="askHero"><span class="deal-ask-pill" id="askPill">GST</span></div>
            <div class="deal-ask-body">
              <div class="deal-ask-name"><h3 id="askName">Pick a product</h3><span id="askEarn">Earn</span></div>
              <div id="askColor" class="deal-ask-muted"></div>
              <div class="deal-ask-exact">Buy this exact variant</div>
              <div class="deal-ask-buys"><div data-k="store"><span>Buy on</span><b id="askStore">—</b></div><div data-k="card"><span>Pay using</span><b id="askCard">—</b></div></div>
              <div class="deal-ask-sum" id="askMoney"></div>
              <div class="deal-ask-gst" id="askGst">GST invoice needed. At checkout, enter the Company and GST No. shown in the delivery address.</div>
            </div>
          </div>
        </div>
      </div>`;

    const steps = [
        ["product", "Which product?"],
        ["store", "Which store?"],
        ["dealer", "Which dealer?"],
        ["card", "Which card?"],
        ["color", "Color"],
        ["qty", "Order qty"],
        ["price", "Dealer price"],
        ["discount", "Discount"],
        ["platform", "Platform fee"],
        ["cardfee", "Card fee"],
        ["cashback", "Cashback"],
        ["reward", "Cash reward"],
        ["spend", "Card holder will spend"],
        ["receive", "Total card holder will receive"],
        ["earn", "Card holder will earn"],
        ["link", "Offer link"],
        ["gst", "GST for this deal?"]
    ];
    const box = {
        color: "txtcolor",
        qty: "txtOrderQty",
        price: "txtDealerPrice",
        discount: "txtDiscount",
        platform: "txtPlatformFee",
        cardfee: "txtCardFee",
        cashback: "txtCashback",
        reward: "txtCashReward",
        spend: "txtCardHolderSpend",
        receive: "txtTotalReceive",
        earn: "txtCardHolderEarn",
        link: "txtOfferLink1"
    };
    let products = [];
    let chosen = null;
    let step = 0;
    const stage = document.getElementById("dealAskStage");

    function inr(value) {
        if (value === "" || value === null || value === undefined) return "—";
        const amount = Number(value);
        if (!isFinite(amount)) return "—";
        const rounded = Math.round(amount * 100) / 100;
        if (rounded % 1 === 0) return "₹" + rounded.toLocaleString("en-IN");
        return "₹" + rounded.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }
    function read(id) {
        const el = document.getElementById(id);
        return el ? el.value : "";
    }
    function write(id, value) {
        const el = document.getElementById(id);
        if (!el) return;
        if (window.jQuery && jQuery(el).hasClass("select2-hidden-accessible")) {
            jQuery(el).val(value).trigger("change");
            return;
        }
        el.value = value == null ? "" : value;
        el.dispatchEvent(new Event("input", { bubbles: true }));
        el.dispatchEvent(new Event("change", { bubbles: true }));
    }
    function parkFile() {
        const file = document.getElementById("deal_images");
        const home = document.getElementById("dealImageHome");
        if (file && home && file.parentElement !== home) home.appendChild(file);
    }
    function optionsOf(id) {
        const el = document.getElementById(id);
        if (!el) return [];
        return Array.from(el.options).filter((opt) => opt.value !== "").map((opt) => ({ value: opt.value, text: opt.text }));
    }
    function paint() {
        const name = read("txtDealName");
        const spend = read("txtCardHolderSpend");
        const receive = read("txtTotalReceive");
        const earn = read("txtCardHolderEarn");
        const cash = read("txtCashback");
        const gstOn = read("txtGSTNumber").trim() !== "";
        document.getElementById("askName").textContent = name || "Pick a product";
        document.getElementById("askEarn").textContent = earn === "" ? "Earn" : "Earn " + inr(earn);
        document.getElementById("askColor").textContent = read("txtcolor");
        const storeOpt = document.querySelector("#ddlStoreID option:checked");
        const cardOpt = document.querySelector("#ddlBankCardId option:checked");
        document.getElementById("askStore").textContent = storeOpt && storeOpt.value ? storeOpt.text : "—";
        document.getElementById("askCard").textContent = cardOpt && cardOpt.value ? cardOpt.text : "—";
        const hero = document.getElementById("askHero");
        if (chosen && chosen.image) {
            hero.style.backgroundImage = "url('" + chosen.image + "')";
        } else {
            hero.style.backgroundImage = "";
        }
        const bank = `<div class="m" data-k="cashback"><div><b>Bank cashback</b><div>Credited to your card/account according to the bank statements.</div></div><b>${inr(cash)}</b></div>`;
        document.getElementById("askMoney").innerHTML = `<h4>Payment summary</h4><div>Here's what you pay and what you get back.</div><div class="line" data-k="spend"><b>You pay at checkout</b><b>${inr(spend)}</b></div>${bank}<div class="m" data-k="receive"><div><b>Mintzer payout</b><div>Reimbursement after verification.</div></div><b>${inr(receive)}</b></div><div class="earnbox" data-k="earn"><b>Your earnings</b><b>${inr(earn)}</b></div><div class="how">How this is calculated?</div><div class="calc" data-k="price"><span>Product price</span><b>${inr(read("txtDealerPrice"))}</b></div><div class="calc" data-k="discount"><span>Discount</span><b>${inr(read("txtDiscount"))}</b></div><div class="calc" data-k="platform"><span>Platform fee</span><b>${inr(read("txtPlatformFee"))}</b></div><div class="calc" data-k="cardfee"><span>Card fee</span><b>${inr(read("txtCardFee"))}</b></div><div class="calc" data-k="reward"><span>Cash reward</span><b>${inr(read("txtCashReward"))}</b></div>`;
        document.getElementById("askPill").style.display = gstOn ? "inline-block" : "none";
        document.getElementById("askGst").style.display = gstOn ? "block" : "none";
        const key = steps[step][0];
        document.querySelectorAll("#dealAsk [data-k]").forEach((el) => el.classList.toggle("hot", el.dataset.k === key));
    }
    function applyProduct(item) {
        chosen = item;
        write("txtDealName", item.name || "");
        write("txtcolor", item.color || "");
        write("txtOfferLink1", item.offer_link1 || "");
        write("ddlStoreID", item.store_id || "");
        if (window.jQuery) jQuery("#ddlDealerId").val(item.dealer_id ? [String(item.dealer_id)] : []).trigger("change");
        write("ddlBankCardId", item.bank_card_id || "");
        write("txtOrderQty", item.order_qty ?? "");
        write("txtDealerPrice", item.product_price ?? "");
        write("txtDiscount", item.discount ?? "");
        write("txtPlatformFee", item.platform_fee ?? "");
        write("txtCardFee", item.card_fee ?? "");
        write("txtCashback", item.cashback ?? "");
        write("txtCashReward", item.cash_reward ?? "");
        write("txtCardHolderSpend", item.card_holder_spend ?? "");
        write("txtTotalReceive", item.card_holder_recieve ?? "");
        write("txtCardHolderEarn", item.card_holder_earn ?? "");
        write("txtGSTNumber", item.gst_number || "");
        write("txtCompanyName", item.company_name || "");
        document.getElementById("reuse_deal_id").value = item.id || "";
        document.getElementById("dealAskFrom").style.display = item.id ? "block" : "none";
    }
    function show() {
        parkFile();
        const id = steps[step][0];
        const title = steps[step][1];
        document.getElementById("dealAskTitle").textContent = title;
        document.getElementById("dealAskProgress").textContent = (step + 1) + " of " + steps.length;
        document.getElementById("dealAskBack").style.visibility = step === 0 ? "hidden" : "visible";
        document.getElementById("dealAskNext").textContent = step === steps.length - 1 ? "Save deal" : "Next";
        document.getElementById("dealAskFrom").style.display = chosen && chosen.id && id !== "product" ? "block" : "none";

        if (id === "product") {
            stage.innerHTML = `<label>Product</label><div class="deal-ask-row"><select id="askProduct" class="form-select"></select><button type="button" class="btn btn-dark" id="askAdd">Add</button></div><div id="askPicked" class="deal-ask-picked"></div><div id="askAddBox" style="display:none"><label>Name</label><input id="askNewName" class="form-control" type="text" /><label>Color</label><input id="askNewColor" class="form-control" type="text" /><label>Photos</label><div id="askFileSlot"></div><label>Offer link</label><input id="askNewLink" class="form-control" type="url" /><button type="button" class="btn btn-label-primary" id="askSaveNew" style="margin-top:8px">Use this product</button></div><div id="askLinkBox" style="display:none"><label>Offer link for this deal</label><input id="askDealLink" class="form-control" type="url" /></div>`;
            const sel = document.getElementById("askProduct");
            sel.innerHTML = `<option value="">Choose</option>` + products.map((p, i) => `<option value="${i}">${p.name}</option>`).join("");
            if (chosen) {
                const idx = products.indexOf(chosen);
                if (idx >= 0) sel.value = String(idx);
                document.getElementById("askPicked").innerHTML = `<div><b>${chosen.name}</b><div>${chosen.offer_link1 || ""}</div></div><button type="button" class="btn btn-label-secondary" id="askChange">Change link</button>`;
                const change = document.getElementById("askChange");
                if (change) change.onclick = () => {
                    const box = document.getElementById("askLinkBox");
                    box.style.display = "block";
                    document.getElementById("askDealLink").value = read("txtOfferLink1");
                };
            }
            sel.oninput = () => {
                if (sel.value === "") return;
                applyProduct(products[Number(sel.value)]);
                show();
            };
            document.getElementById("askAdd").onclick = () => {
                document.getElementById("askAddBox").style.display = "block";
                const slot = document.getElementById("askFileSlot");
                const file = document.getElementById("deal_images");
                if (file && slot) slot.appendChild(file);
            };
            document.getElementById("askSaveNew").onclick = () => {
                const name = document.getElementById("askNewName").value.trim();
                if (!name) return;
                write("txtDealName", name);
                write("txtcolor", document.getElementById("askNewColor").value.trim());
                write("txtOfferLink1", document.getElementById("askNewLink").value.trim());
                document.getElementById("reuse_deal_id").value = "";
                chosen = { name: name, image: "", id: "" };
                parkFile();
                step += 1;
                show();
            };
            const link = document.getElementById("askDealLink");
            if (link) link.oninput = () => write("txtOfferLink1", link.value);
            paint();
            return;
        }
        if (id === "store" || id === "dealer" || id === "card") {
            const source = id === "store" ? "ddlStoreID" : (id === "dealer" ? "ddlDealerId" : "ddlBankCardId");
            const opts = optionsOf(source);
            const current = read(source);
            stage.innerHTML = `<label>${title}</label><select id="askField" class="form-select">${opts.map((o) => `<option value="${o.value}" ${String(current) === String(o.value) ? "selected" : ""}>${o.text}</option>`).join("")}</select>`;
            document.getElementById("askField").oninput = (e) => {
                if (id === "dealer" && window.jQuery) jQuery("#ddlDealerId").val([e.target.value]).trigger("change");
                else write(source, e.target.value);
                paint();
            };
            paint();
            return;
        }
        if (id === "gst") {
            const gst = document.getElementById("gstProfileSelect");
            const opts = gst ? Array.from(gst.options).map((o) => `<option value="${o.value}">${o.text}</option>`).join("") : `<option value="">Off</option>`;
            stage.innerHTML = `<label>GST</label><select id="askField" class="form-select">${opts}</select>`;
            const field = document.getElementById("askField");
            if (gst) field.value = gst.value;
            field.oninput = () => {
                if (gst) {
                    gst.value = field.value;
                    gst.dispatchEvent(new Event("change", { bubbles: true }));
                }
                paint();
            };
            paint();
            return;
        }
        const inputId = box[id];
        stage.innerHTML = `<label>${title}</label><input id="askField" class="form-control" type="${id === "color" || id === "link" ? "text" : "number"}" value="${read(inputId)}" />`;
        const field = document.getElementById("askField");
        field.oninput = () => { write(inputId, field.value); paint(); };
        field.focus();
        field.onkeydown = (e) => { if (e.key === "Enter") document.getElementById("dealAskNext").click(); };
        paint();
    }

    document.getElementById("dealAskNext").onclick = () => {
        if (step === 0 && !read("txtDealName")) return;
        if (step < steps.length - 1) {
            step += 1;
            show();
            return;
        }
        const save = document.querySelector("form[name='deal_form'] button[type='submit']");
        if (save) save.click();
    };
    document.getElementById("dealAskBack").onclick = () => {
        if (step > 0) {
            step -= 1;
            show();
        }
    };

    fetch("/deals-data/0?draw=1&start=0&length=1000", { credentials: "same-origin", headers: { "X-Requested-With": "XMLHttpRequest", "Accept": "application/json" } })
        .then((res) => res.json())
        .then((json) => {
            const seen = {};
            (json.data || []).forEach((row) => {
                const name = (row.name || "").trim();
                if (!name || seen[name]) return;
                seen[name] = true;
                products.push(row);
            });
            show();
        })
        .catch(() => show());
    show();
})();
