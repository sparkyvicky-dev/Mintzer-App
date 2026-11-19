# Mintzer — Agent instructions

**Project path:** `D:\dev\mintzer-app`  
**Read first:** [docs/STATUS.md](docs/STATUS.md) (goodnight / locked / TODO) then [docs/AGENT-DEV-PROCESS.md](docs/AGENT-DEV-PROCESS.md)

---

## What this repo is

Mintzer — Android-first Indian fintech app. Users browse Flipkart/Amazon card deals, accept deals, place orders on stores, submit proof, get paid in an in-app Wallet.

**This repo is specs + mockups + docs + the Flutter Play app** in `app/` (`com.mintzer`). File map: [docs/frontend/03-flutter-app-map.md](docs/frontend/03-flutter-app-map.md).

---

## Current phase

| Phase | Status |
|-------|--------|
| Screen content & product rules | **Done** — `docs/screens/`, `docs/design/` |
| Backend API specs | **Done** — `docs/backend- for developer reference/` |
| HTML reference mockups | **Done** — `assets/mockups/` |
| **Live demo UI** | **LOCKED 2026-09-18** — `assets/mockups/mintzer-designer-taste-demo.html` |
| **Live Play orders** | **Mapped** — `docs/backend- for developer reference/11-live-order-migration.md` |
| **Legacy users / no crash** | **LOCKED** — same phone, no force PAN, mapper must not crash — [docs/STATUS.md](docs/STATUS.md) |
| Figma UI design | Optional polish — match the locked live demo |
| Mobile app code (Flutter) | **In `app/`** — package `com.mintzer`. Map: `docs/frontend/03-flutter-app-map.md`. Do not restyle locked screens. |
| **iOS / App Store** | Scaffold in `app/ios/` — build/Archive on Mac only. See [docs/IOS-APP-STORE.md](docs/IOS-APP-STORE.md). |
| PAN verify | **Live Cashfree** — app `POST /pan-verify`. IFSC stays API Sathi. See `docs/STATUS.md`. |
| Backend implementation | **After or parallel** — see backend docs |

---

## Before you change anything

1. Read [docs/AGENT-DEV-PROCESS.md](docs/AGENT-DEV-PROCESS.md) (full process).
2. Check if the screen is **LOCKED** in [docs/screens/SCREEN-INVENTORY.md](docs/screens/SCREEN-INVENTORY.md).
3. **Markdown specs beat PNG mockups.** HTML exploration files (`home-v2.html`, `home-v3.html`, `home-card-variants.html`) are **not** source of truth.
4. **Locked Home reference:** `assets/mockups/mintzer-designer-taste-demo.html` + `docs/screens/02-home.md` (**style B**). `home-samples.html` is historical.
5. **Locked live demo (full flow):** `assets/mockups/mintzer-designer-taste-demo.html` — UI locked 2026-09-18. Do not restyle screens without client approval. **Always open / verify in Brave** — not Chrome, Edge, or the Cursor browser.

---

## Do not

- Add Offers tab to bottom nav (deferred).
- Add Wallet withdraw button.
- Change the locked Home deal card (**style B**: grey overlay name, caption `card · ₹spend`, Earn button).
- Change the locked Deal detail report chip (combined WhatsApp + cycling copy, top-right).
- Change the locked Deal detail Accept CTA (magnetic **Swipe to accept**).
- Change the locked designer TEST Place order: You pay \| You earn, step rail 1–2–3, ring timer in dock, small Generate new address button.
- Change the locked Order detail **flow line** (purple in-progress · green when paid · pulsing current).
- Change payout cheers to a timer rotator (one line **per visit** only).
- Ship the HTML demo to Play Store.
- Change the Play package off **`com.mintzer`** (that would not be an update).
- Use orange competitor UI. App purple is **`#7B61FF`** (live demo). Website `#9C71E4` is mintzer.in only.
- Force PAN / KYC on Play update or login (legacy users browse old orders first; PAN on **next Accept**).
- Replace any file already on the server (PHP, routes, blade, JS, CSS, image, website, or `beta`) without comparing it to the live copy first. An older `web.php` upload deleted admin ticket reply while the Tickets list still loaded. Full rules: [docs/LIVE-UPLOAD-RULES.md](docs/LIVE-UPLOAD-RULES.md).
- Fix one bug by rewriting a whole file, uploading extra files, or deleting a route, method, column, or button that looks unused. Start from the live file, change only the broken lines, upload only those files, and use the broken action plus the one beside it. Rule: `.cursor/rules/one-bug-no-second-bug.mdc`.
- Replace live `DealsController.php` with the local copy. Live has `sendDealStockAlert` and `pushDealBlast`. The local file does not.
- Hand only an APK when the owner asked for Play — always build **AAB** for Console (`Mintzer-{version}.aab` + hash in `docs/STATUS.md`).
- Invent Mintzer payout with a client formula when Total receive exists — payout is admin Total receive only.
- Commit unless the user explicitly asks.

---

## Quick file map

| Need | Path |
|------|------|
| **A–Z of app + functionality** | `docs/APP-A-TO-Z.md` |
| **Overnight / morning handoff** | `docs/STATUS.md` |
| **Play upload = AAB** (APK sideload only) | `.cursor/rules/play-release-aab.mdc` · `docs/STATUS.md` |
| **Deal money Admin ↔ App** | `.cursor/rules/deal-money-fields.mdc` |
| **Replace any live file — compare first** | `docs/LIVE-UPLOAD-RULES.md` · `.cursor/rules/live-upload-no-regressions.mdc` |
| **One bug — six rules, no second bug** | `docs/LIVE-UPLOAD-RULES.md` · `.cursor/rules/one-bug-no-second-bug.mdc` |
| Full dev process (agents) | `docs/AGENT-DEV-PROCESS.md` |
| **Everything we discussed (master log)** | `docs/COMPLETE-DECISIONS-LOG.md` |
| All screens list | `docs/screens/SCREEN-INVENTORY.md` |
| Per-screen spec | `docs/screens/01-login.md` … `11-account-deleted.md` |
| Designer handoff | `docs/design/FOR-DESIGNER.md` |
| **Affiliate marketing (LOCKED)** | `docs/design/AFFILIATE-MARKETING-REQUIREMENTS.md` |
| **Push templates (LOCKED · short)** | `docs/design/NOTIFICATION-TEMPLATES-LOCKED.md` |
| **Push copy banks (30+ each)** | `docs/design/NOTIFICATION-TEMPLATE-BANKS-LOCKED.md` |
| **Live demo (UI locked)** | `assets/mockups/mintzer-designer-taste-demo.html` — **always open in Brave** (`scripts/open-live-demo.ps1`) |
| **Flutter file map** | `docs/frontend/03-flutter-app-map.md` |
| Frontend build order | `docs/frontend/README.md` |
| Frontend checklist | `docs/frontend/01-implementation-checklist.md` |
| Backend modules | `docs/backend- for developer reference/README.md` |
| **Live Play orders → new UI** | `docs/backend- for developer reference/11-live-order-migration.md` |
| Colors / tokens | `docs/design/COLORS-AND-TOKENS.md` |
| Validation UX | `docs/design/VALIDATION-UX.md` |
| **KYC / payout (LOCKED)** | `docs/design/BANK-AND-PAYOUT-DETAILS.md` |
| **GST deals (LOCKED)** | `docs/design/GST-DEAL-REQUIREMENTS.md` |
| Client “what to do next” | `README.md` |

---

## Style (fixed)

- Material 3 Light default · Dark mode required later
- Primary: `#7B61FF` (dark: `#B39DFF`) — live demo. mintzer.in stays `#9C71E4`.
- Bottom nav: **Home · Orders · Wallet · Profile**
