# Screen: Offers

## Purpose

Promotional content: signup bonuses, referral rewards, seasonal campaigns — separate from core deal list on Home.

## Entry points

- Bottom nav **Offers**

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

## Design

- Same light Material theme as Home
- Avoid competing visually with deal cards on Home

## v1 scope

- Can launch with static offers; dynamic CMS later
