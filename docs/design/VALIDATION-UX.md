# Validation & error UX (LOCKED v1)

**Applies to:** All screens with inputs or submit actions.

**Colors:** Error text `#D93025` (light) · `#F28B82` (dark) · Error field border same · Snackbar bg `#323232` or `#202124`, text `#FFFFFF`

---

## Two ways to show errors (use both)

| Type | Where | When |
|------|--------|------|
| **A — Inline (field)** | Red text **under the field** · field border `#D93025` | User tapped Submit / left field invalid · wrong format before API |
| **B — Snackbar (toast)** | **Bottom of screen** — anchor **bottom-right** on phone (Material snackbar) | API failed · network · duplicate Order ID · success (*Copied*, *Pasted*, *Saved*) |

**Rule:** Field mistakes → **inline first**. Server / action / copy feedback → **snackbar bottom-right**.

Snackbar auto-dismiss ~4s · one line · optional **Dismiss** action.

---

## Global rules

| Rule | Detail |
|------|--------|
| Disable primary button | Until required fields valid (Login phone, empty Order ID, etc.) |
| Do not use alert dialogs | For simple validation — inline + snackbar only |
| Loading | Button spinner · disable double submit |
| Success | Snackbar bottom-right: *Copied* · *Pasted* · *Saved* · *Address updated* |
| Network error | Snackbar: *Something went wrong. Try again.* |

---

## By screen

### Login — [01-login.md](../screens/01-login.md)

| Field / action | Validation | Error UX |
|----------------|------------|----------|
| Phone | 10 digits · Indian mobile (starts 6–9) | **Inline:** *Enter a valid 10-digit mobile number* |
| Continue (empty/invalid) | Button disabled | — |
| OTP | Length per backend (4–6) · digits only | **Inline:** *Enter the full code* |
| Wrong OTP | API reject | **Snackbar:** *Incorrect code. Try again.* |
| OTP expired | API | **Snackbar:** *Code expired. Tap Resend.* |
| Resend | Cooldown timer | Button disabled until timer ends |
| Too many attempts | API | **Snackbar:** *Too many tries. Wait a minute.* |

---

### KYC overlay — [BANK-AND-PAYOUT-DETAILS.md](./BANK-AND-PAYOUT-DETAILS.md)

| Field | Validation | Error UX |
|-------|------------|----------|
| Name | Required · min 2 chars · letters/spaces | **Inline:** *Enter name as on PAN* |
| PAN | Format `AAAAA9999A` (5 letters, 4 digits, 1 letter) · uppercase | **Inline:** *Enter a valid PAN* |
| Submit | Both valid | API fail → **Snackbar** |

---

### Payout / bank overlay — [BANK-AND-PAYOUT-DETAILS.md](./BANK-AND-PAYOUT-DETAILS.md)

| Field | Validation | Error UX |
|-------|------------|----------|
| UPI ID | Valid UPI pattern (`name@bank`) | **Inline:** *Enter a valid UPI ID* |
| Confirm UPI | Must match UPI ID | **Inline:** *UPI IDs do not match* |
| Account number | Digits · length per rules | **Inline:** *Enter a valid account number* |
| Confirm account | Must match | **Inline:** *Account numbers do not match* |
| IFSC | 11 chars · format | **Inline:** *Enter a valid IFSC code* |
| Holder name | Should match KYC name | **Inline:** *Name must match KYC* · hint always visible |
| Submit | All valid | API → **Snackbar** |

---

### Place order — [PLACE-ORDER-REQUIREMENTS.md](./PLACE-ORDER-REQUIREMENTS.md)

| Field / action | Validation | Error UX |
|----------------|------------|----------|
| Tap to paste Order ID | Clipboard empty | **Snackbar:** *Copy Order ID from Flipkart first* |
| Paste | Trim · FK order ID pattern | **Snackbar:** *That doesn’t look like an Order ID* |
| Submit (empty) | Required | **Inline** on field: *Enter Order ID* · button disabled |
| Duplicate Order ID | API 409 | **Snackbar:** *This Order ID is already used* |
| Timer expired | Backend | Full-screen or **Snackbar** + block Submit: *Time expired* |
| Generate new address | Weekly limit | **Snackbar:** *Limit reached. Try next week.* |
| Copy address line | Success | **Snackbar:** *Copied* |

---

### Order detail — [ORDERS-PAGES-REQUIREMENTS.md](./ORDERS-PAGES-REQUIREMENTS.md)

| Field / action | Validation | Error UX |
|----------------|------------|----------|
| Tracking ID | Required to save step | **Inline:** *Enter tracking ID* |
| Delivery partner | Required if not auto-detected | **Inline:** *Select courier* |
| Last 4 digits phone | Exactly 4 digits | **Inline:** *Enter 4 digits* |
| Delivery OTP | Min 4 digits (config) | **Inline:** *Enter delivery OTP* |
| Invoice upload | File required · type/size limits | **Inline:** *Choose a photo or PDF* · too large → **Snackbar** |
| Add note | Max 200 chars | **Inline counter** · over limit disable Save |
| Cancel order | Reason required | **Inline** on picker: *Select a reason* |
| Cancel Other | Max 50 chars | **Inline** |

---

### Raise ticket overlay

| Field | Validation | Error UX |
|-------|------------|----------|
| Category | Required | **Inline** |
| Required answers | Per category | **Inline** under each |
| Submit | All valid | Fail → **Snackbar** |

---

### Profile — Delete account — [ACCOUNT-LIFECYCLE-REQUIREMENTS.md](./ACCOUNT-LIFECYCLE-REQUIREMENTS.md)

| Action | Validation | Error UX |
|--------|------------|----------|
| Delete with order in progress | Block | **Dialog or sheet body** (not snackbar): *You have an order in progress…* |
| Delete confirm | User confirms | API fail → **Snackbar** |
| Log out | Confirm optional | — |

---

### Home · Deal detail · Wallet · Offers

| Screen | Validation |
|--------|------------|
| Home | No form fields · list load fail → **Snackbar** + retry |
| Deal detail | Accept blocked if active order → **overlay** (not snackbar) |
| Wallet | Read-only v1 · no withdraw validation |
| Offers | None v1 |

---

### Account suspended / deleted

No form validation — full-screen messages only.

---

## Figma / dev checklist

- [ ] Snackbar component — bottom-right, dark bg, white text  
- [ ] Inline error text style — 12sp, `#D93025`, 4dp below field  
- [ ] Invalid field border state  
- [ ] Success snackbar same position as error  
- [ ] Every Submit documents inline vs snackbar in screen MD  

---

## Decision log

| Topic | Decision |
|-------|----------|
| Field errors | Inline under field |
| Action / API / copy | Snackbar bottom-right |
| Alerts | Avoid for validation |
| Success feedback | Snackbar (*Copied*, *Saved*) |
