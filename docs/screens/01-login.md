# Screen: Login (OTP)

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
| Invalid phone | Inline error under field |
| OTP sent | Show OTP fields + resend timer |
| Wrong OTP | Shake or error message, allow retry |
| Loading | Button spinner, disable inputs |
| Success | Navigate away; no extra profile form |

## Rules

- Do **not** ask for name, email, KYC, or bank details on login.
- Do **not** block login with mandatory permissions (notifications can be asked later).

## Navigation

| From | To |
|------|-----|
| Success | Home |
| Back on OTP | Phone entry |

## Backend notes

- Send OTP via SMS provider
- Return auth token + user id on verify
- Store session locally for auto-login

## Design

- White background, blue primary button
- Large tap targets for OTP boxes
