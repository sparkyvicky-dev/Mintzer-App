# Mintzer — Backend Specifications

API, admin, and business-logic documentation for the Mintzer rebuild. Pairs with [frontend screen specs](../screens/README.md).

## Principles

- **Timer duration:** Configurable in admin/app config — not hardcoded in mobile app.
- **One active placement:** User cannot accept a new deal until Order ID or screenshot is submitted (or placement cancelled / expired).
- **Expired placement:** Not a user order — write to **admin logs** only.
- **No auto courier tracking:** User submits tracking and delivery details; backend stores and validates.
- **Invoice upload:** Enabled only when admin marks **parcel received** (**new** orders). **Live Play rows** unlock invoice after OTP — see [11-live-order-migration.md](./11-live-order-migration.md).
- **Money figures:** Calculated from admin inputs (order value, fees, cashback, discount, commission) — avoid manual mismatch between fields.

## Module index

| # | Module | File |
|---|--------|------|
| 1 | Deals & pricing (fees, formulas) | [01-deals-and-pricing.md](./01-deals-and-pricing.md) |
| 2 | Auth (OTP) | [02-auth.md](./02-auth.md) |
| 3 | Placements (accept, timer, confirm) | [03-placements.md](./03-placements.md) |
| 4 | Orders (lifecycle, steps) | [04-orders.md](./04-orders.md) |
| 5 | Wallet & payouts | [05-wallet-and-payouts.md](./05-wallet-and-payouts.md) |
| 6 | Admin operations | [06-admin-operations.md](./06-admin-operations.md) |
| 7 | Notifications | [07-notifications.md](./07-notifications.md) |
| 8 | App config | [08-app-config.md](./08-app-config.md) |
| 9 | Support tickets | [09-support-tickets.md](./09-support-tickets.md) |
| 10 | **Stores & cards catalog** | [10-stores-and-cards.md](./10-stores-and-cards.md) |
| 11 | **Live Play orders → new UI** | [11-live-order-migration.md](./11-live-order-migration.md) |

## Core money formula (summary)

```
totalCheckout      = orderValue − discount + platformFee + cardFee
walletFromMintzer  = orderValue − cashback − discount + commission
youEarn            = commission − tds
totalUserReceives  = walletFromMintzer + cashback
```

See [01-deals-and-pricing.md](./01-deals-and-pricing.md) for full admin field mapping and examples.

## Live app flow (29 Sep 2026)

The Play app calls `https://app.mintzer.in/api`. Step-by-step routes are in [frontend/03-flutter-app-map.md](../frontend/03-flutter-app-map.md).

| Step | Route | Provider |
|------|--------|----------|
| Login | `POST /sendotp`, `POST /verify-otp` | Server OTP |
| First Accept PAN | `POST /pan-verify` | **Cashfree** |
| Payout IFSC | `POST /ifsc-lookup` | **API Sathi** |
| Save bank | `POST /updateBankDetail` | `newapp` |
| Orders and proofs | `POST /accept-order` and the order write routes | `newapp` |

Cashfree is used only when `CASHFREE_PAN_ENABLED` is on. PowerAPI, then API Sathi, are the fallbacks when Cashfree is off. A Cashfree failure is shown to the user and is not retried on another provider.

## Order lifecycle (summary)

```
placement.accepted → (timer) → order.confirmed | placement.expired (log only)
order.confirmed → tracking → out_for_delivery → parcel_received (admin)
→ invoice_uploaded → payment_pending (48h) → paid → wallet credited
```
