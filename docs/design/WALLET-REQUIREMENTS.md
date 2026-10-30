# Wallet — requirements (LOCKED v1)

**Status:** LOCKED — 2026-06-04  
**Mockup:** `assets/mintzer-wallet-mockup.png`  
**Purpose:** One clear picture of everything the user has **financially with Mintzer**.  
**Not a bank.** **No withdraw.** View and history only.

---

## What user must understand in 10 seconds

1. How much profit I’ve **made in total** (paid orders)
2. How much profit is **still pending** (orders not yet paid)
3. **Per order** — profit and whether it’s paid or still pending

There is **no Available** in v1 (no withdraw). Total earned + Pending is the full picture.

---

## Page structure

### Section 1 — Summary (top)

Greeting: **Hi, {first name}** (from PAN / KYC). Two rows, label left · amount right:

| Field | Meaning |
|-------|---------|
| **Total earned** | Sum of profit on **paid** orders |
| **Pending** | Sum of profit on **unpaid, not canceled** orders |

**No buttons** in summary — no Withdraw, no Add bank. **No “How it works”.** No footer hints.

---

### Section 2 — Earnings history (main body — full scroll)

**Header row:** title **Transactions** · **Download Excel** icon · **Date range** icon (calendar)

**Filter chips:** **All** · **Paid** · **Pending** · **Canceled** (default **All**)

**Date range:** tap calendar → select start/end → applies to list **and** Excel export (overlay — see mockup reference)

**All orders with money tied to Mintzer** — newest first (default). Sort optional: newest / oldest.

Each row = **one order’s financial line with Mintzer:**

| Column | Example |
|--------|---------|
| Product | iPhone 16 |
| Order ref | ORD···KP80 |
| **You earned** | **₹600** |
| Status | **Paid** / **Pending** / **Canceled** (no earn) |
| Date | 14 Apr 26 |

**Paid** = counted in Total earned.  
**Pending** = counted in Pending.  
**Canceled** = show profit as **₹0** or keep the deal amount with Canceled label (no mix-up with pending).

Tap row → **Order detail** (that order).

### Download Excel (NEW v1)

| Rule | Detail |
|------|--------|
| Where | Icon next to **Transactions** title |
| Exports | Current filter + date range — columns: Order ref, Product, You earned, Status, Date |
| Empty | Toast *No transactions to export* |
| Format | `.xlsx` or CSV — backend `GET /wallet/transactions/export?from=&to=&status=` |

---

## Must not have (v1)

- Withdraw button or withdraw flow  
- Link bank / UPI / add account  
- Transfer, send money, scan pay  
- KYC on this page  

Payout to user’s bank (if you do it offline) is **ops/admin** — not in app v1.

---

## Entry points

- Home header wallet icon / balance tap  
- Profile → Wallet row  
- Notification “Payment credited” → Wallet or order  

---

## Empty state

“No earnings yet” + **Browse deals**

---

## Backend data (minimum)

```json
{
  "pending": 600,
  "totalEarned": 5000,
  "transactions": [
    {
      "orderId": "ORDT86KP80",
      "productName": "iPhone 16",
      "earnAmount": 600,
      "status": "paid",
      "date": "..."
    }
  ]
}
```

---

## Bottom navigation (app-wide)

**Home · Orders · Wallet · Profile** — **no Offers tab** in v1.

Wallet also reachable from Home header balance tap.

---

## Decision log (LOCKED)

| Topic | Decision |
|-------|----------|
| Withdraw in app | **No** |
| Wallet role | Financial picture with Mintzer only |
| Per-order earn | Yes, every row |
| Full history | Yes, scroll all |
| Filters | All · Paid · Pending · Canceled + date range |
| Download Excel | Yes — respects filters |
| Bottom nav | **Wallet tab** — not Offers |
| Mockup approved | `mintzer-wallet-mockup.png` |
