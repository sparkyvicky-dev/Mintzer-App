# Place Order screen (after Accept) — requirements

**Status:** **LOCKED v3 — final** — 2026-06-03 (brand-blue dock + tap-to-paste)  
**Designer TEST visual:** **LOCKED 2026-09-17** — live in `assets/mockups/mintzer-designer-taste-demo.html`  
**Theme:** Material light `#1A73E8`; colors per [COLORS-AND-TOKENS.md](./COLORS-AND-TOKENS.md)

**HTML mockup (open in Chrome):** **`assets/mockups/place-order-locked.html`** — external + in-app · **LOCKED** (brand blue)

### Designer TEST visual (LOCKED 2026-09-17)

Do not change these without client sign-off. Live: **`mintzer-designer-taste-demo.html`**. Brand primary is mintzer.in `#9C71E4` (app `#7B61FF`).

| # | Decision |
|---|----------|
| 1 | **You pay \| You earn** — split checkout box. Caption flow still: open store → paste Order ID → earn. Earn stays strong; block may be slightly more compact. |
| 2 | **Steps 1–2–3** — numbered rail · Open → address → Order ID. Completed steps turn **green ✓**. |
| 3 | **Timer** — sticky **Reserved · mm:ss remaining** + purple **ring** in the dock next to Order ID + Confirm (turns red under 2 minutes). |
| 4 | **Change address** — quiet text under address (was Generate new address). Confirm dialog unchanged. |

### Flutter = ChatGPT Place order layout (20 Sep 2026)

Full visual in `place_order_screen.dart`: product + pay/earn · Instructions before checkout · steps Open → Delivery/GST → Order ID + **Confirm order** stacked · timer pill in app bar · ring kept at bottom · Copy all · Change address · GST *required for payout* wording · amber don’t-search · shared `placementEndsAt`.

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

**Copy button on each row.** Same field set for **GST and non-GST** (20 Sep 2026):

| Field | When shown | Paste into |
|-------|------------|------------|
| **Search on map** | Always | Location / area search (searchable words only) |
| **Flat / House** | Always | Flat/House/building |
| Name · Phone | Always | Name / mobile |
| GSTIN · Company | **GST deals only** — **GSTIN above Company** | Checkout GST fields. GSTIN has Copy; Company is display-only (no Copy) |

Hint under rows (store-aware). No map/pin UI in Mintzer.

### Copy all — optional only

- Copies Search → Flat → Name → Phone (+ GSTIN if GST; not Company)
- Does not replace line-by-line Copy

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

First-time **How do you want to order?** sheet unchanged — see mode choice mockup.

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
