# Screen: My Orders

**Mockup:** `assets/mintzer-my-orders-list-mockup.png` (list) · Order detail: `assets/mintzer-order-inside-mockup.png`

## Purpose

Hub for **active placements** (timer running, Order ID not yet submitted) and **confirmed orders**. User resumes checkout from here, then completes tracking, delivery verification, and invoice — paste-friendly, one next action at a time.

**LOCKED:** [../design/ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md)

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

- Header bar: Mintzer order id + copy icon
- Horizontal progress: **Order placed → Shipped → Out for delivery → Delivered → Invoice → Payment**
- Product thumb, name, color, store logo
- Commission bar (orange/blue): **Commission ₹X** + **Open ›** or tap card to expand
- **48h payment timer** on card when invoice step active (existing rule)

## Order card (expanded) — inline steps

Only **one step active** at a time. Past steps show ✓ collapsed.

### Step 1 — Order placed ✓

Done after Accept flow. Show date.

### Step 2 — Tracking

| Field | Notes |
|-------|-------|
| Tracking ID | Paste field + Paste button |
| Save | Unlocks next step |

No delivery partner dropdown unless backend requires later. **No auto courier tracking.**

### Step 3 — Out for delivery

| Field | Notes |
|-------|-------|
| Last 4 digits | Delivery person mobile — last 4 only |
| OTP | 6+ digits from delivery |
| Save | Unlocks waiting state |

### Step 4 — Waiting for delivery (invoice locked)

| UI | Notes |
|----|-------|
| Grey message | “Waiting for delivery confirmation” |
| No upload button | Invoice disabled |

Backend admin marks **parcel received** → app polls or push updates card.

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
| Timer | **48:00:00 → 0:00:00** from invoice upload time |
| Copy | “Payment within 48 hours” |
| At zero | “Review complete — payment will reflect in wallet” |

### Step 7 — Paid

Move to **Completed** tab; link to Wallet history.

## User actions

| Action | Result |
|--------|--------|
| Paste tracking / OTP | Save step |
| Upload invoice | Start 48h frontend timer |
| Copy order id | Clipboard |
| Search | Filter list |

## Order detail — notes

- **Add note** / **Edit note** in header — user reference only (max 200 chars)
- Modal: “For your reference” · Save / Cancel
- Note on placement copies to order when Order ID confirmed

## Business rules

- **Active placement** appears in Ongoing **immediately after Accept** (with timer)
- Expired placement without Order ID → **does not** stay in Ongoing (admin log only)
- Multiple **confirmed** ongoing orders allowed (each at different step)
- Only **one** active placement timer at a time
- 48h timer is **frontend display**; starts at invoice upload timestamp from server
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
