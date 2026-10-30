# Frontend implementation checklist

Tick items as built. The running tree is [03-flutter-app-map.md](./03-flutter-app-map.md). Live API flags are on in `AppConfig`. This list is the build log.

**Scope:** [../screens/SCREEN-INVENTORY.md](../screens/SCREEN-INVENTORY.md) — **12 main routes**, **~10 overlays**, **~22 UI surfaces**. Mockups are reference only.

---

## Phase 1 — Shell

- [x] Project created (Flutter or Expo)
- [x] Material theme (live-demo purple `#7B61FF`)
- [x] Bottom nav: Home, Orders, Wallet, Profile
- [x] Help chip (not round FAB)
- [x] Router between tabs + stack screens (Navigator; go_router skipped — SDK mismatch)
- [x] Live-order mapper (pure Dart, null-safe) + tests

---

## Phase 2 — Login

Spec: [../screens/01-login.md](../screens/01-login.md)

- [x] Phone input (+91, 10 digits)
- [x] Continue → OTP screen
- [x] Fake verify → navigate Home
- [x] No name/KYC fields

---

## Phase 3 — Home (LOCKED)

Spec: [../screens/02-home.md](../screens/02-home.md) · Mockup: `assets/mockups/mintzer-designer-taste-demo.html` (style B)

- [x] Header: Hi + wallet · bell · WhatsApp community
- [x] Search + list/grid toggle + All/Direct/Link chips
- [x] Tutorial banner first-time only (`tutorialSeen`)
- [x] DealCard **style B:** store pin + GST · photo · grey fade (name + color) · caption bank + pinned ₹ · purple Earn. One urgency chip in a free corner
- [x] Active placement strip (mock) · blocked deal dim state
- [x] Tap card → Deal detail

---

## Phase 4 — Deal detail

Spec: [../screens/03-deal-detail.md](../screens/03-deal-detail.md)

- [x] Product image (fixed frame, contain)
- [x] Name, color, variant, qty
- [x] Store + bank **LogoRow** (no stretch)
- [x] **MoneySummaryCard:** Product value · Discount · fees · Cashback · Checkout · bank cashback · From Mintzer · bank-statement note
- [x] Rules bullets (max 3)
- [x] Sticky magnetic **Swipe to accept**
- [x] Block accept if mock active placement → dialog

---

## Phase 5 — Place order (**LOCKED v2**)

Spec: [../screens/04-accept-place-order.md](../screens/04-accept-place-order.md) · [../design/PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md)  
HTML: `assets/mockups/place-order-locked.html`

- [x] Address block: **Copy per line** (mock rows) · Generate new (confirm)
- [x] Bottom dock: ring timer · tap-to-paste Order ID · Submit
- [ ] Mode choice sheet (first time) + Remember + Change chip
- [ ] **Variant B:** WebView + 3-button bar · Submit ID mini sheet
- [ ] **Variant C:** Show address fields ▾ on A (optional)
- [ ] Cancel order · timer expiry · KYC/bank gate

---

## Phase 6 — Order success

Spec: [../screens/05-order-placed-success.md](../screens/05-order-placed-success.md)

- [x] Checkmark / success chrome
- [x] “Order Placed” + earn chip
- [x] Go to My Orders → Orders tab

---

## Phase 7 — My Orders + Order detail

Spec: [../screens/06-my-orders.md](../screens/06-my-orders.md) · [../design/ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md)

- [x] Tabs: Ongoing / Completed + badge
- [x] **Placement card** in Ongoing: Continue → Place order
- [x] Order card: id, **7-step icon rail**, earn, View order
- [x] **Order detail** route: vertical timeline (track / OTP / simulate steps)
- [x] **Live order mapper** — [../backend- for developer reference/11-live-order-migration.md](../backend-%20for%20developer%20reference/11-live-order-migration.md) (Placed/Shipped/OFD/invoice/`is_payout` → 7 steps; never re-ask Order ID)
- [x] Must-test fixtures: Tracking due · Invoice due · Already paid (seed My Orders)
- [x] `nextActionLabel` + adapter → MockOrder (sparse rows never crash)
- [x] **Add note** modal (user reference, 200 chars)
- [x] One active step on detail (mock advance):
  - [x] Tracking ID + save
  - [x] Last 4 + OTP
  - [x] Waiting (simulate parcel)
  - [x] Upload invoice (mock)
  - [x] Payment → Simulate paid
- [x] Collapsed label: next action only
- [x] Cancel + Report issue (guided ticket)
- [x] My tickets list + ticket thread (+ simulate admin)
---

## Phase 8 — Wallet (LOCKED spec)

- [x] Wallet — [../design/WALLET-REQUIREMENTS.md](../design/WALLET-REQUIREMENTS.md) — Total earned, Pending, full earn history, no Available, no withdraw
- [ ] Offers placeholder only — deferred
- [x] Profile — refer hero, KYC/payout rows, language 5 EN, FAQ, logout/delete
- [x] FAQ accordion (EN subset of locked copy)
- [x] Payout details edit (bank + optional UPI)
- [x] Appearance Light / Dark / System

---

## Phase 9 — Polish remaining

- [x] Help chip general ticket (topic dropdown)
- [x] Notifications list
- [x] KYC PAN sheet on first Accept (gate)

## Mock deal sample (minimum fields)

Use for Home + Deal detail dev:

```json
{
  "id": "deal_1",
  "productName": "IQOO Z10 Lite 5G (4GB/128GB)",
  "color": "Cyber Green",
  "variant": "4GB/128GB",
  "qty": 1,
  "store": { "name": "Flipkart", "logoUrl": "..." },
  "card": { "label": "Axis Credit Card", "logoUrl": "..." },
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
  }
}
```

---

## When frontend is done

Replace mock repository with API client matching [../backend/](../backend/README.md) module by module: auth → deals → placements → orders → wallet.
