# Frontend implementation checklist

Tick items as built. All use **mock data** until backend phase.

---

## Phase 1 — Shell

- [ ] Project created (Flutter or Expo)
- [ ] Material theme (Google blue primary)
- [ ] Bottom nav: Home, Orders, Offers, Profile
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

## Phase 3 — Home

Spec: [../screens/02-home.md](../screens/02-home.md)

- [ ] Header: logo, wallet balance mock, notifications
- [ ] Search bar (UI only)
- [ ] **Active placement banner** when mock flag true → tap opens Accept
- [ ] Deal list from mock JSON
- [ ] Deal card: image, name, store/card chips, order price, **Earn ₹X**
- [ ] Block other deals when active placement (dim + message)
- [ ] Tap deal → Deal detail

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

## Phase 5 — Accept

Spec: [../screens/04-accept-place-order.md](../screens/04-accept-place-order.md)

- [ ] Countdown from mock 15 min (or config constant)
- [ ] Product + card summary
- [ ] Short money row: pay / earn
- [ ] Copy address, copy pin, open store (toast on copy)
- [ ] Order ID field + Paste chip
- [ ] Upload screenshot (image picker UI)
- [ ] Submit → Success
- [ ] **Cancel order** + confirm dialog → Home, clears active placement
- [ ] Timer expiry UI → Home message

---

## Phase 6 — Order success

Spec: [../screens/05-order-placed-success.md](../screens/05-order-placed-success.md)

- [ ] Checkmark animation
- [ ] “Order placed!” + commission line
- [ ] Go to My Orders / Browse deals

---

## Phase 7 — My Orders

Spec: [../screens/06-my-orders.md](../screens/06-my-orders.md)

- [ ] Tabs: Ongoing / Completed
- [ ] Order card: id, progress bar, product, commission bar
- [ ] Expand card — one active step:
  - [ ] Tracking ID + paste
  - [ ] Last 4 + OTP (6+ digits)
  - [ ] Waiting (invoice locked) — mock `parcelReceived: false`
  - [ ] Upload invoice — enabled when mock flag true
  - [ ] 48h countdown after upload
- [ ] Collapsed label: next action only

---

## Phase 8 — Other tabs (light)

- [ ] Wallet mock balance — [../screens/07-wallet.md](../screens/07-wallet.md)
- [ ] Offers static list — [../screens/08-offers.md](../screens/08-offers.md)
- [ ] Profile phone + KYC placeholder — [../screens/09-profile.md](../screens/09-profile.md)

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
