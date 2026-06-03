# Screen: Accept / place order

## Purpose

User places the external order (Flipkart, etc.) within the backend timer and confirms with Order ID or screenshot. Everything needed to **do** the order is on this screen.

## Entry points

- Deal detail → **Accept deal**
- Home → **Active order strip**
- Notification → “Complete your order”

## UI elements

| Element | Description |
|---------|-------------|
| Back | Warn if timer active: “Order in progress” |
| **Countdown timer** | Large; duration from backend config |
| Product summary | Name, color, store |
| Card to use | Chip |
| Money row | You pay ₹X · You earn ₹Y |
| **Copy address** | Full delivery address to clipboard |
| **Copy pin** | Pin code to clipboard |
| **Open Flipkart** (or store) | Deep link / browser |
| Collapsible **Offer details** | Same as deal detail (optional refresh) |
| Order ID field | Paste-friendly text input + **Paste** chip |
| **Upload screenshot** | Order confirmation image |
| **Submit order** | Primary — sends Order ID and/or screenshot |
| **Cancel order** | Secondary/outline — releases placement slot |

## User actions

| Action | Result |
|--------|--------|
| Copy address / pin | Toast “Copied” |
| Open store | External browser / app |
| Paste Order ID + Submit | Success → **Order placed success**; order in backend + My Orders |
| Upload screenshot + Submit | Same (screenshot stored; Order ID may be manual or future OCR) |
| Cancel order | Confirm dialog → placement cancelled → user can accept other deals |
| Timer expires | Auto-navigate or banner; see Expired state |

## KYC (if required)

- On first **Open store** or **Submit** (product decision): show KYC sheet if not completed
- PerkPay-style: not at login, at order time
- Minimal fields until DigiLocker integration

## Business rules

- Timer length from **backend config** (not hardcoded 10/15 in app)
- **Submit before expiry** → order saved to backend and My Orders
- **No submit before expiry** → order **not** in user backend; **admin logs only**
- Push notifications to user when timer near expiry and after expiry (re-engage)
- Only **one** open placement at a time
- **Cancel** frees slot for new Accept on Home

## States

| State | UI |
|-------|-----|
| Timer running | Normal UI; timer amber under 2 min |
| Submitting | Loading on button |
| Success | Navigate to Order placed success |
| Expired | “Time’s up” + **Browse deals** / notification CTA to try again |
| Cancelled | Toast + Home |

## Navigation

| From | To |
|------|-----|
| Submit success | Order placed success |
| Cancel | Home |
| Timer expired | Home (+ admin log) |

## Backend notes

- `POST /placements/:id/confirm` — body: `{ orderId?, screenshotUrl? }`
- `POST /placements/:id/cancel`
- On expiry: webhook/job marks `expired`; write **admin log** row; no user order record
- Push: timer warning (e.g. 5 min, 1 min), expired

## Design

- Timer is hero element
- One screen — no separate “confirm order” page
- Google blue submit; red or grey cancel with confirmation
