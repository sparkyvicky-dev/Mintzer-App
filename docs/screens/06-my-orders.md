# Screen: My Orders

## Purpose

Hub for all orders after Order ID confirmed. User completes tracking, delivery verification, and invoice on **each order card** — paste-friendly, one next action at a time.

## Entry points

- Bottom nav **Orders**
- Order placed success → **Go to My Orders**
- Notification → next action on specific order

## Top section

| Element | Description |
|---------|-------------|
| Title | My Orders |
| Search | Search by Order ID |
| Tabs row 1 | Regular orders · Instant orders (if product needs both) |
| Tabs row 2 | **Ongoing** · **Completed** |

## Order card (collapsed)

Each card shows:

- Header bar: Mintzer order id + copy icon
- Horizontal progress: **Order placed → Shipped → Out for delivery → Delivered → Invoice → Payment**
- Product thumb, name, color, store logo
- Commission bar (orange/blue): **Commission ₹X** + **Open ›** or tap card to expand

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

## Business rules

- Orders without Order ID in time **never appear here** (admin logs only)
- Multiple ongoing orders allowed (each at different step)
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

- `GET /orders?status=ongoing|completed`
- `PATCH /orders/:id/tracking` — `{ trackingId }`
- `PATCH /orders/:id/out-for-delivery` — `{ phoneLast4, otp }`
- Admin: `POST /admin/orders/:id/mark-received`
- `POST /orders/:id/invoice` — file upload; returns `paymentTimerEndsAt`
- Push notifications per step reminder (optional)

## Design

- Paste-friendly wide inputs on card (not separate Payout screen required)
- Show **only next action** label on collapsed card: “Add tracking”, “Enter delivery OTP”, “Waiting for delivery”, “Upload invoice”, “Payment in 36h”
