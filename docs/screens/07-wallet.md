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
| Title | **Wallet** + Hi, {name} · earnings overview |
| Stats | Side-by-side **Total earned** · **Pending** (ChatGPT layout, 20 Sep 2026) |
| **Transactions** header | Download Excel icon · Date range (All time / picked range) |
| Filter chips | **All** · **Paid** · **Pending** · **Canceled** |
| Earnings list | Thumb · product · store order id · date · status pill · **From Mintzer** (Total receive) as main ₹ · **Earn ₹…** as separate profit label (not `· +₹` glued to the big number) · tap → order |

No “How it works”. No withdraw. No Available. No PDF. No separate timeline view.

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

- `GET /wallet` — pending, totalEarned (no available / withdraw in v1)
- `GET /wallet/transactions` — all order credits with earnAmount per order

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md) · detail: [../design/WALLET-REQUIREMENTS.md](../design/WALLET-REQUIREMENTS.md)

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| Summary cards | `#FFFFFF` |
| Total earned | `#188038` |
| Pending | `#E37400` |
| Text secondary | `#5F6368` |
| **No** withdraw button | — |

## Validation

Read-only v1 — no input validation.

## Design spec

See WALLET-REQUIREMENTS.md

## 14 Oct 2026

Not part of the delivery-call update. This screen stays as written above.
