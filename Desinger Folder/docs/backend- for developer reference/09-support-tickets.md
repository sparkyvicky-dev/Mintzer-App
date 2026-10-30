# Module: Support tickets

Order-scoped tickets + optional WhatsApp (admin toggle).

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
