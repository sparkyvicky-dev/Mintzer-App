# Wallet — requirements (LOCKED v1)

**Status:** LOCKED — 2026-06-04  
**Mockup:** `assets/mintzer-wallet-mockup.png`  
**Purpose:** One clear picture of everything the user has **financially with Mintzer**.  
**Not a bank.** **No withdraw.** View and history only.

---

## What user must understand in 10 seconds

1. How much Mintzer has **credited to me** (available)  
2. How much is **still processing** (pending)  
3. How much I’ve **made in total** (lifetime)  
4. **Per order** — what I earned and whether it’s paid or still pending  

---

## Page structure

### Section 1 — Summary (top)

Two cards side by side (reference layout) + optional third line for lifetime:

| Field | Meaning | Reference app says |
|-------|---------|-------------------|
| **Available balance** | Money Mintzer has approved into wallet | “Available balance” |
| **Pending** | Earned but not approved yet (invoice / 48h / ops) | Same idea as **“Upcoming payout”** in other apps — **use “Pending”** in Mintzer UI |
| **Total earned** | Lifetime approved earn (optional third stat or subtitle) | — |

One optional line if Pending &gt; 0:  
“₹X will move to available after review.”

**No buttons** in summary — no Withdraw, no Add bank.

---

### Section 2 — How it works (collapsible, first visit helpful)

3 short bullets, e.g.:
- You earn when your order is verified  
- Pending until Mintzer approves payment  
- Tap any order below for full details  

---

### Section 3 — Earnings history (main body — full scroll)

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

**Paid** = approved, counted in Available / Total earned.  
**Pending** = invoice in review or waiting ops.  
**Canceled** = order canceled — show **₹0** or “—” with Canceled label (no confusion).

Tap row → **Order detail** (that order).

### Download Excel (NEW v1)

| Rule | Detail |
|------|--------|
| Where | Icon next to **Transactions** title |
| Exports | Current filter + date range — columns: Order ref, Product, You earned, Status, Date |
| Empty | Toast *No transactions to export* |
| Format | `.xlsx` or CSV — backend `GET /wallet/transactions/export?from=&to=&status=` |

---

### Section 4 — Footer note (small)

TDS / cashback reminder one line if your deals need it:  
“Bank cashback is on your card statement. Mintzer wallet shows your deal earnings.”

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
  "available": 1500,
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
