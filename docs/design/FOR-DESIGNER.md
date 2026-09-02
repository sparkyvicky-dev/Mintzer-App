# Mintzer — Complete designer handoff

**Date:** June 2026  
**Platform:** Android-first mobile app (Flutter build planned)  
**Languages:** English + Hindi (v1)

**Give your designer this file + the repo folder `docs/` and `assets/mockups/`.**  
Shorter index + PDF instructions: [DESIGNER-HANDOFF.md](./DESIGNER-HANDOFF.md)  
**Master checklist (nothing missed):** [../COMPLETE-DECISIONS-LOG.md](../COMPLETE-DECISIONS-LOG.md)

---

## 0. Start here

### What Mintzer is

Indian fintech deals app. Users browse Flipkart/Amazon card deals, accept a deal, place an order on the store within a timer, submit proof, and get paid into an in-app Wallet. **No withdraw to bank in v1.**

### Client status

Layout and product rules are **locked on key screens** (Home, Place order, Wallet, Profile, account lifecycle). The client tried DIY Figma via AI and **paused** — the result was structurally correct but felt empty (placeholders, too much whitespace, flat cards). **Your job:** same information architecture, **professional visual polish** — real product imagery, spacing rhythm, elevation, typography hierarchy.

### What you own vs what is fixed

| You decide (visual) | Client locked (do not change) |
|---------------------|-------------------------------|
| Typography scale, weights, line heights | Screen list, user flows, bottom nav tabs |
| Shadows, elevation, card density | Home deal card **fields and layout** |
| Illustrations, empty states, skeletons | Place order timer dock behaviour |
| Component styling within Material light/dark | Wallet has **no withdraw** |
| Realistic mock product photos | KYC = Name + PAN only, on first Accept |
| Hindi string layout (allow 2-line buttons) | Primary blue `#1A73E8` — not purple gradients |
| Design system in Figma | No Offers tab in bottom nav (deferred) |

### Style direction (LOCKED)

- **Google Material 3 Light** as default — clean, trustworthy fintech
- **Not** purple AI gradients · **not** dark/gold PerkPay clone · **not** glassmorphism
- Primary: `#1A73E8` · Background: `#F8F9FA` · Surface: `#FFFFFF` · Border: `#E8EAED`
- Text: `#202124` primary · `#5F6368` secondary
- Success/earn green `#188038` on **Deal detail money block** — Home Earn CTA is **blue**, not green
- Full token list: [COLORS-AND-TOKENS.md](./COLORS-AND-TOKENS.md)
- **Light + Dark** required for all 14 routes: [THEME-LIGHT-DARK-MODE.md](./THEME-LIGHT-DARK-MODE.md)

### Validation UX (all screens)

- Wrong field → red text **under** the field + red border
- API / network / success toast → **snackbar bottom-right** (dark `#323232`, white text)
- Full table: [VALIDATION-UX.md](./VALIDATION-UX.md)

---

## 1. Reading order (recommended)

| Order | File | Why |
|------:|------|-----|
| 1 | This file | Overview + locked Home |
| 2 | [SCREEN-INVENTORY.md](../screens/SCREEN-INVENTORY.md) | All 14 routes + 11 overlays |
| 3 | [MINTZER-UI-DESIGN-BRIEF.md](./MINTZER-UI-DESIGN-BRIEF.md) | Full product + every screen element |
| 4 | `assets/mockups/home-samples.html` | **Open in Chrome** — locked Home deal card |
| 4b | `assets/mockups/mintzer-app-demo.html` | **v2.4 affiliate** — carousel, badges, referral, success promos |
| 5 | `assets/mockups/place-order-locked.html` | Locked Place order |
| 6 | `assets/mockups/mintzer-full-flow.html` | Login → end journey |
| 7 | Per-screen specs in `docs/screens/*.md` | Copy, colors, states per route |

**Ignore for layout reference:** `home-v2.html`, `home-v3.html`, `home-card-variants.html` (exploration only).

---

## 2. Scope — how much to design

| Layer | Count | Notes |
|-------|------:|-------|
| **Main routes (pages)** | **14** | User navigates between these |
| **Overlays / sheets** | **11** | On top of a page |
| **Place order layouts** | **2** | External vs in-app — one route |
| **Themes** | **2** | Light + Dark — same layout |

**Total:** ~25 UI surfaces + dark variants of the 14 pages.

### Bottom navigation (LOCKED)

**Home · Orders · Wallet · Profile** — always on main tabs. **No Offers tab.**

**FAB:** Support (chat/tickets) on main tabs — bottom-right, `#1A73E8`.

---

## 3. Main routes — all 14

| # | Screen | Spec file | Status |
|---|--------|-----------|--------|
| 1 | Login — phone | [01-login.md](../screens/01-login.md) | Spec |
| 2 | Login — OTP | [01-login.md](../screens/01-login.md) | Spec |
| 3 | **Home** | [02-home.md](../screens/02-home.md) | **LOCKED layout** |
| 4 | Deal detail | [03-deal-detail.md](../screens/03-deal-detail.md) | Spec + [DEAL-AND-ACCEPT-REQUIREMENTS.md](./DEAL-AND-ACCEPT-REQUIREMENTS.md) |
| 5 | Place order | [04-accept-place-order.md](../screens/04-accept-place-order.md) | **LOCKED** |
| 6 | Order placed success | [05-order-placed-success.md](../screens/05-order-placed-success.md) | Spec |
| 7 | My Orders list | [06-my-orders.md](../screens/06-my-orders.md) | Spec |
| 8 | Order detail | [ORDERS-PAGES-REQUIREMENTS.md](./ORDERS-PAGES-REQUIREMENTS.md) | Spec |
| 9 | Wallet | [07-wallet.md](../screens/07-wallet.md) | **LOCKED** — no withdraw |
| 10 | ~~Offers~~ | Retired from nav | Deferred |
| 11 | Profile | [09-profile.md](../screens/09-profile.md) | **LOCKED** |
| 12 | My tickets | ORDERS-PAGES-REQUIREMENTS.md | Spec |
| 13 | Account suspended | [10-account-suspended.md](../screens/10-account-suspended.md) | **LOCKED** |
| 14 | Account deleted | [11-account-deleted.md](../screens/11-account-deleted.md) | **LOCKED** |

Mockup PNGs in `assets/mintzer-*.png` are **reference only** — if they conflict with `.md` specs, **follow the markdown**.

---

## 4. Overlays — all 11

| # | Name | When | Spec |
|---|------|------|------|
| 1 | KYC (Name + PAN) | First Accept | [BANK-AND-PAYOUT-DETAILS.md](./BANK-AND-PAYOUT-DETAILS.md) |
| 2 | Payout details (UPI or bank) | After KYC | Same |
| 3 | How do you want to shop? | First Place order | [PLACE-ORDER-REQUIREMENTS.md](./PLACE-ORDER-REQUIREMENTS.md) |
| 4 | Cancel order + reason | Place order / Order detail | ORDERS + Place order |
| 5 | Add note | Order detail | ORDERS |
| 6 | Finish current order first | Accept blocked | Deal detail spec |
| 7 | Resume order (optional banner) | App reopen | Home spec |
| 8 | Raise ticket | Order detail | ORDERS |
| 9 | Ticket detail | My tickets | ORDERS |
| 10 | Appearance (Light / Dark / System) | Profile | THEME doc |
| 11 | Delete account | Profile | [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](./ACCOUNT-LIFECYCLE-REQUIREMENTS.md) |

---

## 5. User journey (prototype this flow in Figma)

```
Login (phone → OTP) → Home → Deal detail → Accept deal
                              ↓ first time only
                         KYC → Payout (UPI / bank)
                              ↓
                    Choose: order yourself OR shop in-app
                              ↓
              Place order (timer) → paste Order ID → Submit
                              ↓
                    Success → My Orders list
                              ↓
     Tracking → Delivery OTP → Wait (Mintzer) → Invoice → 48h → Paid → Wallet
```

**Critical flows to prototype:**

1. Accept timer running → Order ID submit success  
2. Active placement blocks new Accept on Home  
3. My Orders step progression (6 steps on Order detail)  
4. Invoice locked vs unlocked  
5. 48-hour payment countdown  
6. Delete account blocked when order in progress  

---

## 6. Home — LOCKED (June 2026)

**Primary reference:** open `assets/mockups/home-samples.html` in Chrome.  
**Full spec:** [02-home.md](../screens/02-home.md)

### Purpose

Browse deals with **earn-first** CTA and clear **checkout spend**. List or grid view.

### Home chrome

| Element | Rule |
|---------|------|
| Header | **Hi, {firstName}** · subtitle “Earn with your card” · **Wallet pill** `₹X` · **Bell** + red dot · **WhatsApp community** (green icon `#25D366` on `#E7F8EE` circle) |
| Search | Full width · “Search deals…” · border `#E8EAED` · radius 24dp |
| View toggle | List (default active) · Grid — persist user preference |
| Filter chips | **All Deals** · **Direct** · **Link** · filter funnel icon |
| Tutorial banner | **First visit only** — “New here? Watch how Mintzer works” + dismiss ✕ · never on repeat visits |
| List meta | “N deals live” · **Highest earn ↓** sort |
| Active order strip | Conditional — product + countdown + Continue |
| Deal list | List (default) or **2-column grid** |
| Support FAB | Bottom-right · `#1A73E8` |
| Bottom nav | Home · Orders · Wallet · Profile |

### Deal card — fields (each shown **once**)

| Field | On card |
|-------|---------|
| Store logo | **Top-left badge on product image only** (FK, Amazon, …) |
| Store name | **Not on Home card text** — logo only; name on Deal detail |
| Product image | Fixed box · **object-fit: contain** · use **real product photos** in mocks |
| Model | Bold title · max 2 lines |
| Color | Meta row left · or “Any color” |
| GST | **`GST` pill on meta row right** — **only when applicable** · **never “No GST”** |
| Bank logo + card name | Row with `#F8F9FA` background |
| Spend (`totalCheckout`) | **Spend box** — filled `#E8F0FE`, border `#D2E3FC`, label “YOU SPEND” `#1A73E8` + **₹X** bold |
| Earn (`youEarn`) | **Blue button** `#1A73E8` — “Earn ₹X” |

**NOT on Home card:** variant · qty · payout speed chip · duplicate earn/spend · store name text · order value before fees

### List view layout

```
┌────────────────────────────────────────────┐
│ [FK]   │  Motorola G57 Power 5G           │
│ [img]  │  Midnight Blue          [GST]    │
│ 80dp   │                                  │
│        │  [bank logo] HDFC Credit Card    │
│ ┌──── YOU SPEND ──────────── ₹17,519 ────┐ │
│ └────────────────────────────────────────┘ │
│ [ Earn ₹300 ]  full width blue button    │
└────────────────────────────────────────────┘
```

### Grid view

Same fields · 2 columns · **Earn button pinned to card bottom** · title min-height 2 lines for row alignment.

### Figma frames to deliver

| Frame | Content |
|-------|---------|
| `Home — List` | Default · 3 sample deals with real-looking product images |
| `Home — Grid` | Grid toggle · 3 deals |
| `Home — First visit` | + tutorial banner |
| `Home — Active order` | + placement strip (optional) |
| `Home — Blocked deal` | Dimmed card + “Finish current order first” |
| `Home — Loading` | Skeleton cards |
| `Home — Empty` | “No deals right now” |

### Sample deal data (for mocks)

| Product | Color | GST | Store | Card | Spend | Earn |
|---------|-------|-----|-------|------|-------|------|
| Motorola G57 Power 5G | Midnight Blue | Yes | Flipkart | Any card | ₹17,519 | ₹300 |
| Samsung Galaxy M35 | Any color | No | Amazon | HDFC Credit Card | ₹22,999 | ₹450 |
| Samsung TV 32" | Black | Yes | Flipkart | Axis Credit Card | ₹12,499 | ₹380 |

---

## 6b. Affiliate marketing layer (September 2026 — LOCKED direction)

Mintzer is an **affiliate hub**, not only order-and-earn. **Full spec:** [AFFILIATE-MARKETING-REQUIREMENTS.md](./AFFILIATE-MARKETING-REQUIREMENTS.md)  
**Interactive demo:** `assets/mockups/mintzer-app-demo.html` (**v2.4 affiliate**) — open in Chrome at `D:\dev\mintzer-app\...`

### Designer must include

| Surface | What to design |
|---------|----------------|
| **Home carousel slide 3** | Partner cards — 118dp banner · blue gradient · card stack art · “Browse cards →” |
| **Home social proof** | One-line strip below carousel |
| **Deal badges** | Hot · Trending · slots left — bottom-left on product image |
| **Order success promo** | **One** rotating template per visit (order more / partner cards / referral / WA) |
| **Refer & earn** | Profile gold banner + referral sheet (code, copy, WA share) |
| **Partner cards sheet** | HDFC + Axis rows · Apply CTA |

### Do NOT design (deferred)

- 5th bottom nav tab · Profile card-catalog hero · full PiePay-style card mall screen

### Figma frames to add

| Frame | Content |
|-------|---------|
| `Home — Carousel partner cards` | Slide 3 in 118dp banner |
| `Home — Badges` | Hot + slots on deal cards |
| `Order success — Promo partner cards` | Upsell card variant |
| `Order success — Promo referral` | Gold refer variant |
| `Profile — Refer banner` | Gold banner + sheet |

---

## 7. Visual polish — Home (designer responsibility)

The locked layout is correct; **premium feel** comes from execution:

| Do | Avoid |
|----|-------|
| Real product PNGs in image boxes | Colorful grid / generic phone placeholders |
| Card padding **12dp**, gap between cards **12dp** | Excessive internal whitespace (16–24dp+) |
| Subtle card shadow: `0 1px 2px rgba(0,0,0,.06)` + `0 2px 8px rgba(0,0,0,.04)` | Flat white cards with border only |
| **Filled** spend box `#E8F0FE` end-to-end | “YOU SPEND” as a label with divider line only |
| Colored bank logo tiles (HDFC red, Axis maroon, etc.) | Generic grey card icon |
| Wallet pill with `#E8F0FE` background | Plain white pill with border only |
| Show **3 deals** in default frame so feed feels alive | 1–2 sparse cards with huge gaps |
| 8dp spacing grid between bank row → spend box → Earn button | Loose vertical rhythm |

Reference apps for **light fintech density** (not copy): Google Pay list views, Paytm home feeds — photos + tight rhythm, not dark high-contrast tricks.

---

## 8. Rejected design directions (do not revisit)

| Rejected | Use instead |
|----------|-------------|
| Green **Earn button** on Home | Blue `#1A73E8` button |
| “No GST” badge when not GST deal | Omit GST pill entirely |
| Duplicate earn/spend on same card | Each fact once (see §6) |
| Variant, qty, Instant/48h chip on Home | Only on Deal detail |
| GST badge on product image | GST on color meta row only; **FK/store logo on image only** |
| Offers tab in bottom nav | Deferred — Wallet tab instead |
| Purple gradients / dark orange competitor clone | Material light Mintzer palette |
| Withdraw button in Wallet | Financial view only |
| Separate Paste button on Order ID field | Tap field to paste from clipboard |
| Persistent tutorial banner every session | First visit only |

---

## 9. Place order — LOCKED v3

**Mockup:** `assets/mockups/place-order-locked.html`  
**Spec:** [PLACE-ORDER-REQUIREMENTS.md](./PLACE-ORDER-REQUIREMENTS.md)

After Accept, user **rechecks model, color, variant** before checkout.

### External mode (default — Open Flipkart)

Single scroll · address below · **2-row bottom dock:**

| Row | Content |
|-----|---------|
| 1 | ⏱ Complete order in **MM:SS** |
| 2 | **Tap to paste Order ID** field + **Submit** |

### In-app mode (Flipkart WebView)

WebView + expandable bottom sheet (Deal · Delivery · Help tabs). **1-row bottom dock:**

`[ ⏱ MM:SS ]` · `[ Order ID field ]` · `[ Submit ]`

### Order ID field (LOCKED)

- **No separate Paste button**
- One tap on field = focus + paste from clipboard
- Empty placeholder: *Tap to paste Order ID*
- Clipboard empty → snackbar: *Copy Order ID from Flipkart first*

Also on screen: product · checkout ₹ · discount · earn · address with Copy per line · Generate new address · Cancel · mode chip.

---

## 10. Deal detail — money block

Sticky bottom: **Accept deal** (blue).

Top bar: WhatsApp + **Report error** (opens WhatsApp with deal prefilled).

**Money summary card** (example rows):

- Order value  
- Platform fee, Card fee (if any)  
- **Total you pay at checkout**  
- Bank cashback (user’s card — not from Mintzer)  
- Wallet credit from Mintzer  
- **You earn (commission)** — **largest green number** `#188038`

Footer note: *Cashback is credited as per your bank’s billing cycle. Mintzer wallet after order completion.*

Full spec: [DEAL-AND-ACCEPT-REQUIREMENTS.md](./DEAL-AND-ACCEPT-REQUIREMENTS.md) · [03-deal-detail.md](../screens/03-deal-detail.md)

---

## 11. My Orders + Order detail

### List card — timer still running

- “Complete order in MM:SS”  
- Product image + name + store  
- Earn amount  
- **Continue order** button  

### List card — order submitted

- Order ID + copy  
- Progress: Placed → Shipped → Out for delivery → Invoice → Payment  
- One line: next action (e.g. “Add tracking ID”)  

### Order detail timeline

| Step | User action |
|------|-------------|
| Accepted / Placed | Date + external Order ID (read-only) |
| Tracking | Paste tracking ID + choose courier |
| Out for delivery | Last 4 digits of phone + delivery OTP |
| Waiting | Grey — “Waiting for Mintzer” |
| Invoice | Upload photo/PDF (after Mintzer unlocks) |
| Payment | 48-hour countdown after invoice |
| Paid | Done → Completed tab |

Header: Order ID · Add note · Cancel · Report issue

Full spec: [ORDERS-PAGES-REQUIREMENTS.md](./ORDERS-PAGES-REQUIREMENTS.md)

---

## 12. Wallet — LOCKED

| Block | Meaning |
|-------|---------|
| **Available** | Money user can count on now |
| **Pending** | Earned but not approved yet |
| **Total earned** | Lifetime |
| **History list** | Every order — Paid / Pending / Canceled + amount |

**Filters:** date range · **Download Excel**

**Do not design:** withdraw · bank transfer · add money

Spec: [WALLET-REQUIREMENTS.md](./WALLET-REQUIREMENTS.md) · mockup `assets/mintzer-wallet-mockup.png`

---

## 13. Profile — LOCKED

- Hi {name} + avatar initial  
- KYC status  
- Payout details (edit)  
- Language (EN / HI)  
- **Appearance** — Light / Dark / System  
- My tickets  
- Help · Tutorials · Notifications · Terms  
- **Delete account** (Settings)  
- Logout (red text)

**Do not put** Wallet or My Orders shortcuts here (bottom nav only).

Spec: [PROFILE-REQUIREMENTS.md](./PROFILE-REQUIREMENTS.md)

---

## 14. Account suspended & deleted — LOCKED

**Suspended:** *Your account is not active right now. Please contact support if you want to restore access.*  
Actions: Contact support · Back to login. No harsh “banned” wording.

**Delete blocked:** *You have an order in progress. Please finish or cancel it before deleting your account.*

**Deleted:** *Your account has been removed. Contact support if you need help.* → Back to login

Spec: [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](./ACCOUNT-LIFECYCLE-REQUIREMENTS.md)

---

## 15. KYC + payout (first Accept only)

**KYC:** Name + PAN only — no other fields at signup or login.

**Payout:** UPI **or** bank account — user picks one path.

Spec + field validation: [BANK-AND-PAYOUT-DETAILS.md](./BANK-AND-PAYOUT-DETAILS.md)

---

## 16. Colors (quick reference)

Full tokens: [COLORS-AND-TOKENS.md](./COLORS-AND-TOKENS.md)

### Light (default)

| Use | Hex |
|-----|-----|
| Primary buttons, links, Home Earn CTA | `#1A73E8` |
| Background | `#F8F9FA` |
| Cards / inputs | `#FFFFFF` |
| Spend box / selected chip bg | `#E8F0FE` |
| Spend box border | `#D2E3FC` |
| Earn / success (Deal detail hero) | `#188038` |
| GST pill text / timer accent | `#E37400` on `#FEF7E0` |
| Error | `#D93025` |
| Text primary | `#202124` |
| Text secondary | `#5F6368` |
| Border / divider | `#E8EAED` |

### Dark

| Use | Hex |
|-----|-----|
| Background | `#121212` |
| Cards | `#1E1E1E` |
| Primary | `#8AB4F8` |
| Text main | `#E8EAED` |
| Earn | `#81C995` |

**Rule:** Same layout in light and dark — colors only.

---

## 17. Logo & image rules

| Asset | Rule |
|-------|------|
| Mintzer brand | **Placeholder** until client delivers final logo — text “Mintzer” `#1A73E8` or grey box; **do not change app blue** when logo updates |
| Store logos (FK, Amazon) | Fixed box · **object-fit contain** · never stretch · ~40dp in detail views · badge on Home image |
| Bank / card logos | ~26–32dp · contain · colored tiles OK in mocks |
| Product images | Fixed frame · contain · **use realistic photos in all marketing mocks** |

---

## 18. Out of scope for v1

- Admin website  
- Withdraw / transfer to bank from app  
- Instant orders tab  
- In-app WhatsApp chat (opens external WhatsApp only)  
- Live courier tracking map  
- Offers tab in navigation  
- OCR from screenshots  

---

## 19. Deliverables checklist

### Figma file

- [ ] Design system page: colors (light + dark tokens), type scale, buttons, inputs, chips, cards, snackbar, inline error
- [ ] **14 main routes** — light mode, all states listed in each screen spec
- [ ] **Same 14 routes** — dark mode
- [ ] **11 overlays** as components
- [ ] **Place order** — external + in-app layouts
- [ ] **Home** — List, Grid, First visit, Loading, Empty, Blocked (minimum)
- [ ] Prototype: main journey §5 + 5 critical flows
- [ ] Component naming matches artboard list in [MINTZER-UI-DESIGN-BRIEF.md](./MINTZER-UI-DESIGN-BRIEF.md) Appendix A

### Assets export

- [ ] Store logo placeholder components (FK, Amazon)
- [ ] Bank logo placeholder components (HDFC, Axis, Any card)
- [ ] Product image frame component (contain behaviour documented)
- [ ] Icon set for bottom nav, FAB, header actions

### Copy / localization

- [ ] English strings in Figma or Google Sheet
- [ ] Hindi strings for priority screens (Login, Home, Deal detail, Accept, Orders, Wallet)
- [ ] Allow 2-line Hindi on primary CTAs

### Handback to dev

- [ ] Figma link with view access
- [ ] Exported PNG/SVG for placeholders
- [ ] Spacing notes (8dp grid) on key components
- [ ] Redlines for Home deal card (locked measurements from mockup)

---

## 20. Complete file index

| Topic | Path |
|-------|------|
| **This handoff** | `docs/design/FOR-DESIGNER.md` |
| Short handoff + PDF | `docs/design/DESIGNER-HANDOFF.md` |
| Full design brief | `docs/design/MINTZER-UI-DESIGN-BRIEF.md` |
| Screen inventory | `docs/screens/SCREEN-INVENTORY.md` |
| All screen specs | `docs/screens/*.md` |
| Colors & tokens | `docs/design/COLORS-AND-TOKENS.md` |
| Light / dark | `docs/design/THEME-LIGHT-DARK-MODE.md` |
| Validation UX | `docs/design/VALIDATION-UX.md` |
| Home spec | `docs/screens/02-home.md` |
| Home HTML mockup | `assets/mockups/home-samples.html` |
| Place order mockup | `assets/mockups/place-order-locked.html` |
| Full flow mockup | `assets/mockups/mintzer-full-flow.html` |
| Place order spec | `docs/design/PLACE-ORDER-REQUIREMENTS.md` |
| Deal + Accept | `docs/design/DEAL-AND-ACCEPT-REQUIREMENTS.md` |
| Orders | `docs/design/ORDERS-PAGES-REQUIREMENTS.md` |
| Wallet | `docs/design/WALLET-REQUIREMENTS.md` |
| Profile | `docs/design/PROFILE-REQUIREMENTS.md` |
| KYC + payout | `docs/design/BANK-AND-PAYOUT-DETAILS.md` |
| Account lifecycle | `docs/design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md` |
| Backend field reference | `docs/backend/01-deals-and-pricing.md` |
| PNG references | `assets/mintzer-*.png` |

---

## 21. Client locked decisions (summary)

| # | Decision |
|---|----------|
| 1 | New Mintzer logo coming — placeholder until delivered |
| 2 | KYC: Name + PAN on **first Accept** only |
| 3 | Login: phone + OTP only |
| 4 | Flow: Home → Deal detail → Accept (read before commit) |
| 5 | One active place-order timer at a time |
| 6 | v1 orders: Regular only — no Instant tab |
| 7 | Wallet: no withdraw |
| 8 | Languages: English + Hindi |
| 9 | Bottom nav: Home · Orders · Wallet · Profile |
| 10 | Home deal card layout: **LOCKED** June 2026 |
| 11 | Place order dock + tap-to-paste Order ID: **LOCKED** |
| 12 | Primary blue `#1A73E8` — fixed brand accent |

---

**Questions?** Work from specs first; flag conflicts in a shared doc. When spec and mockup disagree on **locked** screens, follow **`02-home.md`** and **`home-samples.html`** for Home, **`PLACE-ORDER-REQUIREMENTS.md`** for Place order.

**Version:** June 2026 · Mintzer rebuild v1
