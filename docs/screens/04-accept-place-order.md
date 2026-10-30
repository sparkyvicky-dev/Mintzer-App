# Screen: Place order (after Accept) — LOCKED v3 final

**Status:** LOCKED v3 — final bottom dock + tap-to-paste  
**Spec:** [../design/PLACE-ORDER-REQUIREMENTS.md](../design/PLACE-ORDER-REQUIREMENTS.md)  
**HTML mockup:** `assets/mockups/place-order-locked.html`  
**Designer TEST visual (LOCKED 2026-09-17):** `assets/mockups/mintzer-designer-taste-demo.html` — You pay | You earn · step rail 1–2–3 · ring timer · small Generate new address button

## Purpose

Main area after Accept: user **checks model, color, variant**, copies address, orders on store, submits Order ID before timer ends.

## External (Open Flipkart)

Single scroll · product · checkout · **Open Flipkart** (no scroll) · address copy · Generate new.

**Bottom dock (2 rows, fixed):** timer · tap-to-paste Order ID + Submit

## In-app (WebView)

Flipkart WebView · PerkPay drag-up sheet (Deal · Delivery · Help).

**Bottom dock (1 row, fixed):** `timer · Order ID field · Submit`

## Tap-to-paste Order ID (LOCKED)

One tap on empty field = paste from clipboard. No Paste button. See spec for empty/filled states.

## Shopping mode choice

Unchanged — first-time sheet + Remember + Change chip. Mockup: `mintzer-place-order-mode-choice-mockup.png`

## Generate new address

Link under address → confirm → new lines, **same pincode**. Weekly limit from backend.

## Entry points

Deal Accept · Home strip · My Orders Continue order · push/deep link

## Rules

One placement · timer from backend · cancel · KYC/bank first Accept only · duplicate Order ID blocked

## Backend

`POST /placements/:id/confirm` · `POST /user/address/regenerate` · `GET /placements/active`

## Colors (Figma)

**Tokens:** [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md) · mockup: `place-order-locked.html`

| Element | Light |
|---------|-------|
| Background | `#F8F9FA` |
| Checkout box border | `#1A73E8` |
| Open Flipkart zone | bg `#EAE6F1`, dashed `#1A73E8` |
| Copy buttons | bg `#EAE6F1`, text `#1A73E8` |
| Timer | bg `#FEF7E0`, text `#E37400`, time `#D93025` |
| Bottom dock border | `#188038` |
| Submit button | `#1A73E8` |
| Generate new link | `#1A73E8` |

**Store/card logos:** Grey placeholder tiles until PNG.

## Validation

| Trigger | UX |
|---------|-----|
| Empty Order ID on Submit | **Inline** on field · button disabled |
| Bad paste / empty clipboard | **Snackbar** bottom-right |
| Duplicate Order ID | **Snackbar** |
| Timer expired | Block submit · **Snackbar** or banner |
| Copy address line | **Snackbar** *Copied* |

**Full rules:** [../design/VALIDATION-UX.md](../design/VALIDATION-UX.md)

## 14 Oct 2026

Not part of the delivery-call update. This screen stays as written above.
