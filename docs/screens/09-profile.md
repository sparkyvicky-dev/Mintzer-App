# Screen: Profile

## Purpose

Account settings, KYC status, support, and legal links.

## Entry points

- Bottom nav **Profile**

## UI elements

| Element | Description |
|---------|-------------|
| Phone number | Display logged-in number (read-only) |
| KYC status | Not started · Pending · Verified — tap to complete |
| Wallet shortcut | Row → Wallet screen |
| My Orders shortcut | Row → Orders tab |
| Support | WhatsApp / email / in-app chat |
| Tutorials | YouTube link |
| Notifications settings | Toggle push |
| Terms & Privacy | WebView or external links |
| Log out | Confirm dialog |

## KYC flow (sheet or sub-screen)

Triggered from:

- Profile → Complete KYC
- Accept screen on first order (if not verified)

Minimal v1 fields (product to confirm):

- Name as per bank
- PAN
- UPI or bank account for payout

Future: DigiLocker one-tap verification.

## User actions

| Action | Result |
|--------|--------|
| Complete KYC | KYC form → submit → pending/verified |
| Log out | Clear session → Login |
| Support | Open WhatsApp / chat |

## States

| State | UI |
|-------|-----|
| KYC not started | Amber badge on row |
| KYC pending | “Under review” |
| KYC verified | Green check |

## Navigation

| From | To |
|------|-----|
| Wallet row | Wallet |
| Orders row | My Orders |
| KYC | KYC form sheet |

## Backend notes

- `GET /user/profile`
- `POST /user/kyc`
- `POST /auth/logout`

## Design

- Simple list rows like Google account settings
- No dark theme

## Rules

- KYC **not** required at login
- KYC required before first external order or first withdrawal (align with Accept screen gate)
