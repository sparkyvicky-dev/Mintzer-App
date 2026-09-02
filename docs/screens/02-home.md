# Screen: Home

**Status:** **LOCKED** (June 2026)  
**Reference mockup:** `assets/mockups/home-samples.html`  
**Open in browser:** `file:///…/assets/mockups/home-samples.html`

## Purpose

Browse deals with **earn-first** CTA and clear **checkout spend**. Store + bank logos on every card. List or grid view.

## Entry points

- Bottom nav **Home** (default after login)
- Back from Deal detail
- Notification deep-link

---

## Home chrome (LOCKED)

| # | Element | Rule |
|---|---------|------|
| 1 | **Header** | **Hi, {firstName}** · subtitle “Earn with your card” · **Wallet** pill `₹X` · **Bell** + dot · **WhatsApp community** (green icon → `communityWhatsAppUrl`) |
| 2 | **Search** | Full width · placeholder “Search deals…” · `#E8EAED` border · 24dp radius |
| 3 | **View toggle** | **List** icon · **Grid** icon — persist `homeViewPreference` |
| 4 | **Filter chips** | **All Deals** · **Direct** · **Link** · filter funnel icon (sheet: store, card, min earn) |
| 5 | **Tutorial banner** | **First visit only** — “New here? Watch how Mintzer works” + dismiss ✕ · hidden when `tutorialSeen` · never on repeat visits |
| 6 | **List meta** | “N deals live” · **Highest earn ↓** sort |
| 7 | **Active order strip** | Conditional — product + countdown + Continue (see orders doc) |
| 8 | **Deal list** | List (default) or **2-column grid** — same card data |
| 9 | **Support FAB** | Bottom-right · `#1A73E8` · tickets/help |
| 10 | **Bottom nav** | **Home · Orders · Wallet · Profile** — no Offers |

---

## Deal card — LOCKED fields (each shown **once**)

| # | Field | API | On card |
|---|--------|-----|---------|
| 1 | Store logo | `store.logoUrl` | **Top-left badge on product image** (FK, Amazon, …) |
| 2 | Store name | `store.name` | **Not on Home card text** — logo only; name on Deal detail |
| 3 | Bank logo | `card.logoUrl` | Bank row — 26dp, contain |
| 4 | Card name | `card.label` | Bank row text |
| 5 | Product image | `productImageUrl` / `images[]` | One image · fixed box · **object-fit: contain** |
| 6 | Model | `productName` | Bold title · max 2 lines (grid: fixed min-height for alignment) |
| 7 | Color | `color` | Meta row left — or “Any color” |
| 8 | GST | `gstApplicable` | **`GST` pill on meta row right** — **only when true** · never “No GST” |
| 9 | Spend | `totalCheckout` | **Spend box** — “YOU SPEND” + **₹X** bold |
| 10 | Earn | `youEarn` | **Blue button** `Earn ₹X` — `#1A73E8` |

### NOT on Home card (v1)

Variant · Qty · Payout speed chip · Order value before fees · Cashback/fees · Duplicate store name text

### Multiple images

Admin: one PNG per color. **Home shows one image.** All colors on Deal detail.

---

## Deal card layout (LOCKED)

### List view (default)

```
┌────────────────────────────────────────────┐
│ [FK]   │  Motorola G57 Power 5G           │
│ [img]  │  Midnight Blue          [GST]    │
│ 80dp   │                                  │
│        │  [bank logo] Any credit / debit  │
│ ┌──── YOU SPEND ──────────── ₹17,519 ────┐ │
│ └────────────────────────────────────────┘ │
│ [ Earn ₹300 ]  full width blue button    │
└────────────────────────────────────────────┘
```

### Grid view (2 columns)

Same fields · compact · **Earn button pinned to card bottom** · title min-height 2 lines for row alignment.

```
[FK on image — full width ~88dp height]
Product name
Color ········· [GST]
[bank logo | card name]
[ YOU SPEND ····· ₹17,519 ]  light blue box
[ Earn ₹300 ]
```

### Rules

- **Earn** = only on blue button (not green · not duplicated in a pill)
- **Spend** = only in spend box (not on button)
- **GST** = meta row only (not on image — image has **FK only**)
- **No duplicate** logos or amounts

---

## Colors (card)

| Element | Hex |
|---------|-----|
| Card surface | `#FFFFFF` · border `#E8EAED` |
| Image box bg | `#F8F9FA` |
| Meta color text | `#5F6368` |
| GST pill | `#E37400` on `#FEF7E0` · border `#F9AB00` |
| Bank row | bg `#F8F9FA` · border `#E8EAED` |
| Spend box | bg `#E8F0FE` · border `#D2E3FC` · label `#1A73E8` · amount `#202124` bold |
| Earn button | `#1A73E8` · white text · radius 10dp |

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md)

---

## API

### `GET /deals`

Query: `dealType` · `store` · `card` · `minEarn` · `q`

```json
{
  "id": "deal_123",
  "dealType": "direct",
  "productName": "Motorola G57 Power 5G",
  "productImageUrl": "...",
  "color": "Midnight Blue",
  "store": { "id": "flipkart", "name": "Flipkart", "logoUrl": "..." },
  "card": { "id": "any", "label": "Any credit / debit card", "logoUrl": "..." },
  "totalCheckout": 17519,
  "youEarn": 300,
  "gstApplicable": true,
  "isActive": true
}
```

### Config / user

- `GET /config/public` → `communityWhatsAppUrl`, `communityWhatsAppEnabled`, `tutorialVideoUrl`
- `GET /user/me` → `firstName`, `tutorialSeen`, `homeViewPreference`
- `GET /user/active-placement` → active order strip

---

## States

| State | UI |
|-------|-----|
| Default | 3+ deals · list or grid |
| First visit | Tutorial banner visible |
| Returning | No tutorial banner |
| Active order | Strip under chips |
| Blocked deal | Dim + “Finish current order first” |
| Loading | Skeleton cards |
| Empty | “No deals right now” + refresh |

## Validation

Load fail → snackbar bottom-right. [../design/VALIDATION-UX.md](../design/VALIDATION-UX.md)

## Navigation

| Action | Goes to |
|--------|---------|
| Tap Earn / card | Deal detail |
| Wallet pill | Wallet |
| WhatsApp | External group link |
| Orders tab | My Orders |

---

## Figma frames to export

| Frame | Content |
|-------|---------|
| `Home — List` | Default list · 3 sample deals |
| `Home — Grid` | Grid toggle · 3 deals |
| `Home — First visit` | + tutorial banner |
| `Home — Active order` | + placement strip (optional v1) |

**Match mockup:** `assets/mockups/home-samples.html` (deal card layout)  
**Affiliate layer (carousel, badges, social proof):** `assets/mockups/mintzer-app-demo.html` v2.4 · [../design/AFFILIATE-MARKETING-REQUIREMENTS.md](../design/AFFILIATE-MARKETING-REQUIREMENTS.md)

---

## Affiliate addendum (September 2026 — does not change locked card fields)

These sit **above** the deal list. Deal card rows/columns stay LOCKED.

| # | Element | Rule |
|---|---------|------|
| A1 | **Promo carousel** | 118dp height · below chips · auto-rotate ~5s · admin slides |
| A2 | Slide 1 | WhatsApp community |
| A3 | Slide 2 | Tutorial video |
| A4 | Slide 3 | **Partner cards** — blue gradient + card art · CTA → partner cards sheet |
| A5 | **Social proof strip** | One line below carousel · e.g. “₹8.2L+ earned this week” |
| A6 | **Urgency badges** | On product image bottom-left: Hot · Trending · N slots left (API-driven) |

Badges are **additive** — see affiliate spec for API fields `badge`, `slotsLeft`.
