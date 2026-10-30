# Module: App config

Global settings editable in admin without app store release.

## Config keys

| Key | Type | Default | Used by |
|-----|------|---------|---------|
| `placementTimerMinutes` | int | 15 | Placements — accept timer |
| `paymentReviewHours` | int | 48 | Orders — invoice → payout countdown |
| `placementWarningMinutes` | int[] | `[5, 1]` | Notifications before placement expiry |
| `notificationMaxPushPerDay` | int | 2 | Gateway — max pushes per user per day |
| `notificationMinGapHours` | int | 8 | Min hours between any two pushes |
| `notificationMaxCommercialPerWeek` | int | 4 | Tier 1 deal-attention pushes per week |
| `notificationQuietHoursStart` | string | `22:00` | IST — no commercial push (queue) |
| `notificationQuietHoursEnd` | string | `08:00` | IST — resume queued sends |
| `notificationIgnoreCooldownDays` | int | 7 | After 3 ignores, pause Tier 1 |
| `dealViewedFollowupDelaysHours` | int[] | `[3, 24, 48]` | Steps 1–3 after qualify (viewed, no accept) |
| `dealViewedMinDwellSeconds` | int | 30 | Min time on deal detail to qualify |
| `dealHighEarnThresholdInr` | int | 250 | Min `youEarn` for `deal.new_high_earn` push |
| `dealEndingSoonHours` | int | 12 | Fire `deal.ending_soon` within this window |
| `userComebackInactiveDays` | int | 3 | Days inactive before `user.comeback` |
| `otpExpiryMinutes` | int | 5 | Auth |
| `otpResendSeconds` | int | 30 | Auth |
| `deliveryOtpMinLength` | int | 6 | Orders OFD step |
| `minWithdrawalAmount` | decimal | 250 | Wallet |
| `tdsPercentDefault` | decimal | 0 | Deals (optional default) |
| `communityWhatsAppEnabled` | bool | true | Home header — community group icon |
| `communityWhatsAppUrl` | string | — | WhatsApp group invite URL (`https://chat.whatsapp.com/...`) |
| `communityWhatsAppLabel` | string | `Join community` | Accessibility / tooltip |
| `tutorialVideoUrl` | string | — | First-time banner + Profile → Help |
| `homeSocialProofEnabled` | bool | true | Home strip below carousel |
| `homeSocialProofText` | string | — | e.g. “₹8.2L+ earned this week · 42 orders today” |
| `homeCarouselSlides` | json[] | — | Admin marketing slides — see affiliate spec |
| `orderSuccessPromoTemplates` | json[] | — | Rotating success promos |
| `referralEnabled` | bool | true | Profile + success referral template |
| `referralBonusInr` | int | 200 | Per successful referred first order |
| `partnerCards` | json[] | — | Partner card catalog for sheet |
| `androidMinVersionCode` | int | `1` | Below this → **force update** (cannot use app) |
| `androidLatestVersionCode` | int | `1` | Latest Play build (`versionCode`) |
| `androidLatestVersionName` | string | `1.0.0` | Shown on update screen (e.g. 1.2.0) |
| `inAppUpdateEnabled` | bool | true | Show Play **flexible** update sheet when a newer build exists |
| `forceUpdateEnabled` | bool | false | **Later / emergency only** — blocking immediate update (not v1) |
| `inAppUpdateTitle` | string | `Update available` | Sheet title |
| `inAppUpdateMessage` | string | `A new version is ready. You can keep using Mintzer while it downloads.` | Sheet body |
| `playStoreUrl` | string | `https://play.google.com/store/apps/details?id=com.mintzer` | **Update** button. Package **must** stay `com.mintzer` |
| `postLoginIntroEnabled` | bool | `true` | After OTP verify — brand beat before Home (no Continue button) |
| `postLoginIntroDurationMs` | int | `2800` | Auto-advance to Home |
| `postLoginIntroBrandName` | string | `Mintzer` | Large wordmark |
| `postLoginIntroHeadline` | string / i18n map | `""` | Optional mid line (campaign). Empty = brand only |
| `postLoginIntroFooter` | string / i18n map | `Made in India 🇮🇳` | Bottom pride line. Localize EN/HI/KN/ML |
| `postLoginIntroBannerUrl` | string \| null | `null` | **Future** — optional image/video poster under brand |
| `postLoginIntroBannerLink` | string \| null | `null` | **Future** — tap banner → deep link / https (ignored if no banner) |
| `postLoginIntroShowOn` | enum | `every_otp_success` | `every_otp_success` \| `first_install_only` \| `off` |

## Marketing API (affiliate layer)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/marketing/home-carousel` | Active slides for Home banner |
| GET | `/marketing/order-success-promo` | Template for current user/session |
| GET | `/marketing/post-login-intro` | Post-OTP intro beat (copy + optional banner) |
| GET | `/partner-cards` | Card list for apply sheet |
| GET | `/user/referral` | Code + stats (friends joined, bonus earned) |
| POST | `/user/referral/share` | Optional analytics ping on share |

See [../design/AFFILIATE-MARKETING-REQUIREMENTS.md](../design/AFFILIATE-MARKETING-REQUIREMENTS.md).

| Method | Path | Description |
|--------|------|-------------|
| GET | `/config/public` | Mobile app bootstrap (timer, payment hours) |
| GET | `/admin/config` | All keys |
| PUT | `/admin/config` | Update keys |

## `GET /config/public`

```json
{
  "placementTimerMinutes": 15,
  "paymentReviewHours": 48,
  "deliveryOtpMinLength": 6,
  "minWithdrawalAmount": 250,
  "supportWhatsApp": "+918220507417",
  "supportEmail": "support@mintzer.in",
  "communityWhatsAppEnabled": true,
  "communityWhatsAppUrl": "https://chat.whatsapp.com/EXAMPLE_INVITE",
  "communityWhatsAppLabel": "Join community",
  "androidMinVersionCode": 1,
  "androidLatestVersionCode": 1,
  "androidLatestVersionName": "1.0.0",
  "inAppUpdateEnabled": true,
  "forceUpdateEnabled": false,
  "inAppUpdateTitle": "Update available",
  "inAppUpdateMessage": "A new version is ready. You can keep using Mintzer while it downloads.",
  "playStoreUrl": "https://play.google.com/store/apps/details?id=com.mintzer"
}
```

Mobile reads `placementTimerMinutes` on Accept screen — displays countdown from server `expiresAt`, not local hardcode.

## Admin UI

Single **Settings** page:

- Placement timer (minutes) — user requested backend-controlled
- Payment review window (hours) — 48h invoice timer
- Notification warning intervals + frequency caps + quiet hours + deal follow-up delays
- **Community WhatsApp:** enable toggle + group invite URL (Home header — separate from support number)
- **In-app update:** latest Android `versionCode` + Play flexible sheet copy (Update / Not now)

Changes apply to **new** placements immediately; active placements keep original `expiresAt` unless admin policy says otherwise.

---

## In-app update (LOCKED — v1 = flexible sheet)

When the developer publishes a new APK/AAB on **Play Store**, the next time the user opens Mintzer they see Google Play’s **in-app update sheet**. They **stay in Mintzer**. They can keep using the current version until they install.

**v1 flow (Play `FLEXIBLE`):**

1. After splash, app checks Play + `androidLatestVersionCode`.
2. If a newer build exists and `inAppUpdateEnabled` → **bottom sheet**:
   - Title: **Update available**
   - **Update** · **Not now**
3. **Update** → download **inside the app** (progress). User can keep browsing.
4. When download finishes → snackbar / sheet **Restart** → Play installs and restarts Mintzer.
5. **Not now** → dismiss; they use the old version this session. Prompt again next launch (don’t spam the same session).
6. **Fallback only** if Play in-app update cannot run: open `playStoreUrl`.

**Push (app closed):** `app.update_available` — **Update released** · tap opens the app (sheet shows). Not a commercial deal push.

**Not v1:** blocking full-screen (`IMMEDIATE` / `forceUpdateEnabled`) — keep for a later emergency (security / old API dead). Do not use for normal releases.

This is **not** CodePush / silent UI swap. Play still ships the new APK; the sheet only downloads it **without leaving Mintzer**.

---

## Post-login intro (LOCKED — 20 Sep 2026)

After **OTP success**, do **not** jump straight to Home. Show a short brand beat that **masks Home image precache**, then auto-enter Home. **No Continue button.**

**UX (Flutter — locked):**
- Soft purple-white wash · Mintzer mark (~84dp) scale **0.94→1** + fade · wordmark **Mintzer** (w700) · slogan BIGGER OPPORTUNITIES TOGETHER · green **check** on logo · footer **Made in India 🇮🇳**
- Min beat ~**1800ms** + wait for precache · white fade → Home (opaque underlay — **never** transparent fade / black flash)
- Optional **banner** slot under brand (hidden until admin sets URL)

**Why backend:** Festivals / campaigns / partner creatives without a Play release. Same pattern as Home carousel.

### `GET /marketing/post-login-intro`

Auth: optional (can be public; prefer user locale from `Accept-Language` or profile).

```json
{
  "enabled": true,
  "durationMs": 1800,
  "brandName": "Mintzer",
  "headline": "BIGGER OPPORTUNITIES TOGETHER",
  "footer": "Made in India 🇮🇳",
  "bannerUrl": null,
  "bannerLink": null,
  "showOn": "every_otp_success"
}
```

| Field | Notes |
|-------|--------|
| `headline` | Default slogan line. Campaigns may override |
| `footer` | Pride line. Default **Made in India 🇮🇳**. Per-locale in admin |
| `bannerUrl` | HTTPS image (16:7 recommended). `null` = no banner |
| `bannerLink` | Only if banner shown — open in-app WebView / external / deep link |
| `showOn` | `every_otp_success` (default) · `first_install_only` · `off` |

**Admin:** Settings → **Post-login intro** — enable, duration, EN/HI/KN/ML footer + headline, banner upload, show rule.

**Mobile:** Flutter `IntroConfig` / `IntroScreen`. Until API ships, local defaults match the JSON above.

---

## Home promo carousel — admin upload map (LOCKED intent · 19 Sep 2026)

Home banner is a **swipeable carousel** (118dp · dots · ~5s auto-rotate). Slides come from marketing API / admin — **not** hardcoded forever in the APK.

### App reads

| Method | Path | When |
|--------|------|------|
| GET | `/marketing/home-carousel` | Home open / pull-to-refresh |
| GET | `/config/public` | May embed `homeCarouselSlides` for bootstrap |

### Slide JSON (one item in array)

```json
{
  "id": "partner_cards_sep",
  "enabled": true,
  "priority": 10,
  "startAt": "2026-09-01T00:00:00+05:30",
  "endAt": null,
  "variant": "cards",
  "kicker": "Partner cards",
  "title": "Unlock ₹12,000+ in deals this month",
  "subtitle": "HDFC & Axis · Fee waived on select cards",
  "bullets": [],
  "ctaLabel": "Browse cards →",
  "ctaAction": "open_partner_cards",
  "ctaUrl": null,
  "imageUrl": "https://cdn.mintzer.in/banners/partner-cards-328x118.png",
  "locales": {
    "hi": { "kicker": "…", "title": "…", "ctaLabel": "…" }
  }
}
```

| Field | Admin UI | Notes |
|-------|----------|-------|
| `imageUrl` | **Upload image** (CDN) | Optional full-bleed. Recommend **656×236** (@2× of 328×118). If null, app uses variant art (WA phone / play / card stack) |
| `variant` | Select: `community` · `tutorial` · `cards` · `custom` | Drives gradient + fallback art |
| `ctaAction` | Select | `open_whatsapp` · `open_tutorial` · `open_partner_cards` · `open_url` · `open_referral` |
| `ctaUrl` | URL field | Required when `open_url` |
| `priority` / dates | Sort + schedule | App shows enabled + in-window slides only |
| `locales` | EN default + HI/KN/ML overrides | Footer/copy per language |

### Admin screen (build later)

**Marketing → Home banners**
1. List slides (drag reorder = priority)
2. Add / edit: copy, variant, CTA, schedule
3. **Upload banner image** → stores on CDN → sets `imageUrl`
4. Preview 118dp phone frame
5. Toggle enabled

### Config keys (also on this page)

| Key | Role |
|-----|------|
| `homeCarouselSlides` | Fallback JSON array if dedicated table not ready |
| `homeSocialProofEnabled` / `homeSocialProofText` | Strip under carousel |
| `tutorialVideoUrl` | Tutorial slide + “New here?” row |

**Flutter mock:** `app/lib/mock/home_promos.dart` + `HomePromoCarousel`. Replace with API when backend ships.

See also [AFFILIATE-MARKETING-REQUIREMENTS.md](../design/AFFILIATE-MARKETING-REQUIREMENTS.md) §3 · §9.
