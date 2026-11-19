# Mintzer — iOS / App Store

Card-holder app (`com.mintzer`) on Apple. Android Play stays the primary store until App Store review is live.

**Status:** iOS project scaffolded in `app/ios/`. **IPA / Archive must be built on a Mac** (Xcode). This cloud Linux agent cannot codesign or upload to App Store Connect.

---

## Locked IDs

| Item | Value |
|------|--------|
| Bundle ID | `com.mintzer` (matches Android `applicationId`) |
| Display name | Mintzer |
| Firebase | `mintzer-e45d6` (same project as Android holder FCM) |
| Material | Material 3 light · primary `#7B61FF` |

Set `AppConfig.appStoreId` in `app/lib/config/app_config.dart` after App Store Connect assigns the numeric ID.

---

## One-time Mac setup (M3 / any Apple Silicon)

1. Install **Xcode** (App Store) + open once to accept license.
2. Install **CocoaPods**: `sudo gem install cocoapods` (or Homebrew).
3. Clone this repo; open `app/`.
4. Flutter: `flutter doctor` — iOS toolchain green.
5. Firebase Console → **mintzer-e45d6** → Add iOS app → bundle `com.mintzer` → download **`GoogleService-Info.plist`** → put at `app/ios/Runner/GoogleService-Info.plist` (gitignored). Add to Runner target in Xcode if needed.
6. Apple Developer → create App ID `com.mintzer` with **Push Notifications**.
7. Xcode → Runner → Signing & Capabilities → your Team · enable **Push Notifications** · **Background Modes → Remote notifications** (plist already has `UIBackgroundModes`).
8. APNs key (or cert) → upload to Firebase Cloud Messaging for iOS.

```bash
cd app
flutter pub get
dart run flutter_launcher_icons   # generates iOS icons from assets/logos
cd ios && pod install && cd ..
flutter build ios --release       # device / archive
# or open ios/Runner.xcworkspace → Product → Archive → Distribute App
```

---

## What this branch already did in code

| Area | Change |
|------|--------|
| `app/ios/` | Flutter iOS platform + Podfile + Info.plist usage strings |
| Bundle ID | `com.mintzer` |
| OTP SMS | `OtpSmsAutofill` no-ops on iOS (system one-time-code autofill) |
| Push | Darwin local notification init + details |
| Store links | `AppConfig.storeUrl` / `storeLabel` / `inviteStoreUrl` · Rate opens App Store on iOS |
| Play update | Still Android-only (`play_update_prompt.dart`) |
| Icons | `flutter_launcher_icons` `ios: true` |

---

## App Store Connect checklist

- [ ] Create app record (name Mintzer, bundle `com.mintzer`)
- [ ] Privacy Policy URL: `https://mintzer.in/privacy.html`
- [ ] Terms: `https://mintzer.in/terms.html`
- [ ] Age rating / India distribution
- [ ] Screenshots (6.7" + 6.1" minimum)
- [ ] Export compliance (encryption — usually standard HTTPS only)
- [ ] Paste numeric App Store ID into `AppConfig.appStoreId`
- [ ] TestFlight internal → external → Submit for review

---

## Do not

- Change Android package off `com.mintzer`.
- Point iOS Firebase at a different project than the live holder FCM.
- Commit `GoogleService-Info.plist` or signing certs.
- Force PAN / KYC on first launch (legacy Play users / shared account rules still apply).

---

## Smoke on device (TestFlight)

1. Phone + OTP login (iOS keyboard should suggest OTP).
2. Home deals load · Accept · Place order camera/gallery invoice.
3. Allow notifications · Settings test or live order push.
4. Profile → Rate Mintzer → App Store sheet / listing.
5. WhatsApp community / support links open.
