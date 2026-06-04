# Bank / payout details — when we ask

**Status: LOCKED** (mockups approved June 2026)

**Mockups:** `assets/mintzer-kyc-mockup.png` · `assets/mintzer-bank-details-mockup.png`

**LOCKED flow:** Right after KYC on **first Accept** → ask **bank details** → then user can continue (timer / place order).

Still **no Withdraw button** in Wallet — bank is for **Mintzer to pay the user**, not user self-withdraw in v1.

---

## Order of gates (first Accept only)

```
User taps Accept deal
  → Step 1: KYC (Name + PAN)
  → Step 2: Payout / bank details
  → Step 3: Accept / timer screen (place order)
```

Returning users with KYC + bank already saved → skip straight to timer.

---

## Step 1 — KYC

| Field | Required |
|-------|----------|
| Name (as per PAN) | Yes |
| PAN | Yes |

---

## Step 2 — Bank details (immediately after KYC)

**Screen title example:** “Add payout details” / “Where should we send your earnings?”

User picks **one** method:

### Option A — UPI
| Field | Required |
|-------|----------|
| UPI ID | Yes |
| Confirm UPI ID | Yes (type again) |

### Option B — Bank account
| Field | Required |
|-------|----------|
| Account holder name | Yes (prefill from KYC name) |
| Account number | Yes |
| Confirm account number | Yes |
| IFSC | Yes |

**Tabs or radio:** UPI | Bank — one path only.

**Rules:**
- Name on bank must match KYC name (show hint)
- Save once — editable later from **Profile → Payout details**
- Required before first order placement (same gate as KYC)

**Validation UX:** [VALIDATION-UX.md](./VALIDATION-UX.md) — inline under field · API errors **snackbar bottom-right**

---

## Where it appears in app

| Place | When |
|-------|------|
| **After KYC on first Accept** | Primary collection — **required** |
| **Profile → Payout details** | View / edit later |

**Not on:** Login · Deal detail (read only) · Wallet

---

## Backend

- `POST /user/kyc` — name, pan  
- `POST /user/payout-details` — upi OR bank fields  
- `GET /user/profile` — flags: `kycStatus`, `payoutDetailsComplete`  
- Accept / placement blocked until both true (first time)

---

## Admin

- View PAN + payout details per user  
- Ops uses for manual / batch payout until auto payout exists  

---

## Mockups (visual reference)

| Screen | File | Notes |
|--------|------|--------|
| KYC (step 1 of 2) | `mintzer-kyc-mockup.png` | Name + PAN, Continue |
| Payout details (step 2 of 2) | `mintzer-bank-details-mockup.png` | UPI tab shown; Bank tab same layout with account/IFSC fields per table above |
