# Screen: Home

**Status:** **LOCKED** (18 Sep 2026 — style **B**)  
**Visual source:** `assets/mockups/mintzer-designer-taste-demo.html`  
**Open in Brave:** `scripts/open-live-demo.ps1` · `?home=1`  
**Supersedes:** `assets/mockups/home-samples.html` (June 2026 spend-box card — historical only)

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
| 1 | **Header** | **Morning / Afternoon / Hi / Evening / Night, {firstName}** (white, IST). Subtitle in **`#DDD4FF` on solid purple** (never on the fade wash). **One line per Home open — never a timer rotator.** If placement timer → `Timer's on. Finish this order`. If unpaid order steps 1–4 → `An order needs you`. Else idle pool by time of day (many templates — Flutter `pickHomeIdleSub()`). · **Wallet** pill · **Bell** · **WhatsApp** (green WA glyph on white circle) |
| 2 | **Search** | Full width · placeholder “Search deals…” · `#E8EAED` border · 24dp radius |
| 3 | **View toggle** | **List** icon · **Grid** icon — persist `homeViewPreference` |
| 4 | **Filter chips** | **All Deals** · **Direct** · **Link** · filter funnel icon (sheet: store, card, min earn) |
| 5 | **Tutorial banner** | **First visit only** — “New here? Watch how Mintzer works” + dismiss ✕ · hidden when `tutorialSeen` · never on repeat visits |
| 6 | **List meta** | “N deals live” · **Highest earn ↓** sort |
| 7 | **Active order strip** | **LOCKED 20 Sep 2026:** green card · live `mm:ss left` · product · Complete your order · **Continue →**. Urgent (&lt;5 min): amber *Finish before time runs out*. Timer shared with Place order (`MockSession.placementEndsAt`). |
| 8 | **Deal list** | **2-column grid (default)** or list — same card data |
| 9 | **Help chip** | Bottom-right pill · Help · tickets |
| 10 | **Bottom nav** | **Home · Orders · Wallet · Profile** — no Offers |

---

## Deal card — LOCKED fields (each shown **once**)

| # | Field | API | On card |
|---|--------|-----|---------|
| 1 | Store logo | `store.logoUrl` | **Top-left circle on product image** |
| 2 | Store name | `store.name` | **Not on Home card text** — logo only; name on Deal detail |
| 3 | Bank logo | `card.logoUrl` | Caption row — 22dp circle, contain |
| 4 | Card name | `card.label` | Caption row, with spend |
| 5 | Product image | `productImageUrl` / `images[]` | One image · **object-fit: contain** |
| 6 | Model | `productName` | **On the photo**, grey overlay, **1 line** then ellipsis |
| 7 | Color | `color` | **On the overlay**, under the name — or “Any color” |
| 8 | GST | `gstApplicable` | **`GST` pill on image top-right** — **only when true** · never “No GST” |
| 9 | Spend | `totalCheckout` | Caption **right**, always visible (`₹22,999`). Card name on the left may ellipsis. No “YOU SPEND” box |
| 10 | Earn | `youEarn` | **Primary button** `Earn ₹X` — `#7B61FF` |

### NOT on Home card (v1)

Variant · Qty · Payout speed chip · Order value before fees · Cashback/fees · Duplicate store name text · **YOU SPEND box**

### Multiple images

Admin: one PNG per color. **Home shows one image.** All colors on Deal detail.

---

## Deal card layout (CLIENT PREFERS — ChatGPT hierarchy, 20 Sep 2026)

**Was style B** (name on photo overlay + bank/spend caption) — still in code behind `kChatGptCardPreview = false`.

**Live now:** product → variant → bank/price → Earn. Fixed image zone; title below photo. Flag: `app/lib/widgets/deal_card.dart` → `kChatGptCardPreview`.

### Grid view (default — 2 columns)

```
[store]              [GST]
[fixed photo zone]
product name (bold)
color · variant
[bank]  Amex              ₹79,900
[ Earn ₹900 ]
```

### List view

```
┌──────────┬─────────────────────────────┐
│ [photo]  │  name                       │
│          │  variant                    │
│          │  [bank] Amex · ₹spend       │
│          │  [ Earn ₹X ]                │
└──────────┴─────────────────────────────┘
```

### Rules

- **Earn** = only on primary button (not duplicated in a pill)
- **Spend** = with bank row (not on the button)
- **Name + variant** = below photo (not grey overlay)
- **GST** = tiny quiet chip, image top-right
- **One** urgency label per deal (Hot **or** Trending **or** slots). Free corner: top-right if no GST, bottom-right if GST. **Admin sets `badge` — app never auto-assigns.**
- **Home card names:** BOB Credit Card · Amex
- **Card surface:** white · border `#E8EAED` · light radius 16

<details>
<summary>Previous lock — style B (18 Sep 2026)</summary>

Client lock was: caption-pay + grey overlay (name on photo). Restore with `kChatGptCardPreview = false`.

```
[FK pin]              [GST]
[photo]
  grey fade: product name (1 line)
             color              [Hot]
[bank logo]  HDFC              ₹22,999
[ Earn ₹450 ]
```
</details>

---

## Colors (card)

| Element | Hex |
|---------|-----|
| Card surface | `#FFFFFF` · border `#E8EAED` |
| Image box bg | `#FFFFFF` (dark product shots `#111`) |
| Overlay wash | Bottom fade `linear-gradient(transparent, rgba(60,64,67,.88))` · white title |
| Caption | `#5F6368` · 10sp |
| GST pill | `#E37400` on `#FEF7E0` · border `#F9AB00` |
| Earn button | `#7B61FF` · white text · radius 8dp |

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
| Default | 3+ deals · **2-column grid** (list toggle still available) |
| First visit | Tutorial banner visible |
| Returning | No tutorial banner |
| Active order | Strip under chips |
| Blocked deal | Dim + “Finish current order first” |
| Loading | Skeleton cards |
| Empty | Centered full-width (not a leftover grid cell) · Send-plane icon (not +) · **Got a deal we don’t?** · `WhatsApp · Telegram · anywhere` · CTA **Send it in** |
| Empty + filters | “Nothing matches” + Clear filters + **Send a deal anyway** |

## Validation

Load fail → snackbar bottom-right. [../design/VALIDATION-UX.md](../design/VALIDATION-UX.md)

## Navigation

| Action | Goes to |
|--------|---------|
| Tap Earn / card | Deal detail |
| Wallet pill | Wallet |
| WhatsApp | External group link |
| **Send it in** | Sheet **Send a deal you saw**: product · source chips · store optional · link optional. **Goes to Mintzer ops queue** (`POST /deal-suggestions`) — not WhatsApp, not My tickets. Ops review in **admin app**, then post as a real deal or dismiss. User gets snackbar only. |
| Orders tab | My Orders |

---

## Figma frames to export

| Frame | Content |
|-------|---------|
| `Home — Grid` | **Default** 2-col grid · 3 sample deals |
| `Home — List` | List toggle · 3 sample deals |
| `Home — First visit` | + tutorial banner |
| `Home — Empty` | Send-plane icon · **Got a deal we don’t?** · **Send it in** |
| `Home — Suggest deal` | Overlay: other-source hook → ops queue |

**Match mockup:** `assets/mockups/mintzer-designer-taste-demo.html` (style B)  
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
| A6 | **Urgency badges** | One per deal on the photo: Hot **or** Trending **or** N slots. Corner: top-right if no GST, bottom-right if GST |

Home shows **one** urgency chip (never Hot + slots together). API may still send both; UI prefers slots, else `badge`.

## 14 Oct 2026

Not part of the delivery-call update. This screen stays as written above.
