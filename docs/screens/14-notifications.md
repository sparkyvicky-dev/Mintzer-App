# Screen: Notifications (bell inbox)

**Status:** **LOCKED** (20 Sep 2026 — premium inbox)  
**Flutter:** `app/lib/screens/notifications_screen.dart`

## Purpose

Secondary shoulder-tap for ticket replies, order steps, and Mintzer payouts.  
**Not** the primary resume path (Home strip + My Orders own that).

## UI (LOCKED)

| Element | Rule |
|---------|------|
| Header | Back · **Notifications** · subtitle · **Mark all read** + **Clear all** as visible actions (no ⋮ menu) |
| Groups | **Today** · **Earlier** |
| Card | Typed icon · title · quiet kind label · body (2 lines) · meta · relative time · unread dot · whole-card tap |
| Unread | Soft tint + purple dot |
| Empty / footer | You’re all caught up |

### Kinds

| Kind | Accent | Deep link |
|------|--------|-----------|
| Ticket | Purple | Ticket detail |
| Order | Blue | Order detail / Orders tab |
| Payout | Green | Wallet tab |
| Deal | Soft red | Home (dismiss) |

### Copy rules

- Use **Mintzer payout** — never imply Wallet is a spendable balance
- No shouty `TICKET UPDATE` banners
- No extra “View ticket →” strip (card is the CTA)
- Clear wipes list **on server** (`action=clear`) — no archive
- Phone-tray push is **primary**; this screen is secondary (see [NOTIFICATION-TEMPLATES-LOCKED.md](../design/NOTIFICATION-TEMPLATES-LOCKED.md))

## Must not

- Replace Home strip / My Orders as resume
- Spam Tier-1 deal promos into the inbox while a placement is active
- Archive / folders / filters beyond Today·Earlier

## 14 Oct 2026

Not part of the delivery-call update. This screen stays as written above.
