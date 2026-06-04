# Orders — Page requirements (designer handoff)

**Purpose:** What must exist on each screen. Not visual style instructions.

**Mockups:** `assets/mintzer-my-orders-list-mockup.png` · `assets/mintzer-order-inside-mockup.png` · `assets/mintzer-add-note-mockup.png`

**vs PerkPay:** Mintzer does **not** rely on a separate “Update Order ID” notification as the main way to resume. **Home active strip + My Orders (with timer)** guide the user when they leave or reopen the app. Push is **supplementary** (timer warnings, step reminders) — see [../backend/07-notifications.md](../backend/07-notifications.md).

---

## Resume after Accept (user leaves or closes app) — LOCKED

Applies whenever user **Accepts** (any shopping mode) and has **not** yet submitted Order ID / screenshot.

| Surface | Must show |
|---------|-----------|
| **Home** | **Active order strip** — product name + **countdown** + “Tap to continue” → **Place order** |
| **My Orders → Ongoing** | Same active deal as **top card** (or “Needs action first”) with **visible timer** + primary **Continue order** (same destination as strip) |
| **App reopen (cold start)** | Land on **Home** (or last tab if you prefer — default **Home**). If active placement exists: strip **always** visible; optional **once per session** resume banner: “You have an order in progress — **Continue**” → Place order |
| **Deep link / push** | `mintzer://accept/:placementId` → Place order (not deal detail) |

**Must not:** Require user to remember only notifications (PerkPay-style). Ongoing placement must be findable in **My Orders** without submitting Order ID first.

**After Order ID / screenshot submitted:** placement card becomes normal **order** card; timer strip on Home disappears; user may accept a new deal.

---

## Page: My Orders (list)

### Must show
- Screen title: My Orders
- Search: one field — matches **Order ID**, **Tracking ID**, **product name / model**
- Filter: **Store** (All + each store you support)
- Sort: default **Newest first**; options **Oldest first**, **Needs action first** (see below)
- Tabs: **Ongoing** | **Completed** (badge count on Ongoing = orders needing user action)
- List of order cards (newest first unless sort says otherwise)
- Pull to refresh
- Empty Ongoing: message + **Browse deals** action
- Empty Completed: short message only
- Help entry (FAB or header icon) — general support

### Each list card must show
- Short **Mintzer reference** + copy (`ORD…` for confirmed orders; `PLC…` or placement ref while timer active — backend assigns)
- Current status in **one plain sentence** (not six mini icons only)
- Product image, name, store
- **Earn amount** for that deal/order
- **Placement phase (before Order ID submit):** show **countdown** on card (e.g. `Complete order in 12:34`) — same timer as Place order screen
- **One primary action** when user must do something — label = the task:
  - Placement active → **Continue order** (opens Place order)
  - After confirm → Add tracking, Upload invoice, etc.
- If nothing to do: status sentence only, no fake button

### Must not
- Full money breakdown (belongs on deal detail)
- Tracking / OTP / invoice inputs on the list card
- Instant orders tab (v1 regular only)

### Sort: “Needs action first” (clarity)

**Meaning:** Orders where **the user must do something in the app** appear at the **top** of Ongoing.

| Counts as needs action | Does not |
|------------------------|----------|
| **Active placement — Continue order** (timer running, no Order ID yet) | Waiting for Mintzer (parcel not received yet) |
| Add tracking ID | Payment countdown running (user already uploaded invoice) |
| Enter delivery OTP | Paid / canceled |
| Upload / re-upload invoice | |
| Change courier after wrong detect | |

**Does not include:** orders that are only waiting on Mintzer or on bank/payment timer with no tap required.

**Badge on Ongoing tab** = number of orders in “needs action” state.

### Behaviors
- **Active placement** appears in Ongoing **immediately after Accept** (before Order ID) — with timer + **Continue order**
- **Confirmed order** stays in Ongoing after Order ID / screenshot submit; stepper steps apply as today
- Tap placement card → **Place order** (or Order detail with placement state that hosts timer + **Continue** — same screen destination)
- Tap confirmed order card → **Order detail** (inside order page)
- Completed tab: paid orders + **canceled** orders (show **Canceled** label — not mixed with Paid without distinction)
- **Duplicate external Order ID:** if same Flipkart/Amazon order ID already exists on another Mintzer order → **block Save** — user cannot proceed with duplicate (override only via ops/admin if ever needed)

---

## Page: Order detail (inside one order)

### Header must show
- Back to list
- Order / placement reference + copy
- **Add note** control (see Notes section below)
- **Report / support** control for **this order only** (icon) — opens issue flow tied to order ID (confirmed orders only; optional hide during placement-only if no order id yet)
- **Cancel order** control (allowed until **before delivered** — includes **out for delivery**; during **placement phase**, cancel = cancel placement)

### Placement phase on Order detail (before external Order ID)

When user opens detail while timer still active and Order ID not submitted:

| Element | Behavior |
|---------|----------|
| **Timer** | Prominent — same countdown as Place order / list card |
| Primary CTA | **Continue placing order** → Place order screen |
| Stepper | **Accepted** ✓ · **Ordered** (current) — external Order ID empty until submit on Place order |
| Link | **Open {store}** / **Shop in app** — respects saved shopping mode |
| Submit Order ID | On **Place order** Submit tab (v1); detail may show read-only empty until submitted |

Timer visible on **list card**, **detail**, and **Place order** — all sync to same `expiresAt`.

### Product block must show
- Product image, name, store
- Earn amount for this order (single number)

### Progress must show
- All steps in order, with clear **completed / current / locked / waiting on Mintzer** state
- **Only one step expanded** for input at a time
- Completed steps: what was submitted (no per-step timestamp required v1)

### Notes (user reference) — LOCKED

| Rule | Detail |
|------|--------|
| Purpose | **User’s own reminder** only — not sent to ops as ticket; not required |
| Where | **Order detail** header — **Add note** / **Edit note** |
| UI | Modal or bottom sheet: title “Add note” · subtitle “For your reference” · one text area · **Save** · **Cancel** |
| Limit | Max **200** characters (v1) |
| Placement phase | Note stored on **placement**; copies to **order** on confirm |
| Confirmed order | Note on order; editable anytime |

### Step: Order placed
- Confirmed date/time
- External Order ID user submitted (read-only + copy)

### Step: Tracking
**Inputs (minimal):**
- Tracking ID (paste-friendly)
- Delivery partner

**Behaviors:**
- On paste or typing tracking ID: **auto-select courier** when pattern matches (Ekart, Delhivery, Blue Dart, DTDC, etc.) using rules/samples client provides
- Show detected partner clearly: “Detected: Ekart”
- **Change partner** always available: “Wrong? Change courier” → dropdown
- Do **not** ask for extra fields (no partner phone, no weight, etc.)
- **Save** confirms step; unlock next step
- Helper text: tracking ID usually appears after shipment SMS/email

**Useful copy:** optional “Paste from SMS” chip if OS allows pasteboard read

### Step: Out for delivery
**Inputs (minimal):**
- Last 4 digits of delivery person mobile
- Delivery OTP (6+ digits)

**Must not:** full phone number, delivery address again

### Step: Waiting (system)
- Message: waiting for Mintzer to confirm delivery (parcel received)
- No upload button
- No user input

### Step: Invoice
**Before unlock:** locked + short reason  
**After unlock:** upload (photo/PDF) + submit  
**Behaviors:**
- User cannot upload until backend marks parcel received
- If admin **does not accept** invoice in admin panel: order stays on invoice step — show **Re-upload invoice** + **short reason from ops** (required backend field)

### Step: Payment
- Countdown from invoice submit: **48 hours** to zero (configurable backend)
- Message: payment review in progress
- At zero: payment processing / will reflect in wallet (exact copy TBD)

### Cancel order (from this page)

**Control:** Cancel order (destructive, not hidden in menu)

**Flow:**
1. Tap Cancel
2. Confirm: “Cancel this order?”
3. **Reason required** — pick one (no long essay)

**Preset reasons (v1 minimum):**
- Canceled by seller
- Canceled by marketplace (Flipkart / Amazon)
- Could not use required card
- Price higher than deal at checkout
- Product out of stock / deal not available
- Wrong product / wrong variant ordered
- Delivery / pin code problem
- Changed mind — will not complete order
- Other — optional **short** text (max 50 characters)

**After cancel:**
- Order moves to **Completed** with **Canceled** label (not shown as Paid)
- Allowed **until before delivered** — user may cancel even at **out for delivery**; Mintzer can reject parcel
- User can accept new deals
- Ops sees reason in admin

### Report issue = order ticket (this order only)

User can **only** raise a ticket for **the order they are viewing**.

#### Raise ticket flow (guided — not one empty box)

1. Tap **Report issue** on order detail  
2. **Step 1 — Category** (pick one):  
   - Payout / amount wrong  
   - Deal rules unclear  
   - Tracking or delivery  
   - Invoice problem  
   - Cancel / dispute  
   - Other  
3. **Step 2 — Short questions** (2–4 per category, yes/no or single choice — designer + ops define exact list)  
   Example invoice: “Was invoice rejected?” · “Did you re-upload?”  
4. **Step 3 — Optional message** (one line, max 200 chars)  
5. **Submit ticket**  

**Auto-attached on submit (hidden from user):** Mintzer order ID, external order ID, current step, deal name, store, user phone.

**After submit:** confirmation + ticket ID shown.

#### Track tickets (user)

**Must have a place to see ticket status** — e.g.:

- **Profile → My tickets** (list all tickets), and/or  
- **On that order detail** — section “Support ticket” with status when open ticket exists  

**Ticket status values (user-facing):**
- Submitted  
- In progress  
- Resolved  
- Closed  

Show: ticket ID, category, date, status, linked order ref.

#### WhatsApp (optional — admin controlled)

- **v1 app:** ticket flow only — **no WhatsApp button** in app for now  
- **Design room:** on same help area, space for **Contact on WhatsApp** when enabled  
- **Admin panel:** setting **WhatsApp support ON/OFF** (and number/link)  
- When ON: user sees both **Raise ticket** (primary) and **WhatsApp** (secondary) on order detail / help  
- When OFF: only Raise ticket  

WhatsApp opens with **order ref prefilled** in message when possible.

### Must not (inside order)
- Repeat full deal money breakdown
- Ask bank details, KYC again (unless separate global rule)
- Multiple steps expanded at once
- Delivery partner as mandatory manual step when auto-detect works

---

## Smart courier detection (product rule)

Client will supply sample tracking IDs per courier.

| Pattern hint | Partner |
|--------------|---------|
| (samples TBD) | Ekart |
| (samples TBD) | Delhivery |
| (samples TBD) | Blue Dart |
| (samples TBD) | DTDC |

If no match: partner dropdown blank — user must select.  
If wrong auto-match: user changes dropdown before Save.

---

## Client decisions (locked)

| Topic | Decision |
|-------|----------|
| Resume after Accept | **Home strip + My Orders** with timer; not notification-only (unlike PerkPay primary pattern) |
| Placement in Ongoing | Yes — before Order ID submit |
| Timer on My Orders | Yes — list card + order detail + Place order |
| User notes | Yes — Add note on order detail; for user reference only |
| App reopen | Home + active strip; optional once-per-session resume prompt |
| Needs action sort + badge | Yes — includes **Continue order** for active placement |
| Re-upload invoice | Yes — when admin does not accept; show ops reason |
| Duplicate order ID | Yes — **hard block** on duplicate external order ID |
| Order ticket | Yes — guided questions → submit; track status in Profile and/or on order |
| WhatsApp on order help | Off v1; admin toggle ON/OFF for future |
| Cancel | Until before delivered; includes out for delivery |
| Canceled in Completed | Yes — **Canceled** label |
| Timestamps on steps | No |
| SMS paste / push invoice unlock | No v1 |

---

## New page: My tickets (Profile)

**Must show:**
- List of user’s tickets (newest first)
- Each row: ticket ID, order ref, category, status, date
- Tap → ticket detail (questions answered, status timeline, linked order)

**Empty:** “No tickets yet”

---

## Admin panel (support settings)

| Setting | Default |
|---------|---------|
| WhatsApp support enabled | OFF |
| WhatsApp number / deep link | Configurable |

---

## Open (client to confirm)

1. Courier tracking patterns (when samples ready)
2. Exact question sets per ticket category (ops to supply)
