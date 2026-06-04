# Screen: Wallet

## Purpose

Show full financial picture with Mintzer — balance + per-order earnings history. No withdraw. Accessed from Home header and Profile.

## Entry points

- Home → wallet icon / balance
- Profile → Wallet
- My Orders → after payment credited

## UI elements

| Element | Description |
|---------|-------------|
| Balance cards | **Pending** (left) · **Available** (right) · optional **Total earned** below |
| **Transactions** header | Download Excel icon · Date range (calendar) icon |
| Filter chips | **All** · **Paid** · **Pending** · **Canceled** |
| Earnings list | Full scroll — product, ref, earn, status, date |
| TDS note | Optional footnote if needed |

**No Withdraw button on Wallet** (v1 glimpse only).

## User actions

| Action | Result |
|--------|--------|
| Tap row | That order (order detail / My Orders) |
| Filter chip | Filter list by Paid / Pending / Canceled |
| Date range | Calendar overlay → filter list + export |
| Download Excel | Export filtered rows |
| Pull refresh | Reload balance + list |

## States

| State | UI |
|-------|-----|
| Zero balance | Encouragement + Browse deals |
| Loading | Skeleton list |

## Navigation

| From | To |
|------|-----|
| Transaction row | Order detail |
| Header wallet icon (Home) | Wallet |

## Backend notes

- `GET /wallet` — available, pending, totalEarned
- `GET /wallet/transactions` — all order credits with earnAmount per order

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md) · detail: [../design/WALLET-REQUIREMENTS.md](../design/WALLET-REQUIREMENTS.md)

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| Summary cards | `#FFFFFF` |
| Available / earn amounts | `#188038` |
| Pending | `#E37400` |
| Text secondary | `#5F6368` |
| **No** withdraw button | — |

## Validation

Read-only v1 — no input validation.

## Design spec

See WALLET-REQUIREMENTS.md
