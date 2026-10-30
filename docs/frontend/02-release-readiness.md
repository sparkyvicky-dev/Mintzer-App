# Release readiness (while Play key + Verifico verification credits pending)

**Superseded for day-to-day work by [03-flutter-app-map.md](./03-flutter-app-map.md) and [../STATUS.md](../STATUS.md).** Code version is `3.0.29+30029`. PAN is Cashfree (`POST /pan-verify`). IFSC is API Sathi. `panVerifyLiveEnabled` is `true`. The notes below are the early gate list. Verifico is not the live provider.

**Package:** `com.mintzer` (locked — never change)  
**Play URL:** https://play.google.com/store/apps/details?id=com.mintzer  
**forceUpdateEnabled:** `false` until mapper proven on a real update install  

## Blocked (owner)

| Item | Status | Unlocks |
|------|--------|---------|
| Play signing key / keystore | Pending approval | Internal test AAB as real update |
| The Verifico **verification** credits | OCR key present; `/verify/pan` returns 402 until purchase | Live KYC on first Accept |

## Done offline (no key needed)

- [x] Live DB dump mapped: `Phpadmin/orders.sql` → 1147 rows, 0 crashes  
- [x] Must-test fixture asset: `app/assets/live/must_test_orders.json`  
- [x] Flutter seeds My Orders from that dump (Tracking / Invoice / Payment / Paid / Canceled)  
- [x] Mock KYC sheet (`panVerifyLiveEnabled: false`)  
- [x] Backend Verifico proxy wired (`VerificoPanService` + `POST /pan-verify`)  
- [x] `applicationId = com.mintzer` in Gradle  
- [x] `AppConfig.forceUpdateEnabled = false`  

## When key arrives

1. Put keystore under `secrets/` (gitignored) — never commit  
2. Wire `signingConfigs.release` in `android/app/build.gradle.kts`  
3. `flutter build appbundle --release`  
4. Play Console → **Internal testing** only (not production)  
5. Install as **update** on a phone that already has old app + orders  
6. Open Tracking / Invoice / Paid orders — must not crash  

## When Verifico verification credits are active

1. Confirm `POST https://api.theverifico.com/api/v1/verify/pan` with `{"pan_number":"…"}` returns 200 (not 402)  
2. Set `AppConfig.panVerifyLiveEnabled = true`  
3. Keep: no PAN wall on login / update  
4. Key stays in Hostinger `.env` only — never in the APK  

## Do not

- Change package name  
- Force-update while `forceUpdateEnabled` is false  
- Upload HTML demo to Play  
- Point unfinished build at production Hostinger write APIs  
- Put `VERIFICO_API_KEY` in Flutter / git  
