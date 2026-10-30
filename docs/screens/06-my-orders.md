# Screen: My Orders

**Mockup:** `assets/mintzer-my-orders-list-mockup.png` (list) · Order detail: `assets/mintzer-order-inside-mockup.png`

## Purpose

Hub for **active placements** (timer running, Order ID not yet submitted) and **confirmed orders**. User resumes checkout from here, then completes tracking, delivery verification, and invoice — paste-friendly, one next action at a time.

**LOCKED:** [../design/ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md) · live demo `mintzer-designer-taste-demo.html` (2026-09-18)  
**Flutter list LOCKED (20 Sep 2026):** ChatGPT compact cards in `app/lib/screens/orders_screen.dart` — Mintzer ID, 4-stage rail with exact state logic, notes, whole-card open, filter/sort. Do not restyle without approval.  
**Order detail LOCKED (20 Sep 2026):** `order_detail_screen.dart` — one expanded stage · compact completed · Report + ⋮ · note as **popup dialog** · Payment soft card · Paid → Wallet. Do not restyle without approval.  
**Live Play orders:** [../backend- for developer reference/11-live-order-migration.md](../backend-%20for%20developer%20reference/11-live-order-migration.md) — same rows, new rail. Do not reset Order ID.

## Entry points

- Bottom nav **Orders**
- Order placed success → **Go to My Orders**
- Notification → next action on specific order

## Top section

| Element | Description |
|---------|-------------|
| Title | My Orders |
| Search | **Order ID · Tracking ID · product name / model** |
| Tabs row 2 | **Ongoing** · **Completed** |

## Placement card (collapsed) — before Order ID submit

Shown at top of **Ongoing** when user has active placement:

| Element | Description |
|---------|-------------|
| Reference | Placement ref + copy |
| **Timer** | **Complete order in `MM:SS`** (sync with Place order screen) |
| Product thumb, name, store |
| Earn ₹X | From deal |
| Status line | e.g. “Finish checkout and submit Order ID” |
| Primary action | **Continue order** → Place order |
| Tap card | Place order (same as Continue) |

## Order card (collapsed) — after Order ID confirmed

Each card shows:

- Product thumb, name, store, Order ID
- **No** Tracking / Payment / Paid text chips — the icon rail is the stage
- Icon rail for the 7 steps (bag · truck · parcel · home · invoice · clock · paid)
- Earn amount (`+₹X` / paid)
- **View order**
- Full step timeline on **Order detail** (same icons). **In progress:** purple done + pulsing current. **Paid:** full rail green. Upcoming grey.

## Order card (expanded) — inline steps

Only **one step active** at a time. Past steps show ✓ collapsed.

### Step 1 — Order placed ✓

Show **Order ID** with **Edit** until the order is paid. After paid, read-only.

### Step 2 — Tracking

| Field | Notes |
|-------|-------|
| Tracking ID | Paste field + Paste button |
| Save | Unlocks next step. Saved tracking stays visible with **Edit**. |
| Courier | Auto-detect: **FMPP / FMPC / EK = Ekart**. Dropdown to change. |

No delivery partner dropdown unless backend requires later. **No auto courier tracking.**

### Step 3 — Out for delivery

| Field | Notes |
|-------|-------|
| Last 4 digits | Last 4 of the number used to place the order — **not** the delivery person |
| OTP | 6+ digits from delivery |
| Save | Unlocks confirmation. Saved last 4 + OTP stay visible with **Edit**. |

### Step 4 — Delivery confirmation (invoice locked)

| UI | Notes |
|----|-------|
| Title | **Confirmation** |
| Copy | “This may take up to 1 working day.” |
| No upload button | Invoice stays locked until delivery is confirmed |

Backend admin marks **parcel received** → app polls or push updates card. Demo: simulate.

### Step 5 — Upload invoice (unlocked)

| UI | Notes |
|----|-------|
| Green hint | “You can upload invoice now” |
| Upload | Photo or PDF |
| Submit | Starts 48h timer UI |

User uploads only after physical delivery; some stores issue invoice at ship — ops gate prevents early upload.

### Step 6 — Payment countdown

| UI | Notes |
|----|-------|
| Copy | **One cheer per visit** (does **not** rotate on a timer). Short, a little funny, professional: **1st** `🎉 On the way to your account` · **2nd** `Checked — still in the queue` · **3rd** `Looked again. Still moving` · **later** `Same payout. Next working day` |
| Amount | **From Mintzer** = admin **Total card holder will receive** (bank transfer). Never You pay + profit. Optional lines: Bank cashback (if &gt; 0) · Your earnings (Card holder will earn) |
| Timer | Same **ring timer** as Place order, on the **right** (Xh / YYm inside) |
| Sub | “48 working hours · no payouts on bank holidays” |

### Step 7 — Paid / Completed

Show **Completed** on the list. Receipt on Order detail:
- **From Mintzer** = Total receive (what hit the bank)
- **Bank cashback** when &gt; 0 (from card issuer — separate)
- **Your earnings** = Card holder will earn
- **Account** · **UTR** · **Paid on** (date only, e.g. `8 Oct 2026` — no clock). Hide until API sends real `paid_at` / payout day. Never use phone “now”.

Never show You pay + profit as “credited”.

After paid, the order is **settled**: no Edit on Order ID / tracking / OFD / notes. Header keeps **Report issue**. **Cancel** stays until paid (store can cancel).

**Wording:** **From Mintzer** = Total receive to the user’s bank. **Bank cashback** sub: *Credited to your card/account according to the bank statements.* Your earnings = profit (Card holder will earn).

## User actions

| Action | Result |
|--------|--------|
| Paste tracking / OTP | Save step |
| Upload invoice | Start 48h frontend timer |
| Copy order id | Clipboard |
| Search | Filter list |

## Order detail — notes

- **Add note** / **Edit note** in header until paid (max 200 chars). Note also shows on the My Orders card.
- After paid: note stays visible, not editable.
- Modal: “For your reference” · Save / Cancel
- Note on placement copies to order when Order ID confirmed

## Cancel (own button, not inside Report issue)

**Cancel** on every unpaid order (store may cancel too). Reason required:

- Store canceled · Marketplace canceled · Price higher than deal · Out of stock · Changed my mind

After cancel: Completed tab · Canceled label · reason kept.

## Delivery boy calling (14 Oct 2026)

Only after the delivery OTP is saved, until the invoice is uploaded. Live orders skip the Confirmation wait, so the button is on that stage. Not before OTP, and not while the invoice is checking, or on Payment, Paid, or Canceled.

| Where | What |
|-------|------|
| Order detail | Green card above the steps. One button. The words change: Delivery boy calling? · Delivery agent calling? · Delivery person calling? · Any other issue? · Rescheduled? |
| My Orders card | Same button. Tap does not open the order, except **Rescheduled?** which opens Edit |

WhatsApp message, only the lines that exist:

```
Delivery boy is calling me now.

Order ID: …
Mintzer order: …   (only when it differs from Order ID)
Product: …
Courier: …
Tracking ID: …
Last 4: …
OTP: …
```

The same button changes words:

- **Delivery boy calling** → WhatsApp with this order
- **Any other issue?** → WhatsApp help with this order
- **Rescheduled?** → existing **Edit**. New OTP and last 4. No WhatsApp

**Any other issue?** message:

```
Hi Mintzer, I need help with this order.

Order ID: …
Product: …
Tracking ID: …
```

Unchanged on these screens: flow line, money lines, cancel, report issue, note, tracking, invoice, payout.

## Report issue (ticket)

Pick one, then **one follow-up at a time** (not a dump):

| Reason | Follow-up |
|--------|-----------|
| Product canceled | Who canceled? · Got SMS/email? |
| Paid extra vs app | Checkout more than You pay? · Screenshot? |
| Different color | Was that color on the deal? |
| Different variant | Storage/size, model, or not sure? |
| Other | Type max **80** characters |

Submit → ticket ID. **My tickets → tap ticket** shows the thread (you + Mintzer admin updates). Demo: Simulate admin reply.

## Business rules

- **Active placement** appears in Ongoing **immediately after Accept** (with timer)
- Expired placement without Order ID → **does not** stay in Ongoing (admin log only)
- Multiple **confirmed** ongoing orders allowed (each at different step)
- Only **one** active placement timer at a time
- 48h timer is **frontend display** of **working hours** (bank holidays skipped); starts at invoice upload timestamp from server
- **Live Play rows:** map `Placed` / `Shipped` / `Out For Delivery` / invoice / `is_payout` — [11-live-order-migration.md](../backend-%20for%20developer%20reference/11-live-order-migration.md). Legacy: invoice unlocks after OTP (no extra Confirmation wait)
- Invoice upload enabled only when backend flag `parcelReceived = true`

## States

| State | UI |
|-------|-----|
| Empty ongoing | “No orders yet” + CTA Home |
| Loading | Skeleton cards |
| Step complete | Collapse step, expand next |
| Invoice locked | Grey step 5 |
| Invoice unlocked | Active upload |
| Payment timer | Hero countdown on card |

## Navigation

| From | To |
|------|-----|
| Commission / expand | Expanded card inline |
| Paid | Completed tab |
| Support FAB | Chat |

## Backend notes

- `GET /orders?status=ongoing|completed` — includes **placement** rows (`kind: placement`) and **order** rows (`kind: order`)
- `GET /placements/active` — used with orders list for Home strip + timer sync
- `PATCH /placements/:id/note` · `PATCH /orders/:id/note` — user note (optional)
- `PATCH /orders/:id/tracking` — `{ trackingId }`
- `PATCH /orders/:id/out-for-delivery` — `{ phoneLast4, otp }`
- Admin: `POST /admin/orders/:id/mark-received`
- `POST /orders/:id/invoice` — file upload; returns `paymentTimerEndsAt`
- Push notifications per step reminder (optional)

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md)

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| Order cards | `#FFFFFF` |
| Timer on ongoing card | `#E37400` / `#FEF7E0` |
| Status strip (needs action) | `#E8F0FE` + `#1A73E8` |
| Continue / primary CTA | `#1A73E8` |
| Paid / earn | `#188038` |
| Cancel / destructive | `#D93025` |

## Validation

Tracking · OTP · invoice · note · cancel reason — **inline under field**; API errors **Snackbar** bottom-right. See [../design/VALIDATION-UX.md](../design/VALIDATION-UX.md) and [../design/ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md).

## Design

- Paste-friendly wide inputs on card
- Show **only next action** label on collapsed card
- **Flow line (LOCKED):** one vertical rail. Done steps = green ✓ node + green line. Current = pulsing purple node + purple fade into grey. Upcoming = hollow grey. Live demo.
