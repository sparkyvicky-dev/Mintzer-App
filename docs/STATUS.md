# Mintzer — status (19 Nov 2026)

**A–Z of the whole app (till date):** [APP-A-TO-Z.md](./APP-A-TO-Z.md)

**Flutter tree:** every file in `app/` is listed in [frontend/03-flutter-app-map.md](./frontend/03-flutter-app-map.md). Code version is **3.0.41 (30041)**. **Android live on Play.** **iOS App Store:** scaffold in `app/ios/` — follow [IOS-APP-STORE.md](./IOS-APP-STORE.md) (Mac + Xcode + Firebase iOS plist). On 25 Sep the web scaffold, Windows runner, and generated build/IDE junk were removed. No `app/lib` or Android source was deleted. Logo files that could be recovered were put back. Locked screens were not restyled.

---

## 19 Nov — iOS App Store scaffold

| Item | Detail |
|------|--------|
| Platform | `app/ios/` created · bundle `com.mintzer` |
| Code | OTP SMS Android-gated · Darwin push locals · store URLs / Rate Mintzer |
| Mac next | `GoogleService-Info.plist` · signing · Push capability · Archive → TestFlight |
| Doc | [IOS-APP-STORE.md](./IOS-APP-STORE.md) |

---

## 28 Oct — two-device Cancel / Order ID (server)

Same account on two phones: Cancel after store Order ID, or Order ID stuck on a Cancelled Accept (Pavithra M · `ORD8N7S4X4` restored to Placed with `404-9875421-1233161`).

| File | Change |
|------|--------|
| `newapp/.../API/Order/OrderController.php` | Cancel refused when `store_order_id` is set · `update-order-id` refused when Accept is Cancelled / Declined / Rejected |

Live from live copy first. Only those two guards added. No Play update needed. Beside: Cancel before Order ID still works · Order ID on open Accept still works. Backup: `_hostinger_explore/two-device-cancel-fix-20261028/`.

---

## 26 Oct — Play 3.0.41 (festive logo / notification open)

Festive SALE/FEST drawer icons ended early (no wait for Nov 11). Always plain Mintzer logo. Alias swap runs after open, not in the middle of a notification cold-start — aims to stop force-close when tapping a push.

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB** | `D:\dev\mintzer-app\Mintzer-3.0.41.aab` | `442DFACDF13F75B0D49E224C71F08FF67B72E3AF29A0DD0E85A217C53556F2C6` |

**Play Console = AAB.** Internal testing first. No APK this build. Smoke: tap a push while app was killed → opens Home/Orders, no force-close · drawer icon = plain logo.

---

## 26 Oct — Play 3.0.40 (Tell Mintzer copy)

Removed the helper line under Tell Mintzer (“Same button. The words change…”). Holders still get Tell Mintzer + the changing button. Also includes 3.0.39: invoice unlock only after admin Delivered.

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB** | `D:\dev\mintzer-app\Mintzer-3.0.40.aab` | `98F81FFBCFB47D6BABC03E5781F50B78C77F1C42F48BBD71E504FF12E324299D` |

**Play Console = AAB.** Internal testing first. No APK this build.

---

## 26 Oct — Play 3.0.39 (invoice after Delivered)

After OTP, Confirmation waits with **This may take up to 1 working day.** Upload invoice opens only when admin sets **Delivered**. Older Play builds stay as they are (server not hard-blocked). Tracking duplicate block was already live on the server.

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB** | `D:\dev\mintzer-app\Mintzer-3.0.39.aab` | `B08F71A3FB27C56BF8CFBAB60BE5B9BD4BC0FB79568C744FCE8A4A5BCB886EE4` |
| APK | `D:\dev\mintzer-app\Mintzer-3.0.39.apk` | `A15C4597E3810C55BA722261578F4D45E70E7122D76DE21C87CB2AA5F66141B4` |

**Play Console = AAB.** APK is sideload only. Internal testing first. Smoke: save OTP → Confirmation wait · admin Delivered → Upload invoice · older app still uploads after OTP.

---

## 21 Oct — Play 3.0.38 (coupon on Place order)

Coupon shows on the Place order address card only when the admin deal has a code. Empty stays hidden. The line is purple, with its own Copy. Copy all still copies the address only.

Admin coupon box was already uploaded (Create, Edit, Copy). This build is the app that can show it.

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB** | `D:\dev\mintzer-app\Mintzer-3.0.38.aab` | `B102CB44B0B4C696BAAE386A525EBBE7426A1AD1B06750FED4D1C08FE3B218E0` |
| APK | `D:\dev\mintzer-app\Mintzer-3.0.38.apk` | `035CB928F40BED2A27EB0DA3223C3ACAD1A600393827E719130010388296298F` |

**Play Console = AAB.** APK is sideload only. Internal testing first. Smoke: deal with a coupon → purple Coupon line on Place order · deal with no coupon → no line · Copy on the coupon copies the code · Copy all still copies the address.

---

## 14 Oct — Play 3.0.37 (one button, words change)

Same green button after OTP, until the invoice is uploaded. The words change:

- Delivery boy calling? → WhatsApp with this order
- Delivery agent calling? → same, first line says agent
- Delivery person calling? → same, first line says person
- Any other issue? → WhatsApp help with this order
- Rescheduled? → Edit. New OTP and last 4. No WhatsApp

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB** | `D:\dev\mintzer-app\Mintzer-3.0.37.aab` | `49696F8974A126A1D950917B0A49AF25A48C0BE7DE7F45374C6BC0C8773E4976` |
| APK | `D:\dev\mintzer-app\Mintzer-3.0.37.apk` | `E881809A6A18C04652C33E9F84052F3579C9337E89DD86711599CCFD58466F6F` |

**Play Console = AAB.** APK is sideload only. Internal testing first. Smoke: words change on the button · calling opens WhatsApp · Rescheduled opens Edit · invoice uploaded hides the button.

---

## 14 Oct — Play 3.0.36 (delivery-call button on real orders)

**Audit of 3.0.35:** other screens were unchanged. The new button did not show on live orders, because those orders skip Confirmation and go to Invoice once the OTP is saved.

**This build**
- Button shows after the OTP is saved, until the invoice is uploaded.
- WhatsApp text still includes courier and last 4 when the order has them.
- Order list now sends the delivery phone last 4 (`Common.php`, one added line). Compared to live first.

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB** | `D:\dev\mintzer-app\Mintzer-3.0.36.aab` | `079502A69443993308FFF1A92D9FF8838C1D71F4174AA6DFBAA3B9E6ACC844C4` |
| APK | `D:\dev\mintzer-app\Mintzer-3.0.36.apk` | `51CD71E65378220C854E59C21EFDF1C91CDEB2972A2DF471478A43E6CEE44E9F` |

**Play Console = AAB.** APK is sideload only. Internal testing first. Smoke: order with OTP saved and no invoice → button shows · invoice uploaded → button hides · Edit still saves a new OTP.

---

## 14 Oct — Play 3.0.35 (delivery boy calling · Contact us)

**App only.** No server file uploaded.

- After OTP and last 4 are saved, and the order is still on Confirmation: **WhatsApp Mintzer team** on the order, and **Delivery boy calling** on the My Orders card. The card tap does not open the order.
- WhatsApp text: Order ID, Mintzer order when it differs, product, courier, tracking, last 4, OTP. Lines that are empty are left out.
- Reschedule stays the existing **Edit**. No extra line.
- Profile **Contact support** opens a sheet: WhatsApp 82486 26422, or the existing ticket. Help Center, My tickets, and the rest of Profile stay as they were.
- Button is off before OTP, and off on Invoice, Payment, Paid, and Canceled.

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB** | `D:\dev\mintzer-app\Mintzer-3.0.35.aab` | `6E1D63F2547E463038FE42CEEC8E38B79726AC79AFE1DECE1111C01A5DC65271` |
| APK | `D:\dev\mintzer-app\Mintzer-3.0.35.apk` | `C28372F244DB672604E095E41C75093184E0B449EDB5F9766B9F4ED892E8314C` |

**Play Console = AAB.** APK is sideload only. Internal testing first. Smoke: order on Confirmation → WhatsApp text has order id, product, courier, tracking, last 4, OTP · My Orders button does not open the order · Edit still saves a new OTP · Profile Contact support still opens a ticket.

---

## 12 Oct — Play 3.0.34 (Paid on · cashback copy · GST UI · cancel)

**App**
- Paid on = date only from `paid_at` (never phone clock)
- Bank cashback sub = locked bank-statements wording
- Place order GST: **GSTIN above Company**; Copy only on GSTIN
- Cancel: if server says Order not found / already cancelled → clear locally (no stuck toast)

**Live server (compared first, one file each)**
- `Common.php` — additive `paid_at` when paid
- `OrderController.php` — cancel / auto-delete null-safe dealer address (Instant / missing address no longer crashes)

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB** | `D:\dev\mintzer-app\Mintzer-3.0.34.aab` | `23D907373253D8AA990462C18E49972E8D5FF8E1D104DA16CB1230DCCE0B2841` |
| APK | `D:\dev\mintzer-app\Mintzer-3.0.34.apk` | `6BD5C7C219051B307338708DDA0CA8D971BCA3BBEC21619FE9F36976B8177B4D` |

Internal testing first. Smoke: Accept → Cancel (Place order + Order detail) · GSTIN copy only · Paid Paid-on date · Payment money lines.

**Admin note:** some deals missing GST state code `33` — fix in Admin GST Number field (not app).

---

## 12 Oct — payout credit display (safe)

**Bug:** Order Payment / Paid showed **You pay + profit** (e.g. ₹33,243) while bank transfer was **Total receive** (₹31,635). User **9698687607** / ORDGVD9663.

**Safe fix (display only — no payout math / no admin change):**
- Order Payment + Paid: **From Mintzer** = `mintzer_payout` / Total receive. Never spend + earn.
- Bank cashback line when API sends `cashback` &gt; 0. Your earnings unchanged.
- Live `bankReturnAmount` never falls back to spend+earn or product formula.
- Unit test: `bank return uses mintzer_payout not spend plus earn`.
- Server additive: order list `cashback` field (`Common.php` + `OrderController.php` getOrderList select). Compared from live copies first.

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB** | `D:\dev\mintzer-app\Mintzer-3.0.33.aab` | `417F6A8F88181D91F7188874D0942B4D55928201FD59A71EE421FC7C66005C7A` |
| APK | `D:\dev\mintzer-app\Mintzer-3.0.33.apk` | `0F7B05FF16287E7E583C4ACC76D97CED94FEE06CF061E0C95A6EB5B8921CF3F0` |

Brave preview: `assets/mockups/wrong-payment-credit-fixed.html`. Internal testing first.

---

## 11 Oct night — placement timer + Play 3.0.32

**Owner:** stuck Home timer after kill/reopen (accept past 15 min still showed countdown); Mintzer payout could jump list→detail. Money-field polish deferred; timer shipped.

### Live server (already on Hostinger)

| File | Change |
|------|--------|
| `newapp/app/Traits/Common.php` | List `dealDataFormat` includes `card_holder_receive` (same as detail) |
| `newapp/app/Http/Controllers/API/Order/OrderController.php` | On `getOrderList`, that user’s stale open Accepts (no store OID, not Instant, past `auto_cancel_order_duration`) are released |

Backups / patched copies: `_hostinger_explore/live-check-20261011/timer-payout-fix/`.

### App 3.0.32 (timer)

- No +3 min grace on reopen after expiry
- Home strip expires at 0 → `auto-delete-order`
- Instant / link accepts never auto-deleted by the 15‑min path
- Place order does not invent a fresh 15:00 after clear

### Play upload (Internal testing first)

| Artifact | Path | SHA-256 |
|----------|------|---------|
| **AAB (Play Console)** | `D:\dev\mintzer-app\Mintzer-3.0.32.aab` | `0FB059333B5C038B73F3639B95D8A583AE317BF5D37C1CAA733AE037075054E3` |
| APK (sideload only) | `D:\dev\mintzer-app\Mintzer-3.0.32.apk` | `CF7ADF5A23D2E6BCD52A3721CF65E8754BA8E45CAC669E7F077EBA3F0C028C5D` |

Rules added: `.cursor/rules/play-release-aab.mdc` (always AAB for Play) · `.cursor/rules/deal-money-fields.mdc` (admin ↔ app money map).

**Do not** restyle locked screens. **Do not** Production until Internal smoke: Accept → kill past 15 min → reopen strip gone · Instant deal still OK · submit Order ID still OK.

Money / Cash reward calculation cleanup = later.

---

## 29 Sep afternoon — admin ticket reply restored

Web admin Tickets could not reply to anyone, including **User8715 / 9003718715** (“tamil language call me”, 29 Sep 02:19 PM). The Reply button and `ticketReply` were already on the server. Live `routes/web.php` was missing `GET tickets/{id}/thread` and `POST tickets/{id}/reply` because an older copy of that file had been uploaded over the live one.

Repaired by uploading one merged `web.php`: those two routes, `POST bank/plan/{id}/{on}` (method was already live), and the server-only `POST /send-deal-stock-alert`. `DealsController.php` was not uploaded — the local copy is older and would delete the stock alert.

**Before replacing any live file, and before calling a fix done, read [LIVE-UPLOAD-RULES.md](./LIVE-UPLOAD-RULES.md).** Two always-on rules: compare every replaced file (`.cursor/rules/live-upload-no-regressions.mdc`) and the six fix rules (`.cursor/rules/one-bug-no-second-bug.mdc`). Start from the live file, one bug one edit, upload only those files, leave a server-ahead file alone, use the broken action and the one beside it, and do not delete something because it looks unused.

Refresh the Tickets page and use **Reply**.

---

## 29 Sep — PAN is Cashfree

Checked live Hostinger. No app or API code was changed.

The app still calls `POST /pan-verify`. The server picks the provider in this order:

1. **Cashfree** when `CASHFREE_PAN_ENABLED` is on and `CASHFREE_CLIENT_ID` / `CASHFREE_CLIENT_SECRET` are set. This is what is live. `POST https://api.cashfree.com/verification/pan`. Only the registered name is kept.
2. **PowerAPI** only if Cashfree is off and `POWERAPI_PAN_ENABLED` is on.
3. **API Sathi** only if both of those are off. API Sathi is also the fallback when PowerAPI is the active provider and the name is missing or PowerAPI cannot be reached. A Cashfree failure does not fall through.

**IFSC stays API Sathi** (`POST /ifsc-lookup`). Keys stay in Hostinger `.env` and `Sen Info`. Never in the APK.

Spend guards are unchanged (IST day): an already-verified account is not looked up again · the same PAN name is cached 30 days · **3** upstream checks per user and per phone · **150** for the whole app · a second tap within 20 seconds is rejected.

The sheet is not down. From 28 Sep through 29 Sep morning the server logged 9 successful PAN checks and 0 failures. **9095663920** (user 693) signed in 29 Sep 06:25 and never called `pan-verify`. That account has no PAN and no PAN name.

Full step → API map: [frontend/03-flutter-app-map.md](./frontend/03-flutter-app-map.md).

---

## Earlier — 24 Sep 2026 night

**If you are a new agent or picking up in the morning: read this file first, then [AGENT-DEV-PROCESS.md](./AGENT-DEV-PROCESS.md).**

**Owner goal:** Play update must not crash (Flutter). Same package **`com.mintzer`**. Same backend **`newapp`**. UI stays locked — **no restyle without approval**.

**Last session:** 24 Sep 2026 afternoon. **9727798266** got 159 login OTP texts today from Google’s fetch proxy hitting the public `sendotp` API. No other number was flooded. Live server now refuses that Google proxy and stops a number after 3 texts in 10 minutes. Phone build to upload is **3.0.20 (30020)** — internal testing only, not Production. Ongoing orders show the 3-dot again (list card and inside the order). Paid and canceled still have none. Opening the app asks Play for a flexible update (**Update available** / **Not now**). The copy already on the phone cannot show that prompt until 3.0.20 is installed from the Play listing once. **9342002247** shows **Sasikumar** because that is the PAN name saved on the account. **8667327827** has live Tracking, Invoice, and Paid orders.

---

## 24 Sep late morning — two alerts

| Alert | Where | How often |
|-------|--------|-----------|
| App-open | Admin → Banners. Tick **App-open alert**. Leave it off for a normal Home strip banner. | Once per person. Close hides it for that person. A newer alert shows again. Status off stops it. |
| Deal | Deal form → **Deal alert**. Image plus optional link. | Every time they open that deal, while the switch is on. |

Empty link: tapping the image does nothing. A link opens in the phone browser. Home carousel is unchanged (3 live banners, `home_popup` null until an alert is turned on). Columns added on live, then the one-shot script was deleted.

Festive drawer icons stay **off** until 7 Oct, 12:00 noon IST. **Do not ship Production.**

**Do not commit** unless the user asks. **Do not commit** `Sen Info\` or `.env`.

---

## 24 Sep night — sale banner + festive drawer icon

**Plain logo:** `mipmap/ic_launcher` and `drawable/ic_launcher_foreground` are still the purple Mintzer mark. Nothing was drawn on those files.

**Why a phone can already show a different icon:** an earlier build the same night turned on a gold-band-and-lamp icon from **24 Sep**. Android remembers that switch. This later build turns the plain icon back on until **7 Oct 2026, 12:00 noon IST**. Open the app once after installing this build. The drawer should be the normal mark again.

### What was decided

| Item | Decision |
|------|----------|
| Home banner size | **984 × 354** px (3× of the 328 × 118 carousel). App paints the banner name on a dark band at the bottom. |
| Banner message | Big Billion Days and the Great Indian Festival are coming. Mintzer deals will be limited. |
| Banner art | Not made here. Prompt is for ChatGPT, with the owner’s Flipkart screenshot attached. Admin name: **Big sales from 8 October. Fewer Mintzer deals.** |
| Flipkart dates | Plus, Black, and Flipkart credit card: **8 Oct 2026**. Everyone: **9 Oct**. Early Bird from **24 Sep** is a preview only, not the Plus sale. |
| Amazon | Great Indian Festival starts **8 Oct 2026**. No end date announced. |
| Icon rule | Mintzer mark shape does not change. No motion. Play Store listing icon stays the plain mark. |
| Words kept | **SALE** and **FEST** only (not BBD, GIF, or both together). |
| Decoration kept | Stars around the mark, and a crown of stars above it. Ring, side lamps, and gold corners are out. |
| When it shows | **7 Oct 2026, 12:00 noon IST**, after the user opens the app. Not at midnight by itself. |
| Daily order | 7 Oct after noon: SALE + stars · 8 Oct: SALE + crown · 9 Oct: FEST + stars · 10 Oct: FEST + crown · then repeat. |
| Back to plain | **12 Nov 2026** (season end was set as end of **11 Nov**, through Bhai Dooj). Owner has not confirmed this end date. |

Code: `app/android/app/src/main/kotlin/com/mintzer/FestiveLauncher.kt`. Previews (Brave): `assets/mockups/festive-drawer-icon-around-m.html` and `festive-drawer-icon-words.html`.

### Still to do

1. Install this build and open the app once so the drawer icon is the plain mark again.
2. Owner still has to make the home banner in ChatGPT and upload it in admin. The app does not have that image.
3. Confirm the icon should stop on **12 Nov**, or name a different end date.
4. Do not upload a SALE/FEST picture as the Play Store listing icon.

---

## 24 Sep — Play internal testing

**Owner does not need to retype this in every chat in this project.** New chats are told to read this file. One line is enough: “Read `docs/STATUS.md`.”

**Full write-up:** [PLAY_STORE_READINESS_REPORT.md](../PLAY_STORE_READINESS_REPORT.md).

**Status:** ready for internal testing. Not production.

### Already done

| Done | Detail |
|------|--------|
| App version | `3.0.12` · build **30012** in `app/pubspec.yaml`. Profile label matches. |
| Play today | Production **32 (2.0.15)**, 28 Apr 2026, 100% rollout. Internal testing is **inactive** and has **no releases**. 30012 is higher than 32, so it is safe to upload **after** the AAB exists. |
| Release APK | Built. `D:\dev\mintzer-app\Mintzer-3.0.12.apk`. Sideload check only. Play needs an `.aab`. |
| Camera | `CAMERA` permission added. Denying the camera on invoice photo should show a message, not crash. Not tried on a phone. |
| Backup | `allowBackup=false`. New Google backups will not copy login, PAN, or bank details. People already signed in stay signed in. |
| Store page | In-app store page opens normal `https` links. UPI and phone links leave the page. `http` and script links are blocked. 3 unit tests passed. |
| Own orders | Live on Hostinger. A logged-in person can change only their own order (Order ID, cancel, tracking, invoice, payout request). |
| Second Accept | Live on Hostinger. A new Accept is refused only while this user still has an order waiting for a store Order ID, or a Pine Labs order with no screenshot. Paid, shipped, and cancelled orders do not block the next Accept. |
| Server files uploaded | `OrderController.php` and `dealController.php` under `newapp`. Old live copies: `_hostinger_explore/backups/live-crosscheck-20260924-002707/`. |
| Left alone on purpose | Logo shape, locked screens, package `com.mintzer`, force-update (still off), PAN on/off, login storage format, push-timer password. |
| Home line | **Admin Business Settings.** Show on Home stays **Off** until the owner turns it **On**. Numbers from **Real orders** or **Type my own**. |
| Home banners | Saved on the phone after the first open, so a full close does not blank the strip. A banner with no link does nothing. WhatsApp slide uses the group link in Business Settings. Upload only `Mintzer-3.0.12.aab` hashed `BC982E88…1A70`. |

### Do not do unless the owner asks

- Do not release to Production.
- Do not upload the AAB. The owner uploads it by hand to **Internal testing**.
- Do not rebuild 30012 unless the owner asks. The file to upload is `Mintzer-3.0.12.aab` hashed `BC982E88C62A20D76ACEB2BE626C042D91F9844F7E01E6C9351C14FA420D1A70`.
- Do not deploy more backend changes unless a real blocker shows up.
- Do not change working business rules.
- Do not delete the main test account. Account-delete is view-only during this test.
- Edge-to-edge warnings in Play are about the **old 2.0.15** release. They are not a reason to restyle this build before internal testing.

### Still to do

1. Owner: Play Console → **Test and release → Internal testing → Create new release**. Upload `D:\dev\mintzer-app\Mintzer-3.0.12.aab` (SHA-256 `BC982E88C62A20D76ACEB2BE626C042D91F9844F7E01E6C9351C14FA420D1A70`). Add testers. Install from the **Play testing link**. If 30012 is already on Play, do not replace it — next build is **30013**.
2. Owner runs the phone checklist in the readiness report (login, Accept, second Accept, Order ID, old Tracking / Invoice / Paid orders, camera deny, airplane mode).
3. Owner reads the Play **pre-launch report**.
4. Production stays closed until that Play-installed build passes and no serious failure remains.

**Known issue, do not “fix” during this test:** a dead login does not send the user back to the OTP screen. Record it. Do not change auth to chase it now.

**Expired-token test:** do not invent a fake OTP and do not delete the account. If admin cannot revoke one token safely, mark that row as a known issue and skip it.

---

## 23 Sep night — PAN and IFSC

**Superseded 29 Sep.** Live PAN is Cashfree. Read the section at the top of this file. The notes below are what was true on 24 Sep morning.

**PAN provider (24 Sep morning):** PowerAPI `POST /api/v1/kyc/pan/verify-pan`. Key in `Sen Info\Api keys\Powerapi pan api.txt` and Hostinger `.env` as `POWERAPI_PAN_KEY`. Only the government **name** is kept. Address, phone, and masked Aadhaar from that response are dropped. If `POWERAPI_PAN_ENABLED=false`, PAN falls back to API Sathi. **IFSC stays on API Sathi.**

| Piece | What was live on 24 Sep |
|-------|----------------|
| PAN | `POST /pan-verify` → PowerAPI. App flag `panVerifyLiveEnabled = true`. Sheet still shows only the name. |
| IFSC | `POST /ifsc-lookup` → `ifsc-lookup-v1`. Payout sheet uses this. **Bank found** only after a valid 11-character IFSC lookup. Empty IFSC must not show the old bank name as found. |
| Account number | Save still requires **9–18 digits**. `000000` is rejected. |
| Profile → Payout | Opens immediately. Do not await a bank refresh before the push. |

**PAN spend guards** (server, IST day): already-verified account does not call API Sathi again · same PAN name cached 30 days · **3** upstream checks per user and per phone (survives account delete) · **150** upstream checks for the whole app · a second tap within 20s is rejected.

**IFSC spend guards:** result cached **90 days** · **20** upstream lookups per user per day.

**Do not** call `Http::connectTimeout()` in these services. This Laravel 8 build does not have that method; it crashed every IFSC lookup (“Could not reach IFSC lookup”) until it was removed. Use `Http::timeout()` only.

**Owner test phone `9488918666`:** PAN rows cleared for a fresh check. IFSC was never stored (bank name `HDFC` only, account `000000`). Re-test is: Verify PAN with a real PAN, then type a full IFSC so the branch card appears, then a real 9–18 digit account.

**Name on screen:** API Sathi returns the government name in capitals. The app shows it in normal case (`Vignesh Saravanan Sekar`). The server row stays the official capitals.

**Home top:** 2 designed slides — Partner cards, then Community. Admin banners from `getbanners` are inserted after Partner cards when they exist. The line under the greeting is 1 of 25 for that time of day (100 lines: card-to-cash, points, limit-to-bank, more orders, plus short time-of-day jokes). One per visit.

---

## Tonight in one paragraph (22 Sep, still true except PAN)

Holder push was broken because admin/cron/ticket sends hit legacy Firebase **`mintzer-e14bd`** while Flutter uses **`mintzer-e45d6`** — fixed Common + Send Notification + cron + deals. Ticket admin reply now creates bell + tray push; tap opens chat. Bell Clear deletes server rows. Wallet profit = earn only (not reimbursement). Tickets/profile live. **PAN provider changed 23 Sep** — see the section above, not Verifico. **22 Sep batch:** short first-name greeting · invite + change-phone · Partner Apply (admin Apply URL + bank icons) · Home banners from admin · Home bell unread dot rebuilds on mark-read/clear.

---

## 0. mintzer.in — LIVE (20 Sep night)

**Live:** https://mintzer.in/ — title is `Mintzer — Card deals. Earn paid to your bank`.  
**Admin still up:** https://app.mintzer.in/ — `X-Robots-Tag: noindex, nofollow` (login also has noindex meta).  
**Old Google URLs:** `/aboutus` and `/faqs` 301 to `/`.

**Google Search Console (owner, still needed):** request indexing for https://mintzer.in/ and hide https://app.mintzer.in/  
**Play + App Store (owner, still needed):** paste copy in `mintzer.in/GOOGLE-SEARCH-FIX.txt`

| Ready | Notes |
|-------|--------|
| Logo | `logo-mintzer.svg` = HQ Mintzer spelling |
| Hero | ChatGPT `01_20_22` → `hero-mintzer-dashboard.webp` (true alpha) |
| Footer phone | ChatGPT footer → `hero-app-devices-mockup.webp` |
| Copy / FAQ | Premium short tone; product rules accurate (48h bank, no withdraw, PAN on Accept, Play-only) |
| Legal | privacy.html + terms.html + old URL redirects |
| Hostinger cutover | **Done** via FTP. `newapp` / `beta` not touched except admin noindex. |
| Admin noindex | **Done** — `newapp/public/.htaccess` header + login blade meta |

**Still optional (do not block):** some process/tab raster mockups still show “Instant Deals / same-day” art — HTML copy does not promise that.

---

## 1. What this product is

Android-first. Browse Flipkart/Amazon **card deals** → Accept → order to Mintzer address → proof in app → **48 working hours** payout to bank (no holidays). Wallet is history. **No withdraw.**

Live today: Play **`com.mintzer`** + Laravel **`newapp`** (`app.mintzer.in`). This repo is **specs + locked HTML demo + Flutter app**. The HTML demo is **not** the Play app.

**Naming:** **V2** = live Play holder app · **V3** = new Flutter client (same package update).

---

## 2. Do not crash on update (LOCKED)

This is the main engineering constraint.

| Rule | Why |
|------|-----|
| Keep applicationId **`com.mintzer`** + the **same signing key** | A new package is a new app. Users would not get an update. Orders would look “gone.” |
| **Old holder app source is not required** | Orders and users live in `newapp`. Rebuild the UI in Flutter. You **do** still need Play Console + the **upload/signing keystore** for `com.mintzer`. |
| **Do not** upload `mintzer-designer-taste-demo.html` to Play | Demo is a spec, not the APK. |
| **`forceUpdateEnabled: false`** until the new APK can open a **real old order** without crashing | Flexible Play update only until then. |
| Orders live in **`newapp.orders`**, not in the APK | Update is a new viewer of the same rows. |
| Mapper: never crash on missing fields | No user note, no photo, no parcel_received, no 48h column, tickets have no `order_id`. Hide empties. |
| Never re-ask Order ID if `store_order_id` is set | Old flow already captured it. |
| APIs **additive only** | Old APK still in the wild if they tap Not now. |
| **No user merge. No force PAN on update.** | Same phone = same user. Old app had no PAN; Home/Orders/Wallet still work. PAN = usual **first new Accept**. |
| Legacy invoice unlock after OTP | No Confirmation wait on live rows (`flowVersion = 1`). New accepts after deploy get `flowVersion = 2`. |
| Keep Pine Lab orders | Screenshot path, not GST tracking/OTP. |
| **Do not rebuild `newapp` from scratch** | Extend for V3; leave V2 notify paths unless owner explicitly silences them. |

**Full mapper:** [backend- for developer reference/11-live-order-migration.md](./backend-%20for%20developer%20reference/11-live-order-migration.md)  
**Backend vs Flutter audit:** [13-backend-vs-flutter-audit.md](./backend-%20for%20developer%20reference/13-backend-vs-flutter-audit.md)  
**Play update vs V3 push (22 Sep):** [14-v3-play-update-audit.md](./backend-%20for%20developer%20reference/14-v3-play-update-audit.md) — engineering Ready.  
**Full Flutter↔backend wire matrix (22 Sep night):** [16-flutter-backend-deep-wire-audit.md](./backend-%20for%20developer%20reference/16-flutter-backend-deep-wire-audit.md).  
**Owner phone checklist:** [15-play-update-must-test.md](./backend-%20for%20developer%20reference/15-play-update-must-test.md) — **do before Play upload**.

**Must-test before Play (three live rows):**

1. Tracking due  
2. Invoice due  
3. Already paid  

If any of those crash or blank-screen, **do not** ship.

**Engineering evidence (22 Sep eve):** mapper + Order detail + Wallet widget tests green on Hostinger shapes; debug APK launches on Samsung (no FATAL). **Owner still must** Profile → Load must-test → open the three + Wallet. Full wire/add matrix: [14-v3-play-update-audit.md](./backend-%20for%20developer%20reference/14-v3-play-update-audit.md).

---

## 3. What is LOCKED (do not restyle / re-debate)

**Visual source:** `assets/mockups/mintzer-designer-taste-demo.html` (UI locked **2026-09-18**; Home card **style B** locked same day).  
**Home spec:** [screens/02-home.md](./screens/02-home.md). `home-samples.html` is historical.  
**Master log:** [COMPLETE-DECISIONS-LOG.md](./COMPLETE-DECISIONS-LOG.md).

**SAFETY — 21 Sep:** All Flutter screens already marked LOCKED below stay LOCKED. **Do not restyle** Login · OTP · intro · Home · Deal · Place order · Success · Orders · Order detail · Wallet · Profile · FAQ · Tickets · Suspended · Deleted · KYC/Payout · GST overlays · toasts · filters · language bar. **Notifications inbox LOCKED 21 Sep** to live demo. Adaptive launcher icons are product chrome — keep purple `#7B61FF` + white mark.

### Product

- Bottom nav: **Home · Orders · Wallet · Profile** — no Offers.
- **Profile LOCKED (20 Sep 2026):** tight hierarchy — Name+phone · **Edit** / Account details sheet (photo · name locked after PAN · Change phone OTP) · compact refer · Account/Preferences/Support/Legal · notification prefs · Video tutorials · quiet Delete · camera on avatar. `profile_screen.dart` + `edit_account_sheet.dart`. Do not restyle without approval.
- **FAQ LOCKED (20 Sep 2026):** subtitle · Search FAQs · Popular questions · one card per category (compact rows) · expanded purple wash · Still need help → Contact support. Terms: Earn · Bank cashback · Mintzer payout · Wallet. `faq_screen.dart`. Do not restyle without approval.
- **My tickets LOCKED (20 Sep 2026):** inbox — Open/Resolved segment · compact cards · one status face · unread Support replied + preview · quiet + New ticket · no bottom help filler. Spec: [screens/13-my-tickets.md](./screens/13-my-tickets.md).
- **Notifications inbox LOCKED (21 Sep 2026):** bell list · Clear wipes · no archive · deep links later. Spec: [screens/14-notifications.md](./screens/14-notifications.md). Do not restyle without approval.
- **Push templates FINAL LOCKED (22 Sep 2026):** Engagement-first — every go-live + every re-live · tight view follow-ups (30–60m + ~1.5h) · multi-day still-live heavy · ≥30 variants/bank. Short rules — [NOTIFICATION-TEMPLATES-LOCKED.md](./design/NOTIFICATION-TEMPLATES-LOCKED.md). Banks — [NOTIFICATION-TEMPLATE-BANKS-LOCKED.md](./design/NOTIFICATION-TEMPLATE-BANKS-LOCKED.md). Brave: matching `.html` files.
- **V3 push engine LIVE (22 Sep evening):** FTP’d engagement stack · SQL tables OK (`deal_views` + `templates`) · tick returns all 18 banks · templates.json on server (no APK for copy). Deploy notes: [13-v3-push-engagement-deploy.md](./backend-%20for%20developer%20reference/13-v3-push-engagement-deploy.md). Script: `scripts/upload-v3-engagement-ftp.ps1`. Backups: `_hostinger_explore/backups/v3-engagement-*`.
- **Account deleted:** `/account-deleted` after Profile delete (not straight to login).
- **Wallet LOCKED (20 Sep 2026):** ChatGPT side-by-side Total earned · Pending · Transactions + Excel download (CSV mock) · date range · All/Paid/Pending/Canceled · product rows. **No** withdraw · Available · PDF · timeline. `wallet_screen.dart`. Do not restyle without approval.
- Login: **phone + OTP only**. No KYC, name, email, guest, referral.
- **Login LOCKED (20 Sep 2026):** Welcome to Mintzer · Accept orders. Earn rewards. · benefit row · unified +91 · Get OTP · Terms/Privacy · compact lang · wave. Do not restyle without approval.
- **OTP LOCKED (20 Sep 2026):** Enter OTP · squares · Verify · Resend · auto-submit · SMS autofill. Do not restyle without approval.
- **Post-login intro LOCKED (20 Sep 2026):** scale · check · Made in India · ~1.8s → Home. Do not restyle without approval.
- **My Orders list LOCKED (20 Sep 2026):** compact cards · 4-stage rail · whole-card tap. `orders_screen.dart`.
- **Order detail LOCKED (20 Sep 2026):** expanded stage · Report · earnings · Paid receipt. `order_detail_screen.dart`.
- **Deal detail LOCKED (20 Sep 2026):** Payment summary + TDS · swipe Accept · GST teal strip. `deal_detail_screen.dart`.
- **First Accept KYC + Payout LOCKED (20 Sep 2026):** Step 1 PAN → Step 2 payout. Spec: [BANK-AND-PAYOUT-DETAILS.md](./design/BANK-AND-PAYOUT-DETAILS.md).
- **Account suspended LOCKED (20 Sep 2026):** soft copy · phone `0000`.
- **Order success LOCKED (20 Sep 2026):** celebration · promo rotator · no OID card.
- **Place order LOCKED (20 Sep 2026):** address · timer dock · You pay/earn · step rail. `place_order_screen.dart`.
- **Home Active order strip LOCKED (20 Sep 2026):** green · countdown · Continue.
- **GST deal flow LOCKED (20 Sep 2026):** Accept modal 1·2·3 · invoice GST checklist.
- KYC: **PAN only**, **first Accept**. Not at login. Not as an update wall.
- Wallet: Total earned + Pending. **No Available. No withdraw.**
- One active placement. Timer from admin config.
- Payout: **48 working hours**. No payouts on bank holidays.
- App purple **`#7B61FF`**. No orange competitor UI.
- **Push product (21 Sep):** V3 = **automatic on events** (not admin Notify click). Manual bell = V2-era leftover. Soft OS permission after first Accept only.

### Screens / chrome (unchanged locks)

- Deal detail: WA report chip · magnetic Swipe to accept.
- Place order TEST dock: You pay \| You earn · ring timer · Generate new address.
- Order detail flow line: purple in progress · green when paid · pulsing current.
- Payout cheers: one line per visit.
- Language: **LOCKED 5 EN** `EN` · `हि` · `ಕಾ` · `മല`.
- Home deal card **style B** / ChatGPT hierarchy rules — do not reopen.
- Adaptive icons (21 Sep): FG white mark transparent · BG `#7B61FF` · `ic_stat_mintzer` for status bar.

---

## 4. What we did (21–22 Sep) — do not lose

### 22 Sep morning (push + templates)

| Done | Where / notes |
|------|----------------|
| FCM send project fix | `Common.php` · Send Notification · cron · deals → **`mintzer-e45d6`** |
| Ticket reply → tray + chat deep link | `CustomerController::ticketReply` · `PushRouter` |
| Bell Clear = server delete | `updatenotifications?action=clear` |
| **Templates catalog LOCKED** | [design/NOTIFICATION-TEMPLATES-LOCKED.md](./design/NOTIFICATION-TEMPLATES-LOCKED.md) |
| FTP | `scripts/upload-push-fcm-ftp.ps1` |

### 21 Sep night

| Done | Where / notes |
|------|----------------|
| Adaptive + notification icons | `scripts/gen-adaptive-icons.py` · mipmaps · `ic_stat_mintzer` · monochrome |
| Firebase = existing Mintzer project | `mintzer-e45d6` · Android `com.mintzer` · `app/android/app/google-services.json` |
| FCM in Flutter | `firebase_core` · `firebase_messaging` · `flutter_local_notifications` · `PushBootstrap` |
| Soft notif permission | Already: after Accept · Profile toggles |
| Session persist | `SessionStore` — login/KYC/payout/prefs survive app kill |
| Live `/fcm-update` | After OTP + launch |
| **V3 push engine (additive)** | `App\Services\V3Push\*` · `V3PushController` · routes `/api/v3/push/*` |
| SQL `v3_push_*` tables | Created on live DB via one-shot migrator (script deleted) |
| V3 auto on **deal create** | `DealsController@store` soft-calls `V3DealLiveService` — **no bell** |
| Manual Notify bell | Left **V2-only** (topic) |
| Hostinger FTP explore | `_hostinger_explore/newapp/` · backups under `_hostinger_explore/backups/` |
| Backend vs UI audit | [13-backend-vs-flutter-audit.md](./backend-%20for%20developer%20reference/13-backend-vs-flutter-audit.md) |
| V3 push doc | [12-v3-push-engine.md](./backend-%20for%20developer%20reference/12-v3-push-engine.md) |
| Test push received | “Mintzer V3 push” confirmed on device |

**Earlier (still true):** locked live demo · Flutter UI mock wrap · live OTP · soft push ask · Play review · place-order expiry fix · courier empty default · mintzer.in live.

---

## 5. Source of truth (what to open)

| Need | File |
|------|------|
| **This handoff** | `docs/STATUS.md` (this file) |
| Agent process | `docs/AGENT-DEV-PROCESS.md` |
| Every locked decision | `docs/COMPLETE-DECISIONS-LOG.md` |
| Screen list + LOCKED flags | `docs/screens/SCREEN-INVENTORY.md` |
| Live demo (Brave only) | `assets/mockups/mintzer-designer-taste-demo.html` |
| **Backend ↔ Flutter audit** | `docs/backend- for developer reference/13-backend-vs-flutter-audit.md` |
| V3 push engine | `docs/backend- for developer reference/12-v3-push-engine.md` |
| **Push templates (LOCKED · short)** | `docs/design/NOTIFICATION-TEMPLATES-LOCKED.md` |
| **Push banks (30+)** | `docs/design/NOTIFICATION-TEMPLATE-BANKS-LOCKED.md` |
| Play orders mapper | `docs/backend- for developer reference/11-live-order-migration.md` |
| Flutter checklist | `docs/frontend/01-implementation-checklist.md` |
| **Flutter file map** | `docs/frontend/03-flutter-app-map.md` |

Markdown specs beat PNG mockups. Do not restyle locked Flutter screens.

---

## 6. TODO

### Tomorrow (22 Sep) — plan

1. **UI safety pass** — reopen STATUS + inventory; no visual changes unless owner asks.  
2. **Owner decision:** on deal create, keep V2 auto (`sendFcmNotifications`) for old users, or silence it so only V3 buzzes.  
3. **Wire one live vertical slice** (pick one):  
   - **A)** `getOrderList` → Orders + mapper (best for Play safety), or  
   - **B)** `getDealdata` → Home (best for “app feels live”).  
4. Confirm V3 device row after login (`v3_push_devices`).  
5. Only then: more V3 auto events (timer / accept-abandoned) — still additive.  
6. **Do not:** rebuild backend · restyle locked UI · enable force-update · show withdraw.

### Waiting on owner

| Blocker | Status | Unlocks |
|---------|--------|---------|
| Deal-create: V2 auto on or off? | **Ask tomorrow** | Quiet old Play vs keep legacy buzz |
| Play PEM / signing | Ready on disk — Console approval | Release AAB |
| PAN + IFSC | **Live 29 Sep** · PAN is Cashfree · IFSC is API Sathi · `panVerifyLiveEnabled = true` · keys in `Sen Info` + `.env` only | Empty provider wallet → no name / no branch |
| DLT hash | Pending | Silent OTP autofill |
| GSC indexing | Pending | Homepage snippet |

### Later

| Item | Notes |
|------|--------|
| Full API wire | Deals · accept · place · wallet · tickets · inbox |
| V3 gateway sequences | Follow-ups · quiet drain · deep links |
| Hide Simulate buttons | Before Play |
| FAQ HI/KN/ML | EN done |
| FCM project ID cleanup | `e14bd` vs `e45d6` — backup first, owner OK |

**Do not do:** Offers tab · Wallet withdraw · force PAN · dark polish · backend rewrite.

---

## 7. Goodnight notes

- FTP creds: `mintzer.in/fpt details.txt` (local) — never commit secrets.  
- Live `.env` may exist under `_hostinger_explore` — **do not commit**.  
- One-shot PHP migrators must be **deleted** after use (already done for SQL + test).  
- Install APK with `adb install -r` to avoid wiping session when possible.  
- Live demo verify: **Brave only** (`scripts/open-live-demo.ps1`).

**Morning agent:** read this file → audit doc → do **not** restyle UI → start tomorrow plan item 2–3 with owner.
