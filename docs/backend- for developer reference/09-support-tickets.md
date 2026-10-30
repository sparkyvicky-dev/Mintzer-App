# Module: Support tickets

Order-scoped tickets + optional WhatsApp (admin toggle).

**Live admin reply is on (29 Sep 2026).** Web Tickets → Reply uses `GET tickets/{id}/thread` and `POST tickets/{id}/reply` in `newapp/routes/web.php`. Holder reply uses `POST /api/addticketreply`. Do not remove those routes. An older `web.php` upload deleted the two admin routes on 29 Sep; they were merged back the same day. Upload rules: [LIVE-UPLOAD-RULES.md](../LIVE-UPLOAD-RULES.md).

The tables below are the product spec. Live Play create is still `POST /api/addnewticket`. `order_id` on the ticket row stays additive — see [11-live-order-migration.md](./11-live-order-migration.md).

## User endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/orders/:id/tickets` | Create ticket (guided answers) |
| GET | `/orders/:id/tickets` | Tickets for this order |
| GET | `/tickets` | User’s all tickets (My tickets) |
| GET | `/tickets/:id` | Ticket detail + status history |
| GET | `/config/support` | `{ whatsappEnabled, whatsappUrl }` |

## Create ticket body

```json
{
  "category": "invoice_problem",
  "answers": [
    { "questionId": "invoice_rejected", "value": "yes" },
    { "questionId": "reuploaded", "value": "no" }
  ],
  "message": "optional short text"
}
```

Server attaches: `orderId`, `userId`, `externalOrderId`, `step`, `dealSnapshot`, `phone`.

## Ticket status

`submitted` → `in_progress` → `resolved` → `closed`

## Admin

| Method | Path | Description |
|--------|------|-------------|
| GET | `/admin/tickets` | Filter by order, user, status |
| PATCH | `/admin/tickets/:id` | Update status, internal note |
| PUT | `/admin/config/support` | `whatsappEnabled`, `whatsappNumber` |

## Duplicate order ID

On `POST /placements/:id/confirm` or order update:

- If `externalOrderId` already exists on another order for any user (or same user — product rule: **any user**) → `409 DUPLICATE_ORDER_ID`

## WhatsApp

Not called from backend — app reads config and opens `https://wa.me/...?text=` when enabled.

**Deal detail — Report error / WA icon:** prefilled **deal** fields (product, store, card, earn, dealId, user phone).

**Order detail (when enabled):** prefilled **order** fields (order ref, step, external order id).

**Admin:** `whatsappEnabled` — when false, hide WA + Report error on deal detail; hide optional WA on order help.
