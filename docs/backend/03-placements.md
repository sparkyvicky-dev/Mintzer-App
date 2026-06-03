# Module: Placements (accept, timer, confirm)

A **placement** is the in-progress “place order” window between **Accept deal** and **Order ID / screenshot** submission.

## Business rules

1. User may have **at most one** active placement without confirmed order.
2. Timer duration from [app config](./08-app-config.md) `placementTimerMinutes`.
3. **Confirm before expiry** → create **order** record; snapshot deal money fields.
4. **No confirm before expiry** → placement `expired`; write **admin log** only — no user order.
5. **Cancel** → placement `cancelled`; user may accept another deal.
6. After order confirmed, user may accept another deal (new placement).

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/placements/active` | Current open placement or null |
| POST | `/placements` | Accept deal — start timer |
| POST | `/placements/:id/confirm` | Submit Order ID and/or screenshot |
| POST | `/placements/:id/cancel` | User cancels |
| — | *(job)* | Expire placements past `expiresAt` |

## `POST /placements`

**Request:**
```json
{ "dealId": "deal_123" }
```

**Response:**
```json
{
  "id": "placement_xyz",
  "dealId": "deal_123",
  "status": "active",
  "expiresAt": "2026-06-04T12:30:00Z",
  "timerSecondsRemaining": 900,
  "dealSnapshot": { "...full deal + money..." },
  "deliveryAddress": { "pin", "fullAddress" }
}
```

**Errors:**
- `409 ACTIVE_PLACEMENT_EXISTS` — user already has open placement
- `404 DEAL_NOT_FOUND` / `410 DEAL_INACTIVE`

## `POST /placements/:id/confirm`

**Request:**
```json
{
  "externalOrderId": "OD123456789",
  "screenshotUrl": "https://storage/..."
}
```

At least one of `externalOrderId` or `screenshotUrl` required.

**Response:**
```json
{
  "order": {
    "id": "ORDT86KP80",
    "status": "order_placed",
    "externalOrderId": "OD123456789",
    "money": { "...snapshot from deal..." }
  }
}
```

**Rules:**
- Reject if `now > expiresAt`
- Create order with status `order_placed`
- Close placement as `confirmed`
- Store deal money snapshot on order (see [04-orders.md](./04-orders.md))

## `POST /placements/:id/cancel`

**Response:** `{ "status": "cancelled" }`

## Expiry job

Cron every minute:

1. Find placements `status=active` AND `expiresAt < now`
2. Set `status=expired`
3. Insert **admin_log** row (see [06-admin-operations.md](./06-admin-operations.md))
4. Trigger push notification — re-engage user

**Do not** create order record.

## `GET /placements/active`

Used by Home **active order strip**.

```json
{
  "placement": {
    "id": "...",
    "expiresAt": "...",
    "timerSecondsRemaining": 534,
    "productSummary": "iQOO Z10 Lite 5G"
  }
}
```

Or `{ "placement": null }`.

## Database

```
placements
  id, user_id, deal_id, status (active|confirmed|cancelled|expired)
  expires_at, created_at, confirmed_at, cancelled_at
  deal_snapshot (json)

admin_logs (on expire)
  id, type=placement_expired, user_id, deal_id, placement_id, payload (json), created_at
```

## KYC gate (optional)

Before `POST /placements` or on confirm — require `kycStatus=verified` per product decision. Document in Profile/KYC flow.
