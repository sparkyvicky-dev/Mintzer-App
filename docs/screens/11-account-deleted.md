# Screen: Account deleted

**Spec:** [../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md](../design/ACCOUNT-LIFECYCLE-REQUIREMENTS.md)

## Purpose

Confirm account deletion and send user back to login.

## Entry points

- Successful `POST /user/account/delete` from Profile

## UI

| Element | Copy / behavior |
|---------|-----------------|
| Title | **Account deleted** |
| Body | Your account has been removed. Contact support if you need help. |
| Primary | **Back to login** |
| Link | Contact support (optional) |

## Rules

- Session cleared before showing this screen
- User cannot navigate back to Profile or orders

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md)

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| Title | `#202124` |
| Body | `#5F6368` |
| Back to login | `#1A73E8` |

## Validation

Full-screen only — no field validation.
