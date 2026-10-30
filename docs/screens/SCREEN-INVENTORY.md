# Mintzer — Screen inventory (development count)

**Source of truth:** Markdown specs in this folder + `docs/design/`.  
**Full journey mockup:** `assets/mockups/mintzer-full-flow.html` (Login → end)  
**Mockups:** Files in `assets/mintzer-*.png` are **visual reference only** — layout and copy follow the spec docs.

---

## How many screens to develop?

| Layer | Count | What it means |
|-------|------:|---------------|
| **A — Main routes** | **14** | Full pages the user navigates to |
| **B — Overlays** | **12** | Sheets, dialogs, gates (on top of a page) |
| **C — Place order layouts** | **2** | External vs in-app — **one route**, two layouts |
| **Total UI surfaces** | **~26** | A + B (C lives inside Place order route) |

**Bottom line for Figma / frontend:** **14 pages** + **12 overlays** + **2 Place order layouts**.  
Dark mode = same routes, two themes (not double the count).

---

## A — Main routes (14)

**Live demo UI LOCKED 2026-09-18:** `assets/mockups/mintzer-designer-taste-demo.html` is the visual source for remaining screens (Orders, Wallet, success, tickets, Help, notifications). Do not restyle without client approval.

| # | Route / screen | Spec | LOCKED? |
|---|----------------|------|---------|
| 1 | Login — phone | [01-login.md](./01-login.md) | **LOCKED** 20 Sep 2026 · Welcome + benefits + unified +91 · Get OTP · compact lang · wave footer |
| 2 | Login — OTP | [01-login.md](./01-login.md) | **LOCKED** 20 Sep 2026 · 54px-fit squares · spaced +91 phone · Verify OTP · auto-submit · SMS autofill |
| 2b | **Post-login intro** | [01-login.md](./01-login.md) · [08-app-config.md](../backend-%20for%20developer%20reference/08-app-config.md) § Post-login intro | **LOCKED** 20 Sep 2026 · scale 0.94→1 · check on logo · Made in India 🇮🇳 · ~1.8s + precache · white → Home |
| 3 | Home (tab) | [02-home.md](./02-home.md) | **LOCKED** · style B · live demo · **Active order strip LOCKED** 20 Sep (green + live timer) |
| 4 | Deal detail | [03-deal-detail.md](./03-deal-detail.md) · [GST-DEAL-REQUIREMENTS.md](../design/GST-DEAL-REQUIREMENTS.md) | **LOCKED** 20 Sep 2026 · Payment summary + TDS · instructions · centered swipe · GST teal strip · Accept GST modal 1·2·3 |
| 5 | Place order | [04-accept-place-order.md](./04-accept-place-order.md) · [PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md) | **LOCKED** TEST dock · Flutter polish 20 Sep (checklist · sticky Reserved · Copy all) |
| 6 | Order placed success | [05-order-placed-success.md](./05-order-placed-success.md) | **LOCKED** · live demo |
| 7 | My Orders list (tab) | [06-my-orders.md](./06-my-orders.md) | **LOCKED** · Flutter ChatGPT list (20 Sep) + live demo rules |
| 8 | Order detail | [06-my-orders.md](./06-my-orders.md) · [ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md) | **LOCKED** · Flutter Order detail (20 Sep) |
| 9 | Wallet (tab) | [07-wallet.md](./07-wallet.md) · [WALLET-REQUIREMENTS.md](../design/WALLET-REQUIREMENTS.md) | **LOCKED** |
| 10 | ~~Offers~~ | **Retired from nav** — use **Wallet** tab instead · see [08-offers.md](./08-offers.md) |
| 11 | Profile (tab) | [09-profile.md](./09-profile.md) · [PROFILE-REQUIREMENTS.md](../design/PROFILE-REQUIREMENTS.md) | **LOCKED** |
| 11b | **FAQ** | [12-faq.md](./12-faq.md) | **LOCKED** · Profile sub-page · accordion |
| 12 | My tickets list + ticket detail | [13-my-tickets.md](./13-my-tickets.md) | **LOCKED** 20 Sep 2026 · inbox |
| 12b | **Notifications inbox (bell)** | [14-notifications.md](./14-notifications.md) | **LOCKED** 21 Sep 2026 · live demo list · Clear wipes · no archive · do not restyle |
| — | **Push templates (phone tray)** | [../design/NOTIFICATION-TEMPLATES-LOCKED.md](../design/NOTIFICATION-TEMPLATES-LOCKED.md) | **LOCKED** 22 Sep 2026 · inventory + India competitive bank · V3 defaults |
| 13 | **Account suspended** | [10-account-suspended.md](./10-account-suspended.md) · [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md) | **LOCKED** |
| 14 | **Account deleted** | [11-account-deleted.md](./11-account-deleted.md) · [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md) | **LOCKED** |

**Not a separate route:** App shell (bottom nav) · Ticket detail (`/profile/tickets/:id` — sub-page of tickets)

---

## B — Overlays / gates (12)

| # | UI | When | Spec |
|---|-----|------|------|
| 1 | KYC (PAN → Cashfree name) | First Accept · Step 1 of 2 | [BANK-AND-PAYOUT-DETAILS.md](../design/BANK-AND-PAYOUT-DETAILS.md) · **LOCKED** 20 Sep |
| 2 | Payout account (IFSC → bank) | After KYC · Step 2 of 2 | Same · **LOCKED** 20 Sep · no bank dropdown |
| 3 | How do you want to order? | First Place order (or Change) | [PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md) · **LOCKED** |
| 4 | Cancel order + reason picker | Place order + Order detail | ORDERS + Place order |
| 5 | Add note | Order detail | ORDERS |
| 6 | Finish current order first | Deal detail Accept blocked | [03-deal-detail.md](./03-deal-detail.md) |
| 6b | **GST invoice needed** (1·2·3) | First Accept on GST deal | [GST-DEAL-REQUIREMENTS.md](../design/GST-DEAL-REQUIREMENTS.md) · **LOCKED** 20 Sep |
| 7 | Resume order in progress (optional) | App reopen, once/session | [02-home.md](./02-home.md) |
| 8 | Raise ticket | Order detail | ORDERS |
| 9 | Ticket detail | Profile → My tickets | ORDERS |
| 10 | Appearance (Light / Dark / System) | Profile | [THEME-LIGHT-DARK-MODE.md](../design/THEME-LIGHT-DARK-MODE.md) |
| 11 | **Delete account** | Profile → Settings · confirm or **blocked** if order in progress | [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md) · **LOCKED** |
| 12 | **In-app update sheet** | Newer Play build — **Update available** · Update / Not now · download in app · Restart | [08-app-config.md](../backend-%20for%20developer%20reference/08-app-config.md) · **LOCKED** |
| 13 | **Contact us** | Profile → Contact support | [09-profile.md](./09-profile.md) · sheet only · Profile page stays locked |
| 14 | **Delivery boy calling** | Order detail + My Orders, only after OTP is saved and the order is on Confirmation | [06-my-orders.md](./06-my-orders.md) · does not change the flow line |

**Optional v1 overlays:** Payout edit, My Orders filter, Place order timer expired state, **Send a deal you saw** (Home empty).

**Required overlay:** Language picker **LOCKED 5 EN** bar (`EN` · `हि` · `ಕಾ` · `മല`) from Profile — and the same bar on Login. Applies immediately to the whole app.

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
/intro                      ← post-OTP brand beat (LOCKED) → /main
/account-suspended          ← suspended user (no main app)
/main
  /home
  /orders
  /orders/:id
  /offers
  /profile
  /profile/faq
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
