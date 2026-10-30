# Screen: Profile

**Spec:** [../design/PROFILE-REQUIREMENTS.md](../design/PROFILE-REQUIREMENTS.md) — **LOCKED v1**  
**Affiliate:** [../design/AFFILIATE-MARKETING-REQUIREMENTS.md](../design/AFFILIATE-MARKETING-REQUIREMENTS.md) — Refer & earn

## Purpose

Account hub: **refer & earn**, KYC, payout details, language, tickets, support, appearance (theme), legal, logout.

## Entry points

- Bottom nav **Profile**

## UI (LOCKED 20 Sep 2026 — critique polish)

Tight Profile — not a settings document:

| Block | Content |
|-------|---------|
| Header | Avatar + camera · **Name** · phone + copy · **Edit** |
| Refer | Compact strip: Refer & earn ₹200 · code capsule tap = Copy · Share |
| Account | Account details (Edit) · KYC Pending/Verified › · Payout details Not set up/Saved › |
| Account details sheet | Photo · name (locked after PAN) · Change phone (OTP) · Save |
| Preferences | Language · Appearance · Notifications prefs (master + deals/orders/payments) + inbox |
| Help & Support | Help Center · My tickets · Contact support · Video tutorials |

**Contact support (14 Oct 2026):** same row, green **WhatsApp** label. Opens a sheet. Does not change Help Center, My tickets, tutorials, legal, logout, or delete.

| Sheet block | Action |
|-------------|--------|
| WhatsApp · 82486 26422 | **Message on WhatsApp** — general help. No order lines |
| Ticket | **Open a ticket** — the existing Help sheet |

The rest of Profile stays locked.
| Legal | Terms · Privacy |
| Actions | Log out · Delete account (red text only, no red banner) |
| Footer | Mintzer · v… |

**Dropped:** Account active badge · side-by-side KYC/Payout cards · Extra Complete now buttons · icon-on-every-row · lavender page wash · giant referral art.

## Sub-screens

- **FAQ** (accordion) · [12-faq.md](./12-faq.md)
- **Refer & earn sheet**
- KYC form (Name + PAN)
- Language (English · हिन्दी · ಕನ್ನಡ · മലയാളം) — Profile row is a **small hint**. Tap opens the **LOCKED 5 EN** bar (`EN` · `हि` · `ಕಾ` · `മല`). Same bar on Login. Applies immediately. Persists.
- My tickets list
- Ticket detail
- Delete account (sheet) · [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md)

## Backend notes

- `GET /user/profile`
- `POST /user/kyc`
- `GET /tickets`
- `GET /config/support`
- `POST /auth/logout`

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md) · [../design/PROFILE-REQUIREMENTS.md](../design/PROFILE-REQUIREMENTS.md)

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| List rows | `#FFFFFF` |
| Avatar circle | `#EAE6F1`, letter `#1A73E8` |
| Row chevrons / links | `#1A73E8` |
| Log out | `#D93025` |
| Delete account | `#D93025` text |
| Appearance / toggles | track `#1A73E8` when on |

**Avatar:** Letter, or a photo the user picks (tap avatar).

## Validation

Delete account blocked → message **in sheet** (order in progress). KYC / payout edits → see [../design/VALIDATION-UX.md](../design/VALIDATION-UX.md). Logout API fail → **Snackbar**.
