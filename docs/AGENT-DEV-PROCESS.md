# Mintzer — App development process (for agents)

**Audience:** Cursor agents, developers, and anyone picking up this project cold.  
**Project root:** `D:\dev\mintzer-app`  
**Last updated:** 11 Oct 2026  
**Morning file:** [STATUS.md](./STATUS.md)

---

## 1. Project summary

Mintzer helps users **earn money** by placing e-commerce orders (Flipkart, Amazon, etc.) with specific credit cards, shipping to Mintzer-provided addresses, and completing verification steps in the app.

**Core journey:**

```
Login (phone + OTP)
  → Home (browse deals)
  → Deal detail (read fees + earn)
  → Accept deal
  → [First time: KYC + payout details]
  → Place order (timer — paste Order ID)
  → Order success
  → My Orders (tracking → delivery OTP → invoice → 48h payment wait)
  → Wallet (view earnings — no withdraw in v1)
```

**Platform:** Android-first · **Flutter + Material 3** recommended · English · Hindi · Kannada · Malayalam (v1)

---

## 2. What exists in this repo today

| Layer | Status | Location |
|-------|--------|----------|
| Product / screen specs | Complete | `docs/screens/` |
| Design requirements (locked rules) | Complete | `docs/design/` |
| Backend API & business logic specs | Complete | `docs/backend- for developer reference/` |
| HTML mockups (**open live demo in Brave**) | Complete | `assets/mockups/` · `scripts/open-live-demo.ps1` |
| PNG reference images | Reference only | `assets/mintzer-*.png` |
| Logo placeholders | SVG | `assets/logos/` |
| PDF/HTML generator script | Utility | `scripts/md-to-print-html.js` |
| **Live holder backend** | **Exists** — Laravel `newapp` / Play `com.mintzer` | [11-live-order-migration.md](backend-%20for%20developer%20reference/11-live-order-migration.md) |
| **User app (Flutter)** | **Play client** — `app/` package `com.mintzer`, version in `pubspec.yaml`. File map: [frontend/03-flutter-app-map.md](./frontend/03-flutter-app-map.md) | [STATUS.md](./STATUS.md) |
| **Figma file** | External / optional polish | Match locked live demo |

**Live orders already live in `newapp` — map them, do not rebuild a second history.** Play update must not crash: [STATUS.md](./STATUS.md) §2.

---

## 3. Development phases (order)

### Phase A — UI design (current client priority)

**Goal:** Professional Figma for all 14 routes + 11 overlays, light + dark.

| Step | Action | Reference |
|------|--------|-----------|
| A1 | Designer reads `docs/design/FOR-DESIGNER.md` | Start here |
| A2 | Match locked Home | `assets/mockups/home-samples.html`, `docs/screens/02-home.md` |
| A3 | Match locked Place order | `assets/mockups/place-order-locked.html`, `docs/design/PLACE-ORDER-REQUIREMENTS.md` |
| A4 | Remaining screens per `docs/screens/*.md` | **Locked live demo** `assets/mockups/mintzer-designer-taste-demo.html` (2026-09-18) |
| A5 | Deliver design system + component library | `docs/design/COLORS-AND-TOKENS.md` |

**Client note:** DIY ChatGPT→Figma was tried; layout OK but needed visual polish (real photos, shadows, spacing). Professional designer recommended.

---

### Phase B — Frontend app (mock data first)

**Goal:** Runnable app through full user journey **without a server**.

| Step | Action | Reference |
|------|--------|-----------|
| B1 | Scaffold Flutter (or Expo) + Material theme light/dark | `docs/frontend/README.md` |
| B2 | App shell: bottom nav + routing + FAB | Phase 1 in checklist |
| B3 | Build screens in order below | `docs/frontend/01-implementation-checklist.md` |
| B4 | Shared components once, reuse everywhere | Component table in frontend README |
| B5 | Mock JSON for 2–3 deals, 1 active placement, sample orders | Inline in frontend README |

**Build order (mandatory):**

1. Shell + theme  
2. Login (fake OTP — any code works)  
3. Home (**LOCKED** layout)  
4. Deal detail + money card  
5. Place order (external + in-app layouts)  
6. Order success  
7. My Orders list + Order detail timeline  
8. Wallet (**no withdraw**)  
9. Profile + overlays (KYC, payout, delete account, etc.)  
10. Account suspended / deleted pages  

**Phase B deliverable:** User can tap Login → Home → Deal detail → Place order → Submit → Success → My Orders **entirely offline**.

---

### Phase C — Backend API

**Goal:** First ship talks to **live `newapp`**, not a greenfield server. Mapper: `11-live-order-migration.md`.

| Step | Action | Reference |
|------|--------|-----------|
| C0 | Map live `orders` columns → new 7-step UI | `11-live-order-migration.md` |
| C1 | Read backend module index | `docs/backend- for developer reference/README.md` |
| C2 | Implement auth (OTP) — wrap live `sendotp` / `verify-otp` | `02-auth.md` |
| C3 | Deals list + pricing formulas | `01-deals-and-pricing.md` |
| C3b | Store & card masters (API + admin CRUD) | `10-stores-and-cards.md` · admin app |
| C3c | User deal suggestions → ops queue | `06-admin-operations.md` (`POST /deal-suggestions`) |
| C4 | Placements (live: `orders` with no store id) | `03-placements.md` |
| C5 | Orders lifecycle | `04-orders.md` |
| C6 | Wallet + payouts (ledger, no user withdraw) | `05-wallet-and-payouts.md` |
| C7 | App config (WhatsApp URL, tutorial, timer duration) | `08-app-config.md` |
| C8 | Notifications, support tickets, admin | `07`, `09`, `06` |

**Critical backend rules:**

- **One active placement** — user cannot accept new deal until Order ID submitted or placement expires/cancelled.
- **Timer duration** — from admin config, not hardcoded in app.
- **Expired placement** — admin log only, not a user order.
- **Invoice upload** — **new** orders: unlocked when admin marks parcel received. **Live Play rows:** unlocked after OTP (legacy).
- **Money** — computed from admin fields; formulas in `01-deals-and-pricing.md`.
- **Play package** — `com.mintzer`. Additive APIs only.

---

### Phase D — Integration

**Goal:** Replace mock services with real API calls.

| Step | Action |
|------|--------|
| D1 | Define API client layer (one interface per domain) |
| D2 | Swap mock deal/placement/order services |
| D3 | Wire auth token + session refresh |
| D4 | Error handling per `docs/design/VALIDATION-UX.md` |
| D5 | E2E test critical flows (accept blocked, timer, invoice lock) |

---

## 4. Source of truth hierarchy

When documents conflict, follow this order:

1. **Screen markdown** — `docs/screens/XX-name.md`  
2. **Design requirement docs** — `docs/design/*-REQUIREMENTS.md`  
3. **Locked HTML mockups** — `home-samples.html`, `place-order-locked.html`  
4. **Backend specs** — for API fields and business logic  
5. **PNG mockups** — `assets/mintzer-*.png` (visual hint only)  
6. **Exploration HTML** — `home-v2.html`, `home-v3.html`, `home-card-variants.html` (**ignore for implementation**)

---

## 5. Screen inventory (development count)

**14 main routes + 11 overlays + 2 Place order layouts ≈ 25 UI surfaces**

Full table: [screens/SCREEN-INVENTORY.md](./screens/SCREEN-INVENTORY.md)

### LOCKED layouts (do not change without client sign-off)

| Screen | Spec | Reference |
|--------|------|-----------|
| Home | `screens/02-home.md` | `assets/mockups/home-samples.html` |
| Deal detail header (report chip) | `screens/03-deal-detail.md` §4 | Combined WA + cycling copy, top-right |
| Deal detail Accept CTA | `screens/03-deal-detail.md` | Magnetic **Swipe to accept** |
| Place order | `design/PLACE-ORDER-REQUIREMENTS.md` | `assets/mockups/place-order-locked.html` (blue) · TEST visual `mintzer-designer-taste-demo.html` |
| Wallet | `design/WALLET-REQUIREMENTS.md` | No withdraw |
| Profile | `design/PROFILE-REQUIREMENTS.md` | Nav shortcuts not duplicated here |
| Account suspended / deleted | `design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md` | Copy locked |
| KYC + payout | `design/BANK-AND-PAYOUT-DETAILS.md` | PAN only; name from Cashfree |

### Bottom navigation (LOCKED)

**Home · Orders · Wallet · Profile** — no Offers tab.

---

## 6. Home deal card (LOCKED — agents must know this)

Each fact shown **once** on the card:

| Field | Rule |
|-------|------|
| Store logo | Top-left circle on product image |
| Product image | Fixed box, object-fit contain |
| Model + color | **Grey overlay on the photo** (name, then color) |
| GST | Pill on image **top-right**, only if `gstApplicable` — never “No GST” |
| Bank + spend | Caption `card · ₹amount` — **no YOU SPEND box** |
| Earn | Primary button `#7B61FF` — “Earn ₹X” |

**Not on Home:** variant, qty, payout chip, duplicate earn/spend, store name text.

---

## 7. Design system (implementation)

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#7B61FF` | `#B39DFF` |
| Background | `#F8F9FA` | `#121212` |
| Surface / cards | `#FFFFFF` | `#1E1E1E` |
| Text primary | `#202124` | `#E8EAED` |
| Text secondary | `#5F6368` | `#9AA0A6` |
| Earn (Deal detail hero) | `#188038` | `#81C995` |
| Error | `#D93025` | `#F28B82` |
| Border | `#E8EAED` | `#3C4043` |
| Spend box bg | `#E8F0FE` | map in THEME doc |

Full list: [design/COLORS-AND-TOKENS.md](./design/COLORS-AND-TOKENS.md)  
Dark mode rules: [design/THEME-LIGHT-DARK-MODE.md](./design/THEME-LIGHT-DARK-MODE.md)

**Validation UX (all screens):**

- Field errors → red text under field + red border  
- API / network / toast → snackbar bottom-right (`#323232` bg, white text)  
- Full rules: [design/VALIDATION-UX.md](./design/VALIDATION-UX.md)

---

## 8. Shared frontend components (build once)

From `docs/frontend/README.md`:

| Component | Used on |
|-----------|---------|
| `DealCard` | Home (list + grid) |
| `LogoRow` | Deal detail, cards — fixed size, contain |
| `MoneySummaryCard` | Deal detail |
| `PrimaryButton` / `OutlineButton` | Global |
| `PasteTextField` | Place order — tap to paste, no Paste button |
| `OrderProgressBar` | My Orders |
| `CountdownTimer` | Place order, payment 48h |
| `ActivePlacementBanner` | Home |
| `BottomSheetTabs` | Place order in-app mode |

---

## 9. Agent reading order (first session)

Read in this order — ~30–45 minutes:

| # | File | Why |
|---|------|-----|
| 1 | `AGENTS.md` | Short rules |
| 2 | This file | Full process |
| 3 | `docs/screens/SCREEN-INVENTORY.md` | What to build |
| 4 | `docs/screens/02-home.md` | Most locked screen |
| 5 | `assets/mockups/home-samples.html` + locked live demo | Open in **Brave** |
| 6 | `docs/frontend/README.md` | How to build app |
| 7 | `docs/design/FOR-DESIGNER.md` | Design context |
| 8 | Task-specific screen `.md` | When implementing that screen |
| 9 | `docs/research/AGENT-PIEPAY-AND-PAY-EARN-HANDOFF.md` | Only if building **Pay & earn** (future — not v1) |

---

## 10. Common agent tasks

### “Implement Home screen”

1. Read `docs/screens/02-home.md`  
2. Open `assets/mockups/home-samples.html`  
3. Follow `docs/frontend/01-implementation-checklist.md` Phase 3  
4. Use mock deal JSON with fields from backend `01-deals-and-pricing.md` list API  
5. Do not add fields not in spec  

### “Write backend for deals”

1. Read `docs/backend- for developer reference/01-deals-and-pricing.md`  
2. Implement formulas exactly — no manual mismatch between admin fields  
3. Expose `gstApplicable`, `dealType`, `totalCheckout`, `youEarn` on list API  

### “Update design docs”

1. Check if screen is LOCKED — if yes, ask user before changing layout  
2. Update screen `.md` first, then design requirement doc, then HTML mockup if locked  
3. Update `FOR-DESIGNER.md` if client-facing rules change  

### “Fix a bug without creating another”

Follow the six rules in [LIVE-UPLOAD-RULES.md](./LIVE-UPLOAD-RULES.md) and `.cursor/rules/one-bug-no-second-bug.mdc`:

1. Start from the live file. Add only the lines for this bug.
2. One bug, one edit. Leave every other function and screen as it was.
3. Upload only the files that contain that fix.
4. If the server copy is ahead, leave it there.
5. Use the broken action and the action beside it.
6. Do not delete a route, method, column, or button because it looks unused.

### “Replace any file on Hostinger”

1. Read [LIVE-UPLOAD-RULES.md](./LIVE-UPLOAD-RULES.md). Every path that already exists on the server: download, compare, merge, upload, download again. New paths have nothing to compare.
2. Do this for each file in an upload script, not only `web.php` or controllers.
3. Apply the six rules above. Do not replace live `DealsController.php` until it contains `sendDealStockAlert` and `pushDealBlast`.

### “Help client with Figma”

1. Point to `docs/design/FOR-DESIGNER.md`  
2. Use `docs/design/FIGMA-CHATGPT-PROMPT-RULES.md` + screen-specific prompt files  
3. Remind: polish pass needed after AI generation (photos, shadows, spend box fill)  

### “Build for Play / testers”

1. Follow `.cursor/rules/play-release-aab.mdc`.
2. Bump `app/pubspec.yaml` and `AppConfig.versionLabel` together.
3. Build **AAB** (`flutter build appbundle --release`) → `D:\dev\mintzer-app\Mintzer-{version}.aab` — this is the Play Console file.
4. Also build **APK** for sideload checks only.
5. Record both SHA-256 hashes and the change list in [STATUS.md](./STATUS.md).
6. Default track: **Internal testing**. Do not push Production unless the owner says so.
7. Money-field questions: label them **App** or **Admin panel** (`.cursor/rules/deal-money-fields.mdc`).

---

## 11. Out of scope for v1

Do not design or implement unless user explicitly expands scope:

- Admin panel (separate product)  
- Wallet withdraw / bank transfer from app  
- Offers tab in navigation  
- Instant orders tab  
- In-app WhatsApp chat (external link only)  
- Live courier GPS tracking  
- OCR from order screenshots  
- iOS-specific variants  

---

## 12. Repo folder map

```
D:\dev\mintzer-app\
├── AGENTS.md                 ← agents: read first (short)
├── README.md                 ← client: what to do when back from trip
├── assets/
│   ├── mockups/              ← HTML references (open live demo in Brave)
│   ├── logos/                ← SVG placeholders
│   └── mintzer-*.png         ← reference screenshots
├── docs/
│   ├── AGENT-DEV-PROCESS.md  ← this file
│   ├── screens/              ← per-screen specs (source of truth)
│   ├── design/               ← design rules + designer handoff
│   ├── frontend/             ← build order + checklist
│   ├── research/             ← PiePay checkout + Pay & earn handoff (future)
│   └── backend- for developer reference/
└── scripts/
    └── md-to-print-html.js   ← generate printable HTML/PDF
```

---

## 13. Client locked decisions (do not revert)

| Decision | Rule |
|----------|------|
| Login | Phone + OTP only |
| Deal flow | Home → Deal detail → Accept (read before commit) |
| KYC | PAN on first Accept only; name from Cashfree (verification in process) |
| One timer | One active placement until Order ID or expiry |
| Wallet | View + export — **no withdraw** |
| Nav | Home · Orders · Wallet · Profile |
| Primary color | `#7B61FF` — live demo; website may stay `#9C71E4` |
| Home card | Layout locked June 2026 |
| Place order | Tap-to-paste Order ID, no separate Paste button |
| Languages | English · Hindi · Kannada · Malayalam |

---

## 14. Questions for the user (ask only when blocked)

When asking about deal money or timers, say **App** or **Admin panel** in the question — not abstract API jargon.

- Flutter vs React Native — if scaffold not chosen  
- Figma link — when integrating design tokens  
- Backend stack — when starting Phase C  
- Changing a **LOCKED** screen layout  

Do **not** ask about: Offers tab, withdraw, KYC at login, purple theme — these are decided.

---

## 15. Future: Pay & earn (PiePay-style — not v1)

Owner research (Aug 2026): two-sided checkout (buyer shops → holder pays on buyer session). **Do not implement in v1** unless owner explicitly expands scope.

| Doc | Use |
|-----|-----|
| [research/AGENT-PIEPAY-AND-PAY-EARN-HANDOFF.md](./research/AGENT-PIEPAY-AND-PAY-EARN-HANDOFF.md) | Full competitor + technical handoff |
| [research/MINTZER-PAY-EARN-ROADMAP.md](./research/MINTZER-PAY-EARN-ROADMAP.md) | Phased build after v1 holder app |
| [research/PIEPAY-CHECKOUT-KNOWLEDGE.md](./research/PIEPAY-CHECKOUT-KNOWLEDGE.md) | Short flow summary |

---

**Version:** August 2026 · Mintzer rebuild v1 (+ Pay & earn research doc'd)
