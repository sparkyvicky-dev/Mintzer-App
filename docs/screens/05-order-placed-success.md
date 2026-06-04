# Screen: Order placed success

**Mockup:** `assets/mintzer-order-placed-success-mockup.png`

## Purpose

Celebrate confirmation and set expectation for next steps. Short, positive, clear CTA to My Orders.

## Entry points

- Accept screen → successful Order ID / screenshot submit

## UI elements

| Element | Description |
|---------|-------------|
| Success animation | Checkmark / subtle confetti (not overdone) |
| Title | “Order placed!” |
| Subtitle | Commission amount — e.g. “₹500 commission locked” |
| Next step hint | “Add tracking ID when your order ships” |
| Primary CTA | **Go to My Orders** |
| Secondary | **Browse more deals** (enabled — user can accept another deal) |

## User actions

| Action | Result |
|--------|--------|
| Go to My Orders | My Orders tab, scroll to this order |
| Browse more deals | Home |
| Back | My Orders (prefer not to return to Accept) |

## Business rules

- Placement timer ends on success; user **can accept new deals** from Home
- Order appears under **My Orders → Ongoing**

## States

| State | UI |
|-------|-----|
| Success only | Single state; no form fields |

## Navigation

| From | To |
|------|-----|
| Go to My Orders | My Orders |
| Browse deals | Home |

## Backend notes

- Order status: `order_placed` (or equivalent)
- Return `orderId` display id (e.g. ORDT86KP80) for card header

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md)

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| Success icon / check | `#188038` |
| Primary button (My Orders) | `#1A73E8` |

## Validation

None — success only. Optional **Snackbar** if navigation fails.

## Design

- Keep screen under 3 seconds of reading; one obvious button
