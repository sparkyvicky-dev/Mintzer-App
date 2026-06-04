# Mintzer App — Designer Handoff

> **Give your designer:** **[FOR-DESIGNER.md](./FOR-DESIGNER.md)** — complete handoff (locked Home, flows, polish, deliverables, file index).  
> This file is a shorter index + PDF instructions.

---

## Get a PDF (for your designer)

**Easiest (no coding):**

1. Open this file in **Google Chrome** after generating HTML (step 2), **or** open `docs/design/DESIGNER-HANDOFF.html` if it already exists.
2. Press **Ctrl+P** (Print).
3. Destination: **Save as PDF**.
4. Turn on **Background graphics**.
5. Save as `DESIGNER-HANDOFF.pdf`.

**Generate the HTML file (once):** in the project folder run:

```bash
node scripts/md-to-print-html.js designer
```

Then open: `docs/design/DESIGNER-HANDOFF.html` in Chrome and print to PDF.

**PDF will be saved wherever you choose** (Downloads, Desktop, etc.) — it is not auto-created in the repo unless you run a PDF tool separately.

---

**App:** Mintzer (Android first) — users accept card deals, order on Flipkart/Amazon, submit proof, get paid in Wallet.  
**Style:** Google Material — clean, light by default, dark mode supported. **No purple gradients. No copy of PerkPay dark/gold look.**  
**Primary blue:** `#1A73E8` (light) · `#8AB4F8` (dark) — **fixed**; logo colors do not change app palette.

**Colors for every screen:** [COLORS-AND-TOKENS.md](./COLORS-AND-TOKENS.md) · each `docs/screens/*.md` has a **Colors (Figma)** section.

**Platform:** Design fluid in Figma first (tokens + spacing). Build in **Flutter** (repo default) or another framework after design — same tokens map to code.

**Validation (all screens):** Wrong format → **inline under field**. API / duplicate / network / *Copied* → **snackbar bottom-right**. Full table: [VALIDATION-UX.md](./VALIDATION-UX.md)

---

## 1. How many screens to design?

| Type | Number | Notes |
|------|--------|--------|
| **Full screens (pages)** | **14** | User navigates between these |
| **Pop-ups / sheets** | **11** | Open on top of a page |
| **Place order** | **2 layouts** | External vs in-app — one route |

**Total work:** **~25 UI pieces** (14 pages + 11 overlays). Place order = 2 layouts inside page #5.  
**Full flow HTML:** `assets/mockups/mintzer-full-flow.html` (Login → end)  
**Dark mode:** same 14 pages in dark — not new flows.

Reference images (if any) are in folder `assets/mintzer-*.png`. **If an image disagrees with this document, follow this document.**

---

## 2. Full screens — list all 14

| # | Screen name | What user does here |
|---|-------------|---------------------|
| 1 | **Login — phone** | Enter +91 mobile → Continue |
| 2 | **Login — OTP** | Enter 6-digit code → Verify |
| 3 | **Home** | **LOCKED** — list/grid deals · earn button · spend box · GST on color row · mockup `home-samples.html` |
| 4 | **Deal detail** | Read product, fees, earn amount → **Accept deal** |
| 5 | **Place order** | Timer — copy address, open store / WebView, submit Order ID |
| 6 | **Order placed — success** | Short “done” screen → Go to My Orders |
| 7 | **My Orders — list** | All orders; Ongoing / Completed tabs |
| 8 | **Order detail** | One order — tracking, delivery OTP, invoice, payment wait |
| 9 | **Wallet** | Pending + Available cards, filters, date range, **Download Excel**, history ( **no withdraw** ) |
| — | ~~Offers~~ | **Not in nav v1** — deferred |
| 11 | **Profile** | KYC, payout, theme, tickets, help, **Delete account**, logout |
| 12 | **My tickets** | List of support tickets from Profile |
| 13 | **Account suspended** | Ops suspended user — contact support, no app access |
| 14 | **Account deleted** | After delete account — back to login |

**Bottom bar on main app (always):** Home · Orders · **Wallet** · Profile  
**Floating button:** Support (chat) on main tabs

---

## 3. Pop-ups / sheets — list all 11

| # | Name | When it appears |
|---|------|-----------------|
| 1 | **KYC** | First time user accepts a deal — Name + PAN |
| 2 | **Payout details** | Right after KYC — UPI **or** bank account |
| 3 | **How do you want to shop?** | First place order (or “Change” later) |
| 4 | **Cancel order** | User cancels — pick a reason from list |
| 5 | **Add note** | Order detail — personal reminder only (200 chars max) |
| 6 | **Finish current order first** | User taps Accept while another order timer is active |
| 7 | **Resume order** (optional banner) | User reopens app with timer still running |
| 8 | **Raise ticket** | Order detail — category → short questions → submit |
| 9 | **Ticket detail** | From My tickets |
| 10 | **Appearance** | Profile — Light / Dark / System |
| 11 | **Delete account** | Profile → Settings — confirm, or **blocked** if order in progress |

**Account suspended (#13)** and **Account deleted (#14)** are full pages, not overlays.

**Optional v1:** Language picker (English / Hindi), Edit payout from Profile.

---

## 3b. Account suspended & delete (LOCKED)

**Spec:** `docs/design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md`

### Suspended (page 13)

Shown when ops terminates account — at login or mid-session.

**Copy:**  
*Your account is not active right now. Please contact support if you want to restore access.*

**Actions:** Contact support · Back to login  
**No** harsh “banned” wording in UI.

### Delete account (Profile → overlay 11)

**Block** if active placement or any order in progress.

**Blocked copy:**  
*You have an order in progress. Please finish or cancel it before deleting your account.*

### Account deleted (page 14)

**Copy:**  
*Your account has been removed. Contact support if you need help.*

**Action:** Back to login

---

## 4. Place order screen (important) — LOCKED v3 final

After **Accept**, this is the **main area**. User **rechecks model, color, variant** here before checkout.

**Open in Chrome (external + in-app):** `assets/mockups/place-order-locked.html`

**Full spec:** `docs/design/PLACE-ORDER-REQUIREMENTS.md`

### External (default — Open Flipkart)

Single scroll · Open Flipkart right after checkout · address below.

**Bottom dock (fixed — 2 rows):**

| Row | Content |
|-----|---------|
| 1 | ⏱ Complete order in **MM:SS** |
| 2 | **Tap to paste Order ID** field + **Submit** |

### In-app (Flipkart WebView)

WebView + PerkPay drag-up sheet (Deal · Delivery · Help tabs when expanded).

**Bottom dock (fixed — 1 row):**

`[ ⏱ MM:SS ]` · `[ Order ID field ]` · `[ Submit ]`

### Tap-to-paste Order ID (both modes) — LOCKED

- **No separate Paste button**
- User copies Order ID on Flipkart → returns → **one tap on field** = focus + paste from clipboard
- Empty field: *Tap to paste Order ID* · toast *Pasted* · if clipboard empty: *Copy Order ID from Flipkart first*
- Field filled → tap to edit manually

### Also on screen

Product · checkout ₹ · discount · earn · address Copy each line · Generate new address · Cancel · mode chip

**External:** no tabs. **In-app:** 3 sheet tabs only (not on external).

---

## 5. Main user journey (draw this flow)

```
Login → Home → Deal detail → Accept
         ↓ (first time only)
      KYC → Bank/UPI details
         ↓
      [Choose: order yourself OR shop in app]
         ↓
      Place order (timer) → Submit Order ID
         ↓
      Success screen → My Orders
         ↓
      Tracking → Delivery OTP → Wait (Mintzer confirms) → Invoice → 48h wait → Paid → Wallet
```

---

## 6. Deal detail — money block (must be clear)

Show a **card** with rows (example numbers):

- Order value  
- Platform fee, Card fee (if any)  
- Total you pay at checkout  
- Bank cashback (user’s card — not from Mintzer)  
- Wallet credit from Mintzer  
- **You earn (commission)** — **largest green number**

Footer note: cashback comes from bank billing cycle; Mintzer wallet after order completes.

**Bottom of screen:** sticky **Accept deal** button (blue).

**Top:** WhatsApp icon + **Report error** (opens WhatsApp with deal info prefilled).

---

## 7. My Orders — list card types

### Card type A — Timer still running (not submitted Order ID yet)

- Timer: “Complete order in 12:34”  
- Product image + name + store  
- Earn amount  
- Button: **Continue order**

### Card type B — Order submitted (normal order)

- Order ID + copy  
- Progress: Placed → Shipped → Out for delivery → Invoice → Payment  
- One line: what user must do next (e.g. “Add tracking ID”)  
- Tap card → **Order detail** full page

---

## 8. Order detail — steps (vertical timeline)

| Step | User action |
|------|-------------|
| Accepted / Placed | Show date + external Order ID (read-only) |
| Tracking | Paste tracking ID + choose courier (auto-guess + “change if wrong”) |
| Out for delivery | Last 4 digits of delivery phone + OTP (6+ digits) |
| Waiting | Grey — “Waiting for Mintzer” — no upload |
| Invoice | Upload photo/PDF (only after Mintzer unlocks) |
| Payment | 48-hour countdown after invoice uploaded |
| Paid | Done — moves to Completed tab |

**Header:** Order ID · **Add note** · Cancel order · Report issue (ticket)

---

## 9. Wallet (locked — do not add withdraw)

| Block | Meaning |
|-------|---------|
| **Available** | Money user can count on now |
| **Pending** | Earned but not approved yet |
| **Total earned** | Lifetime |
| **List below** | Every order — Paid / Pending / Canceled + amount |

**No** bank transfer button · **No** withdraw in app.

---

## 10. Profile (locked)

- Hi {name} + avatar initial  
- KYC status  
- Payout details (edit)  
- Language  
- **Appearance** (Light / Dark / System)  
- My tickets  
- Help / Tutorials / Notifications / Terms  
- Logout (red text)

**Do not put** Wallet or My Orders shortcuts here (they are in bottom bar).

---

## 11. Colors

### Light mode (default)

| Use | Color |
|-----|-------|
| Primary buttons, links | `#1A73E8` |
| Background | `#F8F9FA` |
| Cards | `#FFFFFF` |
| Earn / success | `#188038` |
| Warning (timer low) | `#F9AB00` |
| Error / cancel | `#D93025` |
| Text main | `#202124` |
| Text secondary | `#5F6368` |

### Dark mode

| Use | Color |
|-----|-------|
| Background | `#121212` |
| Cards | `#1E1E1E` |
| Primary | `#8AB4F8` |
| Text main | `#E8EAED` |
| Earn | `#81C995` |

**Rule:** Same layout in light and dark — only colors change.

---

## 12. Logos (store + bank on deal cards)

- Fixed box size — logo **never stretched**  
- Store logo ~40×40 · Bank/card logo ~32×32  
- Logo on **left**, text on **right**  
- Missing logo → grey circle with letter (F, A, etc.)

---

## 13. What NOT to design for v1

- Admin website  
- Withdraw / add money to bank from app  
- Instant orders tab  
- In-app WhatsApp chat (only opens real WhatsApp)  
- Auto-tracking courier map  

---

## 14. Deliverables for designer

1. **Figma** — all **14** screens (light) + same 14 (dark)  
2. **11 overlays** as components  
3. **Place order** — `place-order-locked.html` · full journey — `mintzer-full-flow.html`  
4. **Design system** — colors, type, buttons, input fields, cards  
5. **Export** — store/bank logo placeholders, product image frame  

---

## 15. Detailed specs (if designer needs more)

| Topic | File in project |
|-------|-----------------|
| Screen list & routes | `docs/screens/SCREEN-INVENTORY.md` |
| Place order (locked) | `docs/design/PLACE-ORDER-REQUIREMENTS.md` |
| Account suspend / delete | `docs/design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md` |
| Full flow mockup | `assets/mockups/mintzer-full-flow.html` |
| Orders list + detail | `docs/design/ORDERS-PAGES-REQUIREMENTS.md` |
| Wallet (locked) | `docs/design/WALLET-REQUIREMENTS.md` |
| Profile (locked) | `docs/design/PROFILE-REQUIREMENTS.md` |
| KYC + bank | `docs/design/BANK-AND-PAYOUT-DETAILS.md` |
| Light / dark | `docs/design/THEME-LIGHT-DARK-MODE.md` |

---

**Version:** June 2026 · Mintzer rebuild v1
