# Affiliate marketing layer — requirements (LOCKED direction)

**Status:** **LOCKED** for design + demo (September 2026)  
**Interactive reference:** `assets/mockups/mintzer-app-demo.html` — **v2.4 affiliate**  
**Placement mockups:** `assets/mockups/card-apply-placements.html`  
**Audience:** Designer, frontend, backend, client

---

## 1. Why this exists

Mintzer is **not only** “order and earn.” It is an **affiliate hub**:

```
Discover (deals + promos + cards)
  → Apply partner card (optional)
  → Accept deal → order → earn
  → Refer friends → community (WhatsApp)
  → Repeat
```

**Bottom nav stays:** Home · Orders · Wallet · Profile — **no Offers tab**, **no 5th tab** for cards.

Partner cards, referrals, and promos use **existing surfaces** + **admin-rotatable templates**.

---

## 2. What is in v1 affiliate (client approved direction)

| # | Feature | Where | Status in demo |
|---|---------|-------|----------------|
| 1 | **Home promo carousel — Partner cards slide** | Home banner (118dp) | ✅ v2.4 |
| 2 | **Social proof strip** | Home, below carousel | ✅ v2.4 |
| 3 | **Deal urgency badges** | Home deal cards + deal detail | ✅ v2.4 |
| 4 | **Order success — rotating marketing template** | Order placed success | ✅ v2.4 |
| 5 | **Refer & earn** | Profile banner + menu + success template | ✅ v2.4 |
| 6 | **Partner cards full screen** | Home banner / success → PiePay-style list | ✅ v2.5 |

### Explicitly NOT primary v1 affiliate placements (deferred)

| Placement | Decision |
|-----------|----------|
| **Deal detail — card apply block** | Keep in demo for missing-card edge case only; **not** main affiliate entry |
| **Profile — card catalog hero** | **Deferred** — Profile gets referral, not full card mall hero |
| **Bottom nav — Offers / Cards tab** | **Never** without client unlock |

---

## 3. Home — promo carousel

### Layout (LOCKED)

- **Position:** Below filter chips, above tutorial banner / deal list  
- **Height:** **118dp** fixed (same box as WhatsApp + tutorial slides)  
- **Auto-rotate:** ~5s · dots · tap dot to jump  
- **Admin-driven:** swap slides without app release

### Slides (v1 minimum)

| Slide | Kicker | Purpose |
|-------|--------|---------|
| 1 | Mintzer community | WhatsApp channel — deals before Home |
| 2 | New here? | Tutorial video |
| 3 | **Partner cards** | Affiliate — apply HDFC/Axis etc. |

### Slide 3 — Partner cards (LOCKED visual)

- **Background:** Blue gradient `#174EA6` → `#1A73E8` → `#4285F4` (Mintzer — not purple/gold clone)
- **Copy:** Headline e.g. “Unlock ₹12,000+ in deals this month” · subline “HDFC & Axis · Fee waived on select cards”
- **CTA:** “Browse cards →” (white pill)
- **Art (right):** Stacked card images — designer PNG **~78×88dp** inside banner, or CSS fallback
- **Tap CTA:** Opens **Partner cards sheet** (§7)

**Designer asset:** Optional full-bleed banner PNG **328×118 @2×** for slide 3 only.

---

## 4. Home — social proof strip

- **Position:** Directly below promo carousel  
- **Style:** White card · border `#E8EAED` · one line  
- **Example copy:** “🔥 **₹8.2L+** earned this week · **42 orders** completed today”  
- **Source:** Admin config or aggregated stats API  
- **Purpose:** Trust + FOMO — affiliate apps show movement

---

## 5. Home — deal urgency badges

Badges are **additive** — do **not** change locked deal card field layout ([02-home.md](../screens/02-home.md)).

| Badge | When | On image position |
|-------|------|-------------------|
| **🔥 Hot** | Admin `badge: hot` | Bottom-left of product image |
| **📈 Trending** | Admin `badge: trending` | Bottom-left |
| **⚡ N left** / **N slots** | When `slotsLeft ≤ 12` | Bottom-left |

- **GST pill** stays top-right on image (demo v2.4)  
- **Store pin** stays top-left on image  
- Badges stack bottom-left; max 2 visible (priority: slots ≤5 → hot → trending → slots)

**Deal detail:** Same badges as pills under title meta row.

### API fields (deals)

```json
{
  "badge": "hot | trending | null",
  "slotsLeft": 8
}
```

---

## 6. Order placed success — rotating template

**Rule:** **One** marketing slot per visit — **do not stack** two big CTAs (e.g. “order more” + “partner cards” both full size).

### Fixed elements (always)

| Element | Copy / behavior |
|---------|-----------------|
| Success icon | Green check |
| Title | “Order placed!” |
| Subtitle | Track in My Orders |
| Earn chip | “You're earning **₹X** on this order” |
| Primary button | **Go to My Orders** |

### Rotating promo slot (one of)

Admin/backend picks **one template** per success view (rotate by order count, day, segment, or A/B):

| Template ID | Visual | CTA action |
|-------------|--------|------------|
| `order_more` | Blue gradient card · 🔥 | Navigate Home |
| `partner_cards` | White bordered upsell · Level up badge | Partner cards sheet |
| `referral` | Gold/yellow card | Refer & earn sheet |
| `whatsapp` | Green gradient | Open `communityWhatsAppUrl` |

**Demo behavior:** Cycles templates by `orderIndex % 4` after each placed order.

---

## 7. Partner cards sheet (overlay)

**Entry points:**

- Home carousel slide 3 → Browse cards  
- Order success template `partner_cards`  
- *(Optional later)* notification deep-link

**Not entry points (v1):** Bottom nav · Wallet tab

### Sheet content

| Row | Fields |
|-----|--------|
| Title | “Partner cards” |
| Subtitle | Apply through partner links · use on Mintzer deals |
| Card list | Bank logo · name · perk line · **Apply →** |
| Close | Dismiss sheet |

**Apply →** Opens partner URL in browser (affiliate tracking param TBD).

### Sample cards (demo)

| Card | Perk |
|------|------|
| HDFC Credit Card | Lifetime free* · 5% on Flipkart |
| Axis Credit Card | ₹500 welcome · Amazon deals |

**Full catalog screen** (PiePay-style list) = **v1 in demo** — Home banner / success promo opens `Apply for cards` full screen. Sheet overlay is optional fallback only.

---

## 8. Refer & earn

### Profile (LOCKED v1 affiliate)

| Element | Rule |
|---------|------|
| **Gold banner** | Top of Profile, below avatar — “Refer & earn ₹200 per friend” + code hint |
| **Menu row** | “Refer & earn” · sub “₹200 each” |

### Referral sheet

| Element | Rule |
|---------|------|
| Title | “Refer & earn ₹200” |
| Rule | Friend completes **first order** → both get ₹200 Wallet |
| Code | Unique per user e.g. `ARUN200` · **Copy** button |
| Share | **Share on WhatsApp** — prefilled message + code |
| Stats | Friends joined · Referral bonus earned |

### Entry points

- Profile banner / menu row  
- Order success template `referral`

### Business rules (backend TBD)

- One referral credit per referred user (first completed order)  
- Fraud checks on same device / PAN  
- Bonus amount admin-configurable (`referralBonusInr`)

---

## 9. Admin template engine (backend)

Single concept for **Home carousel** + **Order success** promos:

```json
{
  "id": "partner_cards_home",
  "surface": "home_carousel | order_success",
  "priority": 3,
  "enabled": true,
  "startAt": "2026-09-01T00:00:00+05:30",
  "endAt": null,
  "title": "Unlock ₹12,000+ in deals",
  "subtitle": "HDFC & Axis",
  "ctaLabel": "Browse cards →",
  "ctaAction": "open_partner_cards | open_url | navigate_home | open_referral | open_whatsapp",
  "ctaUrl": null,
  "imageUrl": "https://cdn.../banner-partner-cards.png",
  "gradient": ["#174EA6", "#1A73E8", "#4285F4"]
}
```

See [08-app-config.md](../backend-%20for%20developer%20reference/08-app-config.md) for config keys.

---

## 10. What NOT to do

| Don't | Why |
|-------|-----|
| Purple/gold PiePay clone | Mintzer = Material blue `#1A73E8` |
| 5th bottom nav tab | Locked 4-tab nav |
| Two full-size success CTAs | Rotate templates instead |
| Card mall as Profile hero (v1) | Client deferred — referral only on Profile |
| Wallet withdraw button | Still no withdraw v1 |

---

## 11. Files & mockups

| File | Purpose |
|------|---------|
| `assets/mockups/mintzer-app-demo.html` | **Full interactive demo v2.4 affiliate** |
| `assets/mockups/card-apply-placements.html` | 4 placement examples + affiliate hub summary |
| `assets/mockups/home-samples.html` | Locked Home **deal card** only — carousel/badges in demo |
| `docs/screens/02-home.md` | Home spec + affiliate addendum |
| `docs/screens/05-order-placed-success.md` | Success + rotating promo |
| `docs/design/PROFILE-REQUIREMENTS.md` | Referral on Profile |

**Open demo (local dev copy):**  
`D:\dev\mintzer-app\assets\mockups\mintzer-app-demo.html`  
Confirm title shows **v2.4 affiliate**.

---

## 12. Phase 2 (later — not blocking design)

- Full **Apply for cards** scroll screen — **done in demo v2.5** (Home banner → list)  
- Profile card hero (if client unlocks)  
- Deal detail card apply as primary funnel  
- Seasonal carousel slide 4 (Diwali earn boost)  
- In-app **Stories** strip on Home  
- Leaderboard / top earners  
- Offers hub under Profile (not bottom nav)  
- Push templates for “New card live” / “Deal drop”

---

**Version:** September 2026 · **Owner:** Client + product
