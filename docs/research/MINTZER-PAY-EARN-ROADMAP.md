# Mintzer Pay & earn — implementation roadmap (future)

**Status:** Planning only — **not v1 scope**  
**Parent handoff:** [AGENT-PIEPAY-AND-PAY-EARN-HANDOFF.md](./AGENT-PIEPAY-AND-PAY-EARN-HANDOFF.md)  
**v1 specs (ship first):** [../AGENT-DEV-PROCESS.md](../AGENT-DEV-PROCESS.md)

Owner wants PiePay-style **Pay & earn** eventually. Build **after** refreshed holder app v1 (Order & earn) is live unless owner reprioritizes.

---

## Phase 0 — v1 holder app (current priority)

**Goal:** Mintzer public app per locked specs — admin deals, dealer address, Order ID.

| Deliverable | Reference |
|-------------|-----------|
| Flutter app mock → API | `docs/frontend/` |
| Place order, timer, address copy | `docs/design/PLACE-ORDER-REQUIREMENTS.md` |
| Integrate live `newapp` API | `docs/backend- for developer reference/` |

**No WebView session relay in Phase 0.**

---

## Phase 1 — Pay & earn “manual” (lowest risk pilot)

**Goal:** Test marketplace demand without session magic.

| Buyer | Holder |
|-------|--------|
| Paste FK/Amazon product link in Mintzer | Sees job in Pay & earn feed |
| Sees estimated save + platform price | Accepts |
| Pays Mintzer UPI | Orders normally to **buyer address** (holder places order) OR pays if session added later |

**Backend:** Job queue, matching by card, UPI, notifications.  
**Skip:** Cookie handoff (holder uses own merchant login + buyer shipping details from job).

**Validates:** Matching, UPI, wallet, commissions before fragile WebView work.

---

## Phase 2 — WebView shop (buyer only)

**Goal:** Buyer browses FK/Amazon inside Mintzer; stop at payment; create job with **parsed product + price** (no session yet).

| Build | Tech |
|-------|------|
| Merchant WebView | `webview_flutter` |
| Parse product/price at checkout | JS injection or URL/cart intercept |
| Offer estimate | Internal card-offer rules DB |
| Match + UPI | Same as Phase 1 |

Holder still completes order via **Order & earn**-style flow (manual) until Phase 3.

---

## Phase 3 — Session relay (full PiePay parity)

**Goal:** Holder pays on **buyer's checkout session**; order on buyer account.

| Layer | Work |
|-------|------|
| Mobile | Cookie export/import (`webview_flutter` + secure storage or native plugin) |
| Mobile | Encrypt session client-side before upload |
| Mobile | Holder 4-step UI (see handoff doc §4) |
| Mobile | DOM watchers for amount/fee/card last-4 |
| Backend | Session store, TTL, one-time tokens, job state machine |
| Backend | Unlock holder pay only after buyer UPI webhook |
| Ops | Monitoring when FK/Amazon change checkout HTML |

**Merchants:** Flipkart first, Amazon second (separate parsers).

---

## Phase 4 — Scale & ops

- Returns/cancellations workflow  
- Dispute resolution  
- Holder/buyer ratings, limits  
- Remote config to disable merchant if broken  
- Sentry/logging (optional session replay — privacy review)  

---

## Suggested Flutter packages (when building)

| Need | Package direction |
|------|-------------------|
| WebView | `webview_flutter` |
| Cookies | Custom platform channel or community cookie plugin (evaluate Android/iOS parity) |
| UPI / PG | Cashfree or Razorpay Flutter SDK (match PiePay APK choices) |
| Push | FCM + local notifications |
| State restore | Job id persisted; fetch status on app launch |

**PiePay uses React Native, not Flutter** — patterns transfer; code does not.

---

## Backend additions (on top of `newapp`)

New modules likely required (names illustrative):

```
POST /buyer/checkout-jobs          — create from buyer WebView
POST /buyer/checkout-jobs/{id}/pay — initiate UPI
GET  /holder/pay-earn-deals         — feed
POST /holder/deals/{id}/accept
GET  /holder/deals/{id}/session    — encrypted blob for WebView
POST /holder/deals/{id}/step        — report step 1/2/4 completion
POST /webhooks/cashfree|razorpay     — buyer paid
```

Exact shapes TBD after HTTP capture or greenfield design with owner.

**Do not** assume admin deal APIs cover this — separate product surface.

---

## Screen inventory to add (future design task)

| Screen | User |
|--------|------|
| Shop home / merchant picker | Buyer |
| In-app shop WebView + progress header | Buyer |
| Offer sheet + Buy now | Buyer |
| Matching + tip slider | Buyer |
| Pay Mintzer (UPI) | Buyer |
| Order processing | Buyer |
| Pay & earn deal list | Holder |
| Pay for buyer detail | Holder |
| Holder checkout WebView + step sheet | Holder |
| Success / earn confirmed | Both |

Add to `docs/screens/SCREEN-INVENTORY.md` when owner locks Pay & earn scope.

---

## Effort rough order (agent planning)

| Phase | Relative effort |
|-------|-----------------|
| 0 v1 holder | Baseline (in progress) |
| 1 Manual Pay & earn | Medium |
| 2 WebView shop | Medium–High |
| 3 Session relay | **Very High** + ongoing maintenance |
| 4 Ops | Ongoing |

---

## Decision log (for future agents)

| Date | Decision |
|------|----------|
| Aug 2026 | Document PiePay; v1 remains Order & earn |
| Aug 2026 | Owner interested in Pay & earn for income — phased approach |
| — | Payment gateway choice for Mintzer: TBD |
| — | Same app (buyer+holder modes) vs two apps: TBD (PiePay uses one app, two tabs) |

---

*Update this file when owner approves a phase or API capture completes.*
