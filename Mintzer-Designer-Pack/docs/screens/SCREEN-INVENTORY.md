# Mintzer — Screen inventory (development count)

**Source of truth:** Markdown specs in this folder + `docs/design/`.  
**Full journey mockup:** `assets/mockups/mintzer-full-flow.html` (Login → end)  
**Mockups:** Files in `assets/mintzer-*.png` are **visual reference only** — layout and copy follow the spec docs.

---

## How many screens to develop?

| Layer | Count | What it means |
|-------|------:|---------------|
| **A — Main routes** | **14** | Full pages the user navigates to |
| **B — Overlays** | **11** | Sheets, dialogs, gates (on top of a page) |
| **C — Place order layouts** | **2** | External vs in-app — **one route**, two layouts |
| **Total UI surfaces** | **~25** | A + B (C lives inside Place order route) |

**Bottom line for Figma / frontend:** **14 pages** + **11 overlays** + **2 Place order layouts**.  
Dark mode = same routes, two themes (not double the count).

---

## A — Main routes (14)

| # | Route / screen | Spec | LOCKED? |
|---|----------------|------|---------|
| 1 | Login — phone | [01-login.md](./01-login.md) | Spec |
| 2 | Login — OTP | [01-login.md](./01-login.md) | Spec |
| 3 | Home (tab) | [02-home.md](./02-home.md) | **LOCKED** · list/grid · `home-samples.html` |
| 4 | Deal detail | [03-deal-detail.md](./03-deal-detail.md) | Spec + mockup ref |
| 5 | Place order | [04-accept-place-order.md](./04-accept-place-order.md) · [PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md) | **LOCKED** |
| 6 | Order placed success | [05-order-placed-success.md](./05-order-placed-success.md) | Spec |
| 7 | My Orders list (tab) | [06-my-orders.md](./06-my-orders.md) | Spec + mockup ref |
| 8 | Order detail | [ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md) | Spec + mockup ref |
| 9 | Wallet (tab) | [07-wallet.md](./07-wallet.md) · [WALLET-REQUIREMENTS.md](../design/WALLET-REQUIREMENTS.md) | **LOCKED** |
| 10 | ~~Offers~~ | **Retired from nav** — use **Wallet** tab instead · see [08-offers.md](./08-offers.md) |
| 11 | Profile (tab) | [09-profile.md](./09-profile.md) · [PROFILE-REQUIREMENTS.md](../design/PROFILE-REQUIREMENTS.md) | **LOCKED** |
| 12 | My tickets list | [ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md) | Spec |
| 13 | **Account suspended** | [10-account-suspended.md](./10-account-suspended.md) · [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md) | **LOCKED** |
| 14 | **Account deleted** | [11-account-deleted.md](./11-account-deleted.md) · [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md) | **LOCKED** |

**Not a separate route:** App shell (bottom nav) · Ticket detail (`/profile/tickets/:id` — sub-page of tickets)

---

## B — Overlays / gates (11)

| # | UI | When | Spec |
|---|-----|------|------|
| 1 | KYC (Name + PAN) | First Accept | [BANK-AND-PAYOUT-DETAILS.md](../design/BANK-AND-PAYOUT-DETAILS.md) · **LOCKED** |
| 2 | Payout details (UPI / bank) | After KYC, first Accept | Same |
| 3 | How do you want to shop? | First Place order (or Change) | [PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md) · **LOCKED** |
| 4 | Cancel order + reason picker | Place order + Order detail | ORDERS + Place order |
| 5 | Add note | Order detail | ORDERS |
| 6 | Finish current order first | Deal detail Accept blocked | [03-deal-detail.md](./03-deal-detail.md) |
| 7 | Resume order in progress (optional) | App reopen, once/session | [02-home.md](./02-home.md) |
| 8 | Raise ticket | Order detail | ORDERS |
| 9 | Ticket detail | Profile → My tickets | ORDERS |
| 10 | Appearance (Light / Dark / System) | Profile | [THEME-LIGHT-DARK-MODE.md](../design/THEME-LIGHT-DARK-MODE.md) |
| 11 | **Delete account** | Profile → Settings · confirm or **blocked** if order in progress | [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md) · **LOCKED** |

**Optional v1 overlays:** Language (EN/HI), Payout edit, My Orders filter, Place order timer expired state.

---

## C — Place order: two layouts, one route

| Layout | Default? |
|--------|----------|
| **External** — Open Flipkart + scroll + bottom dock | Yes |
| **In-app** — WebView + PerkPay sheet + single-row bottom dock | Optional |

Spec: [PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md) · mockup: `place-order-locked.html`

---

## Navigation map (routes)

```
/login
/login/otp
/account-suspended          ← suspended user (no main app)
/main
  /home
  /orders
  /orders/:id
  /offers
  /profile
  /profile/tickets
  /profile/tickets/:id
/deal/:id
/place-order/:placementId
/order-success/:orderId
/account-deleted            ← after delete → login
```

---

## Happy-path flow (design order)

See **`assets/mockups/mintzer-full-flow.html`**

```
Login → OTP → Home → Deal detail → Accept
  → [KYC] → [Payout] → [Shop mode] → Place order → Success
  → My Orders → Order detail → Wallet / Profile
```

**Account paths:** Suspended at login · Delete account from Profile · Account deleted screen

---

## What is NOT a user screen in v1

| Item | Notes |
|------|--------|
| Admin panel | Separate web app |
| WhatsApp chat UI | Opens external WhatsApp |
| Withdraw | Not in app |

---

## Mockup files (reference)

| Area | File |
|------|------|
| Full flow | `mockups/mintzer-full-flow.html` |
| Place order | `mockups/place-order-locked.html` |
| PNG refs | `assets/mintzer-*.png` |

If a mockup disagrees with a spec doc, **follow the spec doc**.
