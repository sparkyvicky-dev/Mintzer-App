# Module: Deals & pricing

Admin deal creation, fee fields, calculated amounts, and API payload for the app Deal detail screen.

## Admin panel — field mapping

### Existing fields → canonical names

| Current admin label | Canonical field | Required | Notes |
|---------------------|-----------------|----------|-------|
| Dealer price (Product price) | `orderValue` | Yes | Base product price before checkout fees |
| Discount | `discount` | No | Store/coupon discount (default 0) |
| Cashback | `cashback` | Yes* | Bank cashback amount user gets on card |
| Cash Reward | `commission` | Yes | User **You earn** — rename in admin UI |
| Offer Text | `offerText` | Yes | Rules / instructions |
| Offer Link 1–3 | `offerLinks[]` | Link 1 required | Product URLs |
| Card holder will spend | `totalCheckout` | **Calculated** | Do not require manual entry long-term |
| Card holder will earn | `youEarn` | **Calculated** | = commission − tds |
| Total card holder will receive | `totalUserReceives` | **Calculated** | = wallet + cashback |

\*Cashback can be 0 if deal has no bank CB component.

### New fields (add to admin)

| Field | API key | Required | Notes |
|-------|---------|----------|-------|
| Platform fee | `platformFee` | No | Flipkart/platform handling fee (default 0) |
| Card fee | `cardFee` | No | Payment/card surcharge (default 0) |
| TDS | `tds` | No | Deducted from commission (default 0) |
| Cashback % | `cashbackPercent` | No | Display only, e.g. 5 — optional helper |
| Platform fee applies | `platformFeeApplies` | No | Flag if exact fee unknown |
| Card fee applies | `cardFeeApplies` | No | Flag if exact fee unknown |
| Fees eligible for cashback | `feesEligibleForCashback` | No | Always **false** for FK-style deals |

Also required on deal (from other admin sections): product, store, card, delivery address, pin, color, variant, logos, images.

---

## Calculation formulas

Run on **save/publish** in admin; store computed values on the deal record (snapshot at accept time on order).

### 1. Total checkout (what user pays)

```
totalCheckout = orderValue − discount + platformFee + cardFee
```

| Input | Example ₹ |
|-------|-----------|
| orderValue | 20,000 |
| discount | 0 |
| platformFee | 90 |
| cardFee | 110 |
| **totalCheckout** | **20,200** |

Maps to admin **Card holder will spend** and app **YOU PAY → Total checkout**.

**Cashback base:** Fees are **not** eligible for bank cashback. Cashback amount is entered or derived from eligible product amount (usually `orderValue − discount`), not from `totalCheckout`.

---

### 2. Wallet from Mintzer

```
walletFromMintzer = orderValue − cashback − discount + commission
```

| Input | Example ₹ |
|-------|-----------|
| orderValue | 20,000 |
| cashback | 1,000 |
| discount | 0 |
| commission | 300 |
| **walletFromMintzer** | **19,300** |

Credited to user wallet after order verified — not at accept time.

---

### 3. You earn (hero number in app)

```
youEarn = commission − tds
finalEarnings = youEarn
```

Example: commission 300, tds 0 → **youEarn = 300**

Maps to admin **Card holder will earn**.

---

### 4. Total user receives (wallet + bank)

```
totalUserReceives = walletFromMintzer + cashback
```

Example: 19,300 + 1,000 = **20,300**

Maps to admin **Total card holder will receive**.

User also paid `totalCheckout` out of pocket at store — this field is **total inflow** from Mintzer wallet + bank CB, not net profit.

---

## Worked examples

### Example 1 — Flipkart Axis style

| Field | ₹ |
|-------|---|
| orderValue | 20,000 |
| discount | 0 |
| platformFee | 0 |
| cardFee | 0 |
| totalCheckout | 20,000 |
| cashback | 1,000 |
| commission | 300 |
| walletFromMintzer | 19,300 |
| youEarn | 300 |
| totalUserReceives | 20,300 |

### Example 2 — Amazon Pay ICICI with fees

| Field | ₹ |
|-------|---|
| orderValue | 22,999 |
| discount | 0 |
| platformFee | 79 |
| cardFee | 0 |
| totalCheckout | 23,078 |
| cashback | 1,149 |
| commission | 600 |
| tds | 0 |
| walletFromMintzer | 22,450 |
| youEarn | 600 |
| totalUserReceives | 23,599 |

Verify wallet: 22,999 − 1,149 + 600 = **22,450** ✓

---

## Admin UX recommendations

1. **Auto-calculate** spend, earn, receive on field change — show read-only preview matching app layout.
2. **Rename** Cash Reward → **Commission**.
3. **Validate** before publish: `walletFromMintzer` matches formula; `youEarn` = commission − tds.
4. **Snapshot** all money fields onto `order` when user confirms Order ID — deal edits must not change past orders.

### Admin preview block (mirror app)

```
YOU PAY
  Order value       ₹__
  Platform fee      ₹__
  Card fee          ₹__
  Discount          − ₹__
  Total checkout    ₹__

CASHBACK (bank)
  Cashback          ₹__
  (billing cycle note)

MINTZER WALLET      ₹__

YOU EARN
  Commission        ₹__
  TDS               − ₹__
  Final earnings    ₹__
```

---

## API: `GET /deals` (list)

Return minimal fields for Home cards:

```json
{
  "id": "deal_123",
  "productName": "IQOO Z10 Lite 5G",
  "productImageUrl": "...",
  "store": { "id", "name", "logoUrl" },
  "card": { "id", "label", "logoUrl" },
  "orderValue": 20000,
  "totalCheckout": 20200,
  "youEarn": 300,
  "color": "Cyber Green",
  "isActive": true
}
```

## API: `GET /deals/:id` (detail)

Full payload for Deal detail screen:

```json
{
  "id": "deal_123",
  "product": {
    "name": "IQOO Z10 Lite 5G",
    "color": "Cyber Green",
    "variant": "4GB/128GB",
    "qty": 1,
    "imageUrl": "..."
  },
  "store": { "id": "flipkart", "name": "Flipkart", "logoUrl": "..." },
  "card": { "id": "axis", "label": "Axis Credit Card", "logoUrl": "...", "cashbackPercent": 5 },
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
    "youEarn": 300,
    "totalUserReceives": 20300
  },
  "feeFlags": {
    "feesEligibleForCashback": false,
    "platformFeeApplies": false,
    "cardFeeApplies": false
  },
  "offerText": "...",
  "offerLinks": ["https://..."],
  "deliveryAddress": { "pin": "800020", "fullAddress": "..." },
  "rules": ["Any colour", "Apply coupon 500"],
  "expiresAt": null,
  "isActive": true
}
```

## API: Admin `POST /admin/deals` / `PUT /admin/deals/:id`

Request body includes all input fields; server calculates and persists `money.*` computed fields.

Reject publish if:

- `orderValue` ≤ 0
- `walletFromMintzer` ≠ orderValue − cashback − discount + commission
- `totalCheckout` ≠ orderValue − discount + platformFee + cardFee

## Database (deal record — suggested)

```
deals
  id, product_*, store_id, card_id
  order_value, discount, platform_fee, card_fee
  total_checkout, cashback, commission, tds
  wallet_from_mintzer, you_earn, total_user_receives
  offer_text, offer_links (json)
  delivery_address (json)
  fee_flags (json)
  is_active, expires_at, created_at, updated_at
```

## Logo assets (backend storage)

- Store `logoUrl` per store entity — normalized PNG/SVG (fixed canvas, transparent padding).
- Store `logoUrl` per card entity — same rules.
- Do not accept arbitrary per-deal logo uploads without size guidelines.
