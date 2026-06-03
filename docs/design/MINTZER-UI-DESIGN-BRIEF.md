# Mintzer Mobile App — UI Design Brief

**Document version:** 1.1  
**Date:** June 2026  
**Platform:** Android (primary), iOS (future)  
**Languages:** English + Hindi (v1)  
**Audience:** UI/UX designer, Figma handoff  
**Product:** Mintzer — earn through card deals (Flipkart, Amazon, etc.)

---

## Table of contents

1. [Product summary](#1-product-summary)
2. [Design principles](#2-design-principles)
3. [Design system](#3-design-system)
4. [User flows](#4-user-flows)
5. [Global components](#5-global-components)
6. [Screen specifications](#6-screen-specifications)
7. [Money display rules](#7-money-display-rules)
8. [Asset & logo guidelines](#8-asset--logo-guidelines)
9. [Notifications & deep links](#9-notifications--deep-links)
10. [States checklist (all screens)](#10-states-checklist-all-screens)
11. [Out of scope for v1 design](#11-out-of-scope-for-v1-design)
12. [Client decisions (locked)](#12-client-decisions-locked)
13. [Localization (English + Hindi)](#13-localization-english--hindi)

---

## 1. Product summary

Mintzer helps users earn money by placing orders on e-commerce sites (Flipkart, etc.) using specific credit cards, delivering to Mintzer-provided addresses, and completing verification steps in the app.

**Core user journey:**

Login (phone) → Browse deals → Read deal detail → Accept deal → Place order on Flipkart within timer → Confirm Order ID → My Orders (tracking → delivery OTP → invoice) → Wallet payment.

**Key product rules for design:**

- Login: phone + OTP only — no profile at signup.
- Flow: **Home → Deal detail → Accept** (Option B — read before commit).
- Only **one active “place order” timer** at a time until Order ID or screenshot submitted.
- Timer duration set by backend (show countdown, not fixed “15 min” in designs).
- User selects **delivery partner** + pastes tracking ID (no live API tracking in v1; courier list from samples/client).
- Invoice upload unlocked only after ops marks parcel received (backend).
- 48-hour payment countdown starts after invoice upload.
- **v1 orders:** Regular only (no Instant tab).
- **KYC:** Name + PAN on **first Accept**; required before first order.
- **Withdraw:** Full flow in v1.
- **Languages:** English + Hindi.

---

## 2. Design principles

| Principle | Direction |
|-----------|-----------|
| Feel | Fluid like RedBus — fast, clear, trustworthy |
| Theme | **Light only** for v1 |
| Colors | **Google Material** — not purple AI gradients, not dark/gold competitor look |
| Density | One primary action per screen; paste-friendly inputs on order steps |
| Trust | Show exact ₹ figures on deal detail — no vague “Earn” without breakdown |
| Logos | Fixed-size containers — never stretched store/bank logos |

---

## 3. Design system

### 3.1 Color palette

| Token | Hex | Usage |
|-------|-----|--------|
| Primary | `#1A73E8` | Buttons, links, active nav, progress |
| Primary dark | `#1557B0` | Button pressed |
| Surface | `#FFFFFF` | Cards, sheets |
| Background | `#F8F9FA` | Screen background |
| Text primary | `#202124` | Headings, amounts |
| Text secondary | `#5F6368` | Captions, hints |
| Earn / success | `#188038` | You earn, commission, checkmarks |
| Warning | `#F9AB00` | Timer low, alerts |
| Error | `#D93025` | Errors, TDS line, cancel confirm |
| Divider | `#E8EAED` | Card borders, lines |
| Active placement strip | `#E8F0FE` bg + `#1A73E8` text | Timer banner on Home |
| Commission bar | `#1A73E8` (primary blue) | My Orders card footer — **locked** (see §12) |

### 3.2 Typography

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| Display / hero ₹ | 28–32sp | Bold | You earn, wallet balance |
| Title | 20–22sp | SemiBold | Screen titles |
| Section label | 12sp | Medium, uppercase optional | YOU PAY, CASHBACK |
| Body | 14–16sp | Regular | Rules, notes |
| Caption | 12sp | Regular | Billing cycle, hints |
| Money row | 16sp | Medium | Line items in money card |
| Button | 16sp | SemiBold | CTAs |

**Font:** Roboto or Google Sans (Material default).

### 3.3 Spacing & shape

- Screen horizontal padding: **16dp**
- Card padding: **16dp**
- Card corner radius: **12dp**
- Button height: **48dp**; corner **24dp** (pill) or **8dp**
- Bottom nav height: **56dp** + safe area
- FAB: **56dp**, bottom-right above nav (**16dp** margin)
- Min tap target: **48×48dp**

### 3.4 Icons

- Material Icons Outlined
- Header: wallet, notifications, share, back, copy, paste
- Nav: home, shopping_bag/orders, percent/offers, person/profile
- Support FAB: chat or WhatsApp-style

### 3.5 Motion

- Screen transitions: **300ms** ease
- Success checkmark: subtle scale-in
- Timer last 2 min: optional gentle pulse on countdown (not flashing red)
- Skeleton loaders on lists — no full-screen spinners

### 3.6 Localization

- **v1 languages:** English (default) + Hindi.
- Design all screens with **~30% longer Hindi strings** in mind (buttons, labels).
- Provide Figma text styles for both; key strings duplicated as component variants or separate frames.
- Language switcher: Profile row **Language** → English | हिंदी (persists in app).
- Numbers and ₹ stay LTR; dates localized later.

---

## 4. User flows

### 4.1 Primary flow

```
Login → Home → Deal detail → Accept deal
  → [External: Flipkart order]
  → Submit Order ID / screenshot
  → Order placed success → My Orders
  → Tracking ID → Out for delivery (last 4 + OTP)
  → [Wait: parcel received — ops]
  → Upload invoice → 48h timer → Wallet credited
```

### 4.2 Placement rules

- User taps **Accept deal** on Deal detail → timer starts on **Accept screen**.
- While timer active: Home shows **active order strip**; other deals **dimmed** — “Finish current order first”.
- **Cancel order** on Accept → frees slot.
- Timer expires without confirm → no My Orders entry; push to re-engage.

### 4.3 Navigation structure

**Bottom tabs (always visible on main app):**

| Tab | Root screen |
|-----|-------------|
| Home | Deal list |
| Orders | My Orders |
| Offers | Promotions |
| Profile | Settings |

**Stack screens (push over tabs):**

Deal detail → Accept → Order success  
KYC sheet (modal)  
Withdraw (future)

---

## 5. Global components

Design these once in Figma as components:

| Component | Variants |
|-----------|----------|
| **Primary button** | Default, disabled, loading |
| **Secondary / outline button** | Cancel, Browse deals |
| **Deal card (Home)** | Default, disabled/blocked |
| **Active placement banner** | With countdown |
| **Logo row** | Store 40×40, Bank 32×32, contain |
| **Money summary card** | Full (deal detail), compact (accept) |
| **Paste text field** | + Paste chip button |
| **Order progress bar** | 6 steps: placed → shipped → OFD → delivered → invoice → payment |
| **Order card** | Collapsed, expanded per step |
| **Countdown timer** | Accept (mm:ss), Payment (hh:mm:ss) |
| **Bottom nav bar** | 4 tabs, active state |
| **Support FAB** | Blue circle, chat icon |
| **Empty state** | Illustration + CTA |
| **Skeleton** | Deal list, order list |
| **Snackbar / toast** | Copied, error, success |
| **Confirm dialog** | Cancel order, Log out |
| **Collapsible section** | Offer details, Links, How wallet calculated |

---

## 6. Screen specifications

---

### PAGE 1 — Login (Phone)

**Purpose:** Enter app with phone only.

**Layout:**

| Zone | Content |
|------|---------|
| Top | Mintzer logo centered |
| Middle | Headline: “Enter mobile number” |
| Input | Country +91 + 10-digit phone field |
| CTA | **Continue** (disabled until 10 digits) |
| Footer | Terms · Privacy links (small) |

**OTP sub-screen (same flow):**

| Zone | Content |
|------|---------|
| Title | “Verify OTP” |
| Subtitle | “Sent to +91 XXXXX X4321” |
| Input | 4–6 OTP boxes |
| Link | Resend OTP (with countdown) |
| CTA | **Verify** |

**Do not include:** Name, email, KYC, referral.

**States:** Invalid phone error, wrong OTP, loading on button.

---

### PAGE 2 — Home

**Purpose:** Browse deals; resume active placement.

**Layout (top → bottom):**

| # | Element |
|---|---------|
| 1 | **Header:** Mintzer logo left · **WhatsApp** + **YouTube** icons · Wallet ₹ · Notifications bell |
| 2 | Search bar: “Search deals…” + filter icon |
| 3 | **Active placement strip** (conditional): “iQOO Z10 — **12:34** left · Tap to continue →” |
| 4 | Promo banner carousel (optional): signup bonus or YouTube — copy flexible; blue/white |
| 5 | **Deal list** (vertical scroll) |
| 6 | Support FAB (bottom right) |
| 7 | Bottom nav — Home selected |

**Deal card (each row):**

| Element | Spec |
|---------|------|
| Product image | Left, ~80dp, fixed frame |
| Title | Product name, 2 lines max |
| Store logo + name | Small Logo row |
| Card chip | “Axis Credit Card” / “Any card” |
| Order price | “₹20,000” |
| Earn | “Earn ₹300” green |
| Button | **Earn ₹300** full width on card OR whole card tappable |

**Blocked deal variant:** 50% opacity + text “Finish current order first”.

**States:** Loading skeleton, empty “No deals”, error + retry.

**Tap:** Card → **Deal detail** (not Accept directly).

---

### PAGE 3 — Deal detail

**Purpose:** Read full deal and money breakdown; tap Accept.

**Layout (scroll + sticky footer):**

| # | Element |
|---|---------|
| Header | Back · “Deal details” · Share (optional) |
| Hero | Product image — fixed frame, contain |
| Meta | Name · Color · Variant · Qty |
| Store row | [Logo 40dp] Flipkart |
| Card row | [Logo 32dp] Card to use · Axis Credit Card |
| **Money summary card** | See [Section 7](#7-money-display-rules) |
| Rules | Up to 3 bullet points (coupon, colour, card warning) |
| Accordion | Offer details (TDS, timing) |
| Accordion | Links — URL + Copy + Open |
| Accordion | How to use — YouTube |
| Sticky footer | **Accept deal** primary button |

**Do not include:** Timer, delivery address, Order ID, Cancel.

**Dialog:** If active placement exists — “Finish current order first” + Go to Accept.

---

### PAGE 4 — Accept / Place order

**Purpose:** Timer running; user orders on Flipkart and confirms.

**Layout:**

| # | Element |
|---|---------|
| Header | Back (warn if leaving) · “Place your order” |
| **Timer** | Large mm:ss — hero; amber when &lt; 2 min |
| Summary | Product name · color · store · card chip |
| Compact money | You pay **₹20,200** · You earn **₹300** |
| Actions | **Copy address** · **Copy pin** (side by side) |
| CTA | **Open Flipkart** (primary outline or filled) |
| Accordion | Offer details (optional) |
| Input | Order ID — wide field + **Paste** chip |
| Upload | **Upload screenshot** secondary |
| Footer | **Submit order** primary |
| Footer | **Cancel order** outline/red — confirm dialog |

**KYC sheet (first Accept only):** Modal on Accept — “Complete KYC to continue” → KYC form (Name + PAN only).

**States:**

| State | Design |
|-------|--------|
| Running | Normal |
| Submitting | Button loading |
| Expired | Full message “Time’s up” + Browse deals |
| Cancelled | Return Home |

**Success navigates to:** Order placed success.

---

### PAGE 5 — Order placed success

**Purpose:** Confirmation moment.

**Layout (centered):**

| Element | Content |
|---------|---------|
| Animation | Green checkmark |
| Title | **Order placed!** |
| Subtitle | “₹300 commission locked” |
| Hint | “Add tracking ID when your order ships” |
| Primary CTA | **Go to My Orders** |
| Secondary | Browse more deals |

No back to Accept. White background, minimal text.

---

### PAGE 6 — My Orders

**Purpose:** Track and complete all orders after Order ID confirmed.

**Layout:**

| # | Element |
|---|---------|
| Header | “My Orders” |
| Search | “Search by Order ID” + calendar icon (optional) |
| Tabs | **Ongoing** · **Completed** only (v1: **Regular orders only** — no Instant tab) |
| List | Order cards |
| FAB | Support |
| Nav | Orders tab active |

**Order card — collapsed:**

| Element | Content |
|---------|---------|
| Header bar | Order ID ORDT86KP80 + copy icon |
| Progress | Horizontal: Placed → Shipped → OFD → Delivered → Invoice → Paid |
| Product | Thumb · name · color · store logo |
| Footer bar | **Blue** bar: Commission ₹300 · **Payout ›** |

**Next action label on card (one line):**  
“Add tracking” / “Enter delivery OTP” / “Waiting for delivery” / “Upload invoice” / “Payment in 36h”

**Order card — expanded (one step active):**

| Step | UI |
|------|-----|
| 1 Placed | ✓ date |
| 2 Tracking | **Delivery partner** dropdown + Tracking ID paste field + **Save** |
| 3 Out for delivery | Last 4 digits field + OTP field (6+) + **Save** |
| 4 Waiting | Grey — “Waiting for delivery confirmation” — no upload |
| 5 Invoice | Green hint when unlocked + **Upload** + **Submit** |
| 6 Payment | **48:00:00 → 0:00:00** countdown + “Payment within 48 hours” |
| 7 Paid | ✓ — move to Completed tab |

**Delivery partner dropdown:** Ekart, Delhivery, Blue Dart, DTDC, India Post, etc. — list from client samples; future: suggest partner from tracking ID pattern (design dropdown + optional helper text).

**Paste-friendly:** Full-width fields, monospace-friendly Order/Tracking IDs.

---

### PAGE 7 — Wallet

**Purpose:** Balance and history.

**Layout:**

| # | Element |
|---|---------|
| Header | “Wallet” · back if from Home |
| Hero card | Available balance **₹X,XXX** large |
| Row | Pending · Confirmed (smaller) |
| List | Transactions — order credits, withdrawals |
| CTA | **Withdraw** (min balance + KYC verified) |
| Note | TDS deducted line |

**Empty:** “Start earning” + link to Home.

**v1:** Full withdraw flow required (see PAGE 12).

---

### PAGE 8 — Offers

**Purpose:** Promotions separate from deal list.

**Layout:**

| Element | Content |
|---------|---------|
| Header | Offers |
| Cards | Signup bonus, referral, seasonal |
| Each card | Title · expiry · T&C · CTA |

Light styling — don’t compete with Home deal cards.

---

### PAGE 9 — Profile

**Purpose:** Account, KYC, support.

**Layout (list rows):**

| Row | Content |
|-----|---------|
| Header | Phone number |
| KYC | Status badge — tap to complete |
| Wallet | Shortcut → |
| My Orders | Shortcut → |
| Support | WhatsApp / email |
| Tutorials | YouTube |
| Notifications | Toggle |
| Terms & Privacy | Links |
| Log out | Red text — confirm dialog |

**KYC sub-screen/sheet:**

| Field | Required |
|-------|----------|
| Name as per PAN | Yes |
| PAN number | Yes |
| Submit | Primary |

Bank/UPI for withdraw collected on **Withdraw screen** (PAGE 12), not on KYC form.

---

### PAGE 10 — KYC required (modal)

**Purpose:** Gate before first order (PerkPay-style timing).

**Layout:** Sheet or centered modal on Accept screen.

| Element | Content |
|---------|---------|
| Icon | Shield |
| Title | Complete verification |
| Body | One-time before your first order |
| CTA | **Complete KYC** |
| Secondary | Cancel |

Light theme — not dark/gold competitor modal.

---

### PAGE 12 — Withdraw

**Purpose:** User moves wallet balance to bank/UPI (v1 full flow).

**Entry:** Wallet → **Withdraw**

| # | Element |
|---|---------|
| Header | Back · “Withdraw” |
| Summary | Available balance · Min withdrawal ₹250 |
| Method | UPI / Bank account (tabs or radio) |
| UPI | UPI ID field |
| Bank | Account number · IFSC · Account holder name |
| Amount | Enter amount (max = available) · Quick chips 100% / 50% |
| Note | Processing time · TDS summary if applicable |
| CTA | **Withdraw** primary |
| Success | “Withdrawal submitted” + reference id |

**Requires:** KYC verified (Name + PAN). Show blocker if not verified → Complete KYC.

**States:** Insufficient balance, below minimum, invalid UPI, loading, success, failed.

---

### PAGE 13 — Language (Profile sub-screen)

| Element | Content |
|---------|---------|
| Title | Language / भाषा |
| Options | English · हिंदी |
| Note | Applies immediately app-wide |

---

### PAGE 14 — Notification states (not full screens)

Design notification **banners** and **push** templates:

| Type | Title example | Tap opens |
|------|---------------|-----------|
| Timer warning | 5 minutes left to place order | Accept |
| Timer expired | Complete your deal — try again | Deal detail |
| Parcel received | Upload your invoice | My Orders order |
| Payment credited | ₹600 added to wallet | Wallet |

---

## 7. Money display rules

### 7.1 Deal detail — Money summary card (required)

Single white card, four sections:

**YOU PAY**

| Line | Example |
|------|---------|
| Order value | ₹20,000 |
| Platform fee | ₹90 ⚠ |
| Card fee | ₹110 ⚠ |
| Discount | − ₹0 |
| **Total checkout** | **₹20,200** |

**CASHBACK (your card)**

| Line | Example |
|------|---------|
| Cashback | ₹1,000 |
| Credited | Next billing cycle |
| Note | Cashback not on platform/card fees |

**FROM MINTZER (wallet)**

| Line | Example |
|------|---------|
| Wallet credit | ₹19,300 |

**YOU EARN**

| Line | Example |
|------|---------|
| Commission | ₹300 |
| TDS | − ₹0 |
| **Final earnings** | **₹300** ← hero green, largest |

**Expand:** How wallet is calculated  
`Order − Cashback − Discount + Commission = Wallet`

**Footer note:**  
“Cashback is credited as per your bank’s billing cycle. Mintzer wallet after order completion.”

### 7.2 Accept screen — compact money

Two lines only:

- You pay **₹20,200**
- You earn **₹300**

### 7.3 Home deal card

- Order ~₹20,000
- **Earn ₹300** green — no full breakdown

### 7.4 Formulas (for designer reference labels)

```
Total checkout     = Order value − Discount + Platform fee + Card fee
Wallet from Mintzer = Order value − Cashback − Discount + Commission
You earn           = Commission − TDS
```

---

## 8. Asset & logo guidelines

### 8.1 Mintzer brand

- **New logo coming** — client will supply updated brand files before final export.
- Design with **placeholder** horizontal logo in header; swap when assets arrive.
- Formats needed: SVG + PNG @1x/@2x/@3x, light background only.
- Primary blue `#1A73E8` — not purple gradient logo treatments.

### 8.2 Store logos (Flipkart, Amazon, etc.)

- Master file: **80×80px @2x** canvas, transparent PNG
- In app: **40×40dp** box, **object-fit: contain**
- Never stretch width independently

### 8.3 Bank / card logos

- Master file: same padding standard as stores
- In app: **32×32dp** box, contain
- Layout: **[logo] Card to use · Axis Credit Card**

### 8.4 Product images

- Variable aspect — container **160×160dp** or 4:3, contain
- Placeholder if missing

### 8.5 Illustrations needed

| Use | Style |
|-----|--------|
| Empty deals | Simple, light |
| Empty orders | Same family |
| Timer expired | Neutral, not scary |
| Success | Checkmark — minimal |

---

## 9. Notifications & deep links

Design in-app notification center (bell) + push lock screen:

- Badge count on bell
- List: title, time, read/unread
- Tap → Accept / Deal detail / My Orders / Wallet

---

## 10. States checklist (all screens)

For each screen, designer delivers:

- [ ] Default
- [ ] Loading / skeleton
- [ ] Empty
- [ ] Error
- [ ] Disabled / blocked (where applicable)
- [ ] Success (where applicable)

**Critical flows to prototype in Figma:**

1. Accept timer running → submit success  
2. Active placement blocks Home deals  
3. My Orders step progression (6 steps)  
4. Invoice locked vs unlocked  
5. 48h payment countdown  

---

## 11. Out of scope for v1 design

- Dark theme
- Live courier API auto-tracking (user selects partner + enters ID manually)
- Admin panel (separate product)
- iOS-specific variants (optional later)
- OCR auto-fill from screenshot
- Instant orders tab
- Tamil / other languages (after Hindi)
- Referral deep gamification

---

## 12. Client decisions (locked)

| # | Decision |
|---|----------|
| 1 | **Logo:** New brand — client will update; use placeholder until files delivered |
| 2 | **KYC fields:** **Name + PAN only** |
| 3 | **KYC timing:** On **first Accept** (before first order) |
| 4 | **Orders v1:** **Regular only** — no Instant tab |
| 5 | **Home header:** **WhatsApp + YouTube** icons — yes (support + tutorials) |
| 6 | **Commission bar:** **Blue `#1A73E8`** — matches Google Material; white text; clearer than orange for v1 rebrand |
| 7 | **Withdraw:** **Full flow in v1** (UPI + bank) |
| 8 | **Signup / promo banner:** Flexible copy — designer can use placeholder |
| 9 | **Languages:** **English + Hindi** in v1 |
| 10 | **Delivery partner:** **Dropdown required** on tracking step; courier list from client samples; auto-detect from tracking ID is a later enhancement |

---

## 13. Localization (English + Hindi)

Design deliverables:

- All user-facing strings in a **Google Sheet or Figma table**: key · English · Hindi.
- Priority screens for Hindi review: Login, Home, Deal detail money card, Accept, My Orders steps, Wallet withdraw.
- **Do not truncate** Hindi button labels — allow two lines on primary CTAs if needed.
- Icon-only where possible (copy, paste, wallet) to reduce translation load.

Sample:

| Key | English | Hindi |
|-----|---------|-------|
| accept_deal | Accept deal | डील स्वीकारें |
| you_earn | You earn | आपकी कमाई |
| withdraw | Withdraw | निकालें |
| delivery_partner | Delivery partner | डिलीवरी पार्टनर |

---

## Appendix A — Screen inventory

| # | Screen | Artboard name |
|---|--------|---------------|
| 1 | Login phone | `01_Login_Phone` |
| 2 | Login OTP | `02_Login_OTP` |
| 3 | Home | `03_Home` |
| 4 | Home blocked deal | `03b_Home_Blocked` |
| 5 | Deal detail | `04_Deal_Detail` |
| 6 | Accept | `05_Accept` |
| 7 | Accept expired | `05b_Accept_Expired` |
| 8 | Accept cancel dialog | `05c_Cancel_Dialog` |
| 9 | KYC modal | `06_KYC_Modal` |
| 10 | Order success | `07_Order_Success` |
| 11 | My Orders list | `08_Orders_List` |
| 12 | Order expanded — each step | `08a–08f_Order_Steps` |
| 13 | Wallet | `09_Wallet` |
| 14 | Offers | `10_Offers` |
| 15 | Profile | `11_Profile` |
| 16 | KYC form | `12_KYC_Form` |
| 17 | Withdraw | `13_Withdraw` |
| 18 | Withdraw success | `13b_Withdraw_Success` |
| 19 | Language | `14_Language` |
| 20 | Components page | `00_Components` |
| 21 | Design tokens page | `00_Tokens` |
| 22 | Hindi sample frames | `00_Hindi_QA` |

---

## Appendix B — Sample copy (deal detail money)

**Rules bullets example:**

- Any colour acceptable  
- Apply coupon ₹500 at checkout  
- Do not use regular SBI card — use SBI Cashback card only  

**Fee warning:**

- Platform fee and card fee are not eligible for cashback.

---

*End of design brief — Mintzer Technologies Pvt Ltd*
