# Screen: Deal detail

**Mockup:** `assets/mintzer-deal-detail-mockup.png`  
**LOCKED visual (20 Sep 2026):** Flutter `deal_detail_screen.dart` + live demo report chip / swipe. Payment summary (You pay · Bank cashback · Mintzer payout · Your earnings = commission − TDS) · How this is calculated · Instructions before checkout · Before you order · Buy on / Pay using · magnetic **Swipe to accept** (label + Accepted centered; sublabel *Reserve this deal and start earning*). **GST deals:** teal strip under Payment summary. Do not restyle without approval.

## Purpose

Let the user **read and decide** before committing. No timer, no order ID, no address copy on this screen (Option B).

---

## GST on Deal detail (LOCKED)

When `gstApplicable` / `deal.gst`:

- Photo: small **GST** pill (teal tokens).
- Teal strip: *GST invoice needed. At checkout, enter the Company and GST No. shown in the delivery address.*
- On Accept: modal per [GST-DEAL-REQUIREMENTS.md](../design/GST-DEAL-REQUIREMENTS.md) — never dump Company/GSTIN in the modal; never say “Mintzer GST” or “personal GST”.

## Entry points

- Home → tap deal card / **Earn ₹X**
- Notification re-engage after expired timer (optional)

---

## 1. Product block

| Element | Spec |
|---------|------|
| Product image | PNG in a **fixed frame** (e.g. 160×160 or 4:3). Image uses **contain** — never stretch. Size feels natural; consistency matters more than big vs small. |
| Product name | Full title, 2 lines max then ellipsis |
| Color | e.g. Cyber Green / **Any colour** |
| Variant | Storage etc. e.g. **6GB/128GB** |
| Qty | Usually **Qty: 1** — show when deal requires specific quantity |

---

## 2. Store & bank logos (professional setup)

**Problem today:** logos random size — tiny, stretched, or huge.

**Rule:** Logo never sets its own size. A **fixed container** sets the size; logo **fits inside** without distortion.

### Layout pattern (recommended)

```
┌──────────────────────────────────────┐
│  [store logo]  Flipkart              │
│  [bank logo]   Card to use · Axis Credit Card │
└──────────────────────────────────────┘
```

- **Logo first (left), text after (right)** — easier to scan; matches IDZO/competitor clarity.
- Alternative label: **Axis Credit Card** with small “Card to use” caption above in grey — logo still left.

### Logo asset rules (design + backend)

| Type | Container | Fit | Format |
|------|-----------|-----|--------|
| Store (Flipkart, etc.) | 40×40 dp box, 8dp padding | `contain` — aspect ratio preserved | PNG/SVG transparent; prepare **one master per store** |
| Bank / card (Axis, SBI, etc.) | 32×32 dp box (or 40×24 wide lockup) | `contain` — **never stretch width** | Official lockup where possible |

**Do not:** full-width logo bars, different heights per deal, or scaling only width.

**Asset prep (before app):** Export each store/bank logo into the same canvas size (e.g. 80×80 @2x) with transparent padding so they **look equal in the app**. One person edits logos centrally — not per-deal in admin without guidelines.

**Fallback:** If logo missing → grey circle with first letter (F, A) — never broken image.

---

## 3. Money block

Every deal uses the **same layout**. Admin fills numbers; app shows exact rupees — no vague “Earn” badge without breakdown.

#### Core formula (From Mintzer)

```
From Mintzer  =  Order value  −  Cashback  −  Discount  +  Commission
```

| Field | Meaning |
|-------|---------|
| **Order value** | Product price at checkout (before/after store discount — admin defines) |
| **Cashback** | Bank/card cashback — **your bank pays this**, as per that card’s rules. Not paid by Mintzer. |
| **Discount** | Store/coupon discount (0 if none) |
| **Commission** | User’s **deal profit** / **You earn** (hero number) |
| **From Mintzer** | Amount Mintzer pays to the user’s **bank account** after the order is verified. No in-app withdraw. |

#### Example 1 — Flipkart Axis

| Line | ₹ |
|------|---|
| Order value | 20,000 |
| Cashback (5%) | 1,000 |
| Discount | 0 |
| Commission | 300 |
| **Wallet from Mintzer** | **19,300** |

User pays **₹20,000** (+ fees if any). Bank credits **₹1,000** on next billing cycle. User **earns ₹300** (commission).

#### Example 2 — Amazon Pay ICICI (with fees)

| Line | ₹ |
|------|---|
| Actual / order value | 22,999 |
| Platform + card fees | + 79 → **Total you pay 23,078** |
| Cashback (~5%) | 1,149 |
| Discount | 0 |
| Commission | 600 |
| **Wallet from Mintzer** | **22,450** |

Check: 23,078 − 1,149 + 600 ≈ 22,529 (admin may use order value 22,999 in formula: 22,999 − 1,149 + 600 = **22,450** ✓).

Fees are **not eligible** for cashback — show in **You pay**, not in CB base.

---

#### UI (always visible — no accordion required)

One **Money card** with clear rows:

```
┌─────────────────────────────────────────┐
│  Product value            ₹20,000       │
│  − Discount               − ₹   500     │
│  Platform fee             ₹   200       │
│  Card fee                 ₹   320       │
│  Cashback                 ₹   875       │
│  ─────────────────────────────────      │
│  Checkout value           ₹20,020       │
│  From bank cashback       ₹   875       │
│  From Mintzer             ₹19,xxx       │
│                                         │
│  Cashback will be credited to your      │
│  card/account according to the          │
│  bank statements.                       │
└─────────────────────────────────────────┘
```

**Footer note (always show):**

> Cashback will be credited to your card/account according to the bank statements.

**Expand ▼ How wallet is calculated** (optional):

```
Order value     ₹20,000
− Cashback      ₹ 1,000
− Discount      ₹     0
+ Commission    ₹   300
= From Mintzer  ₹19,300
```

---

### Fees honesty

If fees not entered per deal, show chip: **Platform/card fees may apply — not eligible for cashback.**

If admin enters fees, list each row in **YOU PAY**. Do not guess Flipkart fees.

> Small checkout difference (₹1–99) is normal. If total is **much higher** than shown, do not pay — contact support.

---

## 4. Help actions (deal detail header) — **LOCKED** Sep 2026

One control. Top-right of the app bar. No extra bar under the title. No reason chips.

```
←  Deal detail     [ Anything wrong?  ●WA ]
```

| Element | Spec |
|---------|------|
| **Combined report + WhatsApp chip** | Fixed width (~154dp). White surface, hairline `#E8EAED`, green WhatsApp disc on the right. |
| **Cycling copy (inside the chip)** | `Anything wrong?` → `Wrong info?` → `Price changed?` → `Discount changed?` → `More fee?` → `Out of stock?` → `Wrong product?` → `GST extra?` — text stays inside the box; ellipsis if a language runs long. |
| **Tap** | Opens WhatsApp with a **pre-filled** deal message (name, store, card, spend, earn, deal id). No second step. |
| **Visibility** | Hidden when admin **WhatsApp support = OFF**. |
| **Title** | `Deal detail` sits **left** of the chip (next to back). Do not center the title over the chip. |

Not the same as **order ticket** on order detail (guided flow). This is quick report to admin about the **deal** before/during accept.

Live reference: `assets/mockups/mintzer-designer-taste-demo.html` (deal-detail app bar).

## 5. Other deal detail content

| Element | Description |
|---------|-------------|
| Back | Return to Home |
| Share | Optional share deal link |
| Rules | Max 3 bullets (coupon, colour, card warnings) |
| Collapsible **Offer details** | TDS, payout timing, cancellation rules |
| Collapsible **Links** | Product URL — copy + open |
| Collapsible **How to use** | YouTube tutorial |
| Deal badge | Optional: Instant / Regular |
| Expiry | “Valid till …” if time-limited |
| Sticky CTA | **LOCKED** — **Swipe to accept** (magnetic). Full-width pill. Copy is **Swipe to accept**, never “lock”. Drag the knob (or the track). Commit ~70% or a flick; otherwise it springs back. Completing starts the same Accept flow (KYC / payout / placement). |

---

## User actions

| Action | Result |
|--------|--------|
| Accept deal | Check active placement rule → **Accept / place order** |
| Expand sections | Breakdown, fees note, offer details |
| Copy link | Copy product URL |
| Back | Home |

## Business rules

- If another accept timer is already active → dialog: “Finish your current order first” → **Accept screen**.
- **Accept deal** starts backend timer.
- Money figures come from backend; label as **target / estimated** where Flipkart fees apply.

## States

| State | UI |
|-------|-----|
| Loading | Skeleton — include logo placeholders fixed size |
| Accept blocked | Dialog if active order exists |
| Deal expired | Grey CTA “Deal unavailable” |

## Navigation

| From | To |
|------|-----|
| Accept deal | Accept / place order |
| Back | Home |

## Backend notes

`GET /deals/:id` should return structured money + assets:

```json
{
  "product": { "name", "color", "variant", "qty", "imageUrl" },
  "store": { "id", "name", "logoUrl" },
  "card": { "id", "label", "logoUrl", "cashbackPercent": 5 },
  "money": {
    "orderValue": 20000,
    "platformFee": 90,
    "cardFee": 110,
    "discount": 0,
    "totalCheckout": 20200,
    "cashback": 1000,
    "commission": 300,
    "walletFromMintzer": 19300,
    "tds": 0,
    "youEarn": 300
  },
  "feeFlags": { "feesEligibleForCashback": false },
  "rules", "links", "expiresAt"
}
```

Admin panel must calculate `walletFromMintzer` = orderValue − cashback − discount + commission (fees excluded from CB base, included in totalCheckout).

Logo URLs must point to **pre-normalized** assets (same padding/sizing pipeline).

## What is NOT on this screen

- Countdown timer
- Delivery address copy
- Order ID / screenshot
- Cancel order (on Accept screen)

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md)

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| Product card | `#FFFFFF` |
| Store / bank logo box | `#E8EAED` + letter (temp) → PNG later |
| Commission / earn lines | `#188038` |
| Checkout / pay amount | `#202124` bold |
| Sticky Accept | Magnetic **Swipe to accept** pill. Fill uses primary `#1A73E8`. |
| Warning hint | `#E37400` on `#FEF7E0` if used |

**Logos:** Never stretch · never recolor Flipkart/bank marks.

## Validation

Accept blocked → **overlay** *Finish current order first* (not snackbar). No field validation on this screen.

**Full rules:** [../design/VALIDATION-UX.md](../design/VALIDATION-UX.md)

## Design

- Scrollable content; sticky **Accept deal**
- **Money summary + logos** visible without scrolling past hero on most phones

## 14 Oct 2026

Not part of the delivery-call update. This screen stays as written above.
