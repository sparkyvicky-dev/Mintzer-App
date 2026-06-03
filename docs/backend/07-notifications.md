# Module: Notifications

Push (and optional SMS) to drive placement timer and order steps.

## Events

| Event | When | User action / deep link |
|-------|------|-------------------------|
| `placement.timer_warning` | 5 min and 1 min before expiry | Open Accept screen |
| `placement.expired` | Timer ended, no confirm | Open Deal detail — try again |
| `order.confirmed` | Order ID saved | My Orders |
| `order.tracking_reminder` | Optional delay after order placed | My Orders — tracking step |
| `order.parcel_received` | Admin marked received | My Orders — upload invoice |
| `order.payment_approved` | Wallet credited | Wallet |
| `kyc.approved` | KYC verified | Profile |

## Payload shape

```json
{
  "type": "placement.timer_warning",
  "title": "12 minutes left to place your order",
  "body": "Complete your IQOO order before the timer runs out.",
  "data": {
    "placementId": "placement_xyz",
    "dealId": "deal_123",
    "deepLink": "mintzer://accept/placement_xyz"
  }
}
```

## Deep links

| Path | Screen |
|------|--------|
| `mintzer://accept/:placementId` | Accept / place order |
| `mintzer://deals/:dealId` | Deal detail |
| `mintzer://orders/:orderId` | My Orders expanded card |
| `mintzer://wallet` | Wallet |

## Expired placement — re-engage

On `placement.expired`:

- Push: friendly nudge to open app and accept deal again
- Do not reference an order id (none created)
- Logged in admin only

## Implementation notes

- Store FCM token per user device
- Respect notification permissions — ask after first login or first accept
- Idempotency: don’t spam duplicate warnings for same placement

## Config

See [08-app-config.md](./08-app-config.md) for timer warning intervals.
