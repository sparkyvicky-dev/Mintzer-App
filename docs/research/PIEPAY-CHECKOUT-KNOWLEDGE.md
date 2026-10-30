# PiePay checkout — what we know

**Status:** Documented from live testing + APK review (Aug 2026)  
**Purpose:** Shorter flow reference — see **[AGENT-PIEPAY-AND-PAY-EARN-HANDOFF.md](./AGENT-PIEPAY-AND-PAY-EARN-HANDOFF.md)** for full agent handoff  
**Technical APK notes:** `Mintzer-admin-app/apk-pull/PIEPAY-TECH-ANALYSIS.md`  
**Mintzer build phases:** [MINTZER-PAY-EARN-ROADMAP.md](./MINTZER-PAY-EARN-ROADMAP.md)
---

## One-line summary

**You shop on Flipkart inside PiePay → PiePay copies your checkout session → a cardholder finishes payment on Flipkart with their card → you pay PiePay by UPI → the order stays on your Flipkart account.**

---

## Two types of user

| Role | What they do |
|------|----------------|
| **Buyer** | Shops on Flipkart inside PiePay, wants card discount without owning that card |
| **Cardholder** | Has the right card, pays on Flipkart for the buyer, earns commission |

PiePay app has two modes (tabs): **Pay & earn** (holder pays for buyer) and **Order & earn** (holder places order themselves — closer to Mintzer’s model).

This doc is about **Pay & earn** — the “seamless checkout” flow.

---

## Buyer flow (what you saw)

1. Open Flipkart **inside** PiePay (purple header: Shop → Summary → Discount).
2. Log in with **your** Flipkart account.
3. Pick product, address, reach **Payment**.
4. PiePay shows overlay: fetching product / checking discounts.
5. Bottom sheet: **Buy for ₹X**, Save ₹Y, **Buy now** + timer.
6. **Searching for cardholder** (radar screen).
7. Optional: add extra ₹ to match faster.
8. **Complete order:** Pay to PiePay (UPI) — e.g. “Sanju will pay for your order”.
9. After UPI: **Order processing** loading — can close app; it resumes same screen.
10. Order appears in **your** Flipkart My Orders when holder finishes.

**You never pay Flipkart directly** in this flow. You pay **PiePay**.

---

## Cardholder flow (what you saw on test device)

1. Notification or **Deals for you → Pay & earn**.
2. Deal card: e.g. “Help Vignesh · Earn ₹479 · Pay ₹33,148 · Axis Flipkart”.
3. Tap **Pay for this buyer** → Flipkart **Payment** opens inside PiePay.
4. **Important:** Saved cards on that page are the **buyer’s** (proves it’s buyer’s checkout, not holder’s account).

### Four steps (PiePay checklist)

| Step | Action |
|------|--------|
| **1** | On Flipkart: **Credit/Debit card** → type **holder’s** card number → check amount + cashback match |
| **2** | **Accept deal** (PiePay detects handling fees if FK adds ₹248 etc.) |
| **3** | **Wait** until PiePay confirms buyer paid (UPI to PiePay) |
| **4** | Enter CVV/OTP → **Pay on Flipkart** |

Rules shown in app:
- **Do not pay** until PiePay confirms buyer payment.
- Must use **same card** as Accept deal (ending 6059 etc.).

---

## Why holder must type card number again

- Saved cards on screen = **buyer’s** Flipkart wallet.
- Holder must enter **their own** card in “Credit/Debit card” section.
- Flipkart then shows offer amount; PiePay reads it and unlocks **Accept deal**.

---

## Money flow (example from your test)

| Party | Amount | Notes |
|-------|--------|--------|
| Holder pays Flipkart | ₹33,148 | On buyer’s checkout |
| Bank cashback to holder | ₹1,658 | From card offer |
| PiePay pays holder | ₹31,969 | Reimbursement |
| Holder keeps | **₹479** | Commission |
| Buyer pays PiePay (UPI) | ~₹32,456 | After discount |

PiePay keeps the difference between what buyer pays and what they reimburse holder.

---

## How they do it technically (simple)

| Piece | What it does |
|-------|----------------|
| **In-app browser** | Shows Flipkart website inside PiePay |
| **Session copy** | Takes buyer’s logged-in checkout (cookies), sends to PiePay server, loads on holder phone — **not a special Flipkart link** |
| **Page reading** | Reads price, cashback, fees from Flipkart payment page |
| **Matching** | Push + deal list finds holder with right card |
| **UPI to PiePay** | Cashfree / Razorpay — buyer pays PiePay, not FK |
| **Job on server** | “Processing” screen survives app restart |

**App stack (from APK):** React Native app, updates over the air (CodePush). Checkout logic mostly in downloaded code, not visible in store APK alone.

---

## What we are confident about

- Order ends on **buyer’s** Flipkart account.
- Holder sees **buyer’s** saved cards on payment page.
- No Flipkart payment URL is shared with buyer — **session** is shared.
- Buyer pays PiePay first; holder pays Flipkart after confirmation.
- Fee detection (e.g. ₹248) is read from live Flipkart page.

---

## What is not 100% yet

- Exact PiePay server API names and payloads.
- Full list of edge cases (expired checkout, failed UPI, etc.).
- Whether session is one encrypted blob or multiple pieces.

---

## How to get 100% proof (simple — not for coders)

### Option A — Easiest (no tools)

Do **one small test deal** with two phones and record:

1. **Buyer phone:** screen record from Buy now → UPI paid → processing → success.
2. **Holder phone:** screen record from Accept deal → wait → pay Flipkart → success.
3. **Buyer phone:** open Flipkart app → **My Orders** → show order under buyer account.

Share both videos + order screenshot. That confirms the **full user journey** end to end.

---

### Option B — See what PiePay sends to their server (needs one setup)

This shows **what data leaves the phone** during checkout.

1. On **PC:** install free **HTTP Toolkit** — https://httptoolkit.com  
2. On **phone:** same Wi‑Fi as PC; follow HTTP Toolkit’s **Android** setup (install their certificate once — app guides you step by step).
3. Start capture on PC.
4. On phone: open PiePay → run a **cheap test deal** (buyer side until after Buy now, or full flow if you want).
5. Stop capture → **Export** / save the log → share with your dev (or keep for reference).

**Look for:** calls to PiePay’s own website/API (not flipkart.com) right after payment step — often words like `deal`, `session`, `checkout`, `match`.

**Note:** Some apps block this; if PiePay blocks it, Option A is enough for product understanding.

---

### Option C — Give APK + notes to a developer

Already done partially:

- APK saved: `Mintzer-admin-app/apk-pull/piepay-base.apk`
- Tech write-up: `PIEPAY-TECH-ANALYSIS.md`

A dev can add Java + JADX or run Option B for API details.

---

## What we do **not** need for product understanding

- Decompiling full source code  
- Hacking Flipkart  
- Holder’s or buyer’s passwords  

---

## Related files

| File | Content |
|------|---------|
| `Mintzer-admin-app/apk-pull/PIEPAY-TECH-ANALYSIS.md` | APK libraries, SDKs, native modules |
| `Mintzer-admin-app/apk-pull/piepay-base.apk` | Pulled from test device |
| This doc | Flow + money + how to verify |

---

*Last updated: Aug 2026 — from owner testing + wireless APK pull (com.piepay v21.0.0-beta.0).*
