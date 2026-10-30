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

**Request:**
```json
{ "phone": "9876543210", "countryCode": "+91" }
```

**Response:**
```json
{ "success": true, "retryAfterSeconds": 30 }
```

**Rules:**
- Validate 10-digit Indian mobile
- Rate limit per phone and IP
- OTP expiry: 5 minutes (configurable)

## `POST /auth/otp/verify`

**Request:**
```json
{ "phone": "9876543210", "otp": "123456" }
```

**Response:**
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
