# Mintzer — A to Z (till 28 Oct 2026)

**One place for the whole product.** Detail specs stay in `docs/screens/` and `docs/design/`. Day-to-day handoff: [STATUS.md](./STATUS.md).

**Live app:** Play package `com.mintzer` · Flutter in `app/` · version **3.0.41** · Android only.  
**Live UI:** locked 18 Sep 2026 — `assets/mockups/mintzer-designer-taste-demo.html` (open in **Brave**).  
**Live backend:** Hostinger `newapp` · admin on mintzer.in.

---

## A — What Mintzer is

- Indian fintech app for **card deals** (Flipkart / Amazon and similar).
- Holder browses deals → **Accept** → places store order → submits proof → gets paid in **Wallet**.
- Not a bank. Wallet = earnings history. **No withdraw in app.**
- Admin creates deals and pays out. App shows admin numbers — no inventing payout math.

---

## B — Bottom nav (fixed)

- **Home · Orders · Wallet · Profile**
- No Offers tab (retired / deferred).
- No 5th tab for cards.

---

## C — Colors & brand

- App purple: **`#7B61FF`** (live demo).
- Website mintzer.in: `#9C71E4` (site only).
- Earn green: `#188038`.
- Material 3 Light default · Dark mode required (Profile → Light / Dark / System).
- No orange competitor UI. No glassmorphism.

---

## D — Deal money (Admin ↔ App) — LOCKED

| Admin panel | App |
|-------------|-----|
| Card holder will spend | You pay (card) |
| Total card holder will receive | Mintzer payout / **From Mintzer** |
| Card holder will earn | You earn / Home **Earn** |
| Cashback | Bank cashback line (when > 0) |
| Cash reward | Only under “How this is calculated?” for now |

- **From Mintzer** = Total receive field only. Never `You pay + profit`.
- List API must send `card_holder_receive` so Deal detail does not jump.
- **Paid on** = date only from real `paid_at`. Hide if missing. Never phone clock.

---

## E — Full user journey

```
Login (phone + OTP)
  → Intro beat → Home
  → Deal detail → Swipe to Accept
  → [First time: PAN KYC → Bank + UPI]
  → [First time: How do you want to order?]
  → Place order (timer · address · Open store · store Order ID · Submit)
  → Order placed success
  → My Orders → Order detail steps
  → Wallet (when paid)
  → Profile (settings, tickets, delete, logout)
```

- Alternate: Account suspended after OTP · Delete account · Account deleted screen.

---

## F — Login & intro

- Phone + OTP only. No name, email, KYC, or bank at login.
- +91 · 10 digits · OTP auto-submit + SMS autofill.
- Suspended user → Account suspended screen (no main app).
- Post-login intro: logo check · Made in India · ~1.8s → Home.
- Languages on Login: **EN · हि · ಕಾ · മല** (same bar as Profile).

---

## G — Home

- Greeting by time of day + one idle subtitle per open (not a timer rotator).
- Wallet pill · Bell · WhatsApp community (config URL).
- Search · List / Grid · chips All / Direct / Link · filter sheet.
- Deal card **style B LOCKED:** grey overlay name · `card · ₹spend` · purple Earn button.
- GST pill only when deal needs GST.
- Active order strip when placement timer is running (green · Continue · amber under 5 min).
- Tutorial banner first visit only.
- Empty Home: **Send a deal you saw** → ops queue (not a public post).
- Carousel banners + optional app-open alert + deal alert (admin).

---

## H — Deal detail

- Full product · store · card · money breakdown · instructions.
- Report chip top-right: WhatsApp + cycling short lines (Anything wrong? / Price changed? / …).
- Accept = magnetic **Swipe to accept** (not a tap button).
- One active placement: if already placing, “Finish current order first”.
- GST deals: teal strip + Accept modal 1·2·3 about delivery address GST (never dump GSTIN in modal).
- No timer / address / Order ID on this screen.

---

## I — Accept gates (first time)

1. **KYC** — PAN → name from **Cashfree** (live). Status: PAN found. We’re verifying…
2. **Payout** — bank (name must match PAN · number · IFSC via API Sathi) **and** UPI.
3. **How do you want to order?** — External (default) or In-app WebView.
4. Legacy Play users: **no force PAN** on update/login. PAN only on **next new Accept**.

---

## J — Place order

- Timer from admin (`auto_cancel_order_duration`, default **15 min**).
- One active placement until store Order ID submitted, cancelled, or expired.
- Expired placement → admin log only — **not** a My Orders row.
- Address: copy per line + Copy all · Generate new address (weekly limit).
- Coupon line: purple + own Copy — only if admin deal has a code (app **3.0.38+**).
- GST: GSTIN above Company · Copy only on GSTIN.
- Store Order ID: tap field to paste · Submit → Placed.
- Duplicate store Order ID → hard block.
- Cancel with reason on this screen.
- Instant / link accepts: **never** auto-killed by the 15-min path.
- Designer TEST dock LOCKED: You pay \| You earn · steps 1–2–3 · ring timer · small Generate new address.

---

## K — After Placed — order steps

1. **Placed** — store Order ID (Edit until paid).
2. **Tracking** — courier + tracking ID (user picks; no auto GPS).
3. **Out for delivery** — delivery OTP + last 4 of order phone.
4. **Confirmation** — wait for admin; after OTP: “This may take up to 1 working day” (**3.0.39+**).
5. **Invoice** — upload only after admin **Delivered** / parcel received (**3.0.39+**; older builds may unlock earlier).
6. **Payment** — 48 **working** hours · no payouts on bank holidays · one cheer line per visit.
7. **Paid** → Completed · From Mintzer · Bank cashback if any · Your earnings · Paid on date · UTR / bank last4.

- Flow line LOCKED: purple in progress (pulse current) · whole rail green when Paid.
- Cancel until paid · Add note (200 chars) until paid · Report issue → ticket.

---

## L — Tell Mintzer / delivery calling (**3.0.35–3.0.40**)

- Same green button after OTP until invoice uploaded.
- Words change: Delivery boy / agent / person calling? · Any other issue? · Rescheduled?
- Calling / issue → WhatsApp with order facts (empty lines left out).
- Rescheduled → Edit (new OTP + last 4). No WhatsApp.
- My Orders card button does not open the order.
- Profile **Contact support** sheet: WhatsApp **82486 26422** or existing ticket.

---

## M — My Orders

- Tabs: **Ongoing | Completed**.
- Search: Order ID · Tracking · product name.
- Filter by store · Sort · Needs action badge.
- Active placement shows as Continue order with timer.
- Completed: Paid + Canceled labeled separately.
- List: icon flow rail only — no Tracking/Payment/Paid text chips.

---

## N — Wallet

- Total earned (lifetime profit) · Pending (unpaid profit).
- **No Available** · **No withdraw** · no add bank here.
- Payouts list · Download Excel · date range · All / Paid / Pending / Canceled.
- Row: From Mintzer main · Earn as separate label · tap → Order detail.

---

## O — Profile

- Avatar letter or photo · Hi {name} · phone read-only.
- KYC · Payout · Language (EN हि ಕಾ മല) · Appearance.
- My tickets · FAQ · Help / Tutorials · Notification toggles.
- Contact support sheet · Terms · Privacy · Delete account · Logout.
- Delete blocked if order in progress.
- No Wallet / Orders shortcuts (use bottom nav).
- Refer & earn banner (affiliate layer).

---

## P — Tickets & help

- Raise ticket from Order detail (guided categories).
- My tickets list → thread with admin replies.
- Admin Reply must stay on live `web.php` (`thread` + `reply` routes).
- Push + bell when admin replies. Bell Clear wipes list (no archive).

---

## Q — Notifications

- Bell inbox on Home (minimal: tickets + live actions).
- Push tiers: Deal alerts · Order updates · Payment & wallet.
- Firebase project: `mintzer-e45d6`.
- Copy banks LOCKED — do not invent tray text without updating notification docs.
- Push open must not force-close (**3.0.41** festive alias fix).
- In-app update: Play flexible sheet — Update / Not now · Restart. Not force-block.

---

## R — Admin panel (what ops do)

- Create / edit deals (spend · total receive · earn · cashback · coupon · GST · Instant/link flags).
- Deal alert · banners · app-open alert · Home social proof line.
- Business Settings (timer minutes, community WhatsApp, Home line On/Off).
- Orders list: move status · Delivered unlocks invoice · mark paid / UTR.
- Tickets: Reply in thread.
- Stock alert / deal blast live on server (do not overwrite local older `DealsController`).
- Stores & cards masters live in admin; app reads API.

---

## S — Server guards (live, recent)

- Cancel refused when store Order ID already set (two-device case, **28 Oct**).
- `update-order-id` refused if Accept is Cancelled / Declined / Rejected.
- Stale open Accepts past timer released on list fetch (**3.0.32** era).
- Own orders only for logged-in user.
- Second Accept blocked only while waiting for store Order ID (or Pine Labs no screenshot).
- OTP flood guard: Google proxy blocked · max 3 texts / 10 min per number.
- PAN: Cashfree live · spend caps per day · IFSC = API Sathi.

---

## T — Play release rules

- Same package **`com.mintzer`** (update, not a new app).
- Play Console upload = **AAB** (`Mintzer-{version}.aab`). APK = sideload only.
- Default track: **Internal testing** first. Production only when owner says.
- Bump `pubspec.yaml` + `AppConfig.versionLabel` together.
- Hash AAB in STATUS after build.

**Latest AAB:** `Mintzer-3.0.41.aab` · SHA-256 `442DFACD…F2C6` · festive logo off · safer push open.

---

## U — Locked UI (do not restyle without approval)

- Home deal card style B.
- Deal detail Report chip + Swipe to accept.
- Place order TEST dock (pay/earn · steps · ring timer).
- Order detail flow line (purple → green when paid).
- Payout cheer = one line per visit (not a rotator).
- Login / intro / Active strip / KYC+Payout sheets / GST modal / language bar.
- Live demo HTML is the visual source — not exploration `home-v2` / `home-v3`.

---

## V — Out of scope (do not build in v1)

- Wallet withdraw.
- Offers tab.
- Instant tab as separate My Orders mode (Instant deals exist; no Instant list tab).
- Live courier GPS map.
- OCR from screenshots.
- Force PAN on login/update.
- Shipping HTML demo to Play.
- Tamil / Telugu as v1 languages (after EN HI KN ML).
- Replacing live files without compare-first.

---

## W — Live upload safety (ops / agents)

- Download live file first · diff · merge server-only parts · then upload.
- One bug → one edit → upload only those files.
- Never upload older local `DealsController.php` over live (stock alert + deal blast).
- Never upload `.env` or `Sen Info`.
- Full rules: [LIVE-UPLOAD-RULES.md](./LIVE-UPLOAD-RULES.md).

---

## X — Languages

- v1: **English · Hindi · Kannada · Malayalam**.
- Same 4-button bar on Login and Profile.
- Applies to whole app immediately.

---

## Y — Affiliate / marketing layer (LOCKED)

- Home carousel · badges (Hot / Trending / slots) · social proof strip.
- Order success: one rotating marketing template per visit.
- Refer & earn in Profile · partner cards sheet (not full catalog screen).
- Spec: [design/AFFILIATE-MARKETING-REQUIREMENTS.md](./design/AFFILIATE-MARKETING-REQUIREMENTS.md).

---

## Z — Where to look next

| Need | File |
|------|------|
| Today’s handoff / build hashes | [STATUS.md](./STATUS.md) |
| Older decision dump | [COMPLETE-DECISIONS-LOG.md](./COMPLETE-DECISIONS-LOG.md) |
| Screen list | [screens/SCREEN-INVENTORY.md](./screens/SCREEN-INVENTORY.md) |
| Flutter file map | [frontend/03-flutter-app-map.md](./frontend/03-flutter-app-map.md) |
| Agent process | [AGENT-DEV-PROCESS.md](./AGENT-DEV-PROCESS.md) · root `AGENTS.md` |
| Live demo | `assets/mockups/mintzer-designer-taste-demo.html` (Brave) |
| Money map | `.cursor/rules/deal-money-fields.mdc` |
| Play AAB rule | `.cursor/rules/play-release-aab.mdc` |

---

**Version of this doc:** 28 Oct 2026 · app **3.0.41**.
