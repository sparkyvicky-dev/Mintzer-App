# Play Store Readiness Report

Date: 24 Sep 2026. Package `com.mintzer`. This report covers the Flutter app in `app/` and the live Laravel API `newapp` on Hostinger (`app.mintzer.in`). Phone checks below were not run on a device in this session.

## Executive Summary

The app is a Flutter update to the existing Play app. Version is now **3.0.12** (build **30012**). A release APK was built: `Mintzer-3.0.12.apk`.

Two server holes were fixed and uploaded after the live files were compared with this PC. A signed-in person can change only their own order. A second Accept is refused only while an order is still waiting for a store Order ID or a Pine Labs screenshot.

This is enough to install and try on a phone. It is not enough for a public Play release. The three old live orders (Tracking, Invoice, Paid) have not been opened on a phone with this build, and the Play Console build number on 2.0.15 has not been compared with 30012.

## Architecture

| Item | What it is |
|---|---|
| Client | Flutter, Dart SDK ^3.12.0 |
| Android | minSdk 24, targetSdk 36, compileSdk 37 |
| Build tools | Android Gradle Plugin 9.0.1, Kotlin 2.3.20, Gradle 9.1.0 |
| Package | `com.mintzer` |
| Version | 3.0.12, build 30012 |
| Backend | Laravel `newapp` at `https://app.mintzer.in/api` |
| Database | MySQL on the server. The app has no local SQL database |
| Local storage | Shared preferences: login token, phone, PAN, bank, push token, cached deals and orders |
| Login | Phone OTP, Sanctum token |
| Push | Firebase project `mintzer-e45d6`, FCM, local notifications. Channels: deals, orders, payments |
| Crash reports | None in the app |
| Money | No in-app card checkout and no withdraw. PAN goes through Cashfree on the server. IFSC goes through API Sathi. Payout is to the user’s bank |
| Deep links | No App Links. A notification tap is handled inside the app |
| Permissions in the app manifest | Internet, notifications, camera |

Cleartext HTTP is off. Live deals, orders, accept, tickets, and notifications are on. Demo simulate buttons are off. Force-update is off.

## Release Build Status

Release APK build **succeeded** on 24 Sep 2026.

`D:\dev\mintzer-app\Mintzer-3.0.12.apk` (about 60.6 MB).

An Android App Bundle (`.aab`) was **not** built. Play upload needs an `.aab`, not this APK. The APK is for the phone check.

Signing uses `key.properties` when that file is present. Passwords were not opened or copied into this report. If the file is missing, release builds fall back to the debug key. That file is present on this PC and is gitignored.

R8 / resource shrinking ran as part of the Flutter release build (icon font was tree-shaken). That does not prove every screen survives shrinking until the APK is used on a phone.

## Critical Issues — P0

None left in the items that were fixed and uploaded.

These were P0 and are now changed on the live server:

- Order updates checked the order number and did not check the owner. They now require the logged-in user to own the order. Checked by downloading the live file after upload. Not checked by calling the live API with a second account.
- Accept could create a second open order. It now refuses a new Accept while this user still has an order in status Placed with no store Order ID (or a Pine Labs order with no screenshot). Paid, shipped, and cancelled orders do not count. Not checked on a phone.

Still a release gate, not a code bug by itself:

- Play will reject the upload if the build number already on 2.0.15 is **30012 or higher**. That number was not read from Play Console.

## High Priority — P1

- Phone proof is still missing: login, Accept, Order ID, a second Accept, camera photo, and one old Tracking, Invoice, and Paid order.
- Expired login is not handled. Nothing in the app treats HTTP 401, so a dead session can leave the user inside the app with failing calls.
- Login, PAN, and bank details stay in normal phone storage. New Android backups are now off. Existing signed-in users are not logged out. Storage was not moved, on purpose, so this update does not wipe sessions.
- No crash reporter in the app. Play Console is the only crash view after release.
- The in-app store page allows https pages and sends UPI and phone links out of the page. This was unit-tested, not tried on a phone against Flipkart or Amazon.

## Medium Priority — P2

- Push logs can still write notification data to the phone log in release builds.
- High-importance deal and order notifications can show on the lock screen. That is normal Android behavior. They should not contain PAN or full bank details. Copy was not reviewed line by line in this pass.
- The scheduled push job on the server is still protected by a short fixed password in the server code. It was left unchanged so notifications would not stop.
- Account delete exists in Profile and on the server. A public web page for deletion was not verified.
- Tests cover order mapping, a few live JSON shapes, and the new link rules. They do not cover login, money, or order ownership.

## Low Priority — P3

- Biometric and fingerprint permissions are pulled in by the SMS autofill library. The app does not have a fingerprint login. Declare that on the Play form.
- A push “test yourself” API path exists in the app config and is not shown in the UI.
- Some plugins still apply the older Kotlin Gradle plugin. The release APK still built. A future Flutter version may refuse to build until those plugins are updated.

## Security Findings

- Live API is HTTPS. Cleartext is off.
- The upload key file and `key.properties` are gitignored. They were not printed here.
- API Sathi keys are intended to stay in server env and a local notes file, not in the APK. This report did not open those files.
- Order writes on the server now check ownership. The public deal-detail call can still be given a user id. After the ownership fix, that id cannot be used to edit another person’s order.
- Accept errors and deal-detail failures no longer return the raw server exception text.
- WebView JavaScript stays on, because store pages need it. The page will not load `http`, `javascript:`, or `file:` links.
- A `.env.live` file exists under the Hostinger snapshot folder. It was not opened. Do not commit it.

## Privacy Findings

Data the app handles, for the Play Data Safety form:

| Data | Why | Where | Third party | Delete |
|---|---|---|---|---|
| Phone number | Login OTP | App storage and server | SMS provider used by the server | Account delete |
| Name | Profile, and PAN name after verify | App storage and server | Cashfree for PAN name | Account delete. Confirm what the server keeps |
| PAN | First Accept, payout identity | App storage and server | Cashfree | Account delete. Tax rules may require the server to keep a record |
| Bank account, IFSC, UPI | Payout | App storage and server | IFSC lookup via API Sathi | Account delete |
| Order and payout history | The product | Server | No card network in the app | Account delete does not have to erase legally required payout records. Confirm with the server |
| Photos and PDF | Invoice or payment proof | Uploaded to the server | No separate photo SDK beyond the picker | Tied to the order |
| FCM token | Push | Phone and server | Google Firebase | Logout should stop using it. Token clear on logout was not re-tested |
| Notification text | Order and deal alerts | Phone tray | Firebase | User can turn types off in Profile |

No ads SDK was found. No precise location permission was found. Transmission to the API is HTTPS.

Privacy policy URL in the app: `https://mintzer.in/privacy.html`. The page text was not re-read in this session.

## Authentication Findings

- Login is phone OTP only. No password.
- The token is stored in shared preferences and restored on launch.
- Logout calls the server and still clears the local session if the network call fails.
- Account delete calls the server, then the app shows the deleted screen.
- There is no refresh-token loop in the app. A 401 does not send the user back to login.
- Same account can be used on more than one phone. The server is the source of orders. The phone cache can be stale until refresh. That is acceptable. It is not offline editing.

## Data Integrity Findings

- Own-order checks are on the live order update, cancel, delete, tracking, invoice, and payout-request paths.
- One open placement per user is enforced on Accept. A placement already confirmed with an Order ID does not block the next Accept.
- The check was not exercised with two phones at the same time.
- Deal quantity still drops when an Order ID is saved, and that save now requires ownership.
- Wallet has no withdraw button. The old withdraw API still exists for the current Play app. This update does not call it.

## Network/Offline Findings

- API calls use timeouts of about 15–30 seconds.
- Deal and order list refresh reuse an in-flight call, so a double pull does not fire two list requests.
- Accept is protected on the server against a second open order. The screen also ignores a second tap while it is busy.
- Failed writes are not shown as success. Accept shows the server message, or “Couldn’t accept deal.”
- Offline behavior, airplane mode, and slow network were **not** tested on a device.
- There is no infinite retry loop in the client code that was read. That was not proven on a device.

## Android Compatibility Findings

- minSdk 24 (Android 7). targetSdk 36. compileSdk 37.
- Google Play, from 31 Aug 2026, requires target API 36 for new apps and updates on phones. This project meets that on paper. Play Console has not accepted a bundle yet.
- No App Links. Predictive back was not tested.
- Edge-to-edge, font scale, cutouts, and small phones were **not** tested.
- Dark theme exists in code. It was not walked on a device.
- Rotation is not locked in the manifest. Layout on rotate was not tested.

## Permission Findings

| Permission | Why | Needed | If the user says no |
|---|---|---|---|
| Internet | API and store page | Yes | App cannot load |
| Notifications | Deal, order, payout alerts | Yes, asked at runtime | App still works. No tray alerts |
| Camera | Take invoice or payment photo | Yes for that button | Gallery and PDF still work. A denial shows a message instead of crashing |
| Wake lock, vibrate, network state, FCM receive | Brought in by Firebase and notifications | Normal for push | Not a user prompt |
| Biometric, fingerprint | Brought in by SMS autofill | Not a login feature | No prompt expected |

Camera was added in this pass. Runtime denial is caught on the invoice photo picker. That path was not tried on a phone.

## Performance Findings

No performance rewrite was done. Startup avoids waiting on push before the first screen. Image cache is capped. Lists were not profiled. No phone timing was measured.

## Accessibility Findings

Not fully reviewed. Touch targets and TalkBack were not run. No design change was made for this.

## Dependency Findings

Release build succeeded with the current set. Twenty packages have newer versions that were **not** upgraded. Blind upgrades were avoided.

Plugins that still use the old Kotlin plugin: `firebase_core`, `in_app_review`, `smart_auth`. They warned at build time and did not fail this APK.

No dependency vulnerability scan was run against a CVE database.

## Google Play Policy Items

Verify these in current Play Console help. They were not submitted in this session.

- Target API 36: required for phone updates after 31 Aug 2026. Project value is 36. Confirm on the uploaded bundle.
- Data safety form: use the privacy table above. Do not guess extra categories.
- Privacy policy: `https://mintzer.in/privacy.html` must be live and match the form.
- Account deletion: in-app delete exists. Play also wants a web deletion path if accounts can be created. Confirm the site has one.
- Financial features: payouts to a bank, no wallet withdraw. Declare what Console asks for India finance. This is not a loan or card-issuing app.
- Ads: none found. Declare no ads unless a tracker was added outside this review.
- News, health, families: not this app.
- SMS: the app does not read the SMS inbox. OTP autofill uses the SMS retriever / user-consent style library. Declare that if Console asks. DLT registration for the sender was still listed as pending in project notes.
- Foreground service: no special location or camera foreground service was found.
- App access: reviewers need a test phone number that can receive OTP.
- Content rating and target audience: complete in Console. Audience is adults using card deals, not children.

## Tests Performed

| Test | Result |
|---|---|
| Read architecture, manifest, API config, order server code | PASS as a code review on 23–24 Sep 2026 |
| Compare live Hostinger order files with this PC before upload | PASS. Live files matched except the safety additions |
| Upload order ownership and open-placement checks, then download them back | PASS. Live file contains those checks |
| Link rules: https allowed, http and script blocked, UPI handed out | PASS. 3 unit tests |
| `flutter build apk --release` for 3.0.12 | PASS |
| Install that APK on a phone | NOT TESTED |
| Login, OTP, logout, session restore | NOT TESTED |
| Accept, second Accept, Order ID, cancel | NOT TESTED |
| Camera photo, gallery, PDF | NOT TESTED |
| Old Tracking, Invoice, and Paid orders | MANUAL TEST REQUIRED |
| Airplane mode, slow network, 401, 500 | NOT TESTED |
| Release AAB upload to Play | NOT TESTED |
| Play pre-launch report, crashes, ANRs | NOT TESTED |
| Two phones editing one account | NOT TESTED |

## Changes Made

| File | Why |
|---|---|
| `app/pubspec.yaml` | Version 3.0.12, build 30012 |
| `app/lib/config/app_config.dart` | Profile shows v3.0.12 |
| `app/android/local.properties` | Same version for the Android build |
| `app/android/app/src/main/AndroidManifest.xml` | Camera permission. New backups turned off |
| `app/lib/util/shop_url.dart` | Decide which store links may open |
| `app/lib/screens/in_app_shop_screen.dart` | Use that rule inside the store page |
| `app/test/shop_url_test.dart` | Tests for those link rules |
| `app/lib/screens/order_detail_screen.dart` | If camera permission is denied, show a message instead of crashing |
| `_hostinger_explore/newapp/app/Http/Controllers/API/Order/OrderController.php` | Own-order checks and one open Accept. Uploaded to Hostinger |
| `_hostinger_explore/newapp/app/Http/Controllers/API/Deal/dealController.php` | Deal failure no longer returns a raw error. Uploaded to Hostinger |
| `Mintzer-3.0.12.apk` | Release APK for the phone check |

Not changed on purpose: logo, locked screens, package name, force-update, PAN on/off, login storage format, push-timer password.

A copy of the old live PHP files is in `_hostinger_explore/backups/live-crosscheck-20260924-002707/`.

## Manual Device Tests Required

Use `Mintzer-3.0.12.apk` on a phone that already has real orders if possible.

1. Install the APK. If Android refuses because the Play app is signed differently, stop. Do not uninstall the store app.
2. Open Profile and confirm it says v3.0.12.
3. If logged out: enter a real phone, receive OTP, enter it, land on Home.
4. Kill the app and open it again. You should still be logged in.
5. Open one old order that needs tracking. It must not be a blank screen or a crash.
6. Open one old order that needs an invoice. Same check.
7. Open one old order that is already paid. Same check. Open Wallet after that.
8. Accept a deal. Enter a store Order ID. Then Accept a different deal. The second Accept should work.
9. Accept once more before entering an Order ID. It should tell you to finish the current order.
10. On an invoice step, tap Take photo. Allow camera, then deny camera on a second try. Denial must not crash. Gallery and PDF must still work.
11. Turn on airplane mode and pull to refresh Home. You should see an error, not a spinner that never ends.
12. Log out. Open the app. You should be on the login screen, not still inside Home.

## Play Console Tasks

1. Open the 2.0.15 release and read its version code. It must be lower than 30012. If it is not, stop and raise the build number.
2. Build an `.aab` with the same signing key used for `com.mintzer`. Do not upload a debug-signed file.
3. Create an Internal testing release. Upload the `.aab`. Do not roll out to Production.
4. Add yourself as a tester and install from the Play link, not only from the APK.
5. Repeat the phone list above on the Play-installed build.
6. Read the pre-launch report.
7. Read crashes and ANRs after testers use it.
8. Fix anything that crashes or blocks Accept, orders, or login.
9. Move to closed testing only after those are clean.
10. Production should be a staged rollout, with force-update still off, until old orders are proven.

Also in Console, before production: Data safety, privacy policy URL, account deletion URL, content rating, financial declaration, app access (OTP test number), and ads declaration.

## Remaining Risks

- Build 30012 might still be lower than the number already on Play. That rejects the upload. It does not harm current users.
- The order rules are live for the current Play app too, because both apps use the same server. A normal user updating their own order should see no change. A test account should confirm Accept and Order ID before a wide rollout.
- Old Tracking, Invoice, and Paid screens are still the ship risk called out in project notes. They are not proven on this APK.
- No crash tool means a rare crash is invisible until Play Console, and only after a Play upload.
- A dead login token does not return the user to the OTP screen.

## FINAL RELEASE STATUS

READY FOR INTERNAL TESTING

The release APK builds, the version is 3.0.12, and the order-safety fixes are on the live server. Production is not appropriate until the phone list passes, the Play build number is confirmed, and an Internal testing bundle has been installed from Play.
