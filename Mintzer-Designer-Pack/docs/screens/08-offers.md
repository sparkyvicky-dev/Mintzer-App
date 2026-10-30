# Screen: Offers (deferred — not in bottom nav v1)

**Status:** **Not in v1 bottom nav.** Use **Wallet** tab instead. Screen kept for future promos/referrals.

**Mockup (future):** `assets/mintzer-offers-mockup.png`

## Purpose

Promotional content: signup bonuses, referral rewards, seasonal campaigns — separate from core deal list on Home.

## Entry points

- ~~Bottom nav Offers~~ — **removed v1**
- Future: Profile link or Home banner

## UI elements

| Element | Description |
|---------|-------------|
| Title | Offers |
| Banner list | e.g. “Signup & get ₹200 on first order” |
| Offer cards | Title, expiry, T&C link, CTA |
| Referral block | Optional: share code, earn per invite |
| Empty state | “No active offers” |

## User actions

| Action | Result |
|--------|--------|
| Tap offer | Detail sheet or external T&C |
| CTA | Deep-link to Home deal list or specific deal |
| Share referral | System share sheet |

## Business rules

- Offers do not replace deal acceptance flow
- First-order bonus applies per backend rules at payout time

## States

| State | UI |
|-------|-----|
| Loading | Skeleton |
| Empty | Illustration + Home CTA |

## Navigation

| From | To |
|------|-----|
| Offer CTA | Home or Deal detail |
| Back | N/A (tab root) |

## Backend notes

- `GET /offers` — active campaigns

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md)

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| Offer cards | `#FFFFFF` |
| Links | `#1A73E8` |
| Empty state text | `#5F6368` |

## Validation

None v1.

## Design

- Same Material theme as Home; do not compete with deal cards

## v1 scope

- Can launch with static offers; dynamic CMS later
