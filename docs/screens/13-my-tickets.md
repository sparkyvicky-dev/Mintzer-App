# Screen: My tickets

**Status:** **LOCKED** (20 Sep 2026 — inbox polish)  
**Flutter:** `app/lib/screens/tickets_screen.dart` · `ticket_detail_screen.dart` · `models/mock_ticket.dart`

## Purpose

Support inbox — not a CRM dump. User needs: What issue? Who acts next? New reply? What do I do?

## Entry

- Profile → My tickets
- Notification deep link → ticket detail

## UI (LOCKED)

| Element | Rule |
|---------|------|
| Header | **My tickets** · subtitle · quiet **+ New ticket** (top-right only) |
| Tabs | Compact segment **Open N · Resolved N** (~44px) |
| Empty (Open) | Short copy + single New ticket CTA |
| Empty (Resolved) | Short copy only — no filler help card |
| Card | Subject + one status pill · `TKT · Category` grey · Order line · inbox face line · optional reply preview · relative Updated |
| Unread | Purple dot + lilac card tint + **Support replied** + message preview |
| Tap | Whole card → detail (marks read). No chevron required. |
| Bottom help card | **Removed** when tickets exist |

### User-facing status (one primary)

| Face | When |
|------|------|
| Waiting for support | Open · last message from user |
| Support replied | Open · last from Mintzer · unread |
| Your reply needed | Open · last from Mintzer · read |
| Resolved | Resolved / closed |

Internal `in_progress` stays for ops — do not show both “In progress” and “Waiting for support”.

## Must not

- Duplicate New ticket + Need more help when list non-empty
- Category as a colored pill
- Icon soup (date/order/update icons)
- Creation date on the list card (detail only)
- Extra count in the title (tabs own counts)

## 14 Oct 2026

Not part of the delivery-call update. This screen stays as written above.
