# Play update — owner must-test (crash gate)

**Do this on a phone with Flutter `com.mintzer` before Play upload.**  
Engineering checklist: [14-v3-play-update-audit.md](./14-v3-play-update-audit.md)

## Fast path (debug build on your phone)

App is (or was) installed via `flutter run` on the connected Samsung.

1. Profile → **Notifications** (prefs sheet) → scroll to **Load must-test orders (debug)**.
2. Opens Orders with Tracking · Invoice · Paid from live Hostinger export.
3. Open each card → confirm no crash → also open Wallet once.

## Must open without crash / blank screen

| # | Order type | What you should see |
|---|------------|---------------------|
| 1 | **Tracking due** | My Orders → card → detail; “Add tracking ID” (or rail at tracking) |
| 2 | **Invoice due** | Detail opens; upload / re-upload invoice path visible |
| 3 | **Already paid** | Detail opens; Paid / completed; earn looks like **profit**, not full order amount |

Optional: one Pine Lab / Instant row.

## Pass / fail
- **Pass:** all three open, no red screen, no freeze, back to list works, Home still loads.
- **Fail:** any crash or blank → **do not** upload to Play.

## After pass
1. Keep `forceUpdateEnabled: false` for first flexible roll-out.
2. Upload AAB with **existing** Play signing key for `com.mintzer`.
3. Then engagement push reaches updaters via dual FCM register.

## Already verified in CI / Hostinger (no need to re-prove)
- Mapper unit tests (fixtures + live tracking/invoice/paid shapes)
- Widget: Order detail opens for all 3 live shapes without exception
- Widget: Wallet opens with those shapes without exception
- Cron/Deals FCM → `mintzer-e45d6` via `fcmProjectId()`
- V3 live/relist/timers/payout hooks on server
- Splash does not await FCM (`main.dart` runApp-first)
- Live `orderDataFormat` includes `store_order_id` (Orders/Wallet IDs)
- Home tutorial: one ✕ hides this session; shows up to 2 visits total
