# Bank / payout details — when we ask

**Status: LOCKED** (20 Sep 2026 Flutter pattern · mockups June 2026)

**Flutter:** `kyc_sheet.dart` · `payout_account_sheet.dart` · Profile `payout_details_screen.dart`  
**Mockups (visual history):** `assets/mintzer-kyc-mockup.png` · `assets/mintzer-bank-details-mockup.png`

**LOCKED flow:** Right after first **Accept** → **Step 1 of 2** PAN → **Continue to payout setup** → **Step 2 of 2** Payout account → then shop mode / GST (if needed) → Place order.

Still **no Withdraw button** in Wallet — bank is for **Mintzer to pay the user**, not user self-withdraw in v1.

---

## Order of gates (first Accept only)

```
User swipes Accept deal
  → Step 1 of 2: Verify PAN (Cashfree name)
  → Continue to payout setup →
  → Step 2 of 2: Payout account (IFSC → bank)
  → Shop mode (first time)
  → GST modal (if deal.gst)
  → Place order (timer)
```

Returning users with KYC + bank already saved → skip to shop/GST/timer as needed.

**Live Play users (no PAN in the old app):** same phone = same user. **Do not** force PAN on update or login. Old orders and old payouts keep moving. PAN is still the usual **first new Accept**. See [11-live-order-migration.md](../backend-%20for%20developer%20reference/11-live-order-migration.md) §10.

---

## Step 1 — Verify PAN (LOCKED)

| Field | Required | Source |
|-------|----------|--------|
| PAN | Yes | User — auto-uppercase, strip spaces; max 10 |
| Name (as per PAN) | Yes | **Cashfree** via `POST /pan-verify`. No mock name. |

**UI:**
- Title **Verify PAN** · **Step 1 of 2**
- Copy: *Verify your PAN to accept your first deal.* / *Your verified name will be used for payout setup.*
- Soft fields `#F7F7F9` · hint **light grey regular** (not bold) e.g. `ABCDE1234F`
- ✓ Valid PAN format when regex OK
- CTA **Verify PAN** disabled until format valid · quiet grey **Cancel**
- Success: ✓ PAN verified · name · **Continue to payout setup →**
- Footer: *Used for identity verification and payout setup.* (no overclaim)

Do not ask name, Aadhaar, or OTP on this sheet.

---

## Step 2 — Payout account (LOCKED)

**Title:** Payout account · **Step 2 of 2** (on first Accept sheet)  
**Subtitle:** Your Mintzer earnings will be sent to this bank account.

### Fields

| Field | Required |
|-------|----------|
| Account holder name | Yes — **locked from PAN** · **Verified with PAN** · not editable |
| Account number | Yes |
| Confirm account number | Yes — must match |
| IFSC | Yes — lookup bank + branch (**no bank dropdown**) |
| UPI | Optional — collapsed **Add UPI**; payouts go to **bank** |

**After valid IFSC:** card shows bank + branch · **Bank found**. The card stays hidden until the IFSC field is a valid 11-character code and lookup succeeds. A saved bank name with an empty IFSC must not show **Bank found**.  
**CTA:** **Save payout account** (disabled until account + confirm + bank found).  
**Footer:** *Used only for Mintzer payouts*  
**Hints:** soft grey · IFSC `e.g. HDFC0001234`

Profile → **Payout account** uses the same form (no Step 2 label).

**Rules:**
- Name must match PAN name
- Save once — editable later from Profile
- Required before first order placement (same gate as KYC)

**Validation UX:** [VALIDATION-UX.md](./VALIDATION-UX.md)

---

## Where it appears

| Place | When |
|-------|------|
| After PAN on first Accept | Required |
| Profile → Payout account | View / edit |

**Not on:** Login · Deal detail · Wallet

---

## Backend

- `POST /pan-verify` — PAN only. Server calls Cashfree and returns `pan_name`. Already-verified accounts are not looked up again.
- `POST /ifsc-lookup` — IFSC only. Server calls API Sathi `ifsc-lookup-v1`. Cached 90 days.
- `POST /updateBankDetail` — `full_name`, `bank_name`, `bank_account_number` (9–18 digits), `bank_ifsc`, optional `upi_address`.
- `GET /getBankDetail` — saved payout row. `ifsc_code` may be empty on old rows.
- `GET /getuserprofile` — `pan_details.pan_verified` is true only when both `pan` and `pan_name` are set.
- Accept / placement still does **not** force PAN on login or on a Play update. PAN is the first new Accept.

**PAN provider (29 Sep):** Cashfree Secure ID, `POST https://api.cashfree.com/verification/pan`. Live when `CASHFREE_PAN_ENABLED` is on. If Cashfree is off, PowerAPI is next, then API Sathi. A Cashfree failure does not fall through. Only the registered name is stored. Address and Aadhaar-link fields are dropped.

**IFSC provider:** API Sathi. Keys in Hostinger `.env` only (`CASHFREE_CLIENT_ID`, `CASHFREE_CLIENT_SECRET`, `APISATHI_API_KEY`, `APISATHI_IFSC_API_KEY`). Flutter flag `AppConfig.panVerifyLiveEnabled` is **true**. Verifico is off. Do not use `Http::connectTimeout()` on this Laravel 8 app.

Spend guards (IST day): 3 upstream PAN checks per user and per phone · 150 for the app · 20-second lock on a second tap · same PAN name cached 30 days.

---

## Admin

- View PAN + payout details per user  
- Ops uses for payout until auto payout exists  
