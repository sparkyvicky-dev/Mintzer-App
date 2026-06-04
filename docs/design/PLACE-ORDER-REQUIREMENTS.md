# Place Order screen (after Accept) — requirements

**Status:** **LOCKED v3 — final** — 2026-06-03  
**Theme:** Material light `#1A73E8`; colors per [COLORS-AND-TOKENS.md](./COLORS-AND-TOKENS.md)

**HTML mockup (open in Chrome):** **`assets/mockups/place-order-locked.html`** — external + in-app · **LOCKED**

### Final locked items (v3)

| # | Decision |
|---|----------|
| 1 | **External bottom dock** — timer row + tap-to-paste Order ID field + Submit |
| 2 | **In-app bottom dock** — **single row:** timer · Order ID · Submit |
| 3 | **Tap-to-paste** — one tap on empty field = focus + paste clipboard (no Paste button) |

---

## Must show on this page (simple list)

| Block | Fields |
|-------|--------|
| **Product** | Model (name) · **variant** · **color** · **qty** |
| **Store** | Logo PNG **or** store name text (Flipkart, Amazon…) |
| **Card** | Bank logo PNG **or** card name text (Axis, Any card…) |
| **Money** | **Checkout amount** (hero) · **discount** if any · you earn |
| **Timer** | Complete order in MM:SS |
| **Address** | All lines · **Copy each row** · Generate new address |
| **Actions** | Open {store} · tap-to-paste Order ID · Submit · Cancel |

Optional later: platform fee, card fee, wallet line — under **Details ▾** if not on main view.

---

## What must be visible (one list — both shopping modes)

| # | Element | Notes |
|---|---------|--------|
| 1 | App bar | Back · **Place order** · **Cancel order** |
| 2 | **Product block** | Model · **color** · **variant** · **qty** · store logo/text · card logo/text |
| 3 | **Checkout box** | **Checkout amount** (large) · discount if any · **you earn** |
| 4 | Mode chip | Change shopping mode (in-app sheet when expanded) |
| 5 | **Open {store}** | External only — right after checkout, no scroll |
| 6 | **Address block** | External: scroll below Open · In-app: Delivery tab · Copy each line |
| 7 | **Bottom dock (fixed)** | See mode below — always visible |

**Mockup:** `place-order-locked.html`

**External:** timer row + tap-to-paste Order ID + Submit.  
**In-app:** **one row** — timer · Order ID · Submit.

**No 3 tabs on external.** Short scroll OK for address lines.

---

## Delivery address block (LOCKED)

**Like PerkPay reference:** one row per Flipkart field, **Copy button on each row**.

| Field | Copy |
|-------|------|
| Name | ✓ |
| Address line 1 | ✓ |
| Address line 2 | ✓ (hide if empty) |
| City | ✓ |
| State | ✓ |
| Pincode | ✓ |
| Phone | ✓ |

**Hint:** *Paste each line into the matching field on Flipkart*

### Copy all — optional only (not main button)

- Small text link at bottom of block: *Copy all (optional)*
- Copies one text block — **does not replace line-by-line** (FK uses separate fields)
- **Do not** use large “Copy all” as primary CTA

Toast on Copy: *Copied*

---

## Bottom dock (LOCKED)

Fixed to bottom — **never scrolls away.**

### External — two rows

| Row | Content |
|-----|---------|
| 1 | **Timer** — ⏱ Complete order in **MM:SS** |
| 2 | **Tap-to-paste field** + **Submit** |

**No separate Paste button.** User copies Order ID on Flipkart → returns to Mintzer → **one tap on the field** = focus + paste from clipboard.

| State | Field shows |
|-------|-------------|
| Empty | *Tap to paste Order ID* (hint text) |
| After tap | Clipboard text filled in · toast *Pasted* |
| Already filled | Tap to edit / keyboard |

Validate pasted text (trim, FK order ID pattern). If clipboard empty → toast *Copy Order ID from Flipkart first*.

**All validation patterns:** [VALIDATION-UX.md](./VALIDATION-UX.md) — field = inline · action/API = **snackbar bottom-right**

### In-app — single row

| Layout | `[ ⏱ MM:SS ]` · `[ Order ID field ]` · `[ Submit ]` |

Compact timer pill · same tap-to-paste on field · no Paste button · fits small phones.

---

## Generate new address (LOCKED v2)

| Rule | Detail |
|------|--------|
| Where | Link under address block |
| Action | Tap → confirm dialog → new address lines from admin pool |
| Pincode | **Unchanged** per user |
| After | Toast *Address updated — copy each line again* |
| Limit | Max regens per week (backend config, e.g. 2) — show *N left this week* |
| API | `POST /user/address/regenerate` → returns new `deliveryAddress` |

Replaces old bulk Excel-per-deal address upload.

---

## Address data

- **One current address per user** from admin pool (pincode fixed).
- Shown only on **Place order** (not Deal detail).
- **My Orders → Continue order** reopens same screen.

---

## Two shopping modes

| Mode | Default? | Layout |
|------|----------|--------|
| **External** | **Yes** | Single scroll · Open FK after checkout · bottom dock |
| **In-app WebView** | Optional | WebView + PerkPay sheet · same bottom dock |

First-time **How do you want to shop?** sheet unchanged — see mode choice mockup.

---

## Mode — External (Open Flipkart)

**Mockup:** `place-order-locked.html` (top section)

| # | Block |
|---|--------|
| 1 | App bar |
| 2 | Scroll: product · checkout ₹ · **Open Flipkart** · address copy · Generate new |
| 3 | **Bottom dock** | Timer row · tap-to-paste Order ID · Submit |

---

## Mode — In-app (WebView) — LOCKED

**Mockup:** `place-order-locked.html` (in-app section)

### Screen stack (top → bottom)

| # | Block | Detail |
|---|--------|--------|
| 1 | App bar | Back · **Place order** · **Cancel** |
| 2 | **WebView** | Flipkart — **largest when sheet collapsed** |
| 3 | **Bottom sheet** | PerkPay drag-up (expanded only) |
| 4 | **Bottom dock** | **One row:** timer · Order ID · Submit |

### Bottom sheet (expanded)

| Part | Content |
|------|---------|
| Drag handle | Pull up / down |
| Peek row | Hint · blue **⌃ / ⌄** |
| Mode chip | *Ordering in Mintzer* · **Change mode** |
| **3 tabs** | **Deal details** · **Delivery details** · **Help** |
| Tab body | Scroll inside sheet |

**Timer is in bottom dock** (not only in sheet peek).

### Tab content

| Tab | Shows |
|-----|--------|
| **Deal details** | Model · color · variant · qty · store + card · checkout ₹ · discount · earn |
| **Delivery details** | Field rows · Copy each line · Generate new address |
| **Help** | Short steps |

### Default state

Sheet **collapsed** — WebView max · bottom dock always shows timer + Order ID.

### Small / low-RAM phones

One WebView · collapsed default · compact dock · **Open in Flipkart app** if WebView slow.

---

## Shared rules

- Timer from backend · one active placement · cancel with confirm · KYC/bank before first Accept only
- Duplicate Order ID → hard block
- Back → warn “Order in progress”

---

## Flow

```
Accept → [KYC → bank] → [shop mode if first] → Place order (A or B) → Success → My Orders
```

Resume: Home strip + My Orders timer card → same Place order screen.

---

## Backend

- `GET /placements/active` — includes `deliveryAddress` + `dealSnapshot` (product color/variant)
- `POST /user/address/regenerate`
- `POST /placements/:id/confirm` · `POST /placements/:id/cancel`

---

## Decision log (LOCKED v3 — final)

| Topic | Decision |
|-------|----------|
| Main area after Accept | Place order — verify **model, color, variant** + checkout |
| Layout | External: single scroll · In-app: PerkPay sheet |
| **Bottom dock external** | **LOCKED** — timer row + tap-to-paste field + Submit |
| **Bottom dock in-app** | **LOCKED** — **single row** timer · Order ID · Submit |
| **Order ID paste** | **LOCKED** — one tap on field = paste clipboard (no Paste button) |
| Copy address | **Copy per line** (primary) · **Copy all** optional text link only |
| Address fields visible | Yes — Name, Addr1, Addr2, City, State, Pin, Phone |
| Generate new address | Yes — same pincode, weekly limit |
| External layout | Open FK after checkout · bottom dock |
| In-app layout | PerkPay sheet · 3 tabs (Deal · Delivery · Help) |
| HTML mockup | `place-order-locked.html` |
| 3-tab sheet | **External: no** · **In-app: yes** |
