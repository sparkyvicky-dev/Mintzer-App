# Screen: Wallet

## Purpose

Show balance, pending vs confirmed earnings, and withdrawal history. Accessed from Home header and Profile.

## Entry points

- Home → wallet icon / balance
- Profile → Wallet
- My Orders → after payment credited

## UI elements

| Element | Description |
|---------|-------------|
| Balance card | Available balance (large ₹) |
| Pending | Amount in 48h review or processing |
| Confirmed | Ready to withdraw |
| Transaction list | Credits per order, debits, withdrawals |
| Withdraw CTA | Primary when above minimum threshold |
| TDS note | Short line on TDS deducted per order |

## User actions

| Action | Result |
|--------|--------|
| Withdraw | Withdraw flow (bank/UPI — detail in Profile/KYC) |
| Tap transaction | Order detail or receipt |
| Pull refresh | Reload balance |

## States

| State | UI |
|-------|-----|
| Zero balance | Encouragement + link to Home deals |
| Pending items | Badge or separate section |
| Loading | Skeleton |

## Navigation

| From | To |
|------|-----|
| Transaction | My Orders order (Completed) or detail sheet |
| Back | Home or Profile |

## Backend notes

- `GET /wallet` — balance, pending, confirmed
- `GET /wallet/transactions`
- Withdrawal requires KYC complete

## Design

- Google Pay–like clarity: big number, simple list
- Green for credits, neutral for pending

## v1 scope

- Can ship read-only wallet first; withdrawal in Profile phase 2
