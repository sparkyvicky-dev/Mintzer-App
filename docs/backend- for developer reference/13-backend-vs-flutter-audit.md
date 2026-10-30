# Backend audit — live `newapp` vs Flutter V3 UI

**Date:** 21 Sep 2026 (night) — **superseded for ship decisions by [14-v3-play-update-audit.md](./14-v3-play-update-audit.md)** (22 Sep refresh).  
**Scope:** Hostinger Laravel `newapp` (`app.mintzer.in`) vs Flutter app in `app/`  
**Rule:** **Reuse existing backend.** Additive only. Do not rebuild from scratch. Do not crash Play V2.

**Explore dump:** `_hostinger_explore/newapp/` (FTP read; do not commit `.env`)

> **22 Sep note:** Flutter flags now wire deals / orders / accept / tickets / notifications / dual FCM. Do not treat tables below as current Flutter status — use [03-flutter-app-map.md](../frontend/03-flutter-app-map.md). **29 Sep:** PAN is live on Cashfree. Bank save is live.

---

## Verdict (smart summary) — historical 21 Sep

| Question | Answer |
|----------|--------|
| Build backend from scratch? | **No** — same `newapp` + same users/orders |
| Can the locked UI be powered by live APIs? | **Yes ~80%** — most routes already exist |
| Biggest gap? (21 Sep) | Was mock deals/orders — **now wired** (see doc 14) |
| Notifications? | V2 auto paths + **V3 engine live** |
| Safe for Play users? | Keep **additive** APIs · mapper never crashes · `forceUpdateEnabled: false` until must-test rows pass |

---

## A. What live backend already has

### Auth / session
| API | Status | Flutter |
|-----|--------|---------|
| `POST /sendotp` | Live | **Wired** |
| `POST /verify-otp` | Live (Sanctum token) | **Wired** |
| `POST /logout` | Live | Not wired |
| `POST /deleteAccount` | Live | UI only / mock |
| Social login routes | Live | **Not used** (phone-only LOCKED) |

### Catalog
| API | Status | Flutter |
|-----|--------|---------|
| `GET /getDealdata` | Live | Mock Home |
| `GET /getDealDetail` | Live | Mock Deal detail |
| `GET /getStoreAndCardData` | Live | Mock logos |
| `GET /getBanks` / bank cards | Live | Mock |
| `GET /getbanners` | Live | Optional |
| `GET /getLogistics` | Live | Courier list (mock empty default) |
| `GET /business-configuration` | Live | App config mostly local |

### Profile / KYC / bank
| API | Status | Flutter |
|-----|--------|---------|
| `GET /getuserprofile` | Live | Mock session |
| `POST /updateProfile` / image | Live | Partial UI |
| `POST /pan-verify` | Live (Cashfree?) | **Mock** KYC sheet |
| `POST /updateBankDetail` · `GET /getBankDetail` | Live | Mock payout |
| `POST /updateAddress` · `GET /getAddress` | Live | Place-order address mock |
| `POST /update-settings` | Live (WhatsApp flag) | Not mapped to V3 prefs |

### Orders (core money path)
| API | Status | Flutter |
|-----|--------|---------|
| `POST /accept-order` | Live | Mock Accept |
| `POST /update-order-id` | Live | Mock Place order |
| `POST /cancel-order` · `GET /cancel-reasons` | Live | Mock cancel |
| `POST /update-tracking-id` | Live | Mock order detail |
| `POST /update-outfordelivery` | Live | Mock OTP/OFD |
| `POST /update-invoice-delivery` | Live | Mock invoice |
| `POST /getOrderList` · Pine Lab list | Live | Mock + offline dump mapper |
| `POST /auto-delete-order` | Live | Placement expiry |
| `POST /payout-request` · history · stage | Live | Wallet mock |

### Wallet / tickets / inbox
| API | Status | Flutter |
|-----|--------|---------|
| `POST /withdraw-request` | Live | **Must NOT show** in UI (LOCKED) |
| `GET /getnotifications` · update | Live | Mock bell inbox |
| `POST /addnewticket` · get · subjects | Live | Mock tickets (**no order_id** on live rows — mapper hide) |
| Referral get settings/history | Live | Profile refer strip mock |

### Push (critical — 21 Sep work)
| Piece | Status | Notes |
|-------|--------|-------|
| `POST /fcm-update` | Live V2 | Writes `users.fcm_token` — Flutter wired |
| V2 auto deal create | Live | `sendFcmNotifications` → old project `mintzer-e14bd` (may be flaky) |
| V2 manual bell | Live | Topic `all_users` — leave alone |
| `HolderNotifyService` | Live | Auto order/invoice/OTP/payout → token |
| Cron reminders | Live | Order ID / tracking — leave alone |
| **V3** `v3_push_*` tables | **Created** | devices · prefs · outbox · send_log |
| **V3** `/v3/push/register` · prefs · test-self | **Live** | Flutter wired |
| **V3** auto on deal **create** | **Live** | Soft-fail; V3 devices only |
| V3 Flipkart gateway (follow-ups, quiet drain) | Partial | Caps/quiet in gateway; sequences not fully scheduled |

---

## B. What the locked Flutter UI needs (gap list)

Priority for **safe Play update**: open real old orders without crash, then wire catalog.

### P0 — must for Play update (no UI restyle)
1. `getOrderList` → existing **null-safe mapper** (`11-live-order-migration.md`)
2. Must-test: tracking due · invoice due · already paid
3. `accept-order` / `update-order-id` / tracking / OTP / invoice — live writes
4. Keep Sanctum token + session persist (done)
5. `forceUpdateEnabled: false` until P0 proven

### P1 — Home / deals feel real
6. `getDealdata` + `getDealDetail` → Home + Deal detail (map money/TDS/GST fields)
7. `getStoreAndCardData` → logos (letter tiles if missing)
8. `accept-order` + address APIs → Place order
9. Soft push ask already done; keep V3 register

### P2 — Profile / wallet / tickets
10. `getuserprofile` · bank · pan-verify (Cashfree owner)
11. Wallet history from payout APIs — **no withdraw button**
12. Tickets list/detail — hide missing `order_id`
13. `getnotifications` → bell inbox

### P3 — V3 notification product (auto, not click)
14. Deal create → V3 only option (owner decision: silence V2 auto?)
15. Accept-abandoned · timer warnings · browse follow-ups on **V3 gateway**
16. Deep links `deal` / `order` / `wallet`
17. Align legacy cron FCM project (`e14bd` vs `e45d6`) **only after backup** — do not rush

### Not needed / do not build
- Offers tab · Wallet withdraw UI · force PAN on login · new admin CMS · backend from scratch  
- Social login in Flutter (API exists; product LOCKED phone-only)

---

## C. Field / product mismatches to watch

| UI / spec | Live backend risk |
|-----------|-------------------|
| 7-step order rail | Map from `order_status` + tracking/OTP/invoice/`is_payout` — see migration doc |
| Placement timer | Often empty `store_order_id` row — not separate table |
| Ticket ↔ order | Live tickets may lack `order_id` — never crash |
| GST company/GSTIN on address | Confirm deal flags + address fields |
| PAN name lock | `pan-verify` response shape vs Cashfree |
| Withdraw API | Exists — **Flutter must not call/show** |
| Dual FCM projects | V2 create uses `mintzer-e14bd`; AdminFcmClient/`google-services` use `mintzer-e45d6` |

---

## D. Safety checklist (every backend touch)

- [ ] Backup file via FTP before overwrite  
- [ ] Additive routes/tables only  
- [ ] Soft-fail new hooks (`try/catch`) so admin/V2 never 500  
- [ ] Never delete `orders` / users  
- [ ] Never force-update until must-test passes  
- [ ] UI locks: do not restyle screens in §3 of STATUS  

---

## E. Tomorrow plan (suggested order)

See [STATUS.md](../STATUS.md) § Tomorrow (22 Sep). Short version:

1. Confirm UI locks untouched  
2. Decide: deal-create V2 auto on/off for old users  
3. Wire **one** live vertical slice: Home deals **or** Orders list from API  
4. Expand V3 auto events only after slice works  
