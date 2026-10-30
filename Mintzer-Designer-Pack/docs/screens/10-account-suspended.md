# Screen: Account suspended

**Spec:** [../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md)

## Purpose

Block app use when ops has suspended the account. User can only contact support or return to login.

## Entry points

- OTP success with `user.status = suspended`
- Any API `ACCOUNT_SUSPENDED` while logged in

## UI

| Element | Copy / behavior |
|---------|-----------------|
| Icon | Neutral warning (not aggressive) |
| Title | **Account suspended** |
| Body | Your account is not active right now. Please contact support if you want to restore access. |
| Primary | **Contact support** |
| Secondary | Back to login |

## Navigation

No bottom nav. No access to Home, Orders, Wallet, Profile.

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md)

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| Icon | `#E37400` on `#FEF7E0` (neutral warning) |
| Title / body | `#202124` / `#5F6368` |
| Contact support button | `#1A73E8` |
| Secondary (login) | text `#1A73E8` |

## Validation

Full-screen only — no field validation.
