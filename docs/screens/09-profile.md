# Screen: Profile

**Spec:** [../design/PROFILE-REQUIREMENTS.md](../design/PROFILE-REQUIREMENTS.md) — **LOCKED v1**  
**Affiliate:** [../design/AFFILIATE-MARKETING-REQUIREMENTS.md](../design/AFFILIATE-MARKETING-REQUIREMENTS.md) — Refer & earn

## Purpose

Account hub: **refer & earn**, KYC, payout details, language, tickets, support, appearance (theme), legal, logout.

## Entry points

- Bottom nav **Profile**

## UI elements

See PROFILE-REQUIREMENTS.md. **Affiliate v1 adds:**

| Element | Description |
|---------|-------------|
| Refer banner | Gold card below avatar — “Refer & earn ₹200 per friend” |
| Refer menu row | Opens referral sheet — code, copy, WhatsApp share, stats |

## Sub-screens

- **Refer & earn sheet**
- KYC form (Name + PAN)
- Language (EN / HI)
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
| Avatar circle | `#E8F0FE`, letter `#1A73E8` |
| Row chevrons / links | `#1A73E8` |
| Log out | `#D93025` |
| Delete account | `#D93025` text |
| Appearance / toggles | track `#1A73E8` when on |

**Avatar:** Letter placeholder — no photo upload v1.

## Validation

Delete account blocked → message **in sheet** (order in progress). KYC / payout edits → see [../design/VALIDATION-UX.md](../design/VALIDATION-UX.md). Logout API fail → **Snackbar**.
