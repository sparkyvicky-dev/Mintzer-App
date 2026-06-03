# Screen: Home

## Purpose

Browse available deals and start the deal flow. Show active in-progress order when user has an open accept timer.

## Entry points

- Bottom nav **Home** (default after login)
- Back from Deal detail
- Notification deep-link (expired timer re-engage → deal or Accept)

## UI elements (top → bottom)

| Element | Description |
|---------|-------------|
| Header | Logo left; **Wallet** balance (tap → Wallet); **Notifications** bell with badge |
| Search bar | Placeholder: “Search deals…” |
| Filter icon | Filter by store, card type, min earn (v1 can be simple) |
| **Active order strip** | Shown only when user has open accept timer (no Order ID/SS yet). Product name + countdown + “Tap to continue” |
| Promo banner | Optional carousel (e.g. YouTube tutorials). Blue/white, not purple |
| Deal list | Vertical list of deal cards (not grid) |
| Support FAB | Floating chat button, bottom right |
| Bottom nav | Home · Orders · Offers · Profile |

## Deal card content

Each card shows:

- Product image
- Product name + color (if fixed)
- Store logo (Flipkart, etc.)
- Chip: **Card to use** (e.g. SBI Cashback, Any card)
- **Order price** (₹)
- **Earn ₹X** in green
- Primary button: **Earn ₹X** (or tap whole card)

## User actions

| Action | Result |
|--------|--------|
| Tap deal / Earn button | **Deal detail** (if no blocking active order) |
| Tap active order strip | **Accept screen** (resume timer) |
| Tap wallet | Wallet |
| Tap notification | Contextual screen |
| Search / filter | Filter deal list |

## Business rules

- **One active placement:** If user has accept timer running without Order ID or screenshot, other deals show dimmed state: “Finish current order first” — Accept disabled.
- After Order ID/SS submitted, strip disappears; user can accept new deals.
- User may accept many deals over time, but **only one open timer** at a time.

## States

| State | UI |
|-------|-----|
| Loading | Skeleton deal cards |
| Empty | “No deals right now” + pull to refresh |
| Active order | Amber/blue strip under search |
| Blocked deal | Grey card + message |
| Error | Snackbar + retry |

## Navigation

| From | To |
|------|-----|
| Deal tap | Deal detail |
| Active strip | Accept place order |
| Orders tab | My Orders |

## Backend notes

- `GET /deals` — list with image, price, earn, card, store, color
- `GET /user/active-placement` — null or `{ dealId, expiresAt, productSummary }`
- Wallet balance for header

## Design reference

- Light theme, Google blue CTAs
- Borrow IDZO card density + PerkPay categories later; avoid dark/gold competitor look
