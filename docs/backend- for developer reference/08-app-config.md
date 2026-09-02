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

## Marketing API (affiliate layer)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/marketing/home-carousel` | Active slides for Home banner |
| GET | `/marketing/order-success-promo` | Template for current user/session |
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
  "communityWhatsAppLabel": "Join community"
}
```

Mobile reads `placementTimerMinutes` on Accept screen — displays countdown from server `expiresAt`, not local hardcode.

## Admin UI

Single **Settings** page:

- Placement timer (minutes) — user requested backend-controlled
- Payment review window (hours) — 48h invoice timer
- Notification warning intervals + frequency caps + quiet hours + deal follow-up delays
- **Community WhatsApp:** enable toggle + group invite URL (Home header — separate from support number)

Changes apply to **new** placements immediately; active placements keep original `expiresAt` unless admin policy says otherwise.
