# V3 Notification Engine — additive (does not replace V2)

**Goal:** Flipkart-grade orchestration for the new Flutter app, **without breaking** live Play V2 pushes.

## Isolation rule

| Path | Used by | Touch? |
|------|---------|--------|
| `HolderNotifyService`, `CronjobController` FCM, `users.fcm_token`, `POST /fcm-update` | **V2 Play** | **Do not change behavior** |
| `AdminPushService` / `admin_device_tokens` | Admin app phones | Leave alone |
| **New** `App\Services\V3Push\*` + tables `v3_push_*` + routes `/api/v3/push/*` | **Flutter V3 only** | Build here |

V2 keeps working even if V3 tables are empty or `MINTZER_V3_PUSH=0`.

## Engine pieces

1. **Devices** — `v3_push_devices` (multi-device; `app_channel=flutter_v3`)
2. **Prefs** — `v3_push_prefs` (master + deals / orders / payments)
3. **Outbox** — `v3_push_outbox` (queued sends, status, cancel)
4. **Gateway** — engagement-first caps (every live/relist · tight view follow-ups · still-live · 20–30m min gap · soft ~8–12/day) from [NOTIFICATION-TEMPLATES-LOCKED.md](../design/NOTIFICATION-TEMPLATES-LOCKED.md)
5. **Sender** — reuse same Firebase project `mintzer-e45d6` via thin client (does not edit `AdminFcmClient`)
6. **Triggers (V3 only)** — `deal.live`, `deal.relist`, viewed follow-ups, still-live; **not** wired into V2 cron by default

## Rollout

1. Run SQL (create tables only)
2. Upload new PHP files + additive routes
3. Keep `MINTZER_V3_PUSH` optional; deal broadcast via `/api/v3/push/deal-live` (sanctum admin or internal later)
4. Flutter registers to `/api/v3/push/register` **and** keeps `/fcm-update` so V2 column still updates if needed

## Automation model (locked)

**No manual “click Notify” for V3.** Ops create/update state → server fires push.

| Event | V3 behavior |
|-------|-------------|
| Deal created / goes live | **Auto** `deal.live` → `v3_push_devices` |
| Same deal off → on again | **Auto** `deal.relist` (separate bank) |
| View deal · leave · no Accept | Tight follow-ups 30–60m + ~1.5h |
| Deal still ON day 2–3 | Still-live heavy (2–3/day or 8–12h) |
| Manual admin bell | **V2 only** (topic) — left alone |
| Order / invoice / tracking / OTP / payout | Still auto via existing `HolderNotifyService` → `users.fcm_token` (Flutter registers that too). Later: route through V3 gateway for prefs/caps |

V3 = futuristic orchestration. V2 paths stay until Play users are fully on Flutter.
