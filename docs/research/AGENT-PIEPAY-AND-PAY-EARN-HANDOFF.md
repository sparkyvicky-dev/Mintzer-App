# Agent handoff — PiePay checkout + Mintzer “Pay & earn” direction

**Audience:** Cursor agents building the **refreshed Mintzer public app** (`D:\dev\mintzer-app`)  
**Owner context:** Mintzer (India) — card-offer deals on Flipkart/Amazon  
**Last updated:** August 2026  
**Status:** Research complete enough to plan; API capture still optional for 100%

---

## 0. Read this when

- Implementing **buyer-side shopping** or **holder Pay-for-buyer** flows  
- Comparing Mintzer v1 (Order & earn) vs PiePay (Pay & earn)  
- Deciding backend job queue, WebView, session relay, UPI wallet  
- **Do not** treat this as LOCKED v1 scope — v1 specs remain holder-first unless owner explicitly expands

**Shorter flow doc:** [PIEPAY-CHECKOUT-KNOWLEDGE.md](./PIEPAY-CHECKOUT-KNOWLEDGE.md)  
**APK tech only:** `D:\dev\Mintzer-admin-app\apk-pull\PIEPAY-TECH-ANALYSIS.md`  
**Mintzer v1 process:** [../AGENT-DEV-PROCESS.md](../AGENT-DEV-PROCESS.md)

---

## 1. Executive summary

**PiePay** is a **two-sided marketplace**:

| Side | User | Action |
|------|------|--------|
| **Buyer** | Shopper without the right card | Shops FK/Amazon inside app → pays **PiePay** (UPI) → gets discount |
| **Cardholder** | Person with eligible card | Accepts deal → pays **Flipkart/Amazon** on **buyer’s checkout** → earns commission |

**Core trick:** There is **no Flipkart payment URL**. PiePay copies the buyer’s **logged-in checkout session** (cookies + checkout state) to the holder’s phone via their server. Holder completes payment with **their card**; order remains on **buyer’s merchant account**.

**Amazon works the same way** as Flipkart — WebView (or Amazon app) + same session handoff at payment. No Amazon API partnership.

**Mintzer today (v1 specs):** **Order & earn** only — admin-posted deals, holder accepts, shops with **dealer address**, submits Order ID. **PerkPay-like**, not PiePay buyer flow.

**Owner intent (Aug 2026):** Eventually add **Pay & earn** (PiePay-style) as income system — likely **after** v1 holder app ships. Document everything now for future phases.

---

## 2. Three products compared (agent reference)

| | **Mintzer v1 (locked specs)** | **PiePay Pay & earn** | **PiePay Order & earn** |
|---|------------------------------|------------------------|-------------------------|
| **Who starts** | Holder picks admin deal | Buyer shops any product | Holder (similar to Mintzer) |
| **Deal source** | Admin API | Buyer browse + auto job | Posted / browse |
| **Merchant** | External FK app or WebView | FK/Amazon **inside** PiePay | External |
| **Address** | Mintzer dealer address | **Buyer’s own address** | Varies |
| **Payment** | Holder pays merchant | **Holder pays on buyer session**; buyer pays PiePay | Holder pays |
| **Order on** | Holder flow → buyer N/A | **Buyer’s FK/Amazon account** | — |
| **Complexity** | Medium | **Very high** | Medium |

**Competitor note:** PerkPay ≈ Mintzer holder model. PiePay ≈ buyer marketplace + session relay.

---

## 3. PiePay buyer flow (observed — Flipkart test)

Real test: OPPO phone, buyer **Vignesh**, holder test account, PiePay `com.piepay` v21.0.0-beta.0.

### 3.1 UI progression

```
Login PiePay
  → Open Flipkart inside app (header: Shop | Summary | Discount)
  → FK Order Summary (buyer name/address visible — buyer's FK login)
  → FK Payments Step 3/3
  → Overlay: "Fetching product details" / "Checking merchant discounts"
  → Bottom sheet: Buy for ₹32,208 · Save ₹1,940 · BUY NOW (timer ~4 min)
  → "Searching for the perfect Cardholder" (radar)
  → Optional slider: add ₹0–500 to match faster
  → Complete order: You → PiePay → Flipkart diagram
       · Pay to PiePay (selected)
       · "Sanju will pay for your order"
       · PAY ₹32,456 via UPI · Save ₹1,940 (timer ~10 min)
  → After UPI: "Order processing" (persists after force-close app)
  → Success when holder completes FK payment
  → Order in buyer's Flipkart My Orders
```

### 3.2 Buyer rules (inferred)

- Buyer **does not** complete Flipkart payment themselves in Pay & earn mode  
- Buyer **does** pay PiePay first (UPI)  
- Processing screen = waiting on **server job** + holder FK payment  
- App restore on cold start = server returns active job status  

### 3.3 Example numbers (one real deal)

| Field | Value |
|-------|--------|
| FK list / checkout price | ~₹34,148 – ₹34,396 |
| PiePay buy price | ₹32,208 – ₹32,456 |
| Buyer savings | ~₹1,940 |
| Holder pay on FK | ₹33,148 |
| Bank cashback (holder) | ₹1,658 |
| PiePay reimbursement (holder) | ₹31,969 |
| Holder earn | **₹479** |
| Handling fee detected | ₹248 (FK "Offer & Payment Handling Fees") |

---

## 4. PiePay cardholder flow (observed)

### 4.1 Entry

- Tab: **Deals for you → Pay & earn** (separate tab: **Order & earn**)  
- Copy: *Pay for these people and earn cashback plus reimbursement*  
- Deal card: buyer first name, product, **Earn ₹X**, **Pay ₹Y**, required bank logo, reimbursement date  
- CTA: **EARN ₹479 — Pay for this Buyer**

### 4.2 Four-step checklist (exact product behavior)

| Step | State | Holder action |
|------|--------|----------------|
| **1** | Active | FK still visible behind sheet. Tap **Credit/Debit/ATM Card** → **Continue** → enter **holder card number**. Verify payment amount (e.g. ₹33,148) and cashback (e.g. ₹1,658). **DO NOT PAY** until confirmation. |
| **2** | After amounts match | PiePay detects fee changes → **Accept deal** (shows card ending e.g. 6059). Timer on button. |
| **3** | After Accept | **Wait until we confirm {buyer}'s payment** — buyer UPI to PiePay must clear first. |
| **4** | After confirm | Enter CVV/expiry → **Pay on Flipkart**. |

### 4.3 Proof holder sees **buyer's** checkout

On holder device, FK Payment page lists **buyer's saved cards** (e.g. Flipkart Axis • 3806, SBI, HDFC…) — not holder's wallet.  
**Conclusion:** Session is buyer's; holder only supplies payment card.

### 4.4 Why re-type card number

- Saved cards on page = **buyer's** FK account  
- Holder must use **Credit/Debit card** path with **their** number  
- FK recalculates offer on page → PiePay **reads DOM** → unlocks Accept deal  
- Message: *Continue using same card used to accept this deal*

---

## 5. Session handoff — how checkout works (no magic URL)

### 5.1 What buyer has at payment step

- Logged into **buyer's** Flipkart in PiePay WebView  
- FK created checkout tied to **buyer's account** (address, cart, order draft)  
- Normal FK payment URL in address bar — **not shareable** as a unique pay link  

### 5.2 What PiePay transfers

```
Buyer WebView (FK payment page)
    → extract: cookies, checkout/cart state, parsed amounts, required card type
    → encrypt (native AES/RSA — see APK)
    → POST to PiePay backend (job created)
    → FCM/poll notifies matching holders

Holder app opens job
    → backend sends session blob + target URL
    → inject cookies into holder WebView
    → load same FK payment step → shows buyer's saved cards
    → holder enters own card → pay
```

### 5.3 What PiePay does **not** do

- Share buyer's FK password  
- Order on holder's FK account to buyer address  
- Use official Flipkart/Amazon checkout API  
- Rely on a permanent payment deep link  

### 5.4 Page monitoring (fee / amount detection)

- `injectedJavaScript` on WebView (APK evidence)  
- Reads visible totals, cashback lines, handling fee text  
- Gates **Accept deal** until DOM matches expected deal terms  
- Re-prompts if FK adds fees (e.g. +₹248)  

---

## 6. Amazon — same model as Flipkart

**Evidence:** APK queries `in.amazon.mShop.android.shopping`; buyer flow is merchant-agnostic in UI.

| Step | Flipkart | Amazon India |
|------|----------|--------------|
| Browse | amazon.in or Amazon app in WebView | Same |
| Login | Buyer's Amazon account | Same |
| Stop point | Payment step | Payment step |
| Session copy | Cookies + checkout state | Same mechanism |
| Holder pays | Buyer's Amazon checkout + holder's card | Same |
| Order owner | Buyer Amazon account | Same |

**Implementation note for Mintzer:** Separate **page parsers** / step copy per merchant (DOM differs), same **job + session** backend.

---

## 7. PiePay technical stack (APK analysis)

**Pulled from device:** `Mintzer-admin-app/apk-pull/piepay-base.apk`  
**Package:** `com.piepay` · **v21.0.0-beta.0 (99)**

| Layer | Technology |
|-------|------------|
| App framework | **React Native** + **Hermes** |
| OTA updates | **Microsoft CodePush** — **most checkout logic NOT in store APK** |
| In-app merchant | **react-native-webview** |
| Cookies | **@react-native-cookies/cookies** |
| Session crypto | `com.piepay.RNCryptoAESModule`, `com.piepay.RSAOAEPModule` |
| Buyer UPI | **Cashfree PG** + **Razorpay** SDK |
| Push | Firebase FCM + **Notifee** |
| Deep links | `link.piepay.in`, AppsOnAir |
| Observability | Sentry (+ session replay), Firebase Crashlytics |

**Gap:** PiePay REST API host/paths live in **CodePush JS bundle** — not extracted yet. Use HTTP Toolkit during live deal to capture.

---

## 8. Logical architecture (for Mintzer engineers)

```
┌─────────────────────────────────────────────────────────────────┐
│                        MINTZER / PIEPAY BACKEND                  │
│  Job queue · session store · matching · wallet · notifications │
└────────────▲───────────────────────────────────────▲────────────┘
             │                                       │
    ┌────────┴────────┐                   ┌────────┴────────┐
    │   BUYER APP     │                   │  HOLDER APP     │
    │  WebView shop   │                   │  Pay & earn tab │
    │  Offer overlay  │                   │  4-step UI      │
    │  UPI → platform │                   │  WebView pay    │
    └────────┬────────┘                   └────────┬────────┘
             │                                       │
             ▼                                       ▼
      Flipkart / Amazon                         Same checkout
      (buyer session)                           (session replay)
```

### 8.1 Suggested backend entities (greenfield)

| Entity | Purpose |
|--------|---------|
| `CheckoutJob` | status: draft → matching → buyer_paid → holder_paying → completed / failed / expired |
| `SessionBlob` | encrypted cookies + metadata + merchant + expiry |
| `DealTerms` | expected pay amount, cashback, card BIN/bank, timers |
| `MatchOffer` | holder id, earn, reimbursement date |
| `BuyerPayment` | UPI via Cashfree/Razorpay id, amount |
| `HolderPayment` | FK/Amazon pay confirmation signal (manual or scraped) |

### 8.2 Suggested job state machine (holder UI)

```
NOT_STARTED → STEP1_CARD_ENTERED → STEP2_DEAL_ACCEPTED → STEP3_WAIT_BUYER_UPI → STEP4_PAY_MERCHANT → DONE
                                      ↑ fee change may loop back
```

Buyer UI states: `SHOPPING → OFFER_SHOWN → MATCHING → PAY_PLATFORM → PROCESSING → DONE`

---

## 9. Mintzer refreshed app — what exists vs what to build

### 9.1 Already specced (v1 — build first)

Location: `mintzer-app/docs/`

- Holder journey: Home → Deal detail → Accept → Place order → Order ID  
- **Order & earn** model, dealer address, timer, wallet view-only  
- Flutter + Material `#1A73E8`, nav: Home · Orders · Wallet · Profile  
- Backend specs: `docs/backend- for developer reference/`  
- **Live admin API** on Hostinger (`mintzer.in/newapp`) — map in Phase C, not greenfield  

**Agent rule:** Do not block v1 on Pay & earn. Ship holder app per locked specs.

### 9.2 Future — Pay & earn (PiePay-style)

Not specced in screen inventory yet. Requires **new** screens + **new** backend modules.

| Component | Notes |
|-----------|--------|
| Buyer onboarding / KYC | Separate or shared with holder? TBD with owner |
| Shop WebView | FK + Amazon, merchant picker |
| Offer engine | Card offer DB or scrape at payment |
| Matching | Push to holders by card type + availability |
| Platform UPI | Cashfree/Razorpay merchant account for Mintzer |
| Holder Pay & earn tab | Deal feed + 4-step flow |
| Session relay service | Highest risk / maintenance |
| Returns & disputes | Policy + UI (PiePay advertises return support) |

See [MINTZER-PAY-EARN-ROADMAP.md](./MINTZER-PAY-EARN-ROADMAP.md) for phased build order.

---

## 10. Income / business model (owner context)

**Why owner cares:** Pay & earn scales beyond manually posted deals — any FK/Amazon product.

| Revenue | Mechanism |
|---------|-----------|
| Platform spread | Buyer pays Mintzer > Mintzer reimburses holder − holder earn |
| Match priority fee | Optional tip to holder (PiePay slider ₹0–500) |
| Volume | Many transactions vs limited admin deals |

| Cost / risk | |
|-------------|--|
| FK/Amazon DOM changes break scrapers | |
| Failed matches, expired checkouts | |
| Payment disputes, returns | |
| Compliance (KYC, payment aggregator rules) | |
| Fraud (fake buyers, card misuse) | |

---

## 11. Confidence matrix

| Claim | Confidence | Source |
|-------|------------|--------|
| Order on buyer FK account | **High** | Owner test + holder saw buyer saved cards |
| Session not URL | **High** | User confirmed no pay link; holder UI proves buyer session |
| Buyer pays platform UPI before holder pays FK | **High** | Screenshots + step 3 wait |
| WebView + cookies + injected JS | **High** | APK |
| Cashfree/Razorpay for buyer | **High** | APK |
| Exact API JSON | **Low** | Need network capture or CodePush bundle |
| Amazon identical flow | **Medium–High** | APK + same product pattern; less live testing |

---

## 12. How to get 100% API proof (owner / QA)

### No code (enough for product)

1. Two phones, cheap item  
2. Screen record buyer + holder full flow  
3. Screenshot buyer FK/Amazon My Orders  

### With capture (for backend design)

1. PC: [HTTP Toolkit](https://httptoolkit.com)  
2. Phone same WiFi, install cert once  
3. Capture during Buy now → match → UPI → holder pay  
4. Export HAR; grep non-FK/non-Amazon hosts  

### Dev

- APK: `Mintzer-admin-app/apk-pull/piepay-base.apk`  
- Java + JADX for native modules  
- Wireless pull script: `Mintzer-admin-app/scripts/pull-piepay-apk.bat`

---

## 13. Risks & compliance (agents must flag to owner)

- Flipkart/Amazon **Terms of Service** — session sharing may violate merchant ToS  
- **PCI** — never store holder CVV; WebView only  
- **Session security** — encrypt blobs, short TTL, one-time use  
- **App store** — WebView checkout + third-party payment aggregation policies  
- PiePay uses Sentry **session replay** — consider privacy if Mintzer copies  

---

## 14. Related repositories & paths

| Path | Contents |
|------|----------|
| `D:\dev\mintzer-app\` | **New public holder app** specs, mockups (Flutter not started) |
| `D:\dev\Mintzer-admin-app\` | Admin Flutter app (MAA) + Laravel upload packs |
| `mintzer-app/docs/AGENT-DEV-PROCESS.md` | v1 build process |
| `mintzer-app/docs/design/PLACE-ORDER-REQUIREMENTS.md` | v1 Order & earn place order (LOCKED) |
| `mintzer-app/docs/research/` | This research folder |
| `Mintzer-admin-app/apk-pull/` | PiePay APK + `PIEPAY-TECH-ANALYSIS.md` |
| Live API | Hostinger `~/domains/mintzer.in/public_html/newapp` |

---

## 15. Agent checklist — implementing Pay & earn later

- [ ] Owner explicitly approved phase (not v1 default)  
- [ ] Read this doc + `MINTZER-PAY-EARN-ROADMAP.md`  
- [ ] v1 holder app shipped or parallel team assigned  
- [ ] Payment gateway merchant account for Mintzer  
- [ ] Legal/compliance sign-off on session relay  
- [ ] Network capture or API spec for session upload endpoint  
- [ ] Separate FK and Amazon QA test matrices  
- [ ] Do not copy PiePay UI verbatim — Mintzer brand `#1A73E8`  

---

## 16. Glossary

| Term | Meaning |
|------|---------|
| **Pay & earn** | Holder pays merchant on buyer's checkout (PiePay) |
| **Order & earn** | Holder places order themselves (Mintzer v1, PerkPay) |
| **Session blob** | Cookies + state to replay checkout on another device |
| **Dealer address** | Mintzer-provided shipping address (v1 only) |
| **Checkout job** | Server record linking buyer, holder, merchant, timers |
| **CodePush** | PiePay OTA JS updates — why APK alone is incomplete |

---

*Document compiled from owner live PiePay testing (Aug 2026), screenshots, and APK reverse engineering. Update when HTTP capture or Mintzer Pay & earn specs are written.*
