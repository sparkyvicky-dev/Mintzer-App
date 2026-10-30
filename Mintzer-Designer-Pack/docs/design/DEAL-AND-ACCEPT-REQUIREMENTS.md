# Deal detail + Accept (timer) — requirements

What must be on each page. Visual design is designer’s choice.

---

## Already discussed (locked)

### Deal detail (before Accept)
- Product image, name, color, variant, qty
- Store + bank logos (fixed boxes, not stretched)
- Money card: order value, platform fee, card fee, discount, total checkout, cashback, wallet, you earn
- Rules, offer details, links, how-to
- Sticky **Accept deal** at bottom
- Tap Accept → goes to **Accept / timer** screen (not timer on this page)

### Place order (after Accept tap) — **UI LOCKED v1**
- **LOCKED v3** spec + mockups: [PLACE-ORDER-REQUIREMENTS.md](./PLACE-ORDER-REQUIREMENTS.md) (2026-06-03)
- Two modes: **order yourself (default)** + **shop in app**; mode choice sheet first time + **Change** chip
- Timer + tabs: Deal details · Delivery details · Submit order
- **Cancel order** on this screen
- First Accept: **KYC** → **Payout details** → then Place order

---

## NEW — Deal detail page

### Header / actions (must have)

| Control | Behavior |
|---------|----------|
| **WhatsApp icon** | Quick access — opens WhatsApp to **admin support number** (from admin config) |
| **Report error** | Same destination as WA — opens WhatsApp with **pre-filled message** containing **deal details** (not empty chat) |

**Pre-filled message must include (deal context — no Mintzer order yet unless user has open placement on this deal):**
- Deal / product name
- Store
- Card required
- Order value / earn amount
- Deal ID (internal)
- User phone (from account)
- Optional: placement ID if user already accepted this deal but returned to deal detail

**Admin panel:**
- WhatsApp number / link
- **WhatsApp ON/OFF** — when OFF, hide WA icon and Report error on deal detail (or hide both quick actions)

**v1 note:** User asked WA on deal detail now; order-level ticket flow stays separate on order detail.

**Report error vs order ticket:**
- **Deal detail — Report error:** fast WhatsApp to admin with deal info (no question wizard)
- **Order detail — Raise ticket:** guided questions + status tracking (separate spec)

---

## Place order — locked

See [PLACE-ORDER-REQUIREMENTS.md](./PLACE-ORDER-REQUIREMENTS.md) and [../screens/04-accept-place-order.md](../screens/04-accept-place-order.md).

Optional later: small **Report error** on Accept too (same WA + deal/placement info) — only if you want; not required unless you say yes.

---

## Flow reminder

```
Home → Deal detail → Accept → [KYC/bank if first] → [shop mode if first] → Place order → Success → My Orders
```

---

## Wallet (related)

No withdraw in app. See [WALLET-REQUIREMENTS.md](./WALLET-REQUIREMENTS.md).

## Open

- Ticket question lists per category — client later
- Exact WA message template text
