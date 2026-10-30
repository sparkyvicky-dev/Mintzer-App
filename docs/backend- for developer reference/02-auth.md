# Module: Auth (OTP)

Phone-only login. No profile data required at signup.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/otp/send` | Send OTP to phone |
| POST | `/auth/otp/verify` | Verify OTP, return tokens |
| POST | `/auth/logout` | Invalidate session |
| GET | `/auth/me` | Current user (phone, kyc status) |

## `POST /auth/otp/send`

**Live `newapp` (what Flutter calls today):** `POST https://app.mintzer.in/api/sendotp`  
Body: `{ "mobile": "9876543210" }` — 10 digits, no `+91`.  
SMS is sent by Laravel via **SMS Gateway Hub** (Mintzer sender / DLT). Do **not** call Pakka Bill.

**Ideal / future shape:**
```json
{ "phone": "9876543210", "countryCode": "+91" }
```

**Response (live):**
```json
{ "is_new_user": false, "message": "OTP Sent Successfully", "otp_expiry": "..." }
```
(Live may also echo `OTP` in JSON — clients must **ignore** it; never show in UI.)

**Ideal response:**
```json
{ "success": true, "retryAfterSeconds": 30 }
```

**Rules:**
- Validate 10-digit Indian mobile
- Rate limit per phone and IP
- OTP expiry: 5 minutes (configurable)

## `POST /auth/otp/verify`

**Live:** `POST https://app.mintzer.in/api/verify-otp`  
```json
{ "mobile": "9876543210", "otp": "123456" }
```

**Live response:**
```json
{
  "is_new_user": false,
  "message": "Your login OTP has been verified.",
  "user_id": 1,
  "token": "849|…"
}
```
(`token` = Laravel Sanctum; store as Bearer for later APIs.)

**Ideal / future shape:**
```json
{ "phone": "9876543210", "otp": "123456" }
```

**Ideal response:**
```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "user": {
    "id": "user_abc",
    "phone": "9876543210",
    "kycStatus": "not_started"
  }
}
```

**Rules:**
- Create user on first verify if not exists
- Do not require name, email, PAN at login

## KYC status values

| Value | Meaning |
|-------|---------|
| `not_started` | No KYC submitted |
| `pending` | Under review |
| `verified` | Approved |
| `rejected` | Resubmit allowed |

KYC submission documented in [06-admin-operations.md](./06-admin-operations.md) / Profile module.

## Security

- Hash OTP at rest; max attempts before lockout
- JWT or session token for mobile
- Refresh token rotation
