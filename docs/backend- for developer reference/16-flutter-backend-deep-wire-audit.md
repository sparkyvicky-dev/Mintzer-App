# Flutter V3 ↔ `newapp` — deep wire audit

**Date:** 23 Sep 2026 (night update). **29 Sep:** PAN is Cashfree. IFSC is still API Sathi. Current flow is [03-flutter-app-map.md](../frontend/03-flutter-app-map.md).  
**Scope:** Every live flag, API client, screen CTA, and field mapper vs Hostinger `newapp`.  
**PAN / IFSC:** Cashfree for PAN. API Sathi for IFSC. Verifico is off.  
**Related:** [14-v3-play-update-audit.md](./14-v3-play-update-audit.md) (ship gate) · this file = **full wiring matrix**.

**Live base:** `https://app.mintzer.in/api`  
**Source of truth for PHP:** Hostinger FTP (mirrored in `_hostinger_explore/newapp` after uploads).

---

## Verdict (one screen)

| Layer | Status |
|-------|--------|
| Money path (login → deals → accept → place → proofs → orders/wallet read) | **Live** |
| Profile read / photo / name / logout / delete | **Live** |
| Tickets + bell + dual FCM | **Live** |
| **Bank save after KYC** | **Live** — `POST /updateBankDetail` from payout sheet |
| **PAN verify** | **Live** — Cashfree · flag on · spend caps in `ProfileController` |
| **IFSC lookup** | **Live** — `POST /ifsc-lookup` · bank card only after a valid code |
| Home greeting | **Live session name** (`profileDisplayName`) |
| Order ID edit on detail | **Live** → `update-order-id` when `liveAcceptOrderId` set |
| Invite / change-phone / partner Apply | **Mock or toast** |
| Crash-safe Play update | Still blocked on **owner must-test** + signing key — not on these wires |

---

## A. Feature flags (`app_config.dart`)

| Flag | Now | Effect |
|------|-----|--------|
| `useLiveDealsApi` | **true** | Home catalog from `getDealdata` |
| `useLiveOrdersApi` | **true** | Orders + Wallet refresh + order-detail reads |
| `useLiveAcceptApi` | **true** | Accept / place / cancel / auto-delete / proof writes |
| `useLiveTicketsApi` | **true** | Tickets CRUD |
| `useLiveNotificationsApi` | **true** | Bell inbox |
| `panVerifyLiveEnabled` | **true** | KYC calls `POST /pan-verify`. No mock name. |
| `showSimulateControls` | **false** | Hidden demo CTAs |
| `forceUpdateEnabled` | **false** | No UI yet (doc only) |
| `useLiveDumpFixtures` | **false** | Offline dump off |

---

## B. Flow matrix (wire status)

| Flow | Flutter | Backend | Gap |
|------|---------|---------|-----|
| Login OTP | Live `sendotp` / `verify-otp` | Live | — |
| Home deals | Live `getDealdata` | Live | Greeting still `kMockFirstName` |
| Home banners | **Designed slides only** | `getbanners` exists | Intentional; `BannersApi` unused |
| Deal detail / Accept | Live `getDealDetail` + `accept-order` | Live | KYC/bank gates still mock writes |
| Place order | Live `update-order-id` · cancel · auto-delete | Live | **Change address** = toast only (by design for dealer pool) |
| Orders list | Live `getOrderList` | Live + `store_order_id` | — |
| Tracking / OTP / invoice | Live writes | Live | Courier list hardcoded (not `getLogistics`) |
| Order ID **edit** on detail | **Local only** | `update-order-id` exists | Re-save never hits API |
| Wallet | Derived from orders | No ledger API | Correct · no withdraw |
| Profile read | Live | Live | — |
| KYC PAN | Live `pan-verify` | Cashfree | Caps: 3/phone/day · 30-day name cache · already verified skips the call |
| Payout bank **save** | Live `updateBankDetail` | Live | Account number 9–18 digits |
| IFSC | Live `ifsc-lookup` | API Sathi | **Bank found** only when the field is a valid IFSC |
| Bank **read** | Live `getBankDetail` | Live | — |
| Tickets | Live | Live · no `order_id` | UI hides empties |
| Bell get / mark / clear | Live | Clear **restored** 22 Sep night | Was briefly overwritten by PAN FTP |
| Push dual FCM + prefs + deal-view | Live | Live | `test-self` unused (OK) |
| Delete / logout | Live | Live | — |
| Invite code | Hard-coded `MZARUN200` | `getReferral*` exists | Not wired |
| Change phone | Mock OTP `123456` | No dedicated route | Defer |
| Partner cards Apply | Toast if no URL | `getBanks` exists | Not wired |
| Suggest deal | WhatsApp only | None | OK |
| Report deal chip | WhatsApp | None | OK |

---

## C. Priority gaps (do next)

### P0 — product-broken if users Accept for real

1. ~~**`POST /updateBankDetail`**~~ **DONE 22 Sep night** — `ProfileApi.updateBankDetail` + payout sheet.  
2. ~~**PAN live**~~ **DONE** — `panVerifyLiveEnabled = true`. Provider is Cashfree (29 Sep), not Verifico.

### P1 — wrong / dead UX on live data

3. ~~**Order detail → Edit Order ID**~~ **DONE** → `PlacementsApi.updateOrderId`.  
4. ~~**Home greeting**~~ **DONE** → `MockSession.profileDisplayName`.  
5. ~~**Courier picker**~~ **DONE** — Xpressbees · Ekart · Amazon Logistics · Delhivery · Blue Dart · Shadowfax · Others (`MintzerCouriers`).  
6. **Paid-on timestamp** — UI uses `DateTime.now()`; not payout date from API (field may not exist → hide or use available date).

### P2 — polish / later

7. Partner cards → `getBanks` + real Apply URLs.  
8. Invite / referral → `getReferralSettings` / histories.  
9. Banners — keep designed Partner+Community **or** document that admin `getbanners` is intentionally unused.  
10. Notification deep-link order refs — parse body heuristics weaker than needed.  
11. Deal list vs detail **earning_price** (list = TDS-net, detail = gross) — Money card must keep using detail path.  
12. Silence V2 deal-create FCM (double tray) after most users on Flutter.

### Do **not** wire

- `POST /withdraw-request` · Offers tab · social login · force PAN on login · force-update until must-test.

---

## D. Field / mapper notes

| UI / model | Live field | Notes |
|------------|------------|-------|
| Order ID on cards | `store_order_id` | Fixed in live `orderDataFormat` |
| Earn / TDS | `earning_price`, `tds_amount`, `to_card_holder` | Prefer deal detail for Accept money |
| Delivery address | `address` on `getDealDetail` | FK Location titles local |
| Invoice PDF | `account_order_pdf` | Multipart upload live |
| Ticket order link | — | Backend has no `order_id` |
| Wallet profit | Paid orders earn only | Not reimbursement |
| Profile `pan_details` | `pan_verified`, `pan_name`, `pan` | From `getuserprofile` |
| Bank | `account_holder_name`, `bank_name`, `account_number`, `ifsc_code`, `upi_address` | Read OK; write missing |

---

## E. Dead / mock controls (icons & buttons)

| Control | What happens |
|---------|----------------|
| Partner **Apply** (no URL) | Toast “coming soon” |
| Place order **Change / Generate address** (live) | Info toast — no regenerate API |
| Profile invite copy/share | Hard-coded code |
| Edit account **Change phone** | Mock OTP |
| KYC Verify (flag off) | Always succeeds as Arun Kumar |
| Wallet Excel | Clipboard CSV only |
| Order detail **Continue to tracking** (legacy) | Local step bump |
| Simulate CTAs | Hidden by flag |
| `forceUpdateEnabled` | No screen reads it yet |

Icons on bottom nav / flow line / locked CTAs are **visual only** where listed above — logic gaps are the rows in §C, not missing Material icons.

---

## F. Regression fixed during this audit

Verifico PAN FTP had replaced live `ProfileController` with a copy that:

- Auto-marked all notifications read on `GET getnotifications`
- Dropped `action=clear` on `updatenotifications`

**Restored** on Hostinger (22 Sep night) + made `updateBankDetail` UPI optional. Verifico `panVerify` kept.

---

## G. Suggested wire order (historical — these are done)

```
1. ProfileApi.updateBankDetail + payout_account_sheet / PayoutDetailsScreen
2. Home greeting from session name
3. Order detail Order ID edit → update-order-id
4. panVerifyLiveEnabled = true — provider is Cashfree, not Verifico
5. Optional: getLogistics · getBanks · referral
```

---

## Bottom line

Core earn loop is live. The one Accept-path hole that will bite users first is **bank save never hitting the server**. Everything else in §C is smaller. PAN stays parked. Ship gate for Play remains owner must-test + signing key ([14](./14-v3-play-update-audit.md) · [15](./15-play-update-must-test.md)).
