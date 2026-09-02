# Module: Admin operations

Admin panel APIs and manual steps not exposed to regular users.

## Deal management

Create/edit deals — see [01-deals-and-pricing.md](./01-deals-and-pricing.md).

**Required on publish:**
- All money fields calculated (order value, platform fee, card fee, discount, cashback, commission, totals)
- Logos via store/card entities

## Mark parcel received

Unlocks invoice upload on user app.

| Method | Path | Description |
|--------|------|-------------|
| POST | `/admin/orders/:id/mark-received` | Set parcel received |

**Effect:**
- `parcelReceivedAt = now`
- Order status → `parcel_received`
- `invoiceUploadEnabled = true` on next fetch
- Optional push: “You can upload your invoice now”

**Who triggers:** Ops when physical parcel arrives at Mintzer address — not when user submits tracking/OFD.

## Approve payout

| Method | Path | Description |
|--------|------|-------------|
| POST | `/admin/orders/:id/approve-payout` | Credit wallet, mark paid |

**Effect:**
- Wallet credit per [05-wallet-and-payouts.md](./05-wallet-and-payouts.md)
- Order `status=paid`

## Reject / cancel order

| Method | Path | Description |
|--------|------|-------------|
| POST | `/admin/orders/:id/cancel` | Cancel with reason |
| POST | `/admin/orders/:id/reject-invoice` | Request re-upload |

## Admin logs (expired placements)

When placement expires without confirm — **no order** for user.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/admin/logs/placement-expired` | List expired attempts |

**Log row:**
```json
{
  "id": "log_123",
  "type": "placement_expired",
  "userId": "user_abc",
  "phone": "9876543210",
  "dealId": "deal_123",
  "placementId": "placement_xyz",
  "dealTitle": "IQOO Z10 Lite 5G",
  "expiredAt": "...",
  "createdAt": "..."
}
```

Use for ops follow-up and re-engage campaigns — not shown in user My Orders.

## KYC review

| Method | Path | Description |
|--------|------|-------------|
| GET | `/admin/kyc/pending` | Queue |
| POST | `/admin/kyc/:userId/approve` | |
| POST | `/admin/kyc/:userId/reject` | |

## User lookup

| Method | Path | Description |
|--------|------|-------------|
| GET | `/admin/users/:id/orders` | User order history |
| GET | `/admin/orders` | Filter by status, date, order id |

## Roles (suggested)

| Role | Access |
|------|--------|
| `ops` | Mark received, view orders |
| `finance` | Approve payout, wallet adjustments |
| `admin` | Deals, config, all above |
