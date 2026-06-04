# Profile — requirements (LOCKED v1)

**Status:** LOCKED  
**Mockup:** `assets/mintzer-profile-mockup.png`  
**Theme:** Light + Dark — see [THEME-LIGHT-DARK-MODE.md](./THEME-LIGHT-DARK-MODE.md)

---

## Header

| Element | Behavior |
|---------|----------|
| Avatar | First letter of name (from KYC) — static circle, no upload v1 |
| Greeting | **Hi, {Name}** or **Hi there** |
| Phone | Read-only, small |

---

## List (no Wallet / Orders shortcuts — use bottom nav)

### Account
| Row | Tap → |
|-----|-------|
| KYC | Name + PAN form · status badge |
| Language | English · हिंदी |
| **Appearance** | Light · Dark · System — **required** |

### Support
| Row | Tap → |
|-----|-------|
| My tickets | List + badge if open |
| Help & support | WhatsApp (if admin ON) or email |
| Video tutorials | YouTube |

### Settings
| Push notifications | Toggle |
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
| Profile photo upload | Avatar tap → upload |
| **Payout details** | Collected right after KYC on first Accept |
| Referral / invite | Refer & earn |
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
| Photo upload v1 | No |

---

## Appearance row (add to mockup v1.1)

Profile list includes **Appearance**: Light | Dark | System — applies to full app.
