# Module: App config

Global settings editable in admin without app store release.

## Config keys

| Key | Type | Default | Used by |
|-----|------|---------|---------|
| `placementTimerMinutes` | int | 15 | Placements — accept timer |
| `paymentReviewHours` | int | 48 | Orders — invoice → payout countdown |
| `placementWarningMinutes` | int[] | `[5, 1]` | Notifications before expiry |
| `otpExpiryMinutes` | int | 5 | Auth |
| `otpResendSeconds` | int | 30 | Auth |
| `deliveryOtpMinLength` | int | 6 | Orders OFD step |
| `minWithdrawalAmount` | decimal | 250 | Wallet |
| `tdsPercentDefault` | decimal | 0 | Deals (optional default) |

## API

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
  "supportEmail": "support@mintzer.in"
}
```

Mobile reads `placementTimerMinutes` on Accept screen — displays countdown from server `expiresAt`, not local hardcode.

## Admin UI

Single **Settings** page:

- Placement timer (minutes) — user requested backend-controlled
- Payment review window (hours) — 48h invoice timer
- Notification warning intervals

Changes apply to **new** placements immediately; active placements keep original `expiresAt` unless admin policy says otherwise.
