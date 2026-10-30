# Screen: Order placed success

**Mockup:** `assets/mintzer-order-placed-success-mockup.png`  
**Interactive demo:** `assets/mockups/mintzer-app-demo.html` (v2.4 — rotating promo)  
**Affiliate spec:** [../design/AFFILIATE-MARKETING-REQUIREMENTS.md](../design/AFFILIATE-MARKETING-REQUIREMENTS.md)

## Purpose

Celebrate confirmation, show earn amount, route to My Orders, and show **one admin-marketing promo** (affiliate layer).

## Entry points

- Place order → successful Order ID submit

## UI elements

| Element | Description |
|---------|-------------|
| Success animation | Short phone → ring → check → confetti |
| Title | **Order Placed!** |
| Subtitle | Earn amount + next step (GST line if needed) |
| Earn pill | Expected earnings ₹X |
| **Primary CTA** | **View order →** (My Orders) |
| **Secondary CTA** | **Browse more deals** (Home) |
| **Fat rotating promo** | One of 4 under **More for you** — marketing-led |

**Dropped (20 Sep 2026):** store Order ID + Copy card (useless after submit).

There are **4** rotating templates (one per order, `successPromoSeq % 4`):

| Template | Visual | Action |
|----------|--------|--------|
| 1. Order more | Large + card | Home |
| 2. Partner cards | Purple border · HDFC/Axis · Explore CTA | Partner apply |
| 3. Referral | Cream card · ₹200 each | Refer |
| 4. WhatsApp | Green gradient | Community |

**Rule:** One promo only — rotate. Dual CTAs stay.

## User actions

| Action | Result |
|--------|--------|
| Go to My Orders | My Orders tab, this order |
| Promo: Order more | Home |
| Promo: Partner cards | Partner cards overlay |
| Promo: Referral | Refer & earn overlay |
| Promo: WhatsApp | `communityWhatsAppUrl` |
| Back | Prefer My Orders (not Place order) |

## Business rules

- Placement timer ends on success; user **can accept new deals** from Home
- Order appears under **My Orders → Ongoing**
- Promo template chosen by backend/config (demo: cycles by order count)

## States

| State | UI |
|-------|-----|
| Success | Single state; earn chip + one promo template |

## Navigation

| From | To |
|------|-----|
| Go to My Orders | My Orders |
| Order more promo | Home |
| Partner cards promo | Partner cards sheet |
| Referral promo | Referral sheet |

## Backend notes

- Order status: `order_placed`
- `GET /config/public` or `GET /marketing/order-success-promo` → active template for user/session
- Return display `orderId` for My Orders card

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md)

| Element | Light |
|---------|-------|
| Background gradient | `#E8F0FE` → `#F8F9FA` |
| Success icon | `#188038` on `#E6F4EA` |
| Earn chip | `#188038` / border `#CEEAD6` |
| Primary button | `#1A73E8` |
| Partner upsell border | `#1A73E8` |
| Referral card | `#FEF7E0` / `#E37400` accent |
| WhatsApp promo | `#25D366` gradient |

## Validation

None — success only. Snackbar if navigation fails.

## Design

- Earn chip + one promo readable in ~5 seconds
- **Go to My Orders** remains obvious primary action above promo

## 14 Oct 2026

Not part of the delivery-call update. This screen stays as written above.
