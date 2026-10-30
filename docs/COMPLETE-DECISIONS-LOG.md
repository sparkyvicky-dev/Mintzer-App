# Mintzer â€” Complete decisions log (everything we discussed)

**Phone-friendly A-Z (through Oct 2026):** [APP-A-TO-Z.md](./APP-A-TO-Z.md)

**Purpose:** Single checklist so **nothing is missed** â€” for you, designer, and developers.  
**Last updated:** September 2026  
**Rule:** If this file disagrees with a screen `.md`, **fix the `.md`** â€” this log summarizes all of them.

**Also read:** [AGENT-DEV-PROCESS.md](./AGENT-DEV-PROCESS.md) Â· [FOR-DESIGNER.md](../design/FOR-DESIGNER.md) Â· [SCREEN-INVENTORY.md](../screens/SCREEN-INVENTORY.md)

**UI LOCKED 2026-09-18.** Live demo: `assets/mockups/mintzer-designer-taste-demo.html`. Do not restyle screens without client approval.

---

## 1. What Mintzer is

Android-first Indian fintech app. Users browse Flipkart/Amazon **card deals**, read full money breakdown, **Accept** a deal, place an order on the store within a **timer**, complete tracking â†’ delivery OTP â†’ invoice â†’ **48h payment wait**, earnings show in **Wallet**.

**v1 languages:** English Â· Hindi Â· Kannada Â· Malayalam  
**Later:** Tamil, Telugu, then others.  
**Not a bank.** Wallet = view earnings history. **No withdraw in app.**

---

## 2. Full user journey

```
Login (phone + OTP only)
  â†’ Home (browse deals)
  â†’ Deal detail (read money + rules)
  â†’ Accept deal
  â†’ [First time: KYC PAN â†’ Payout bank + UPI]
  â†’ [First time: How do you want to order? External vs In-app]
  â†’ Place order (timer, copy address, Open store, paste Order ID, Submit)
  â†’ Order placed success
  â†’ My Orders (Ongoing â†’ steps â†’ Completed)
  â†’ Order detail (tracking, OTP, invoice, payment countdown)
  â†’ Wallet (balance + history + Excel export)
  â†’ Profile (settings, tickets, delete account, logout)
```

**Alternate paths:** Account suspended at login Â· Delete account (blocked if order in progress) Â· Account deleted screen

---

## 3. Global rules (never break)

| # | Rule |
|---|------|
| 1 | **Bottom nav:** Home Â· Orders Â· Wallet Â· Profile â€” **no Offers tab** |
| 2 | **Login:** phone + OTP only â€” **no** name, email, KYC, bank at login |
| 3 | **KYC:** PAN only â€” name from Cashfree â€” **first Accept only** |
| 4 | **Payout:** bank (recommended: name, number, IFSC â€” name must match PAN) **and** UPI â€” right after KYC on first Accept; edit in Profile |
| 5 | **Deal flow:** Home â†’ Deal detail â†’ Accept (read before commit â€” Option B) |
| 6 | **One active placement** at a time until Order ID submitted or cancelled/expired |
| 7 | **Timer duration** from backend config â€” not hardcoded in app |
| 8 | **Expired placement** â†’ admin log only â€” **not** a user order in My Orders |
| 9 | **Wallet:** no withdraw, no add bank on Wallet screen |
| 10 | **App primary:** `#7B61FF` â€” live demo. Website mintzer.in stays `#9C71E4`. |
| 11 | **Style:** Google Material 3 Light default + **full dark mode** required |
| 12 | **Not:** orange competitor clone Â· glassmorphism |
| 13 | **v1 orders:** Regular only â€” **no Instant tab** |
| 14 | **No auto courier GPS** â€” user picks partner + pastes tracking ID |
| 15 | **Invoice upload** only after admin marks parcel received |
| 16 | **48h payment countdown** starts at invoice upload â€” **48 working hours**. **No payouts on bank holidays** (RBI calendar). Holiday hours do not count. If the window ends on a holiday, pay the **next working day**. If a transfer fails, retry on the next working day. |
| 17 | **Validation:** field errors **inline** Â· API/copy â†’ **snackbar bottom-right** |
| 18 | **Markdown specs beat PNG mockups** Â· exploration HTML (`home-v2`, `home-v3`, `home-card-variants`) **not** source of truth |

---

## 4. Style & theme

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#7B61FF` | `#B39DFF` |
| Background | `#F8F9FA` | `#121212` |
| Surface / cards | `#FFFFFF` | `#1E1E1E` |
| Text primary | `#202124` | `#E8EAED` |
| Text secondary | `#5F6368` | `#9AA0A6` |
| Earn hero (Deal detail) | `#188038` | `#81C995` |
| Home Earn **button** | `#7B61FF` | same as app primary |
| Spend box | `#EDE7FF` / border `#DDD4FF` | |
| Error | `#D93025` | `#F28B82` |
| GST pill | `#E37400` on `#FEF7E0` | â€” |
| Timer accent | `#E37400` on `#FEF7E0` | â€” |

**Appearance:** Profile â†’ Light Â· Dark Â· System (follow phone)

**Logos:** Fixed box Â· `object-fit: contain` Â· never stretch Â· placeholder until brand files arrive

Detail: [design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md) Â· [design/THEME-LIGHT-DARK-MODE.md](../design/THEME-LIGHT-DARK-MODE.md)

---

## 5. Money formulas

```
totalCheckout      = orderValue âˆ’ discount + platformFee + cardFee
walletFromMintzer  = orderValue âˆ’ cashback âˆ’ discount + commission
youEarn            = commission âˆ’ tds
```

- Bank **cashback** is user's card â€” not paid twice by Mintzer  
- Fees may not be eligible for cashback â€” show in YOU PAY block  
- Admin calculates; app displays exact rupees from API  

---

## 6. All 14 main screens

### 6.1 Login â€” phone + OTP
- +91 Â· 10 digits Â· Continue disabled until valid  
- OTP 4â€“6 digits Â· resend timer  
- Wrong OTP â†’ snackbar Â· invalid phone â†’ inline  
- Success â†’ Home (or **Account suspended** if ops suspended user)  
- **No** KYC / bank / mandatory notification permission  
- Spec: [screens/01-login.md](../screens/01-login.md)

### 6.2 Home â€” **LOCKED layout**
**Reference:** `assets/mockups/home-samples.html` Â· [screens/02-home.md](../screens/02-home.md)

**Chrome:**
- Morning / Hi / Evening, {firstName} Â· Home subtitle templates (action or one idle line per open)  
- Wallet pill â‚¹X â†’ Wallet  
- Bell + notification dot â†’ notification center (design brief)  
- **WhatsApp community** icon (green) â†’ `communityWhatsAppUrl` from config  
- Search â€œSearch dealsâ€¦â€  
- List / Grid toggle â€” persist `homeViewPreference`  
- Chips: **All Deals Â· Direct Â· Link** + filter funnel â†’ **sheet:** store, card, min earn  
- Tutorial banner **first visit only** â€” dismiss â†’ `tutorialSeen` â€” never every session  
- â€œN deals liveâ€ Â· **Highest earn â†“** sort  
- **Active order strip** when placement timer running  
- Support **Help chip** (not a fat round FAB) â†’ topic list + short follow-up + details  
- Bell inbox: **minimal** â€” ticket updates and live actions only Â· **Clear** wipes the list (no archive)  
- Bottom nav  

**Deal card â€” each fact ONCE:**
| On card | Not on Home card |
|---------|------------------|
| Store logo **top-left on image** | Store name text |
| Product image (contain) | Variant, qty |
| Model (bold, max 2 lines) | Payout speed chip |
| Color on meta row left | Duplicate earn/spend |
| GST pill meta row **right** â€” **only if** `gstApplicable` | â€œNo GSTâ€ label |
| Bank row: logo + card name | Order value before fees |
| Spend box `#EDE7FF` â€œYOU SPENDâ€ + â‚¹ | |
| Primary button â€œEarn â‚¹Xâ€ `#7B61FF` | |

**Grid:** 2 columns Â· Earn button pinned bottom Â· title min-height 2 lines  

**States:** loading skeleton Â· empty (**Got a deal we donâ€™t?** â†’ **Send it in** â†’ ops queue) Â· blocked deals dimmed Â· first visit tutorial  

**Rejected (Home):** green Earn button Â· duplicate earn/spend Â· GST on image Â· variant/qty on card Â· Offers tab Â· purple/dark-orange clone UI  

### 6.3 Deal detail
- Product image, name, color, **variant**, **qty**  
- Store + bank **LogoRow** (fixed size, contain)  
- **Money card:** Product value, âˆ’ Discount, Platform fee, Card fee, Cashback, Checkout value, From bank cashback, From Mintzer. Footer: credited per bank statements. 
- Footer: cashback is from the **bank / card rules**. **From Mintzer** is paid to the userâ€™s **account** after the order completes.  
- Optional expand â€œHow wallet is calculatedâ€  
- Collapsible: Offer details Â· Links Â· How to use (YouTube)  
- Header: **LOCKED** â€” one **Report + WhatsApp chip** (cycling `Anything wrong?` / `Wrong info?` / `Price changed?` / `Discount changed?` / `More fee?` / `Out of stock?` / `Wrong product?` / `GST extra?`, tap â†’ prefilled WA). Title left of the chip. No extra bar, no reason chips.  
- Sticky **Swipe to accept** â€” magnetic swipe **LOCKED**. Copy: â€œSwipe to acceptâ€. Not a tap button. Spring-back if they let go early.  
- **No** timer Â· address Â· Order ID on this screen  
- Active placement exists â†’ overlay â€œFinish current order firstâ€  
- Spec: [screens/03-deal-detail.md](../screens/03-deal-detail.md) Â· [design/DEAL-AND-ACCEPT-REQUIREMENTS.md](../design/DEAL-AND-ACCEPT-REQUIREMENTS.md)

### 6.4 Place order â€” **LOCKED v3**
**Reference:** `assets/mockups/place-order-locked.html` Â· [design/PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md)

**Must show:** product model Â· color Â· variant Â· qty Â· store Â· card Â· checkout â‚¹ Â· discount Â· earn Â· timer Â· address Â· actions  

**Address â€” copy per line:** Name Â· Addr1 Â· Addr2 Â· City Â· State Â· Pin Â· Phone â€” **Copy** each Â· optional small â€œCopy allâ€ link Â· **Generate new address** (same pincode, weekly limit)  

**Order ID â€” LOCKED:** **Tap field to paste** from clipboard â€” **no separate Paste button**  

**External mode (default):** scroll Â· Open Flipkart after checkout Â· **2-row bottom dock:** timer row + Order ID + Submit  

**Designer TEST visual â€” LOCKED 2026-09-17** (`mintzer-designer-taste-demo.html`): **You pay \| You earn** split with â†’ flow Â· numbered **steps 1â€“2â€“3** with a connecting line Â· **ring timer** in the dock Â· small **Generate new address** button (no red warning block). Brand-blue mockup `place-order-locked.html` unchanged.  

**In-app mode:** WebView + PerkPay drag-up sheet Â· **3 tabs:** Deal Â· Delivery Â· Help Â· **1-row dock:** timer Â· Order ID Â· Submit  

**Cancel order** on this screen Â· duplicate external Order ID â†’ **hard block**  

**First time:** overlay â€œHow do you want to order?â€ Â· mode chip + Change  

### 6.5 Order placed success
- Short confirmation Â· **Go to My Orders**  
- Spec: [screens/05-order-placed-success.md](../screens/05-order-placed-success.md)

### 6.6 My Orders list
- Tabs: **Ongoing | Completed**  
- **Search:** Order ID Â· Tracking ID Â· **product name / model**  
- **Filter:** Store (All + each store)  
- **Sort:** Newest (default) Â· Oldest Â· **Needs action first**  
- **Badge** on Ongoing = count needing user action  
- Pull to refresh  
- Empty Ongoing â†’ Browse deals  

**Each card:** Mintzer ref + copy Â· one status sentence Â· product Â· store Â· earn Â· timer on placement Â· one primary action when needed  

**Active placement in Ongoing immediately after Accept** (before Order ID) â€” **Continue order**  

**Resume rule â€” LOCKED:** Home strip + My Orders timer â€” **not** notification-only (unlike PerkPay pattern)  

**Completed tab:** Paid + **Canceled** (labeled separately)  

Spec: [screens/06-my-orders.md](../screens/06-my-orders.md) Â· [design/ORDERS-PAGES-REQUIREMENTS.md](../design/ORDERS-PAGES-REQUIREMENTS.md)

### 6.7 Order detail
**Header:** back Â· **Add note** (until paid) Â· **Report issue** Â· **Cancel** (until paid, own button + reason)

**After paid (settled):** read-only IDs Â· note visible if any Â· Report issue only.

**Notes â€” LOCKED:**
- User reminder only (e.g. â€œUsed Rajâ€™s HDFC cardâ€)  
- Order detail header **and** My Orders card if set  
- Modal Â· max **200** chars  
- Blocked after paid  

**Report issue:** Product canceled Â· Paid extra vs app Â· Different color Â· Different variant Â· Other (80 chars). One follow-up question at a time. Ticket detail shows admin updates.

**Cancel:** own button, not inside Report. Reasons: Store canceled Â· Marketplace canceled Â· Price higher than deal Â· Out of stock Â· Changed my mind. Until paid.  

**Steps (one expanded at a time):**
1. Order placed â€” Order ID with Edit until paid  
2. Tracking â€” paste ID Â· **FMPP / FMPC / EK = Ekart** Â· dropdown to change courier  
3. Out for delivery â€” last 4 digits (order phone, **not** delivery person) Â· delivery OTP  
4. Waiting â€” parcel not confirmed yet; Mintzer warehouse confirms delivery (simulate in demo)  
5. Invoice â€” short status only Â· re-upload if rejected  
6. Payment â€” **one cheer per visit** (short, not a rotator) Â· **From Mintzer = Total receive** (never You pay + profit) Â· optional Bank cashback Â· Your earnings Â· Place-order **ring timer on the right** Â· 48 working hours, **no payouts on bank holidays** Â· (updated 12 Oct 2026 after live payout confusion)  
7. Paid â†’ **Completed** Â· receipt: bank name Â· account last4 Â· UTR Â· **Paid on** date only from real `paid_at` (hide if missing; never phone clock) Â· From Mintzer = Total receive Â· Bank cashback when &gt; 0 Â· Your earnings

**Order detail flow line (LOCKED):** continuous rail with step icons. **In progress:** done + current = app purple `#7B61FF` (current node pulses). **Paid:** whole rail green `#188038`. Upcoming = hollow grey. My Orders list: **no** Tracking / Payment / Paid text chips â€” icon rail only. 

**v1:** ticket flow only on order help â€” **no WhatsApp button** on order detail (admin toggle for future)  

### 6.8 Wallet â€” **LOCKED**
- Greeting: **Hi, {first name}**
- **Total earned** = lifetime profit from paid orders (one line: label | amount)
- **Pending** = profit still on unpaid orders (one line: label | amount)
- **No Available** â€” no withdraw in v1, so available is misleading
- No â€œHow it worksâ€ Â· no footer hints
- **Payouts** + **Download Excel** + **Date range**
- Filter chips: All Â· Paid Â· Pending Â· Canceled
- Row: status + amount on one line Â· tap â†’ Order detail
- Spec: [design/WALLET-REQUIREMENTS.md](../design/WALLET-REQUIREMENTS.md)

### 6.9 Profile â€” **LOCKED**
- Avatar: letter **or photo** (tap â†’ Use a photo / Use letter) Â· Hi {name} Â· phone read-only  
- KYC Â· Payout details Â· **Language** (LOCKED **5 EN** bar: EN Â· à¤¹à¤¿ Â· à²•à²¾ Â· à´®à´², whole app) Â· **Appearance**  
- My tickets Â· Help Â· Tutorials Â· Notification toggles (master + tiers)  
- Terms Â· Privacy Â· **Delete account**  
- Logout (red)  
- **No** Wallet / My Orders shortcuts (use bottom nav)  
- Spec: [design/PROFILE-REQUIREMENTS.md](../design/PROFILE-REQUIREMENTS.md)

### 6.10 My tickets (route 12)
- List newest first Â· ticket ID Â· order ref Â· category Â· status Â· date  
- **Tap ticket â†’ detail thread** (you + Mintzer admin updates)  
- Admin reply â†’ **phone tray push** (primary) + **bell notification** (Clear wipes inbox â€” no archive)  
- Tap push â†’ open that ticket chat  
- Status: Submitted Â· In progress Â· Resolved Â· Closed  
- Spec: ORDERS-PAGES-REQUIREMENTS.md
- **Web admin Reply (29 Sep 2026):** `GET tickets/{id}/thread` and `POST tickets/{id}/reply` must stay in live `newapp/routes/web.php`. They were deleted by an older-file upload and restored the same day. Compare-before-replace plus the six fix rules: [LIVE-UPLOAD-RULES.md](./LIVE-UPLOAD-RULES.md).

### 6.10b Push templates â€” **LOCKED 22 Sep 2026**
- Full live inventory + India competitive patterns + V3 default bank  
- Spec: [design/NOTIFICATION-TEMPLATES-LOCKED.md](../design/NOTIFICATION-TEMPLATES-LOCKED.md)  
- Firebase project for Flutter holder push: **`mintzer-e45d6`**  
- Do not invent default push copy in code without updating that doc

### 6.11 Account suspended â€” **LOCKED**
- After OTP if `status = suspended` or mid-session 403  
- Copy: account not active Â· contact support â€” no harsh â€œbannedâ€ wording  
- Spec: [design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md)

### 6.12 Account deleted â€” **LOCKED**
- After delete account Â· back to login  
- Spec: same

### 6.13 ~~Offers~~ â€” **Retired from nav**
- Deferred Â· see [screens/08-offers.md](../screens/08-offers.md)

---

## 7. All 12 overlays / gates

| # | Overlay | When |
|---|---------|------|
| 1 | KYC (PAN â†’ Cashfree name) | First Accept |
| 2 | Payout (bank recommended + UPI) | After KYC, first Accept |
| 3 | How do you want to order? | First Place order |
| 4 | Cancel order + reason | Place order / Order detail |
| 5 | **Add note** | Order detail |
| 6 | Finish current order first | Accept blocked |
| 7 | Resume order banner (optional) | App reopen, once/session |
| 8 | Raise ticket | Order detail |
| 9 | Ticket detail | My tickets |
| 10 | Appearance | Profile |
| 11 | Delete account | Profile â€” block if order in progress |
| 12 | **In-app update sheet** | Play flexible â€” Update / Not now Â· download in app Â· Restart |

**Required v1:** Language picker (English / Hindi / Kannada / Malayalam) Â· Payout edit, My Orders filter sheet Â· Timer expired state Â· **Send a deal you saw** (Home empty / filter-empty)

Users find deals on **other apps, groups, sites**. Submissions go to **`POST /deal-suggestions`** â†’ **admin ops queue**. Ops post a real deal or dismiss. User gets a snackbar only â€” not a ticket.

---

## 8. KYC + payout (LOCKED)

**KYC:** PAN (user) Â· Name from Cashfree Â· status: **PAN found. Weâ€™re verifying your details.**  
**Payout:** Bank recommended (Account name = PAN name, Account number, IFSC) **and** UPI (optional on same sheet)  
**Gate:** both required before first placement  
**Later:** Profile â†’ edit  
**Not on:** Login Â· Deal detail Â· Wallet  

Spec: [design/BANK-AND-PAYOUT-DETAILS.md](../design/BANK-AND-PAYOUT-DETAILS.md)

---

## 9. Resume after Accept (LOCKED)

| Surface | Must show |
|---------|-----------|
| Home | Active order strip + countdown + continue |
| My Orders Ongoing | Placement card top + timer + Continue order |
| App reopen | Home + strip; optional once/session banner |
| Deep link | â†’ Place order (not deal detail) |

Timer syncs: list card Â· order detail Â· place order Â· home strip â€” same `expiresAt`

---

## 10. Notifications (summary)

- Bell on Home Â· badge count Â· in-app list  
- Push tiers in Profile: Deal alerts Â· Order updates Â· Payment & wallet  
- Quiet hours Â· frequency caps (config)  
- Push is **supplementary** â€” user finds active order via Home + My Orders  

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
- Expired placement â†’ admin log only  
- Duplicate external Order ID â†’ block  
- Invoice gated by `parcelReceived`  
- Money from admin fields â€” formulas in deals module  
- Placements â†’ orders on confirm  

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

- Admin panel (separate product â€” `D:\dev\Mintzer-admin-app`)  
- Wallet withdraw / transfer to bank from app  
- Offers tab in navigation  
- Instant orders tab  
- In-app WhatsApp chat UI (external links OK)  
- Live courier GPS map  
- OCR from screenshots  
- Tamil / Telugu / other languages (after EN Â· HI Â· KN Â· ML)  
- Referral gamification  
- iOS-specific variants  

---

## 15. Open / TBD (client or ops to supply later)

| Item | Status |
|------|--------|
| Courier tracking ID patterns per partner | Client samples TBD |
| Exact ticket question sets per category | Ops to define |
| Exact WhatsApp prefill message template | TBD |
| Final Mintzer logo files | Placeholder until delivered |
| Hindi / Kannada / Malayalam string table | Live demo: `assets/mockups/mintzer-i18n.js` |
| Promo banner carousel copy | Flexible placeholder OK |
| Official store/bank logo files | Letter tiles until admin uploads `logoUrl` |

---

## 16. Known doc gaps (fix when editing)

| Topic | Issue |
|-------|--------|
| My Orders search in `06-my-orders.md` | Says â€œOrder ID onlyâ€ â€” should match design doc (+ model + tracking) |
| Backend `GET /orders` search param | Should document product name search |
| `MINTZER-UI-DESIGN-BRIEF.md` Â§2 | Once said â€œlight onlyâ€ â€” **THEME doc wins:** light + dark required |
| `07-wallet.md` entry | Says Profile â†’ Wallet â€” Profile spec says **no** Wallet shortcut (use nav/header) |
| Notes on list card preview | **Not locked** â€” notes are on Order detail only unless you add list preview |

---

## 17. Implementation status (September 2026)

| Layer | Status |
|-------|--------|
| Screen + design specs | **Done** |
| Backend API specs | **Done** |
| HTML locked references | Home, Place order, full-flow diagram |
| Interactive demo | `assets/mockups/mintzer-app-demo.html` â€” **partial** â†’ **v2.4 affiliate** adds marketing layer |
| Figma | Optional polish â€” designer handoff ready |
| Flutter user app | **Not started** â€” next |
| Live holder backend | **`newapp` already running** â€” map orders, donâ€™t replace first |

---

## 18. Mockup & spec file index

| Need | File |
|------|------|
| **This master log** | `docs/COMPLETE-DECISIONS-LOG.md` |
| Agent process | `docs/AGENT-DEV-PROCESS.md` |
| Designer package | `docs/design/FOR-DESIGNER.md` |
| All screens | `docs/screens/01-login.md` â€¦ `11-account-deleted.md` |
| Screen count | `docs/screens/SCREEN-INVENTORY.md` |
| Home LOCKED | `docs/screens/02-home.md` Â· `assets/mockups/home-samples.html` |
| **Live demo UI LOCKED 2026-09-18** | `assets/mockups/mintzer-designer-taste-demo.html` |
| **Live Play orders â†’ new UI** | `docs/backend- for developer reference/11-live-order-migration.md` |
| Place order LOCKED | `docs/design/PLACE-ORDER-REQUIREMENTS.md` Â· `place-order-locked.html` |
| Orders + notes + search | `docs/design/ORDERS-PAGES-REQUIREMENTS.md` |
| Wallet | `docs/design/WALLET-REQUIREMENTS.md` |
| Profile | `docs/design/PROFILE-REQUIREMENTS.md` |
| KYC + payout | `docs/design/BANK-AND-PAYOUT-DETAILS.md` |
| Account lifecycle | `docs/design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md` |
| Colors / validation | `docs/design/COLORS-AND-TOKENS.md` Â· `VALIDATION-UX.md` |
| Interactive demo | `assets/mockups/mintzer-app-demo.html` â€” **v2.4 affiliate** (carousel, badges, referral, rotating success) |
| **Stores & cards catalog** | [backend- for developer reference/10-stores-and-cards.md](./backend-%20for%20developer%20reference/10-stores-and-cards.md) |
| **Affiliate marketing spec** | `docs/design/AFFILIATE-MARKETING-REQUIREMENTS.md` |
| Affiliate placement mockups | `assets/mockups/card-apply-placements.html` |
| Flow diagram | `assets/mockups/mintzer-full-flow.html` |
| Add note mockup PNG | `assets/mintzer-add-note-mockup.png` |

---

## 19. Client locked decisions (master table)

| # | Decision |
|---|----------|
| 1 | App primary `#7B61FF` (live demo). Website purple `#9C71E4` is mintzer.in only. |
| 2 | KYC: PAN on first Accept; name from Cashfree |
| 3 | Login: phone + OTP only |
| 4 | Flow: Home â†’ Deal detail â†’ Accept |
| 5 | One active placement timer |
| 6 | v1: Regular orders only |
| 7 | Wallet: no withdraw |
| 8 | Languages: English Â· Hindi Â· Kannada Â· Malayalam |
| 9 | Nav: Home Â· Orders Â· Wallet Â· Profile |
| 10 | Home deal card layout LOCKED June 2026 |
| 11 | Place order dock + tap-to-paste LOCKED |
| 12 | Resume via Home strip + My Orders (not notification-only) |
| 13 | My Orders search includes **model name** |
| 14 | User notes on order â€” 200 chars, save/edit |
| 15 | Duplicate Order ID hard block |
| 16 | Invoice upload after admin parcel received |
| 17 | 48h payment timer after invoice â€” **working hours**, no payouts on bank holidays |
| 18 | Cancel with reason presets |
| 19 | Guided support tickets + My tickets list |
| 20 | Delete account blocked if order in progress |
| 21 | Light + dark theme entire app |
| 22 | WhatsApp community on Home header (config URL) |
| 23 | Tutorial banner first visit only |
| 24 | Deal detail Report + WA = **one locked chip** (8 short lines rotate, tap prefilled WA; no flip bar) |
| 24b | Deal detail Accept = magnetic **Swipe to accept** (not tap, not â€œlockâ€) |
| 25 | Order detail Raise ticket = guided flow (not WA v1) |
| 26 | **Affiliate layer:** Mintzer = deals + cards + referral + community â€” not â€œorder onlyâ€ |
| 27 | **No 5th nav tab** for cards/Offers â€” promos on Home carousel + Profile |
| 28 | **Home carousel slide 3:** Partner cards in 118dp banner (blue gradient + card art) |
| 29 | **Home social proof strip** below carousel (admin text) |
| 30 | **Deal badges:** Hot Â· Trending Â· slots left â€” on image bottom-left |
| 31 | **Order success:** ONE rotating marketing template (order more / cards / referral / WA) |
| 32 | **Refer & earn:** Profile banner + menu Â· â‚¹200 default Â· WA share |
| 33 | **Partner cards sheet** â€” not full catalog screen v1 |
| 34 | **Deferred:** Profile card hero Â· deal detail as main card funnel |
| 35 | **Demo reference:** `mintzer-app-demo.html` **v2.4 affiliate** |
| 36 | **In-app update (v1):** Play **flexible** sheet â€” Update / Not now; keep using app while download; Restart. Not force-block. Not silent OTA. |
| 36 | **Store + card masters** live in admin (`D:\dev\Mintzer-admin-app`). User app reads API. Seed list: [10-stores-and-cards.md](./backend-%20for%20developer%20reference/10-stores-and-cards.md). Missing logos = Mintzer letter tiles. |
| 37 | **Empty Home hook:** users send deals they saw elsewhere (WhatsApp / Telegram / other app / website) to **Mintzer ops**. Not a public post. Designer PNGs: `assets/mockups/designer-empty-home.png` Â· `designer-suggest-deal.png`. |
| 38 | **Language picker LOCKED 5 EN** bar: `EN` Â· `à¤¹à¤¿` Â· `à²•à²¾` Â· `à´®à´²` â€” Login + Profile. Same control. |
| 39 | **Profile photo:** optional. Tap avatar â†’ Use a photo / Use letter. |
| 40 | **Payout cheer:** one line **per visit** (not a timer rotator). 1st cheer Â· 2nd light Â· 3rd short funny Â· later calm. Copy in `mintzer-i18n.js` `cheer1â€“4`. |
| 41 | **Order detail flow line LOCKED:** in-progress purple (`#7B61FF`) + pulsing current; paid = green (`#188038`). Live demo. |
| 51 | **My Orders list:** no Tracking / Payment / Paid chips. **Home product name:** 1 line ellipsis (color still under it). |
| 52 | **Deal detail report chip:** 8 rotating lines â€” Anything wrong? Â· Wrong info? Â· Price changed? Â· Discount changed? Â· More fee? Â· Out of stock? Â· Wrong product? Â· GST extra? Same WA chip. |
| 42 | **No payouts on bank holidays.** 48 **working hours**. Next working day if the window lands on a holiday. |
| 43 | **Play update = same `orders` rows.** Package **`com.mintzer`**. Mapper: [backend- for developer reference/11-live-order-migration.md](./backend-%20for%20developer%20reference/11-live-order-migration.md). Do not ship the HTML demo. Legacy: invoice after OTP (no extra Confirmation). Pine Lab kept. API additive. |
| 44 | **Home subtitle â€œEarn with your cardâ€** = lilac `#DDD4FF` on **held** `#7B61FF`. Do not use 88% white on a wash that already faded to pale â€” screenshots clip that to a bright smear; on a real screen it only looked slightly there. |
| 45 | **Home greeting templates.** Name line = time of day (Morning / Hi / Evening). Subtitle = action if needed (timer / order), else **one idle line per app open** (`home_sub1â€“4`). Same rule as payout cheers: never rotate on a timer. |
| 46 | **Home spend** is `card Â· â‚¹amount` in the caption (style B). No â€œYOU SPENDâ€ box on Home. Deal detail still shows full checkout. |
| 50 | **Home deal card style B LOCKED 18 Sep 2026.** Grey fade on photo (name + color). Caption bank + pinned â‚¹. Earn button. One urgency chip per deal, free corner. BOB Credit Card Â· Amex. HDFC crop = full square. Imagine store mapped. Live demo in Brave. |
| 48 | **Legacy Play users: no merge, no force KYC.** Same phone = same user. Old app had no PAN; they still keep using Home/Orders. PAN = usual first **new** Accept. Do not freeze old payouts if bank already exists. |
| 49 | **Handoff:** [STATUS.md](./STATUS.md) â€” locked UI, crash rules, TODO. Morning read. |
| 53 | **Deal detail Flutter LOCKED 20 Sep 2026:** Payment summary + TDS Â· instructions Â· Before you order Â· centered swipe Â· sublabel *Reserve this deal and start earning*. |
| 54 | **First Accept KYC + Payout LOCKED 20 Sep 2026:** Step 1/2 PAN â†’ Step 2/2 Payout account (IFSC lookup, no bank dropdown, UPI collapsed). [BANK-AND-PAYOUT-DETAILS.md](./design/BANK-AND-PAYOUT-DETAILS.md). |
| 55 | **GST deals LOCKED 20 Sep 2026:** Teal Deal-detail strip Â· Accept modal 1Â·2Â·3 points to **delivery address section** (never Mintzer/personal GST language Â· no GSTIN dump in modal) Â· Invoice step GST checklist. [GST-DEAL-REQUIREMENTS.md](./design/GST-DEAL-REQUIREMENTS.md). |
| 56 | **Home Active order strip LOCKED 20 Sep 2026:** green card Â· live countdown Â· Continue â†’ Â· &lt;5 min amber. Shared placement timer. |
| 57 | **Place order polish 20 Sep 2026:** sticky Reserved timer Â· checklist Â· Open primary Â· Copy all Â· quiet Change address Â· GST for payout Â· dock ring kept. Skipped: lock Step 3 until Open. |
| 58 | **Place order LOCKED night 20 Sep 2026:** No auto âœ“ on step rail Â· restored pay/earn + logo size Â· Change address = quiet text (not purple bar) Â· Company+GSTIN visible on GST Â· Instructions title kept. |

---

**When in doubt:** open this file â†’ find the screen â†’ open linked spec â†’ for Home/Place order open HTML mockup in **Brave**.

**Version:** September 2026
