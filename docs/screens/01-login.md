# Screen: Login (OTP)

**Status:** **LOCKED** (20 Sep 2026 — Welcome login + OTP + post-login intro)  
**Visual source:** Flutter `app/lib/screens/login_screen.dart` · `otp_screen.dart` · `intro_screen.dart`  
**Flag:** `kChatGptLoginPreview = true` (do not flip without client approval)

## Purpose

Let the user into the app with minimal friction. Phone number is the only identifier required at entry.

## Entry points

- App cold start (logged out)
- Session expired

## Login — phone (LOCKED 20 Sep 2026)

| Element | Spec |
|---------|------|
| Logo | Circle mark ~72dp, top center |
| Title | **Welcome to Mintzer** |
| Subtitle | Accept orders. Earn rewards. |
| Benefit row | Pick a deal · Order on store · Earn in wallet (icons in pale-purple discs) |
| Phone | Unified field: `+91 \|` + 10 digits · clear × only when focused + non-empty · height ~48 |
| Helper | We’ll send you an OTP. |
| CTA | **Get OTP** · height ~44 · purple · no trailing icon |
| Terms | “By continuing…” + purple underlined **Terms** & **Privacy** |
| Language | Compact chips `EN` · `हि` · `ಕಾ` · `മല` — pale-purple selected |
| Footer | Soft lavender wave + **BIGGER OPPORTUNITIES TOGETHER** (`#80868B`) near bottom |

Do **not** restyle without approval. Pre-lock “Get Started / Accept. Order. Get paid.” kept only behind `kChatGptLoginPreview = false`.

## OTP (LOCKED 20 Sep 2026)

| Element | Spec |
|---------|------|
| Logo | Small circle mark above title |
| Title | Enter OTP |
| Subtitle | Code sent to `+91 68686 68686` (spaced) |
| Boxes | 6 squares · ~48–54px fit to width · light-grey idle · purple 2px active |
| CTA | **Verify OTP** · same width as box group · height 44 · soft lavender when disabled |
| Resend | Resend in **Ns** (seconds bold purple) |
| Autofill | SMS Retriever + auto-submit on 6th digit |

Do **not** restyle without approval.

## Post-login intro (LOCKED 20 Sep 2026)

After OTP success → brand beat → Home. **No Continue.**

| Element | Spec |
|---------|------|
| Purpose | Mask Home image precache — do not invent long wait |
| Logo | ~84dp · fade + scale **0.94 → 1.0** (no bounce/spin) |
| Brand | **Mintzer** · weight w700 |
| Slogan | BIGGER OPPORTUNITIES TOGETHER (muted) |
| Success | Green check badge on logo after beat |
| Footer | **Made in India 🇮🇳** · small · light · bottom |
| Timing | ~1.8s min beat + precache · then white fade to Home |
| Bug rule | Always opaque light underlay — **never** fade to transparent (causes black flash) |

Flutter: `app/lib/screens/intro_screen.dart` · config `IntroConfig.durationMs`. Do not restyle without approval.

Optional later: admin banner slot (`bannerUrl`) — not required for lock.

## User actions

1. Enter phone number → tap **Get OTP**
2. Enter OTP → auto-submit when complete or tap **Verify**
3. On success → **post-login intro** (brand beat) → **Home**

## States

| State | UI |
|-------|-----|
| Empty | Get OTP disabled |
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
| Success | **Post-login intro** → Home (active). Backend: [08-app-config.md](../backend-%20for%20developer%20reference/08-app-config.md) § Post-login intro |
| Suspended | [10-account-suspended.md](./10-account-suspended.md) |
| Back on OTP | Phone entry |

## Backend notes

- Send OTP via SMS provider
- Return auth token + user id on verify
- Store session locally for auto-login

## Colors

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md)

| Element | Value |
|---------|--------|
| Background | `#FFFFFF` (login) |
| Primary CTA | `#7B61FF` |
| Terms links | `#7B61FF` underlined |
| Footer slogan | `#80868B` |
| Lang selected | fill `#F3F0FF` · text `#7B61FF` |

**Logo:** Circle mark asset — keep as shipped.

## 14 Oct 2026

Not part of the delivery-call update. This screen stays as written above.
