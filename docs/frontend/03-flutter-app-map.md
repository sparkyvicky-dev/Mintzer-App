# Flutter app map

**Last written:** 29 Sep 2026  
**Code:** `app/` · package **`com.mintzer`** · version **`3.0.29+30029`** (`app/pubspec.yaml`, label also in `AppConfig.versionLabel`)  
**Live API:** `https://app.mintzer.in/api` (`app/lib/api/api_config.dart`)  
**UI lock:** do not restyle. Visual source is `assets/mockups/mintzer-designer-taste-demo.html`. Screen rules stay in `docs/screens/` and `docs/STATUS.md`.

This file is the inventory of the Play app. Specs still win on product rules. If this map and an older frontend doc disagree, this map is the one that matches the code.

---

## What the app is

Android-only Flutter client for the live Play app. Same package and same `newapp` backend as the old holder app. Users log in with phone + OTP, browse card deals, accept, place the store order to a Mintzer address, send proof, and see earnings in Wallet. There is no withdraw button.

Platforms that are not the product were removed on 25 Sep 2026: the default **web** scaffold and the **Windows** runner (including its plugin copies). Android is the only platform folder.

Base URL: `https://app.mintzer.in/api`. Signed-in calls send the Sanctum token. PAN and IFSC keys stay on the server.

## Live flow and API

Checked against `app/lib/api/api_config.dart` and live `newapp` on 29 Sep 2026. PAN on the server is Cashfree. IFSC is API Sathi.

```
Phone + OTP
  POST /sendotp
  POST /verify-otp
  POST /fcm-update
  POST /v3/push/register
    → Home

Home
  GET /getDealdata
  GET /getbanners
  GET /business-configuration
  POST /home-popup-seen          once the person closes an app-open alert
    → Deal detail
  GET /getDealDetail
    → Swipe Accept
  POST /accept-order

First Accept only, when PAN or payout is missing
  POST /pan-verify               Cashfree name. Sheet shows the name only.
  POST /ifsc-lookup              API Sathi bank + branch
  POST /updateBankDetail         9–18 digit account. UPI optional.
    → Place order
  POST /update-order-id
    → My Orders
  POST /getOrderList
  POST /update-tracking-id
  POST /update-outfordelivery
  POST /update-invoice-delivery
  POST /cancel-order
  GET  /cancel-reasons
  POST /auto-delete-order

Wallet
  No wallet API and no withdraw. Rows come from paid orders.

Profile
  GET  /getuserprofile
  POST /updateProfile
  POST /updateProfileImage
  GET  /getBankDetail
  POST /change-phone
  POST /verify-change-phone
  GET  /getReferralSettings
  POST /logout
  POST /deleteAccount

Also signed in
  GET/POST /v3/push/prefs
  POST /v3/push/deal-view
  POST /v3/push/cancel-view-followups
  GET  /getBanks                 partner cards
  GET  /getnotifications
  POST /updatenotifications
  POST /addnewticket
  POST /addticketreply
  POST /closeticket
  GET  /getticket
  GET  /getsubjects
```

`POST /pan-verify` order on the server: Cashfree if `CASHFREE_PAN_ENABLED` is on, else PowerAPI, else API Sathi. A Cashfree error is returned to the app. It does not switch provider. An account that already has a PAN and a PAN name is not sent upstream again. Same name is cached 30 days. Caps, IST day: 3 checks per user and per phone, 150 for the app, and a second tap within 20 seconds is rejected.

Login does not ask for PAN. A Play update does not ask for PAN. The first new Accept does.

---

## How to run

From `app/`:

```
flutter pub get
flutter run
```

Release bundle (owner uploads by hand; do not ship Production unless asked):

```
flutter build appbundle --release
```

Signing uses `app/android/key.properties` (gitignored). Do not commit it, `.env`, or `Sen Info\`.

`AppConfig.forceUpdateEnabled` stays **false**. The in-app prompt is a flexible Play update only.

---

## Release flags (`app/lib/config/app_config.dart`)

| Flag | Value | Meaning |
|------|--------|---------|
| `packageId` | `com.mintzer` | Must not change. A new id is a new Play app. |
| `versionLabel` | `3.0.29` | Shown in Profile. Must match `pubspec.yaml`. |
| `forceUpdateEnabled` | `false` | Flexible update only. |
| `panVerifyLiveEnabled` | `true` | `POST /pan-verify`. Server calls Cashfree and returns the name only. |
| `showSimulateControls` | `false` | Demo parcel / invoice / paid buttons stay off for Play. |
| `useLiveDealsApi` | `true` | Home from `getDealdata`. |
| `useLiveOrdersApi` | `true` | Orders from `getOrderList` when signed in. |
| `useLiveAcceptApi` | `true` | Accept and place-order writes hit `newapp`. |
| `useLiveTicketsApi` | `true` | Tickets from live endpoints. Empty order id and empty thread stay hidden. |
| `useLiveNotificationsApi` | `true` | Bell from `getnotifications`. |
| `useLiveDumpFixtures` | `false` | Bundled SQL dump. Engineering only. |

Public links in the same file: terms, privacy, mintzer.in, community WhatsApp group, support `wa.me/918248626422`, YouTube tutorial.

---

## Startup (`app/lib/main.dart`)

`main` loads session, deal cache, orders, banners, tickets, and notifications with a **2 second** cap each, then `runApp`. Push and the live refresh run **after** the first frame so the logo splash cannot stick. Image cache is capped (~160 MB) so Home and Orders do not blink.

Route table is `app/lib/app.dart`:

| Route | Screen |
|-------|--------|
| `/login` | Login |
| `/login/otp` | OTP (`OtpRouteArgs` or a phone string) |
| `/intro` | Post-login intro |
| `/suspended` | Account suspended |
| `/account-deleted` | After Profile delete |
| `/main` | Bottom nav shell |
| `/debug/must-test` | Debug builds only |

Signed-in users open `/main`. Everyone else opens `/login`. Theme follows `MockSession.themeMode`. Copy follows `LangHost` (EN · हि · ಕಾ · മല).

---

## `app/lib` — every file

### Root

| File | Role |
|------|------|
| `main.dart` | Startup, cache caps, then `MintzerApp`. |
| `app.dart` | `MaterialApp`, theme, language, routes. |

### `screens/`

| File | Role |
|------|------|
| `login_screen.dart` | Phone + Get OTP. Locked. |
| `otp_screen.dart` | OTP squares, resend, SMS autofill. Locked. |
| `otp_route_args.dart` | Phone + in-flight send passed into OTP. |
| `intro_screen.dart` | Short Made-in-India intro, then Home. Locked. |
| `shell.dart` | Bottom nav Home · Orders · Wallet · Profile, help chip, update bar. |
| `home_screen.dart` | Deal list, filters, banners, active-order strip. Locked card style B. |
| `deal_detail_screen.dart` | Payment summary, TDS, swipe Accept, GST strip. Locked. |
| `place_order_screen.dart` | Address, timer dock, You pay / You earn, step rail. Locked. |
| `in_app_shop_screen.dart` | In-app store WebView. `http` and script links blocked. |
| `order_success_screen.dart` | Celebration and one promo line per visit. Locked. |
| `orders_screen.dart` | Compact order cards and 4-stage rail. Locked. |
| `order_detail_screen.dart` | Stage detail, report, earnings, paid receipt, 3-dot on ongoing orders. Locked. |
| `wallet_screen.dart` | Total earned, pending, transactions. No withdraw. Locked. |
| `profile_screen.dart` | Account, prefs, support, legal, delete. Locked. |
| `payout_details_screen.dart` | Payout details entry. |
| `faq_screen.dart` | Search, popular, one card per category. Locked. |
| `tickets_screen.dart` | Open / Resolved inbox. Locked. |
| `ticket_detail_screen.dart` | One ticket thread. |
| `notifications_screen.dart` | Bell list. Clear wipes. Locked. |
| `partner_cards_screen.dart` | Partner card apply list. On-plan banks, reward, lounge. |
| `partner_apply_screen.dart` | Bank apply page inside the app. Sends the Apply tap. |
| `account_suspended_screen.dart` | Soft suspended copy. Locked. |
| `account_deleted_screen.dart` | After delete. Not a jump straight to login. |
| `debug_must_test_gate_screen.dart` | Debug-only must-test order opener. Not in release routes. |

### `widgets/`

| File | Role |
|------|------|
| `deal_card.dart` | Home card. Style B is the locked look. |
| `deal_image_gallery.dart` | Deal photos, GST chip, letter fallback. |
| `product_thumb.dart` | Small product image. |
| `product_image_cache.dart` | Cached network product photos. |
| `money_summary_card.dart` | You pay / fees / earn. |
| `swipe_to_accept.dart` | Magnetic Swipe to accept. |
| `report_chip.dart` | Deal-detail WhatsApp report chip. |
| `order_progress_rail.dart` | Order stage rail. |
| `home_promo_carousel.dart` | Home banner strip. |
| `home_filter_sheet.dart` | Store / card filters. |
| `suggest_deal_sheet.dart` | User deal suggestion. |
| `kyc_sheet.dart` | First-Accept PAN. Name only. |
| `payout_account_sheet.dart` | IFSC + account. Bank found only after a real lookup. |
| `edit_account_sheet.dart` | Photo, name lock after PAN, change phone OTP. |
| `help_ticket_sheet.dart` | Help chip → ticket. |
| `raise_ticket_sheet.dart` | New ticket. |
| `mintzer_dialogs.dart` | Note, shop mode, GST steps. |
| `mintzer_toast.dart` | Toasts. |
| `mintzer_refresh.dart` | Pull to refresh. |
| `image_alert_popup.dart` | App-open and deal image alerts. |
| `play_update_prompt.dart` | Flexible Play update: Update available / Not now. |
| `lang_rail.dart` | EN · हि · ಕಾ · മല. |
| `brand_mark.dart` | Circular store / card mark. |
| `whatsapp_icon.dart` | Bundled WhatsApp PNG. |

### `api/` — HTTP to `newapp`

| File | Role |
|------|------|
| `api_config.dart` | Base URL and every path (table below). |
| `auth_api.dart` | `sendotp`, `verify-otp`. |
| `deals_api.dart` | Deal list and detail. |
| `placements_api.dart` | Accept. Returns `DealDetailLive` and `AcceptOrderResult`. |
| `order_writes_api.dart` | Order ID, tracking, out for delivery, invoice, cancel. |
| `orders_api.dart` | `getOrderList`. |
| `banners_api.dart` | Banners and home popup. |
| `profile_api.dart` | Profile, photo, logout, delete, change phone. |
| `banks_api.dart` | Bank / partner card list. |
| `tickets_api.dart` | Subjects, list, create, reply, close. |
| `notifications_api.dart` | Bell list and clear. |
| `logistics_api.dart` | Courier list. |

Paths in `ApiConfig`: `/sendotp`, `/verify-otp`, `/fcm-update`, `/v3/push/register`, `/v3/push/prefs`, `/v3/push/test-self`, `/v3/push/deal-view`, `/v3/push/cancel-view-followups`, `/getOrderList`, `/getBankDetail`, `/updateBankDetail`, `/getuserprofile`, `/updateProfile`, `/updateProfileImage`, `/logout`, `/deleteAccount`, `/getDealdata`, `/getDealDetail`, `/getbanners`, `/home-popup-seen`, `/getBanks`, `/getReferralSettings`, `/change-phone`, `/verify-change-phone`, `/accept-order`, `/update-order-id`, `/update-tracking-id`, `/update-outfordelivery`, `/update-invoice-delivery`, `/cancel-order`, `/cancel-reasons`, `/auto-delete-order`, `/getLogistics`, `/addnewticket`, `/addticketreply`, `/closeticket`, `/getticket`, `/getsubjects`, `/getnotifications`, `/updatenotifications`, `/pan-verify`, `/ifsc-lookup`, `/business-configuration`.

### `live/` — map `newapp` JSON onto the locked UI

| File | Role |
|------|------|
| `deals_repository.dart` | Home deals + phone cache. |
| `live_deal_adapter.dart` | Deal JSON → `MockDeal`. |
| `orders_repository.dart` | Order list + cache. |
| `live_order_adapter.dart` | Order JSON → UI order. |
| `live_order_json.dart` | Loose JSON reads. Never throw on a missing field. |
| `live_order_row.dart` | One raw order row. |
| `order_mapper.dart` | Rail step from legacy + new columns. |
| `banners_repository.dart` | Home banners saved on the phone after first open. |
| `tickets_repository.dart` | Ticket cache. |
| `live_ticket_adapter.dart` | Ticket JSON → UI ticket. |
| `notifications_repository.dart` | Bell cache. |
| `partner_cards_repository.dart` | Partner cards from `getBanks`, with mock fallback. |
| `brand_catalog.dart` | Store and card **names** → bundled logo ids. Admin logo URLs are not used. |
| `social_proof.dart` | Home line under the greeting (admin business settings). |
| `live_fixtures.dart` | Offline order shapes for tests. |
| `must_test_shapes.dart` | Loads `assets/live/live_mapper_shapes_export.json`. |

### `mock/` — session and offline fallbacks

The name is historical. Live flags are on; these types are still what the UI reads.

| File | Role |
|------|------|
| `session.dart` | Signed-in user, deals, orders, theme, language. |
| `session_store.dart` | `shared_preferences`. Survives process kill. |
| `sample_deals.dart` | Three offline deals (used if live deals are off or empty). |
| `home_promos.dart` | Designed Partner cards + Community slides. |
| `partner_cards.dart` | Offline partner-card rows. |
| `faq_data.dart` | FAQ copy (English). |

### `models/`

| File | Role |
|------|------|
| `deal.dart` | `MockDeal`, money, store/card asset paths. |
| `mock_order.dart` | Order the screens render. |
| `mock_ticket.dart` | Ticket, status, inbox face, messages. |
| `delivery_address.dart` | Place-order address. |

### `push/`

| File | Role |
|------|------|
| `push_bootstrap.dart` | Firebase `mintzer-e45d6`, local notifications, token register. |
| `push_router.dart` | Tap opens the right screen. `MintzerNav` holds the navigator key. |

### `l10n/`

| File | Role |
|------|------|
| `s.dart` | `S` lookup, `LangHost`, `LangScope`. |
| `strings.dart` | `L10n` string table. |
| `demo_l10n.dart` | Generated from `assets/mockups/mintzer-i18n.js`. Do not edit by hand. |
| `extra_l10n.dart` | Strings added after that generator. |

### `util/`

| File | Role |
|------|------|
| `format.dart` | Rupees and dates. |
| `shop_url.dart` | Which store links may open. UPI and phone leave the page. |
| `external_links.dart` | Terms, privacy, WhatsApp, tutorials, partner cards. |
| `otp_sms_autofill.dart` | SMS OTP via `smart_auth`. |
| `notification_permission.dart` | Soft notification ask after first Accept. |
| `ifsc_lookup.dart` | Client side of `POST /ifsc-lookup`. |
| `couriers.dart` | Courier name list. |
| `play_in_app_review.dart` | Play in-app review, with a pre-prompt. |

### `config/` and `theme/`

| File | Role |
|------|------|
| `config/app_config.dart` | Flags and public URLs above. |
| `config/intro_config.dart` | Intro length (`IntroConfig.durationMs`). |
| `theme/app_theme.dart` | Material 3 light and dark. Primary `#7B61FF` (dark `#B39DFF`). |

---

## Assets that ship

Declared in `app/pubspec.yaml`.

| Path | Why it is here |
|------|----------------|
| `assets/products/` | Offline sample photos: Motorola G57, Samsung M35, Samsung TV 32. Live deals use network product images. |
| `assets/logos/stores/` | One PNG per id in `BrandCatalog.storeIds`. |
| `assets/logos/cards/` | One PNG per id in `BrandCatalog.cardIds`, including `any.png`. |
| `assets/logos/mintzer-mark-circle.png` | Login, OTP, intro. |
| `assets/logos/whatsapp.png` | Report chip and WhatsApp icon. |
| `assets/live/must_test_orders.json` | Bundled order dump. Loaded only if `useLiveDumpFixtures` is true. |
| `assets/live/live_mapper_shapes_export.json` | Must-test shapes for the debug gate and Profile engineering entry. |

Launcher source PNGs (not drawn at runtime; `flutter_launcher_icons` reads them): `assets/logos/ic_launcher_full.png`, `assets/logos/ic_launcher_foreground.png`.

Generator source, not bundled: `assets/logos/mintzer-mark-circle.svg` (`scripts/extract-mark.py`).

Store ids: flipkart, amazon, apple, imagine, instamart, iqoo, jiomart, motorola, myntra, oppo, reliance-digital, sangeetha, shopsy, tata-neu, vijaysales, vivo.

Card ids: any, amex, axis, bob, canara, federal, hdfc, hsbc, icici, idfc, indusind, kotak, onecard, pnb, rbl, sbi, scapia, yes.

---

## Android (`app/android`)

| Piece | Role |
|-------|------|
| `app/build.gradle.kts` | `applicationId` `com.mintzer`, release signing from `key.properties`. |
| `app/google-services.json` | Firebase project `mintzer-e45d6`. |
| `app/src/main/AndroidManifest.xml` | Internet, notifications, camera. `allowBackup=false`. Cleartext off. Launcher aliases for the plain icon and four festive icons. |
| `app/src/main/kotlin/com/mintzer/MainActivity.kt` | Flutter activity. Applies `FestiveLauncher` on open. |
| `app/src/main/kotlin/com/mintzer/FestiveLauncher.kt` | Plain icon until **7 Oct 2026, 12:00 IST**. Then SALE+stars, SALE+crown, FEST+stars, FEST+crown, repeating, through **11 Nov 2026**. Switch happens on app open. Play listing icon stays the plain mark. |
| `res/mipmap-*` | Plain `ic_launcher` plus sale/fest variants at each density. |
| `res/drawable/ic_launcher_foreground.png` | Plain adaptive foreground. |
| `res/drawable/ic_launcher_fg_*.png` | Festive foregrounds. |
| `res/drawable/ic_stat_mintzer.png` | Status-bar notification icon. |
| `res/drawable/launch_background.xml` | Splash behind the Flutter first frame. |
| `key.properties` | Release passwords and keystore path. Never commit. |
| `local.properties` | This machine’s Android SDK path. Never commit. |

---

## Tests

| File | Role |
|------|------|
| `test/order_mapper_test.dart` | Legacy order rows → rail. Uses `live_fixtures.dart`. |
| `test/order_detail_live_shapes_test.dart` | Order detail against live shapes. |
| `test/wallet_live_shapes_test.dart` | Wallet against live shapes. |
| `test/shop_url_test.dart` | Store page allows https; blocks http and script links. |
| `test/widget_test.dart` | Widget smoke around sample deals. |
| `integration_test/must_test_shapes_test.dart` | Must-test shape asset. |

---

## Dependencies (`pubspec.yaml`)

Runtime: Flutter, `url_launcher`, `share_plus`, `webview_flutter`, `image_picker`, `http`, `smart_auth`, `permission_handler`, `shared_preferences`, `in_app_review`, `firebase_core`, `firebase_messaging`, `flutter_local_notifications`, `cached_network_image`, `flutter_cache_manager`, `file_picker`, `in_app_update`.

Dev: `flutter_test`, `integration_test`, `flutter_lints`, `flutter_launcher_icons`.

`cupertino_icons` and `flutter_svg` stay in `pubspec.yaml`. No screen imports them today. They were taken out on 25 Sep and put back the same day.

---

## Removed 25 Sep 2026 (not product)

| Removed | Why |
|---------|-----|
| `app/web/` | Default Flutter web scaffold. Play app is Android. |
| `app/windows/` | Default Windows runner, plus a full copy of plugin packages under `flutter/ephemeral`. |
| `app/build/`, old `app/.dart_tool/` | Generated. `flutter pub get` recreated `.dart_tool`. The next build recreates `build/`. |
| `app/.idea/`, `*.iml` | IDE files. |
| `app/android/.kotlin/`, `app/android/.gradle/` | Compiler logs and the Gradle cache. |
| `GeneratedPluginRegistrant.java` | Flutter writes this again on the next Android build. |

Put back the same day, because they belong in the app folder:

| File | How |
|------|-----|
| `assets/logos/mintzer-mark-glyph.png` | Rebuilt from `mintzer-mark-circle.svg`. Listed in `pubspec.yaml` again. |
| `assets/logos/mintzer-mark-blue.png` | Copied from `assets/logos/` (the mockup copy was never deleted). |
| `assets/logos/any-card.svg` | Copied from `assets/logos/`. Screens use `cards/any.png`. |
| `cupertino_icons`, `flutter_svg` | Restored in `pubspec.yaml`. |

No copy remains of these three, so they could not be put back. Current Dart does not load them. `whatsapp.png` is the icon the screens use.

| File | Note |
|------|------|
| `assets/logos/whatsapp.svg` | Was listed in `pubspec.yaml`. The PNG is still there. |
| `assets/logos/_launcher-preview.png` | Preview still, not a screen asset. |
| `assets/products/boat-airdopes-141.jpg` | An older order-adapter draft mapped a Boat name to this file. Current `live_order_adapter.dart` does not. The three sample photos in `sample_deals.dart` are still in `assets/products/`. |

Nothing under `app/lib` or the Android source was deleted. Festive icons, store logos (16), card logos (18), `google-services.json`, and `key.properties` are still there.

---

## Older frontend docs

| Doc | How to read it |
|-----|----------------|
| `docs/frontend/README.md` | Original build order. The app now exists; use this map for the tree. |
| `docs/frontend/01-implementation-checklist.md` | What was ticked while building. |
| `docs/frontend/02-release-readiness.md` | Early gate list. PAN is Cashfree (`docs/STATUS.md`). Version in code is 3.0.29. |
| `docs/STATUS.md` | What is locked, what is live, what not to ship. |
