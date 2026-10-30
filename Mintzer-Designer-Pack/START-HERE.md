# Mintzer — Designer brief (WhatsApp / quick share)

**App:** Android deals app — browse Flipkart/Amazon card deals → Accept → order on store → submit proof → earn in Wallet.

---

## How many screens?

| What | Count |
|------|------:|
| **Main pages** | **14** |
| **Popups / sheets** | **11** |
| **Place order layouts** | **2** (external browser + in-app) |
| **Total UI to design** | **~25** |
| **Themes** | Light + Dark (same pages, two themes) |

### 14 main pages

1. Login — phone  
2. Login — OTP  
3. Home  
4. Deal detail  
5. Place order  
6. Order success  
7. My Orders  
8. Order detail  
9. Wallet  
10. Profile  
11. My tickets  
12. Account suspended  
13. Account deleted  
14. *(Ticket detail = sub-page under My tickets, not extra tab)*

### 11 popups / sheets

KYC · Payout details · Shop mode choice · Cancel order · Add note · Finish current order first · Resume order · Raise ticket · Ticket detail · Appearance (light/dark) · Delete account

---

## Mockups — reference only

**HTML mockups are for flow + content only. Do NOT copy the look.**

| File | Use it for |
|------|------------|
| `assets/mockups/mintzer-app-demo.html` | Full clickable demo — what happens when user taps |
| `assets/mockups/home-samples.html` | Home card **fields** (what text goes where) |
| `assets/mockups/place-order-locked.html` | Place order **behaviour** (timer, Order ID dock) |
| `assets/mockups/mintzer-full-flow.html` | Login → end journey |

**Your design should look totally different** — fresh layout, spacing, typography, imagery. Same screens and same info, new visual identity.

Full specs (if needed): folder `docs/screens/` + `docs/design/FOR-DESIGNER.md`

---

## Must keep (product — not visual style)

- Bottom nav: **Home · Orders · Wallet · Profile** (4 tabs only)  
- Home deal card fields: image, store logo, GST badge, title, color, bank row, You spend, Earn button  
- No Withdraw on Wallet  
- KYC = Name + PAN on **first Accept only** (not at login)  
- Primary colour: **#1A73E8** (Google blue — can style around it, don’t switch to purple/orange competitor look)  
- English + Hindi (v1)

---

## Login — returning user (NEW)

After OTP success:

| User | Show |
|------|------|
| **New user** | Go to Home (normal) |
| **Old user** (has name on account) | Short welcome, e.g. **“Welcome back, Arun”** then Home |

- Use first name from profile (backend sends it after OTP).  
- One line is enough — not a full onboarding screen.  
- Suspended user → Account suspended screen (not Home).

---

## What to deliver in Figma

1. All **14 pages** — light + dark  
2. All **11 popups/sheets**  
3. Both **Place order** layouts  
4. Component library (buttons, inputs, cards, nav, snackbar)  
5. Realistic product photos in cards (not grey boxes)

---

## Questions?

Reply in group. Spec owner: client / dev team.

**Repo path:** `Mintzer-App/docs/design/DESIGNER-WA-BRIEF.md`
