# Mintzer — Complete decisions log (everything we discussed)

**Purpose:** Single checklist so **nothing is missed** — for you, designer, and developers.  
**Last updated:** September 2026  
**Rule:** If this file disagrees with a screen `.md`, **fix the `.md`** — this log summarizes all of them.

**Also read:** [AGENT-DEV-PROCESS.md](./AGENT-DEV-PROCESS.md) · [FOR-DESIGNER.md](../design/FOR-DESIGNER.md) · [SCREEN-INVENTORY.md](../screens/SCREEN-INVENTORY.md)

---

## 1. What Mintzer is

Android-first Indian fintech app. Users browse Flipkart/Amazon **card deals**, read full money breakdown, **Accept** a deal, place an order on the store within a **timer**, complete tracking → delivery OTP → invoice → **48h payment wait**, earnings show in **Wallet**.

**v1 languages:** English + Hindi  
**Not a bank.** Wallet = view earnings history. **No withdraw in app.**

---

## 2. Full user journey

```
Login (phone + OTP only)
  → Home (browse deals)
  → Deal detail (read money + rules)
  → Accept deal
  → [First time: KYC Name+PAN → Payout UPI/bank]
  → [First time: How do you want to shop? External vs In-app]
  → Place order (timer, copy address, Open store, paste Order ID, Submit)
  → Order placed success
  → My Orders (Ongoing → steps → Completed)
  → Order detail (tracking, OTP, invoice, payment countdown)
  → Wallet (balance + history + Excel export)
  → Profile (settings, tickets, delete account, logout)
```

**Alternate paths:** Account suspended at login · Delete account (blocked if order in progress) · Account deleted screen

---

## 3. Global rules (never break)

| # | Rule |
|---|------|
| 1 | **Bottom nav:** Home · Orders · Wallet · Profile — **no Offers tab** |
| 2 | **Login:** phone + OTP only — **no** name, email, KYC, bank at login |
| 3 | **KYC:** Name + PAN — **first Accept only** |
| 4 | **Payout:** UPI **or** bank — right after KYC on first Accept; edit in Profile |
| 5 | **Deal flow:** Home → Deal detail → Accept (read before commit — Option B) |
| 6 | **One active placement** at a time until Order ID submitted or cancelled/expired |
| 7 | **Timer duration** from backend config — not hardcoded in app |
| 8 | **Expired placement** → admin log only — **not** a user order in My Orders |
| 9 | **Wallet:** no withdraw, no add bank on Wallet screen |
| 10 | **Primary color:** `#1A73E8` (dark: `#8AB4F8`) — fixed when logo updates |
| 11 | **Style:** Google Material 3 Light default + **full dark mode** required |
| 12 | **Not:** purple gradients · dark/orange PerkPay clone · glassmorphism |
| 13 | **v1 orders:** Regular only — **no Instant tab** |
| 14 | **No auto courier GPS** — user picks partner + pastes tracking ID |
| 15 | **Invoice upload** only after admin marks parcel received |
| 16 | **48h payment countdown** starts at invoice upload (configurable hours) |
| 17 | **Validation:** field errors **inline** · API/copy → **snackbar bottom-right** |
| 18 | **Markdown specs beat PNG mockups** · exploration HTML (`home-v2`, `home-v3`, `home-card-variants`) **not** source of truth |

---

## 4. Style & theme

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#1A73E8` | `#8AB4F8` |
| Background | `#F8F9FA` | `#121212` |
| Surface / cards | `#FFFFFF` | `#1E1E1E` |
| Text primary | `#202124` | `#E8EAED` |
| Text secondary | `#5F6368` | `#9AA0A6` |
| Earn hero (Deal detail) | `#188038` | `#81C995` |
| Home Earn **button** | `#1A73E8` blue | not green |
| Spend box | `#E8F0FE` / border `#D2E3FC` | per THEME doc |
| Error | `#D93025` | `#F28B82` |
| GST pill | `#E37400` on `#FEF7E0` | — |
| Timer accent | `#E37400` on `#FEF7E0` | — |

**Appearance:** Profile → Light · Dark · System (follow phone)

**Logos:** Fixed box · `object-fit: contain` · never stretch · placeholder until brand files arrive

Detail: [design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md) · [design/THEME-LIGHT-DARK-MODE.md](../design/THEME-LIGHT-DARK-MODE.md)

---

## 5. Money formulas

```
totalCheckout      = orderValue − discount + platformFee + cardFee
walletFromMintzer  = orderValue − cashback − discount + commission
youEarn            = commission − tds
```

- Bank **cashback** is user's card — not paid twice by Mintzer  
- Fees may not be eligible for cashback — show in YOU PAY block  
- Admin calculates; app displays exact rupees from API  

---

## 6. All 14 main screens

### 6.1 Login — phone + OTP
- +91 · 10 digits · Continue disabled until valid  
- OTP 4–6 digits · resend timer  
- Wrong OTP → snackbar · invalid phone → inline  
- Success → Home (or **Account suspended** if ops suspended user)  
- **No** KYC / bank / mandatory notification permission  
- Spec: [screens/01-login.md](../screens/01-login.md)

### 6.2 Home — **LOCKED layout**
**Reference:** `assets/mockups/home-samples.html` · [screens/02-home.md](../screens/02-home.md)

**Chrome:**
- Hi, {firstName} · “Earn with your card”  
- Wallet pill ₹X → Wallet  
- Bell + notification dot → notification center (design brief)  
- **WhatsApp community** icon (green) → `communityWhatsAppUrl` from config  
- Search “Search deals…”  
- List / Grid toggle — persist `homeViewPreference`  
- Chips: **All Deals · Direct · Link** + filter funnel → **sheet:** store, card, min earn  
- Tutorial banner **first visit only** — dismiss → `tutorialSeen` — never every session  
- “N deals live” · **Highest earn ↓** sort  
- **Active order strip** when placement timer running  
- Support FAB → tickets/help  
- Bottom nav  

**Deal card — each fact ONCE:**
| On card | Not on Home card |
|---------|------------------|
| Store logo **top-left on image** | Store name text |
| Product image (contain) | Variant, qty |
| Model (bold, max 2 lines) | Payout speed chip |
| Color on meta row left | Duplicate earn/spend |
| GST pill meta row **right** — **only if** `gstApplicable` | “No GST” label |
| Bank row: logo + card name | Order value before fees |
| Spend box `#E8F0FE` “YOU SPEND” + ₹ | |
| Blue button “Earn ₹X” `#1A73E8` | |

**Grid:** 2 columns · Earn button pinned bottom · title min-height 2 lines  

**States:** loading skeleton · empty · blocked deals dimmed · first visit tutorial  

**Rejected (Home):** green Earn button · duplicate earn/spend · GST on image · variant/qty on card · Offers tab · purple/dark-orange clone UI  

### 6.3 Deal detail
- Product image, name, color, **variant**, **qty**  
- Store + bank **LogoRow** (fixed size, contain)  
- **Money card:** order value, platform fee, card fee, discount, total checkout, bank cashback, wallet from Mintzer, **you earn (largest green)**  
- Footer note on billing cycle  
- Optional expand “How wallet is calculated”  
- Collapsible: Offer details · Links · How to use (YouTube)  
- Header: **WhatsApp** + **Report error** → prefilled WA message with deal info (hidden if admin WA OFF)  
- Sticky **Accept deal** blue button  
- **No** timer · address · Order ID on this screen  
- Active placement exists → overlay “Finish current order first”  
- Spec: [screens/03-deal-detail.md](../screens/03-deal-detail.md) · [design/DEAL-AND-ACCEPT-REQUIREMENTS.md](../design/DEAL-AND-ACCEPT-REQUIREMENTS.md)

### 6.4 Place order — **LOCKED v3**
**Reference:** `assets/mockups/place-order-locked.html` · [design/PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md)

**Must show:** product model · color · variant · qty · store · card · checkout ₹ · discount · earn · timer · address · actions  

**Address — copy per line:** Name · Addr1 · Addr2 · City · State · Pin · Phone — **Copy** each · optional small “Copy all” link · **Generate new address** (same pincode, weekly limit)  

**Order ID — LOCKED:** **Tap field to paste** from clipboard — **no separate Paste button**  

**External mode (default):** scroll · Open Flipkart after checkout · **2-row bottom dock:** timer row + Order ID + Submit  

**In-app mode:** WebView + PerkPay drag-up sheet · **3 tabs:** Deal · Delivery · Help · **1-row dock:** timer · Order ID · Submit  

**Cancel order** on this screen · duplicate external Order ID → **hard block**  

**First time:** overlay “How do you want to shop?” · mode chip + Change  

### 6.5 Order placed success
- Short confirmation · **Go to My Orders**  
- Spec: [screens/05-order-placed-success.md](../screens/05-order-placed-success.md)

### 6.6 My Orders list
- Tabs: **Ongoing | Completed**  
- **Search:** Order ID · Tracking ID · **product name / model**  
- **Filter:** Store (All + each store)  
- **Sort:** Newest (default) · Oldest · **Needs action first**  
- **Badge** on Ongoing = count needing user action  
- Pull to refresh  
- Empty Ongoing → Browse deals  

**Each card:** Mintzer ref + copy · one status sentence · product · store · earn · timer on placement · one primary action when needed  

**Active placement in Ongoing immediately after Accept** (before Order ID) — **Continue order**  

**Resume rule — LOCKED:** Home strip + My Orders timer — **not** notification-only (unlike PerkPay pattern)  

**Completed tab:** Paid + **Canceled** (labeled separately)  

Spec: [screens/06-my-orders.md](../screens/06-my-orders.md) · [design/ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md)

### 6.7 Order detail
**Header:** back · ref + copy · **Add note** · **Report issue** · **Cancel order**  

**Notes — LOCKED:**
- User reminder only (e.g. “Used Raj’s HDFC card”)  
- Order detail header · modal/sheet · max **200 chars**  
- Save · reopen · edit · save again  
- On placement → copies to order on confirm  

**Steps (one expanded at a time):**
1. Order placed — external Order ID read-only + copy  
2. Tracking — paste ID · delivery partner · **auto-detect courier** + change dropdown  
3. Out for delivery — last 4 digits of phone · delivery OTP (6+)  
4. Waiting — Mintzer confirms parcel (no upload)  
5. Invoice — locked until admin unlocks · re-upload if rejected + ops reason  
6. Payment — **48h countdown** from invoice upload  
7. Paid → Completed tab  

**Cancel:** until before delivered (includes out for delivery) · **reason required** from preset list  

**Raise ticket (guided):** category → short questions → optional message → ticket ID · track in Profile → My tickets  

**v1:** ticket flow only on order help — **no WhatsApp button** on order detail (admin toggle for future)  

### 6.8 Wallet — **LOCKED**
- **Available** · **Pending** · **Total earned**  
- No withdraw · no add bank  
- Collapsible “How it works”  
- **Transactions** + **Download Excel** + **Date range**  
- Filter chips: All · Paid · Pending · Canceled  
- Tap row → Order detail  
- Spec: [design/WALLET-REQUIREMENTS.md](../design/WALLET-REQUIREMENTS.md)

### 6.9 Profile — **LOCKED**
- Avatar initial · Hi {name} · phone read-only  
- KYC · Payout details · Language EN/HI · **Appearance**  
- My tickets · Help · Tutorials · Notification toggles (master + tiers)  
- Terms · Privacy · **Delete account**  
- Logout (red)  
- **No** Wallet / My Orders shortcuts (use bottom nav)  
- Spec: [design/PROFILE-REQUIREMENTS.md](../design/PROFILE-REQUIREMENTS.md)

### 6.10 My tickets (route 12)
- List newest first · ticket ID · order ref · category · status · date  
- Tap → ticket detail  
- Spec: ORDERS-PAGES-REQUIREMENTS.md

### 6.11 Account suspended — **LOCKED**
- After OTP if `status = suspended` or mid-session 403  
- Copy: account not active · contact support — no harsh “banned” wording  
- Spec: [design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md)

### 6.12 Account deleted — **LOCKED**
- After delete account · back to login  
- Spec: same

### 6.13 ~~Offers~~ — **Retired from nav**
- Deferred · see [screens/08-offers.md](../screens/08-offers.md)

---

## 7. All 11 overlays / gates

| # | Overlay | When |
|---|---------|------|
| 1 | KYC (Name + PAN) | First Accept |
| 2 | Payout (UPI or bank) | After KYC, first Accept |
| 3 | How do you want to shop? | First Place order |
| 4 | Cancel order + reason | Place order / Order detail |
| 5 | **Add note** | Order detail |
| 6 | Finish current order first | Accept blocked |
| 7 | Resume order banner (optional) | App reopen, once/session |
| 8 | Raise ticket | Order detail |
| 9 | Ticket detail | My tickets |
| 10 | Appearance | Profile |
| 11 | Delete account | Profile — block if order in progress |

**Optional v1:** Language picker · Payout edit sheet · My Orders filter sheet · Timer expired state

---

## 8. KYC + payout (LOCKED)

**KYC:** Name · PAN  
**Payout:** UPI (with confirm) **or** Bank (holder name, account, confirm, IFSC)  
**Gate:** both required before first placement  
**Later:** Profile → edit  
**Not on:** Login · Deal detail · Wallet  

Spec: [design/BANK-AND-PAYOUT-DETAILS.md](../design/BANK-AND-PAYOUT-DETAILS.md)

---

## 9. Resume after Accept (LOCKED)

| Surface | Must show |
|---------|-----------|
| Home | Active order strip + countdown + continue |
| My Orders Ongoing | Placement card top + timer + Continue order |
| App reopen | Home + strip; optional once/session banner |
| Deep link | → Place order (not deal detail) |

Timer syncs: list card · order detail · place order · home strip — same `expiresAt`

---

## 10. Notifications (summary)

- Bell on Home · badge count · in-app list  
- Push tiers in Profile: Deal alerts · Order updates · Payment & wallet  
- Quiet hours · frequency caps (config)  
- Push is **supplementary** — user finds active order via Home + My Orders  

Spec: [backend- for developer reference/07-notifications.md](../backend-%20for%20developer%20reference/07-notifications.md)

---

## 11. App config (backend-controlled)

- `placementTimerMinutes` (default 15)  
- `paymentReviewHours` (default 48)  
- `communityWhatsAppUrl` + enable toggle  
- `tutorialVideoUrl`  
- OTP expiry / resend seconds  
- Support WhatsApp / email  

Spec: [backend- for developer reference/08-app-config.md](../backend-%20for%20developer%20reference/08-app-config.md)

---

## 12. Backend business rules (summary)

- One active placement  
- Expired placement → admin log only  
- Duplicate external Order ID → block  
- Invoice gated by `parcelReceived`  
- Money from admin fields — formulas in deals module  
- Placements → orders on confirm  

Modules: [backend- for developer reference/README.md](../backend-%20for%20developer%20reference/README.md)

---

## 13. Design polish notes (from client Figma attempt)

Light Material can feel empty without:
- Real product photos in mocks  
- Filled spend box `#E8F0FE` (not label line only)  
- Card shadows + 12dp padding rhythm  
- Colored bank logo tiles  
- 3+ deals visible in Home frame  

Designer owns visual polish; **layout locked** on Home, Place order, Wallet, Profile.

---

## 14. Out of scope v1 (do not build)

- Admin panel (separate product)  
- Wallet withdraw / transfer to bank from app  
- Offers tab in navigation  
- Instant orders tab  
- In-app WhatsApp chat UI (external links OK)  
- Live courier GPS map  
- OCR from screenshots  
- Tamil / other languages (after Hindi)  
- Referral gamification  
- Profile photo upload  
- iOS-specific variants  

---

## 15. Open / TBD (client or ops to supply later)

| Item | Status |
|------|--------|
| Courier tracking ID patterns per partner | Client samples TBD |
| Exact ticket question sets per category | Ops to define |
| Exact WhatsApp prefill message template | TBD |
| Final Mintzer logo files | Placeholder until delivered |
| Hindi string table | Google Sheet / Figma table needed |
| Promo banner carousel copy | Flexible placeholder OK |

---

## 16. Known doc gaps (fix when editing)

| Topic | Issue |
|-------|--------|
| My Orders search in `06-my-orders.md` | Says “Order ID only” — should match design doc (+ model + tracking) |
| Backend `GET /orders` search param | Should document product name search |
| `MINTZER-UI-DESIGN-BRIEF.md` §2 | Once said “light only” — **THEME doc wins:** light + dark required |
| `07-wallet.md` entry | Says Profile → Wallet — Profile spec says **no** Wallet shortcut (use nav/header) |
| Notes on list card preview | **Not locked** — notes are on Order detail only unless you add list preview |

---

## 17. Implementation status (September 2026)

| Layer | Status |
|-------|--------|
| Screen + design specs | **Done** |
| Backend API specs | **Done** |
| HTML locked references | Home, Place order, full-flow diagram |
| Interactive demo | `assets/mockups/mintzer-app-demo.html` — **partial** → **v2.4 affiliate** adds marketing layer |
| Figma | Client paused — designer handoff ready |
| Flutter / backend code | **Not started** |

---

## 18. Mockup & spec file index

| Need | File |
|------|------|
| **This master log** | `docs/COMPLETE-DECISIONS-LOG.md` |
| Agent process | `docs/AGENT-DEV-PROCESS.md` |
| Designer package | `docs/design/FOR-DESIGNER.md` |
| All screens | `docs/screens/01-login.md` … `11-account-deleted.md` |
| Screen count | `docs/screens/SCREEN-INVENTORY.md` |
| Home LOCKED | `docs/screens/02-home.md` · `assets/mockups/home-samples.html` |
| Place order LOCKED | `docs/design/PLACE-ORDER-REQUIREMENTS.md` · `place-order-locked.html` |
| Orders + notes + search | `docs/design/ORDERS-PAGES-REQUIREMENTS.md` |
| Wallet | `docs/design/WALLET-REQUIREMENTS.md` |
| Profile | `docs/design/PROFILE-REQUIREMENTS.md` |
| KYC + payout | `docs/design/BANK-AND-PAYOUT-DETAILS.md` |
| Account lifecycle | `docs/design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md` |
| Colors / validation | `docs/design/COLORS-AND-TOKENS.md` · `VALIDATION-UX.md` |
| Interactive demo | `assets/mockups/mintzer-app-demo.html` — **v2.4 affiliate** (carousel, badges, referral, rotating success) |
| **Affiliate marketing spec** | `docs/design/AFFILIATE-MARKETING-REQUIREMENTS.md` |
| Affiliate placement mockups | `assets/mockups/card-apply-placements.html` |
| Flow diagram | `assets/mockups/mintzer-full-flow.html` |
| Add note mockup PNG | `assets/mintzer-add-note-mockup.png` |

---

## 19. Client locked decisions (master table)

| # | Decision |
|---|----------|
| 1 | New logo coming — placeholder OK; app blue stays `#1A73E8` |
| 2 | KYC: Name + PAN on first Accept |
| 3 | Login: phone + OTP only |
| 4 | Flow: Home → Deal detail → Accept |
| 5 | One active placement timer |
| 6 | v1: Regular orders only |
| 7 | Wallet: no withdraw |
| 8 | Languages: English + Hindi |
| 9 | Nav: Home · Orders · Wallet · Profile |
| 10 | Home deal card layout LOCKED June 2026 |
| 11 | Place order dock + tap-to-paste LOCKED |
| 12 | Resume via Home strip + My Orders (not notification-only) |
| 13 | My Orders search includes **model name** |
| 14 | User notes on order — 200 chars, save/edit |
| 15 | Duplicate Order ID hard block |
| 16 | Invoice upload after admin parcel received |
| 17 | 48h payment timer after invoice |
| 18 | Cancel with reason presets |
| 19 | Guided support tickets + My tickets list |
| 20 | Delete account blocked if order in progress |
| 21 | Light + dark theme entire app |
| 22 | WhatsApp community on Home header (config URL) |
| 23 | Tutorial banner first visit only |
| 24 | Deal detail Report error = WA prefilled (not ticket wizard) |
| 25 | Order detail Raise ticket = guided flow (not WA v1) |
| 26 | **Affiliate layer:** Mintzer = deals + cards + referral + community — not “order only” |
| 27 | **No 5th nav tab** for cards/Offers — promos on Home carousel + Profile |
| 28 | **Home carousel slide 3:** Partner cards in 118dp banner (blue gradient + card art) |
| 29 | **Home social proof strip** below carousel (admin text) |
| 30 | **Deal badges:** Hot · Trending · slots left — on image bottom-left |
| 31 | **Order success:** ONE rotating marketing template (order more / cards / referral / WA) |
| 32 | **Refer & earn:** Profile banner + menu · ₹200 default · WA share |
| 33 | **Partner cards sheet** — not full catalog screen v1 |
| 34 | **Deferred:** Profile card hero · deal detail as main card funnel |
| 35 | **Demo reference:** `mintzer-app-demo.html` **v2.4 affiliate** |

---

**When in doubt:** open this file → find the screen → open linked spec → for Home/Place order open HTML mockup in Chrome.

**Version:** September 2026
