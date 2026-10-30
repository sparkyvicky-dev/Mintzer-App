# Frontend implementation checklist

Tick items as built. All use **mock data** until backend phase.

**Scope:** [../screens/SCREEN-INVENTORY.md](../screens/SCREEN-INVENTORY.md) — **12 main routes**, **~10 overlays**, **~22 UI surfaces**. Mockups are reference only.

---

## Phase 1 — Shell

- [ ] Project created (Flutter or Expo)
- [ ] Material theme (Google blue primary)
- [ ] Bottom nav: Home, Orders, Wallet, Profile
- [ ] Support FAB placeholder
- [ ] Router between tabs + stack screens

---

## Phase 2 — Login

Spec: [../screens/01-login.md](../screens/01-login.md)

- [ ] Phone input (+91, 10 digits)
- [ ] Continue → OTP screen
- [ ] Fake verify → navigate Home
- [ ] No name/KYC fields

---

## Phase 3 — Home (LOCKED)

Spec: [../screens/02-home.md](../screens/02-home.md) · Mockup: `assets/mockups/home-samples.html`

- [ ] Header: Hi + wallet · bell · WhatsApp community
- [ ] Search + list/grid toggle + All/Direct/Link chips
- [ ] Tutorial banner first-time only (`tutorialSeen`)
- [ ] DealCard — list + grid: store logo on image · meta row (color + GST if any) · bank row · spend box · blue Earn button
- [ ] Active placement strip (mock) · blocked deal dim state
- [ ] Tap card → Deal detail

---

## Phase 4 — Deal detail

Spec: [../screens/03-deal-detail.md](../screens/03-deal-detail.md)

- [ ] Product image (fixed frame, contain)
- [ ] Name, color, variant, qty
- [ ] Store + bank **LogoRow** (no stretch)
- [ ] **MoneySummaryCard:**
  - [ ] YOU PAY (order value, platform fee, card fee, discount, total)
  - [ ] CASHBACK + billing cycle note
  - [ ] MINTZER WALLET
  - [ ] YOU EARN (hero green)
  - [ ] Expand: wallet formula
- [ ] Rules bullets + collapsible offer/links/how-to
- [ ] Sticky **Accept deal**
- [ ] Block accept if mock active placement → dialog

---

## Phase 5 — Place order (**LOCKED v2**)

Spec: [../screens/04-accept-place-order.md](../screens/04-accept-place-order.md) · [../design/PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md)  
HTML: `assets/mockups/place-order-locked.html`

- [ ] Mode choice sheet (first time) + Remember + Change chip
- [ ] Address block: **Copy per line** (7 rows) · optional *Copy all* link · Generate new
- [ ] **Variant B:** WebView + 3-button bar · Submit ID mini sheet
- [ ] **Variant C:** Show address fields ▾ on A (optional)
- [ ] Generate new address confirm dialog + toast
- [ ] Cancel order · timer expiry · KYC/bank gate

---

## Phase 6 — Order success

Spec: [../screens/05-order-placed-success.md](../screens/05-order-placed-success.md)

- [ ] Checkmark animation
- [ ] “Order placed!” + commission line
- [ ] Go to My Orders / Browse deals

---

## Phase 7 — My Orders + Order detail

Spec: [../screens/06-my-orders.md](../screens/06-my-orders.md) · [../design/ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md)

- [ ] Tabs: Ongoing / Completed; needs-action sort + badge
- [ ] **Placement card** in Ongoing: timer + **Continue order** → Place order
- [ ] Order card: id, progress bar, product, commission bar
- [ ] **Order detail** route (`/orders/:id`): stepper, cancel, report ticket
- [ ] **Add note** modal (user reference, 200 chars)
- [ ] One active step on detail (or expand — match final spec):
  - [ ] Tracking ID + paste
  - [ ] Last 4 + OTP (6+ digits)
  - [ ] Waiting (invoice locked) — mock `parcelReceived: false`
  - [ ] Upload invoice — enabled when mock flag true
  - [ ] 48h countdown after upload
- [ ] Collapsed label: next action only

---

## Phase 8 — Wallet (LOCKED spec)

- [ ] Wallet — [../design/WALLET-REQUIREMENTS.md](../design/WALLET-REQUIREMENTS.md) — Available, Pending, Total earned, full earn history, no withdraw
- [ ] Offers placeholder only — [../screens/08-offers.md](../screens/08-offers.md)
- [ ] Profile — [../screens/09-profile.md](../screens/09-profile.md)

---

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
