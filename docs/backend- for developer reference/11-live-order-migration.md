# Live Play orders → new UI (LOCKED)

**Status:** LOCKED 2026-09-18  
**Why this file exists:** The card-holder app is already on Play (`com.mintzer`). The new UI is a **new viewer** of the **same `orders` rows**. Do not invent a second history.

**Live backend:** Laravel `newapp` on Hostinger (`app.mintzer.in`). Facts from admin dump + [Mintzer-admin-app/docs/NEWAPP.md](../../../Mintzer-admin-app/docs/NEWAPP.md).  
**New UI:** `assets/mockups/mintzer-designer-taste-demo.html` + [04-orders.md](./04-orders.md).

**Do not** upload the HTML demo to Play. The demo is a spec, not the app.

---

## 1. Play listing (do not break)

| Item | Live today | Specs sometimes said | Rule |
|------|------------|----------------------|------|
| Application id | **`com.mintzer`** | `in.mintzer.app` | **Update must keep `com.mintzer`** + the **same signing key** |
| Store URL | `https://play.google.com/store/apps/details?id=com.mintzer` | — | Use this in app-config |
| Admin app | `in.mintzer.mintzer_admin` | — | Unrelated listing. Leave it |

A new package name is a **new app**. Users would not receive this as an update. Old orders would only appear after they log in to a new listing — do not do that.

Until the mapper is live: Play **flexible** update only (`forceUpdateEnabled: false`). Force-update after the new APK can open a real old order without crashing.

---

## 2. What lives where

Orders are **not** in the APK. They are rows on `newapp.orders`.

The new app paints the locked 7-step rail. The server (or a thin mapper in the app) turns live columns into that rail.

**Live happy path (normal deals, not Pine Lab):**

```
accept-order (Placed, no store id)
  → update-order-id (still Placed, store_order_id set)
  → update-tracking-id (Shipped)
  → update-outfordelivery (Out For Delivery + OTP)
  → update-invoice-delivery (PDF, verification_status = null)
  → admin Verified | Re-Upload | Alerted
  → admin Delivered
  → admin approve-payout (is_payout = 1)
```

Holder APIs (Sanctum token name `mintzer`): `getOrderList`, `update-order-id`, `update-tracking-id`, `update-outfordelivery`, `update-invoice-delivery`, `cancel-order`, `getPinelabOrderList`.

---

## 3. Live columns we actually have

| Column / flag | Meaning |
|---------------|---------|
| `store_order_id` | Flipkart/Amazon order id. Empty = still a placement |
| `order_status` | `Placed` · `Shipped` · `Out For Delivery` · `Delivered` · `Cancelled` · `Rejected` (`Declined` exists in filters; prefer Rejected) |
| `order_tracking_id` | Tracking |
| `order_delivery_otp` | Delivery OTP |
| `account_order_pdf` | Invoice file |
| `verification_status` | `null` · `Verified` · `Re-Upload` · `Alerted` |
| `is_payout` | `1` = paid to holder |
| `transaction_id` | UTR / bank ref when present |
| `is_pine_lab_deal` | Pine Lab deal — no ship/OTP pipeline |
| `payment_screenshot` · `is_payment_verified` | Pine Lab only |
| `is_ready_for_payout` | Admin gate |
| `deleted_at` | Timer / auto-clear of accept with no store id |
| Bank on user/order | `bank_name`, `bank_full_name`, `bank_account_number`, `bank_ifsc`, `upi_address` |
| Amount | `card_holder_recieve` (live earn figure) |

There is **no** `parcel_received_at` on live. There is **no** 48h working-hours timer column. There is **no** user note, cheer visit, or profile photo.

Live **tickets** still have **no `order_id` column** — do not break `addnewticket`. The reply thread **is live**: table `ticket_replies`, holder `POST /api/addticketreply`, admin `GET tickets/{id}/thread` and `POST tickets/{id}/reply`. Do not delete those routes. See [LIVE-UPLOAD-RULES.md](../LIVE-UPLOAD-RULES.md).

Live **wallet withdraw** exists (`withdraw-request`). New Wallet UI still has **no Withdraw**. Pending requests stay in admin only.

---

## 4. Map to the new 7 steps

New rail (locked): **Placed → Tracking → Out for delivery → Confirmation → Invoice → Payment → Paid**

### 4.1 Normal (GST) deals

Evaluate **top-down**. First match wins. `has()` = non-empty string.

| If live looks like | New `currentStep` | Rail |
|--------------------|-------------------|------|
| `deleted_at` set, no `store_order_id` | **Hide** | Expired accept — admin log only, not My Orders |
| `order_status` = Cancelled or Rejected (or Declined) | Completed · **Canceled** | Show reason if stored. No Edit |
| `is_payout = 1` **or** real `transaction_id` | **Paid** | All prior steps done. Receipt: bank + UTR if present; hide missing rows |
| Invoice **Verified** (and not paid) | **Payment** | Confirmation + Invoice done. Ring: see §6 |
| Invoice file present, status `Re-Upload` / `Alerted` | **Invoice** (rejected) | Show ops reason. Re-upload on. Confirmation done |
| Invoice file present, `verification_status` null | **Invoice** (verifying) | Wait. Confirmation done |
| Status **Delivered**, no invoice file | **Invoice** unlocked | Admin marked Delivered in orders list |
| OTP present **or** status Out For Delivery, not Delivered, no invoice file | **Confirmation** | Wait copy: “This may take up to 1 working day.” Upload locked |
| Tracking present **or** status Shipped, no OTP | **Out for delivery** | Tracking done |
| `store_order_id` set, no tracking | **Tracking** | Placed done |
| No `store_order_id`, not cancelled | **Placement** | Ongoing card + timer. Not a 7-step order yet |

### 4.2 Confirmation (Play app)

| App build | Confirmation | Invoice lock |
|-----------|--------------|--------------|
| **New Play build** (this change) | Real wait after OTP / OFD | Unlocks only when `order_status` = **Delivered** |
| **Older Play builds still installed** | Unchanged — still unlock after OTP | Server does **not** hard-block early upload, so old phones keep working until they update |

Admin mark = status **Delivered** on the orders list (no new DB column required).

### 4.3 Pine Lab (`is_pine_lab_deal = 1`)

No tracking / OTP / GST invoice.

| Live | New UI |
|------|--------|
| Payment screenshot missing | Current step = **Invoice** slot, copy **Payment screenshot** (not GST) |
| Screenshot in, `is_payment_verified = 0` | Verifying |
| Verified, not paid | **Payment** |
| `is_payout = 1` | **Paid** |

Do not drop Pine Lab orders. Do not force them through Tracking/OFD.

---

## 5. List labels (My Orders card)

| Mapped step | `nextActionLabel` |
|-------------|-------------------|
| Placement | Continue order |
| Tracking | Add tracking ID |
| Out for delivery | Enter delivery OTP |
| Confirmation (new flow only) | Waiting for delivery |
| Invoice | Upload invoice / Checking invoice / Re-upload |
| Payment | Payment in {time} **or** On the way (if no timer) |
| Paid | Completed |
| Canceled | Canceled |

Search still: store order id · tracking · product/model name.

---

## 6. Payment ring on old rows

Live has no `paymentTimerEndsAt`.

| What we have | What to show |
|--------------|----------------|
| `invoice_upload_date` or verified-at timestamp | 48 **working hours** from that instant (holidays skipped). Ring as locked UI |
| No usable timestamp | **No fake countdown.** Cheer + amount + “On the way to your bank”. Ring optional/off |
| Already paid | Paid receipt, no ring |

Cheer visit starts at **1** the first time they open Payment in the **new** app (`cheerVisit` is client or new column; default 0).

Amount line: **₹{they paid} + ₹{profit}** if money snapshot exists; else **₹{card_holder_recieve}** as earn-only — never invent a spend figure.

---

## 7. Fields the new UI must tolerate as empty

Never crash. Never ask them to paste Order ID again if `store_order_id` is set.

| New UI | If live missing |
|--------|-----------------|
| User note | Hide note |
| Profile photo | Letter avatar |
| Courier name | Detect from tracking prefix; else blank + dropdown |
| Last 4 of phone | Hide OFD “last 4” row if empty; OTP still shows |
| UTR | Paid receipt without UTR line |
| Language | Default English until they pick |
| KYC / payout | See **§10**. Do not force PAN on login or update |

Edits (Order ID / tracking / OTP) stay allowed until **Paid**, same as locked Order detail.

---

## 8. API rule (old APK still in the wild)

- **Additive only** on `newapp`. Do not rename/remove `getOrderList`, `update-tracking-id`, etc.
- New app may call the same holder APIs and map client-side **or** a new `GET /orders` that returns `currentStep` + `progress` already mapped.
- Preferred: **server mapper** so admin + user app share one stage. Reuse the logic in `OrderListService::pipelineFor` / `stageFor` and extend it to the 7-step names above.
- Old APK users who tap **Not now** keep using old screens against the same rows.

---

## 9. Mapper algorithm (implement this, don’t improvise)

```
if deleted_at && !store_order_id → drop (not a user order)
if status in Cancelled|Rejected|Declined → completed/canceled
if is_payout==1 || nonempty transaction_id → step Paid
if is_pine_lab_deal:
    if !payment_screenshot → Invoice (screenshot)
    if !is_payment_verified → Invoice verifying
    else → Payment
else:
    if verification_status in Re-Upload|Alerted → Invoice rejected
    if account_order_pdf && verification_status is null → Invoice verifying
    if account_order_pdf && verification_status == Verified → Payment
    if status==Delivered → Invoice
    if otp || status==Out For Delivery → Confirmation (wait; invoice locked)
    if tracking || status==Shipped → OFD
    if store_order_id → Tracking
    else → Placement
```

---

## 10. Legacy users (old Play — no PAN)

The old holder app **never collected PAN / Cashfree KYC**. People still logged in with phone + OTP, placed orders, and got paid on `bank_*` / UPI on the user (or order).

**There is no user merge.** Same Play package `com.mintzer` + same phone = same `users` row + same `orders`. The update is a new UI on that row. Do not create a second account. Do not ask them to “link” anything.

### Do not force-verify on the update

Do **not** block Home / Orders / Wallet with KYC after they install. That is KYC-at-login under another name. Locked rule still stands: **PAN only on first Accept** (plus the payout exception below).

Force-update (`forceUpdateEnabled`) is about the APK, not about PAN.

### What to do instead (usual gate + holes filled)

| They have… | After update | Next Accept | Old in-flight order / payout |
|------------|--------------|-------------|------------------------------|
| PAN already + bank/UPI | Skip KYC + payout sheets | Straight to timer | Pay as today |
| Bank/UPI, **no PAN** (typical live user) | Home works. Profile KYC = **Add PAN** (not “blocked”) | **Usual:** PAN → Cashfree name → bank prefilled. If Cashfree name ≠ `bank_full_name`, they must fix payout name/account before that **new** Accept continues | **Keep paying** on existing bank. Do not freeze old payouts for missing PAN |
| Orders, **no bank and no PAN** | Home + old order rail still work | Usual PAN + bank before timer | Soft sheet **only if** that order is in **Payment** and ops cannot pay: “Add PAN and bank so we can send this.” Not a full-app lock |
| No orders, no PAN | Same as a new user | Usual first Accept | — |

Flags to store (additive on `users`, do not break old APK):

| Flag | Legacy default |
|------|----------------|
| `legacyHolder` | `true` if they had any live order before `flowVersion=2` shipped |
| `kycStatus` | `not_started` until PAN + Cashfree name succeed — **do not** set `verified` just because they ordered |
| `payoutDetailsComplete` | `true` if live bank or UPI is already on the user |

Profile copy for `legacyHolder` + no PAN: **Add PAN** · not “Unverified — cannot use Mintzer.”

### Why not force PAN on day one

- They already trusted you with a store order and (often) a bank account.
- Blocking the app would hide live tracking / OTP / invoice they still owe you.
- Cashfree name vs old `bank_full_name` mismatches would strand payouts if we required a match before showing Orders.

When they **do** submit PAN later: match to payout name for **new** accepts. Old unpaid rows stay on the bank already used unless ops asks them to update.

---

## 11. What to build next (engineering)

Do **not** start with a Play upload.

1. Flutter user app (mock data) matching the locked demo — [frontend/01-implementation-checklist.md](../frontend/01-implementation-checklist.md)
2. Point it at **staging copy of `newapp`**, run this mapper on real rows
3. Open three live cases before Play: (a) tracking due, (b) invoice due, (c) already paid
4. Then ship as **`com.mintzer`** update

Admin app stays. Figma polish can run in parallel; it is not a gate to start Flutter.

---

## Related

- [04-orders.md](./04-orders.md) — target lifecycle after rebuild  
- [03-placements.md](./03-placements.md) — live “accept with no store id” = placement  
- [05-wallet-and-payouts.md](./05-wallet-and-payouts.md) — no withdraw in user app  
- [08-app-config.md](./08-app-config.md) — Play URL + flexible update  
- [09-support-tickets.md](./09-support-tickets.md) — live tickets need additive `order_id` later  
