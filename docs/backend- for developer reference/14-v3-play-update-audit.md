# Backend vs Flutter V3 — crash-safe Play update audit

**Date:** 22 Sep 2026 (refreshed evening). **29 Sep:** live PAN is Cashfree, not API Sathi. Current flow is [03-flutter-app-map.md](../frontend/03-flutter-app-map.md).  
**Owner goal:** All Play users update to Flutter (`com.mintzer`) **without crash**. Same `newapp`. Engagement push phased.

**Related:** [STATUS.md](../STATUS.md) §2 · [11-live-order-migration.md](./11-live-order-migration.md) · [12-v3-push-engine.md](./12-v3-push-engine.md) · [13-v3-push-engagement-deploy.md](./13-v3-push-engagement-deploy.md) · [13-backend-vs-flutter-audit.md](./13-backend-vs-flutter-audit.md) (older snapshot — **this file wins**) · [15-play-update-must-test.md](./15-play-update-must-test.md)

---

## Go / no-go (evidence)

| Gate | Evidence | Status |
|------|----------|--------|
| Package `com.mintzer` + Firebase `mintzer-e45d6` | `build.gradle.kts` · `google-services.json` | **Ready** |
| `forceUpdateEnabled: false` | `app_config.dart` | **Ready** |
| Null-safe mapper + live Hostinger shapes | `flutter test test/order_mapper_test.dart` → **21 green** | **Ready** |
| Order detail opens tracking / invoice / paid | `test/order_detail_live_shapes_test.dart` → **green** | **Ready** |
| Wallet opens with those shapes | `test/wallet_live_shapes_test.dart` → **green** | **Ready** |
| Splash never waits on FCM | `main.dart` — `runApp` before `PushBootstrap`; timeouts on hydrate | **Ready (22 Sep night)** |
| `getOrderList` returns `store_order_id` | Live `Common.php` `orderDataFormat` (FTP verified) | **Ready (22 Sep night)** |
| Debug APK cold start on Samsung | `am start -W` TotalTime ~1.6s · Flutter paints Login/Home | **Ready (smoke)** |
| Dual FCM register | `PushBootstrap` → `/fcm-update` + `/v3/push/register` | **Ready** |
| No force PAN on update | KYC only on Accept · `cashfreeLiveEnabled: false` | **Ready** |
| Live Cron / Deals FCM project | `fcmProjectId()` · no hardcoded `e14bd` | **Verified** |
| V3 tick (drain / still-live / timers) | `GET /api/v3/push/tick` | **Verified** |
| Play signing keystore | Ops — not in repo | **Owner** |
| **Owner phone must-test** (Profile → Load must-test → open 3 + Wallet) | [15-play-update-must-test.md](./15-play-update-must-test.md) | **Ship gate** |

**Ship rule:** Flexible Play update when Ready rows are green **and** owner must-test passes. Keep `forceUpdateEnabled: false` until wild proof.

---

## Verdict

| Question | Answer |
|----------|--------|
| Rebuild backend? | **No** |
| Crash-safe update blocked on backend rewrite? | **No** — blocked on **owner device must-test** + signing key |
| Do we need new backend APIs for crash-safe update? | **No** — orders already in `newapp`; mapper + live `getOrderList` enough |
| What still needs backend *adds*? | Almost nothing for ship — see §C. PAN (Cashfree) and bank save are already wired. |
| All Play users get V3 live/relist today? | **No** — only after they update + open app (`v3_push_devices`) |
| Engagement wiring clear + phased? | **Yes** — §B + §D |

---

## A. Crash-safe path (what “all users update without crash” needs)

```
Play update (same com.mintzer + signing key)
  → Flutter opens
  → Sanctum login (existing phone) OR already signed in
  → getOrderList → null-safe mapper → Orders / Order detail / Wallet
  → Missing new fields stay empty (never throw)
  → forceUpdate OFF · no PAN wall · no withdraw
```

**Not required for crash-safe update:** Cashfree live PAN, silence V2 deal-create, new wallet API, backend rebuild.

---

## B. Push matrix (phased)

| Event | Path | Status |
|-------|------|--------|
| deal.live (create) | V2 `fcm_token` + V3 devices | **Both** (silence V2 later) |
| deal.relist (OFF→ON) | V3 | **Live** |
| View follow-ups / still-live | V3 outbox + cron tick | **Live** |
| Order ID / tracking cron | V2 via `fcmProjectId()` → e45d6 | **Live** |
| OTP / invoice / ticket | V2 HolderNotify / Common | **Live** |
| payout_sent | `V3PayoutNotifyService` on approve | **Live** |
| timer 5m / 1m | `V3PlacementTimerService` in cron/tick | **Live** |
| Manual topic Notify | V2 ops | **Keep** |

Flutter dual-registers so V2 order cron + V3 deals both reach updaters.

---

## C. ADD / WIRE / KEEP / DEFER (deep)

### Already on backend — Flutter **WIRED** (flags on in `app_config.dart`)

| Area | Live API | Flutter |
|------|----------|---------|
| Auth | `/sendotp` · `/verify-otp` | Wired |
| Home deals | `/getDealdata` · banners | Wired (`useLiveDealsApi`) |
| Accept / place | `/accept-order` · `/update-order-id` · `/auto-delete-order` · address on detail | Wired |
| Orders list | `/getOrderList` + mapper | Wired (`useLiveOrdersApi`) — **22 Sep:** `orderDataFormat` now includes `store_order_id` (+ store/offer/OTP/UTR) |
| Order writes | tracking · OTP · invoice · cancel | Wired |
| Tickets | get/add/reply/close/subjects | Wired |
| Bell inbox | get/update notifications | Wired |
| Profile read | `/getuserprofile` · `/getBankDetail` | Wired (read) |
| Dual FCM | `/fcm-update` + `/v3/push/register` · prefs · deal-view | Wired |
| V3 engagement stack | tables + tick + live/relist/follow-ups/still-live/timers/payout | **Live on Hostinger** |

### Flutter still **MOCK / local** — wire to **existing** APIs (no new backend)

| Item | Existing API | Notes |
|------|--------------|-------|
| PAN verify | `/pan-verify` | **Live** Cashfree · `panVerifyLiveEnabled: true` |
| IFSC → bank name | `/ifsc-lookup` | **Live** API Sathi · card only after a valid IFSC |
| Wallet rows | derived from orders | **Do not** call `/withdraw-request` |

**Wired 22 Sep night:** `POST /updateBankDetail` (payout sheet) · Home greeting from `profileDisplayName` · Order detail Order ID edit → `update-order-id`.

### Backend **ADD** — done for V3 (do not rebuild)

| Item | Status |
|------|--------|
| `v3_push_*` tables + routes | Done |
| Template banks JSON/DB | Done |
| Gateway caps · prune dead tokens · live/relist gap exempt | Done |
| `V3PayoutNotifyService` · `V3PlacementTimerService` | Done |
| Cron/Deals → `fcmProjectId()` (e45d6) | Done |

### Do **NOT** add / do not wire

- Offers tab · Wallet withdraw UI · force PAN on login/update  
- New order history store · rebuild `newapp`  
- Social login in Flutter  
- Force-update until owner must-test + wild proof  

### DEFER (after most users on Flutter)

| Item | When |
|------|------|
| Silence V2 deal-create auto FCM | Phase 2 — avoid double tray |
| Route order/OTP pushes through V3 gateway prefs | Nice-to-have |
| `forceUpdateEnabled: true` | Only if leftover V2 breaks engagement |
| Cashfree live PAN | **Live 29 Sep** |

---

## D. Ship phases

```
Phase 0 ✅  FCM e45d6 + V3 drain/timers/payout on Hostinger
Phase 1 ⏳  Owner must-test (3 shapes + Wallet) → flexible Play (force OFF)
Phase 2     Most on Flutter → optional silence V2 deal-create
Phase 3 ✅  payout_sent + placement timers
Phase 4     Cashfree PAN is live · force-update only if needed
```

---

## E. Evidence commands (re-run anytime)

```powershell
cd D:\dev\mintzer-app\app
flutter test test/order_mapper_test.dart test/order_detail_live_shapes_test.dart test/wallet_live_shapes_test.dart
flutter install --debug -d <samsung>
# Profile → Notifications → Load must-test orders → open Tracking · Invoice · Paid · Wallet
```

Wireless `integration_test` on this Samsung has been flaky (hang / exit 79). Prefer widget tests + Profile tile for the ship gate.

---

## Bottom line

**No backend rewrite for a crash-safe update.** Core money APIs already exist and Flutter already calls them. V3 push is additive and live.  

**Ship blocker:** you open Tracking / Invoice / Paid (+ Wallet) on the debug build via Profile must-test, then upload AAB with the existing `com.mintzer` signing key — still with **force update off**.
