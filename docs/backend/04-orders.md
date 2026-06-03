# Module: Orders (lifecycle)

Orders exist only after placement confirm (Order ID or screenshot in time). User completes steps on My Orders card.

## Status flow

```
order_placed
  → tracking_submitted
  → out_for_delivery_submitted
  → awaiting_parcel (invoice locked)
  → parcel_received (admin)
  → invoice_uploaded
  → payment_pending (48h window)
  → paid
  → completed
```

Cancelled branch: `cancelled` (from user or admin) — before payout only.

## Endpoints (user)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/orders` | List orders (`?status=ongoing\|completed`) |
| GET | `/orders/:id` | Order detail + current step |
| PATCH | `/orders/:id/tracking` | Submit tracking ID |
| PATCH | `/orders/:id/out-for-delivery` | Last 4 + OTP |
| POST | `/orders/:id/invoice` | Upload invoice (multipart) |

## `GET /orders`

**Query:** `status=ongoing|completed`, `search=orderId`, `type=regular|instant`

**Response item:**
```json
{
  "id": "ORDT86KP80",
  "status": "tracking_submitted",
  "currentStep": "out_for_delivery",
  "nextActionLabel": "Enter delivery OTP",
  "productSummary": { "name", "imageUrl", "color", "store" },
  "money": {
    "youEarn": 300,
    "commission": 300,
    "cashback": 1000,
    "totalCheckout": 20200,
    "walletFromMintzer": 19300
  },
  "progress": {
    "orderPlacedAt": "...",
    "trackingSubmittedAt": null,
    "outForDeliverySubmittedAt": null,
    "parcelReceivedAt": null,
    "invoiceUploadedAt": null,
    "paymentTimerEndsAt": null,
    "paidAt": null
  },
  "invoiceUploadEnabled": false
}
```

## `PATCH /orders/:id/tracking`

**Request:**
```json
{ "trackingId": "FMPP123456789" }
```

**Rules:**
- Order must be `order_placed` or allow update with edit flag
- Set status `tracking_submitted`
- No auto courier integration

## `PATCH /orders/:id/out-for-delivery`

**Request:**
```json
{
  "deliveryPhoneLast4": "1234",
  "deliveryOtp": "654321"
}
```

**Rules:**
- OTP min length 6 (configurable)
- Requires tracking submitted first
- Set status `out_for_delivery_submitted` → `awaiting_parcel`
- Invoice upload remains **disabled**

## Invoice upload gate

`invoiceUploadEnabled = true` only when admin sets `parcelReceivedAt` (see admin module).

## `POST /orders/:id/invoice`

**Request:** multipart file (image/pdf)

**Response:**
```json
{
  "status": "payment_pending",
  "invoiceUrl": "...",
  "paymentTimerEndsAt": "2026-06-06T12:00:00Z",
  "paymentTimerSecondsRemaining": 172800
}
```

**Rules:**
- Reject if `parcelReceivedAt` is null
- Set `invoiceUploadedAt = now`
- Set `paymentTimerEndsAt = now + 48 hours` (configurable in app config)
- Frontend shows countdown to `paymentTimerEndsAt`

## Money snapshot on order

Copy from deal at confirm time — never recalculate from live deal:

```
order.money_snapshot:
  orderValue, platformFee, cardFee, discount, totalCheckout
  cashback, commission, tds, walletFromMintzer, youEarn, totalUserReceives
```

## Database

```
orders
  id (display ORD*), user_id, deal_id, placement_id
  external_order_id, screenshot_url
  status, current_step
  tracking_id, delivery_phone_last4, delivery_otp_hash
  parcel_received_at, invoice_url, invoice_uploaded_at
  payment_timer_ends_at, paid_at
  money_snapshot (json)
  type (regular|instant)
  created_at, updated_at
```

## Progress labels for app

| Backend step | Collapsed card label |
|--------------|------------------------|
| order_placed | Add tracking ID |
| tracking_submitted | Enter delivery OTP |
| awaiting_parcel | Waiting for delivery |
| parcel_received | Upload invoice |
| payment_pending | Payment in Xh |
| paid | Completed |
