# Module: Notifications

Push, in-app messaging, and notification inbox to drive **deal acceptance**, placement conversion, and order steps — without spam.

**Mintzer vs PerkPay:** PerkPay often uses push (“Deal Bought”, “Update Order ID”) as the main way to return to the app. **Mintzer primary resume = Home active strip + My Orders card with timer.** Notifications are a **secondary tap on the shoulder** (warnings, deal follow-ups, step reminders), not a replacement for in-app visibility.

**Design reference:** In-app bell + push templates — [../design/MINTZER-UI-DESIGN-BRIEF.md](../design/MINTZER-UI-DESIGN-BRIEF.md) § Notifications & deep links.

---

## Strategy summary

| Principle | Rule |
|-----------|------|
| In-app first | Home strip, My Orders, bell inbox reach **100% of active users** |
| Push second | Brings users **back** when app is closed — requires opt-in |
| Intent-based | Fire on **behavior** (viewed deal, started accept), not generic broadcasts |
| Orchestrated | All sends pass through a **gateway** with daily caps and priority — no trigger fires in isolation |
| Rich content | Product image + store + **Earn ₹X** in every deal-related push |
| Real urgency only | Timer and deal-end copy must match server state — no fake scarcity |

---

## Three tiers

### Tier 1 — Deal attention (acceptance & re-engagement)

Goal: get users to **open a deal and accept**. Highest commercial priority when user has **no active placement**.

Includes: deal viewed follow-up, accept abandoned, new high-earn deal, deal ending soon, placement expired re-engage, inactive user comeback.

**Cap:** Counts toward **commercial push budget** (see [Frequency caps](#frequency-caps)).

### Tier 2 — In-funnel (placement & order steps)

Goal: convert an **accepted** placement or move order forward.

Includes: placement timer warnings, order confirmed, tracking reminder, parcel received.

**Cap:** Transactional / behavioral — allowed when relevant; still subject to **global daily cap** except true order-critical timer warnings.

### Tier 3 — Confirmations (wallet, KYC)

Goal: confirm outcomes. Lower urgency.

Includes: payment approved, KYC approved.

**Cap:** Prefer **in-app bell** first; push optional if user has order updates enabled.

---

## Channels

| Channel | When | Reach |
|---------|------|-------|
| **Push (FCM)** | User outside app | Opt-in only (~40–50% typical) |
| **In-app banner** | User on Home / relevant screen | 100% of active session |
| **Notification inbox (bell)** | Persistent list in app | 100% — survives push dismiss |
| **SMS** | Not v1 | — |

**Push-to-in-app stitching:** Tap on push must land on the **exact screen** promised (deal detail, accept, order card) — not generic Home unless copy says “browse deals”.

---

## User intent levels

Map Mintzer funnel to industry browse / cart abandonment patterns:

| Signal | Intent | Follow-up style |
|--------|--------|-----------------|
| Deal detail open **&lt; 5s** | Accidental / low | **No push** |
| Deal detail **≥ 30s** or **2nd view same deal in 24h** | Browse abandon — warm | Gentle sequence (2–4h, +24h, +48–72h) |
| Tapped **Accept**, left before Order ID | Cart abandon — **hot** | Fast sequence (30–60m, +24h if valid) |
| **Active placement** (timer running) | In funnel | **No Tier 1 deal promos** — strip + timer warnings only |
| Order ID submitted | Post-accept | Tier 2 order steps only |

### Suppression rules (always)

- **Active placement** → suppress all `deal.*` discovery and viewed follow-ups
- User **accepted** that deal → stop viewed follow-ups for that `dealId`
- User **disabled Deal alerts** in Profile → suppress Tier 1 commercial
- **Quiet hours** → queue until window opens (except Tier 2 timer at 1 min — always send)
- **Cooldown** after 3 consecutive ignores/dismisses → pause Tier 1 for 7 days

---

## Events — full catalog

### Tier 1 — Deal attention

| Event | When | Deep link | Notes |
|-------|------|-----------|-------|
| `deal.viewed_followup_1` | Detail ≥30s (or 2nd view/24h), no accept, +2–4h | `mintzer://deals/:dealId` | First browse nudge |
| `deal.viewed_followup_2` | Still no accept, +24h from step 1 | `mintzer://deals/:dealId` | Social proof or scarcity if deal `endsAt` near |
| `deal.viewed_followup_final` | Still no accept, +48–72h from step 1 | `mintzer://deals/:dealId` | Final soft nudge then **stop** |
| `deal.accept_abandoned_1` | Accept tapped, left within 15m, no Order ID | `mintzer://accept/:placementId` | Cart-abandon — 30–60m after leave |
| `deal.accept_abandoned_2` | Still no Order ID, +24h | `mintzer://accept/:placementId` | Only if placement/deal still valid |
| `deal.new_high_earn` | New deal above admin threshold | `mintzer://deals/:dealId` | Max 1/day per user |
| `deal.ending_soon` | Deal `endsAt` within configured window | `mintzer://deals/:dealId` | Real end time only |
| `deal.back_in_stock` | Relisted deal user viewed before | `mintzer://deals/:dealId` | Optional v1.1 |
| `user.comeback` | Inactive N days + deals live | `mintzer://home?sort=earn` | Max 1 per 48–72h |
| `placement.expired` | Timer ended, no confirm | `mintzer://deals/:dealId` | Friendly re-accept nudge; no order id |

### Tier 2 — In-funnel

| Event | When | Deep link |
|-------|------|-----------|
| `placement.timer_warning` | Config intervals before expiry (default 5m, 1m) | `mintzer://accept/:placementId` |
| `order.confirmed` | Order ID saved | `mintzer://orders/:orderId` |
| `order.tracking_reminder` | Optional delay after order placed | `mintzer://orders/:orderId` |
| `order.parcel_received` | Admin marked received | `mintzer://orders/:orderId` |

### Tier 3 — Confirmations

| Event | When | Deep link |
|-------|------|-----------|
| `order.payment_approved` | Wallet credited | `mintzer://wallet` |
| `kyc.approved` | KYC verified | Profile / KYC screen |

---

## Deal viewed — follow-up sequence (browse abandon)

**Trigger conditions (all required):**

1. User opened **Deal detail** for `dealId`
2. **No Accept** within that session (and no active placement created for that deal)
3. Qualifying engagement: **dwell ≥ 30s** OR **same deal opened twice within 24h**
4. User has **no active placement** on any deal
5. User has **Deal alerts** enabled (or default ON — see Profile)
6. Not in quiet hours (step 1 queues for next window)

**Do not trigger:** detail open &lt; 5s, user already accepted, deal sold out / hidden.

| Step | Event | Delay from qualify | Example copy |
|------|-------|------------------|--------------|
| 1 | `deal.viewed_followup_1` | 2–4 hours | Title: `Earn ₹300 · Flipkart` · Body: `Motorola G57 — you checked this earlier. Tap to accept.` |
| 2 | `deal.viewed_followup_2` | +24h after step 1 | Title: `Still available — earn ₹300` · Body: `Motorola G57 on Flipkart. Accept before deal ends.` |
| 3 | `deal.viewed_followup_final` | +48–72h after step 1 | Same deal context · then **mark sequence complete** — no 4th push |

**Sequence caps:**

- Max **1 push per day** within this sequence
- Max **3 pushes total per deal per user per 7 days**
- User dismisses push → **24h cooldown** before next `deal.viewed_*` for any deal
- If user opens app and accepts **in-app** (no push tap), cancel pending steps

**In-app (same trigger):**

- **Home:** dismissible card — “You viewed **{productName}** — Earn ₹{youEarn}”
- **Bell inbox:** persistent row until accept or 7 days

---

## Accept abandoned — follow-up sequence (cart abandon)

**Trigger:** User reached Accept / Place order screen (`placement` created or accept flow started), then **left app** without Order ID or screenshot within **15 minutes**.

Higher intent than browse — faster timing. Does **not** replace `placement.timer_warning` (those fire on schedule until expiry).

| Step | Event | Delay | Example copy |
|------|-------|-------|--------------|
| 1 | `deal.accept_abandoned_1` | 30–60 min after leave | `You started this deal — earn ₹300. {N} min left to place order.` |
| 2 | `deal.accept_abandoned_2` | +24h | Only if placement still active or deal still live |

**Caps:** Max **2 pushes** per placement for this flow. Idempotent — one send per step per `placementId`.

---

## Notification gateway (orchestration)

All notification requests **enqueue**; a scheduler sends winners per user per day. Modeled after centralized gateways (e.g. Uber CCG) — avoid conflicting campaigns.

### Priority (high → low)

1. `placement.timer_warning` at **1 min**
2. `deal.accept_abandoned_*`
3. `deal.viewed_followup_*` (high dwell / 2nd view)
4. `placement.timer_warning` at **5 min**
5. `deal.new_high_earn` / `deal.ending_soon`
6. `user.comeback`
7. Tier 2 reminders (tracking, etc.)
8. Tier 3 confirmations

When daily budget is full, **drop lower priority** — never drop 1 min timer warning.

### Per-send checks

```
1. Event + payload enqueued
2. User state: active placement? opted out? cooldown?
3. Intent score (optional v1.1) — dwell time, repeat views, earn amount
4. Apply frequency caps
5. Apply quiet hours (queue or drop by tier)
6. Dedupe / idempotency key
7. Send push + write bell inbox row
8. Log: sent, opened, dismissed, converted (accept within 24h)
```

**Idempotency keys:** `{event}:{userId}:{dealId|placementId}:{step}` — prevent duplicate sends on worker retry.

---

## Frequency caps

Industry benchmarks: **46%** opt-out after 2–5 msgs/week; **6+/week** correlates with **3.4×** uninstall risk. Mintzer defaults are conservative.

| Cap | Default | Config key |
|-----|---------|------------|
| Max pushes per user per **day** | 2 | `notificationMaxPushPerDay` |
| Min gap between any two pushes | 8 hours | `notificationMinGapHours` |
| Max **commercial** (Tier 1) pushes per **week** | 4 | `notificationMaxCommercialPerWeek` |
| Max deal-viewed sequence per deal per 7 days | 3 | — (fixed) |
| Max `deal.new_high_earn` per day | 1 | — |
| Max `user.comeback` | 1 per 48h | — |
| Quiet hours | 22:00–08:00 IST | `notificationQuietHoursStart/End` |
| Ignore cooldown | 3 ignores → 7 day Tier 1 pause | `notificationIgnoreCooldownDays` |

**Exceptions:** `placement.timer_warning` at 1 min may bypass quiet hours and daily cap if it is the only way to save a valid placement.

---

## Payload shape

### Standard push + inbox row

```json
{
  "type": "deal.viewed_followup_1",
  "title": "Earn ₹300 · Flipkart",
  "body": "Motorola G57 — you checked this earlier. Tap to accept.",
  "imageUrl": "https://cdn.mintzer.in/deals/deal_123/product.png",
  "data": {
    "dealId": "deal_123",
    "placementId": null,
    "storeSlug": "flipkart",
    "youEarn": 300,
    "deepLink": "mintzer://deals/deal_123",
    "campaignId": "viewed_followup_1:usr_1:deal_123",
    "tier": 1
  }
}
```

### Timer warning (Tier 2)

```json
{
  "type": "placement.timer_warning",
  "title": "1 minute left",
  "body": "Finish checkout to lock ₹300 earn on Motorola G57.",
  "data": {
    "placementId": "placement_xyz",
    "dealId": "deal_123",
    "deepLink": "mintzer://accept/placement_xyz",
    "minutesRemaining": 1,
    "tier": 2
  }
}
```

**Rich push (recommended):** include `imageUrl` (product) and optional `storeLogoUrl` — higher CTR than text-only.

---

## Deep links

| Path | Screen |
|------|--------|
| `mintzer://accept/:placementId` | Accept / place order |
| `mintzer://deals/:dealId` | Deal detail |
| `mintzer://orders/:orderId` | My Orders expanded card |
| `mintzer://wallet` | Wallet |
| `mintzer://home?sort=earn` | Home, highest earn sort |

---

## Copy guidelines

**Do:**

- Lead with **Earn ₹X** and store name (same as Home card)
- Name the **product** (model)
- One clear action implied by deep link
- Use **real** timer / deal end times from server

**Don’t:**

- “Open Mintzer” / “You have a notification” with no deal context
- Fake countdown or fake “only 2 left” unless backed by admin inventory rules
- More than one deal in a single push (v1)

**Examples:**

| Bad | Good |
|-----|------|
| Don’t miss out! | Earn ₹450 · Flipkart |
| Check the app | Motorola G57 — spend ₹17,519 · tap to accept |

---

## Permissions & Profile toggles

| Moment | Action |
|--------|--------|
| Login | **Do not** block on notification permission |
| After **first successful accept** | Soft pre-prompt: “Get notified when high-earn deals go live and when your order timer is running?” → OS permission |
| Profile → Settings | User-controlled toggles (see below) |

### Profile toggles (Settings)

| Toggle | Default | Controls |
|--------|---------|----------|
| **Deal alerts** | ON | Tier 1: viewed follow-up, new high earn, ending soon, comeback |
| **Order updates** | ON | Tier 2: timer warnings, tracking, parcel received |
| **Payment & wallet** | ON (or in-app only) | Tier 3: payment approved, KYC |

Master **Push notifications** OFF disables all push; bell inbox may still show in-app history (configurable).

---

## Expired placement — re-engage

On `placement.expired`:

- Push: friendly nudge to open deal and accept again
- Deep link: `mintzer://deals/:dealId`
- Do **not** reference an order id (none created)
- Logged in admin only
- Counts as Tier 1 commercial

---

## Implementation notes

- Store **FCM token** per user device; refresh on app launch
- Log client events: `deal.detail_open`, `deal.detail_dwell_30s`, `deal.detail_repeat_view`, `accept.screen_open`, `accept.abandon` — backend schedules sequences
- **Cancel** pending viewed follow-ups when user accepts that deal or any new placement starts
- **Dedupe** timer warnings per `placementId` + interval
- Track metrics: send, open, dismiss, accept-within-24h, opt-out, uninstall correlation
- Admin: notification send log with filter by event type and campaign id

### Analytics events (client → backend)

| Event | Properties |
|-------|------------|
| `deal.detail_open` | `dealId`, `timestamp` |
| `deal.detail_dwell` | `dealId`, `seconds` (fire at 30s) |
| `deal.detail_repeat_view` | `dealId`, `viewCount24h` |
| `accept.flow_start` | `dealId`, `placementId` |
| `accept.flow_abandon` | `placementId`, `secondsOnScreen` |
| `notification.open` | `campaignId`, `type` |
| `notification.dismiss` | `campaignId`, `type` |

---

## Config

See [08-app-config.md](./08-app-config.md) for:

- `placementWarningMinutes` — timer warning intervals
- `notificationMaxPushPerDay`, `notificationMinGapHours`, `notificationMaxCommercialPerWeek`
- `notificationQuietHoursStart`, `notificationQuietHoursEnd`
- `dealViewedFollowupDelaysHours` — default `[3, 24, 48]`
- `dealViewedMinDwellSeconds` — default `30`
- `dealHighEarnThresholdInr` — min earn for `deal.new_high_earn`
- `dealEndingSoonHours` — window for `deal.ending_soon`
- `userComebackInactiveDays` — default `3`

---

## Related docs

- Placements & timer: [03-placements.md](./03-placements.md)
- Orders lifecycle: [04-orders.md](./04-orders.md)
- App config keys: [08-app-config.md](./08-app-config.md)
- Screen deep links: [../screens/README.md](../screens/README.md)
- Profile toggles: [../design/PROFILE-REQUIREMENTS.md](../design/PROFILE-REQUIREMENTS.md)
