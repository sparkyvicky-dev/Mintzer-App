# Profile — requirements (LOCKED v1)

**Status:** LOCKED  
**Mockup:** `assets/mintzer-profile-mockup.png`  
**Theme:** Light + Dark — see [THEME-LIGHT-DARK-MODE.md](./THEME-LIGHT-DARK-MODE.md)

---

## Header

| Element | Behavior |
|---------|----------|
| Avatar | Letter from name, **or** user photo. Tap → **Use a photo** / **Use letter instead** |
| Greeting | **Hi, {Name}** or **Hi there** |
| Phone | Read-only, small |

---

## Refer & earn (LOCKED — affiliate v1)

| Element | Behavior |
|---------|----------|
| **Gold banner** | Below avatar — “Refer & earn ₹{bonus} per friend” · tap → referral sheet |
| **Menu row** | Refer & earn · sub “₹{bonus} each” |

**Sheet:** unique code · Copy · Share on WhatsApp · stats (friends joined, bonus earned).  
See [AFFILIATE-MARKETING-REQUIREMENTS.md](./AFFILIATE-MARKETING-REQUIREMENTS.md).

---

## List (no Wallet / Orders shortcuts — use bottom nav)

### Account
| Row | Tap → |
|-----|-------|
| KYC | Name + PAN form · status badge |
| Language | Row shows current language as a small hint. Tap → **LOCKED 5 EN** segmented bar (`EN` · `हि` · `ಕಾ` · `മല`). Applies **immediately app-wide**. Persists. Login uses the same bar. |
| **Appearance** | Light · Dark · System — **required** |

### Support
| Row | Tap → |
|-----|-------|
| **FAQ** | Accordion Q&A — [12-faq.md](../screens/12-faq.md) |
| My tickets | List + badge if open |
| Help & support | WhatsApp (if admin ON) or email |
| Video tutorials | YouTube |

### Settings
| Push notifications | Master toggle — OFF disables all push |
| Deal alerts | Tier 1: viewed follow-up, new deals, ending soon, comeback — default ON |
| Order updates | Tier 2: timer warnings, tracking, parcel — default ON |
| Payment & wallet | Tier 3: payout, KYC — default ON |
| Terms of Service | Link |
| Privacy Policy | Link |
| **Delete account** | Confirm sheet · see [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](./ACCOUNT-LIFECYCLE-REQUIREMENTS.md) |

### Log out
Confirm → Login

---

## KYC + payout (first Accept)

**Flow:** KYC (Name + PAN) → **Bank details** (UPI or bank) → then timer. See [BANK-AND-PAYOUT-DETAILS.md](./BANK-AND-PAYOUT-DETAILS.md).

| Row | Tap → |
|-----|-------|
| KYC | Status · edit if rejected |
| **Payout details** | View / edit UPI or bank |

---

## Optional later (not v1 — consider when scaling)

| Feature | Profile row? |
|---------|----------------|
| **Payout details** | Collected right after KYC on first Accept |
| Referral / invite | **v1 affiliate** — Refer & earn banner + row · see AFFILIATE-MARKETING-REQUIREMENTS.md |
| Rate the app | Play Store |
| App version | Footer “Version 1.0.0” |
| Change phone number | OTP re-verify |

---

## Must not (v1)

- Withdraw button in Wallet  
- Wallet / My Orders duplicate shortcuts  

---

## LOCKED

| Topic | Decision |
|-------|----------|
| Mockup | `mintzer-profile-mockup.png` |
| Appearance toggle | Yes — whole app |
| Bank after KYC | Yes — first Accept, then Profile → Payout details |
| Delete account | Yes — Profile → Settings · block if order in progress |
| Photo | Optional — avatar tap, camera badge |
| Language | **LOCKED 5 EN** bar · English · हिन्दी · ಕನ್ನಡ · മലയാളം · whole app, persists |

---

## Appearance row (add to mockup v1.1)

Profile list includes **Appearance**: Light | Dark | System — applies to full app.
