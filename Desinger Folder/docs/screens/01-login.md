# Screen: Login (OTP)

**Mockups:** `assets/mintzer-login-mockup.png` · `assets/mintzer-login-otp-mockup.png`

## Purpose

Let the user into the app with minimal friction. Phone number is the only identifier required at entry.

## Entry points

- App cold start (logged out)
- Session expired

## UI elements

| Element | Description |
|---------|-------------|
| Mintzer logo | Brand mark, top center |
| Phone input | Indian mobile, 10 digits, country code +91 fixed or implied |
| Continue button | Primary blue; disabled until valid 10-digit number |
| OTP sheet / screen | 4–6 digit OTP input (match backend) |
| Resend OTP | Timer countdown before resend enabled |
| Terms link | Optional footer: Terms & Privacy |

## User actions

1. Enter phone number → tap **Continue**
2. Enter OTP → auto-submit or tap **Verify**
3. On success → navigate to **Home**

## States

| State | UI |
|-------|-----|
| Empty | Continue disabled |
| Invalid phone | **Inline** under field: *Enter a valid 10-digit mobile number* |
| OTP sent | Show OTP fields + resend timer |
| Wrong OTP | **Snackbar** bottom-right: *Incorrect code. Try again.* · optional field shake |
| **Account suspended** | After verify — **Account suspended** screen (not Home) |
| Loading | Button spinner, disable inputs |
| Success | Navigate to **Home** (if `status = active`) |

## Rules

- Do **not** ask for name, email, KYC, or bank details on login.
- Do **not** block login with mandatory permissions (notifications can be asked later).

## Navigation

| From | To |
|------|-----|
| Success | Home (active users only) |
| Suspended | [10-account-suspended.md](./10-account-suspended.md) |
| Back on OTP | Phone entry |

## Backend notes

- Send OTP via SMS provider
- Return auth token + user id on verify
- Store session locally for auto-login

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md) · [../design/THEME-LIGHT-DARK-MODE.md](../design/THEME-LIGHT-DARK-MODE.md)

| Element | Light | Dark |
|---------|-------|------|
| Background | `#F8F9FA` | `#121212` |
| Surface / inputs | `#FFFFFF` | `#1E1E1E` |
| Mintzer logo (placeholder) | Text `#1A73E8` or grey box `#E8EAED` | Text `#8AB4F8` |
| Continue / Verify button | `#1A73E8` on `#FFFFFF` text | `#8AB4F8` |
| OTP boxes | border `#E8EAED`, focus `#1A73E8` | border `#3C4043` |
| Error (wrong OTP) | `#D93025` | `#F28B82` |
| Terms link | `#1A73E8` | `#8AB4F8` |

**Logo:** Placeholder only — swap asset when ready; **keep button blue unchanged**.

## Validation

**Full rules:** [../design/VALIDATION-UX.md](../design/VALIDATION-UX.md)

| Trigger | UX |
|---------|-----|
| Bad phone format | **Inline** under phone field |
| Wrong / expired OTP | **Snackbar** bottom-right |
| Resend before timer | Button disabled |
| API / network fail | **Snackbar** *Something went wrong. Try again.* |

## Design

- Large tap targets for OTP boxes
