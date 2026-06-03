# Module: Wallet & payouts

Wallet credit after order review. Commission (you earn) is the primary Mintzer payout to user; full wallet amount may include reimbursement formula from deal.

## Concepts

| Term | Meaning |
|------|---------|
| **walletFromMintzer** | Amount credited per deal formula (order − CB − discount + commission) |
| **youEarn** | Commission − TDS — shown as user profit |
| **cashback** | Paid by bank — not wallet credit from Mintzer |
| **pending** | Invoice uploaded; within 48h review window |
| **confirmed** | Approved for withdrawal |
| **available** | Confirmed balance user can withdraw |

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/wallet` | Balance summary |
| GET | `/wallet/transactions` | Ledger |
| POST | `/wallet/withdraw` | Withdraw to bank/UPI (KYC required) |

## `GET /wallet`

```json
{
  "available": 1500.00,
  "pending": 600.00,
  "confirmed": 1500.00,
  "currency": "INR"
}
```

## Transaction types

| Type | Description |
|------|-------------|
| `order_credit` | Wallet credited after order paid |
| `commission` | Line item reference (part of order_credit) |
| `tds_deducted` | TDS on commission |
| `withdrawal` | Payout to user bank/UPI |
| `adjustment` | Admin manual correction |

## Payout trigger (admin)

After `payment_pending` and ops review:

1. Admin approves payout on order
2. Credit `walletFromMintzer` (or approved amount) to user wallet
3. Set order `status=paid`, `paidAt=now`
4. Create wallet transaction rows

TDS recorded per order from snapshot `tds` field.

## `POST /wallet/withdraw`

**Requires:** `kycStatus=verified`, minimum balance from config.

**Request:**
```json
{ "amount": 500.00, "method": "upi", "upiId": "user@upi" }
```

## Relation to deal pricing

On payout approval, ledger should reference order snapshot:

```
Credit: walletFromMintzer  ₹19,300  (order ORDT86KP80)
User earn display:         youEarn   ₹300 (commission net of TDS)
Bank CB:                   not wallet — informational only on order
```

## Config

- `minWithdrawalAmount` — see [08-app-config.md](./08-app-config.md)
- `paymentReviewHours` — default 48
