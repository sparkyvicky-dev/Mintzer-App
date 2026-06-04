# ChatGPT rules — paste with every Figma prompt

Copy **BLOCK A** every time. Paste **BLOCK B** (one screen MD) below it. Ask ChatGPT to output **one Figma AI prompt**.

---

## BLOCK A — always paste this

```
You are writing ONE prompt for Figma AI (or similar) to generate a mobile app screen.

APP: Mintzer — Indian fintech deals app (Flipkart/Amazon card deals). Android-first.

STYLE (LOCKED):
- Google Material light theme — clean, trustworthy — NOT purple gradients, NOT dark/gold PerkPay clone
- Primary blue: #1A73E8 (buttons, links, active states)
- Background: #F8F9FA · Cards/surface: #FFFFFF
- Text primary: #202124 · Secondary/hints: #5F6368
- Success/earn green: #188038 · Error: #D93025
- Timer: amber bg #FEF7E0, text #E37400
- Dividers/borders: #E8EAED
- Rounded buttons (~24dp radius), min tap height 48dp, 8dp spacing grid

LOGOS (temporary):
- Mintzer logo = text "Mintzer" in #1A73E8 OR grey placeholder box — NOT final brand
- Flipkart/store/bank = grey circle/tile #E8EAED with letter (F, AX) — do NOT recolor official logos
- When real logo arrives, only swap asset — do NOT change app blue

FRAME:
- Phone: 390 × 844 (or 360 × 800)
- Status bar + content — no desktop layout

VALIDATION UX (show in design where relevant):
- Wrong field input → red text UNDER the field (#D93025) + red field border
- API / network / duplicate / success (Copied, Saved) → small dark SNACKBAR bottom-RIGHT (#323232 bg, white text)
- Primary button DISABLED until required fields valid

COMPONENTS:
- Primary button: filled #1A73E8, white label
- Secondary: outline #1A73E8
- Text fields: white bg, #E8EAED border, focus border #1A73E8
- Copy buttons on address rows: light blue pill #E8F0FE / #1A73E8 text

DO NOT:
- Withdraw button in Wallet
- Purple AI gradient backgrounds
- Stretch logos
- iOS-only chrome unless specified
- Alert dialogs for simple validation (use inline + snackbar)

OUTPUT FORMAT:
Write ONE detailed Figma prompt (paragraph + bullet list of every UI element top to bottom).
Include: layout, copy/labels, colors with hex, states (default + error example if form), spacing notes.
End with: "Style: Material light Mintzer v1"
```

---

## BLOCK B — paste one screen spec

For **Home**, paste [HOME-FIGMA-PROMPT.md](./HOME-FIGMA-PROMPT.md) BLOCK B or full `02-home.md`.
**Also paste** `## Validation` and `## Colors` sections from that file.

For **Place order**, add: "Match layout in place-order-locked.html — external 2-row bottom dock OR in-app 1-row dock."

For **KYC / Bank**, paste from `docs/design/BANK-AND-PAYOUT-DETAILS.md`.

---

## Example message to ChatGPT

```
[PASTE BLOCK A]

SCREEN SPEC:
[PASTE 01-login.md contents]

Task: Write one Figma AI prompt for Login — phone screen only. Include empty state, invalid phone inline error, and example snackbar for wrong OTP.
```

---

## Design order (same as flow HTML)

1. Login phone · 2. Login OTP · 3. Home · 4. Deal detail  
5. Overlays: KYC · Bank · Shop mode  
6. Place order (external + in-app) · 7. Success · 8. My Orders · 9. Order detail  
10. Wallet · ~~11. Offers~~ · 12. Profile · 13. Account suspended · 14. Account deleted  

Reference: `assets/mockups/mintzer-full-flow.html`

---

## Extra refs (only when needed)

| Topic | File |
|-------|------|
| All colors | `COLORS-AND-TOKENS.md` |
| All validations | `VALIDATION-UX.md` |
| Place order layout | `place-order-locked.html` |
| Home (LOCKED) | `HOME-FIGMA-PROMPT.md` · `home-samples.html` |
