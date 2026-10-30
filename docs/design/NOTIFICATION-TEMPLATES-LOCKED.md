# Mintzer — Push templates (**LOCKED · short**)

**FINAL** 22 Sep 2026 · Firebase `mintzer-e45d6`  
**Banks (100 each):** [NOTIFICATION-TEMPLATE-BANKS-LOCKED.md](./NOTIFICATION-TEMPLATE-BANKS-LOCKED.md)  
**Brave:** `NOTIFICATION-TEMPLATES-LOCKED.html`

This product needs users **in-app often**. Caps below are **engagement-first** (not “2/day”).

---

## Money

Only when **₹ released to bank** → Wallet. No “payment verified” spam.

---

## Deal live — fire every time

| Event | Push? |
|-------|--------|
| Deal goes live (any time, 24×7) | **Yes — always** `deal.live` |
| **2nd / 3rd deal** same day | **Yes — each** gets its own live push |
| Same deal **off → on again** | **Yes — always** `deal.relist` (different templates) |
| Quiet hours | **Still send** live + relist (manual not required) |

- Deal **ON** → push live (bank: Deal live / funny)
- Deal **OFF** → no push
- Deal **ON again** → push relist (bank: Deal relist)

Home always shows deals; push is the shoulder tap **every** publish/re-publish.

---

## After user opens a deal · leaves without Accept

**Tight follow-up** (drive return):

| Wave | Timing | Count | Bank |
|------|--------|-------|------|
| Early | **30–60 min** after view | **1–2** pushes | Viewed follow-up (30–60 min) |
| Mid | **~1.5 hours** after view (or after early) | **1–2** pushes | Viewed follow-up (~1.5h) |
| Then | Stop **this** view-sequence unless they open again | — | — |

Rules:
- Qualifying view: dwell **≥15–30s** (bounce &lt;5s = no follow-up)
- They Accept → **cancel** remaining view follow-ups  
- They open the deal again → **restart** tight sequence  
- Deep link → **Deal detail**

---

## Deal stays live 2–3 days

**Heavy “still live”** while deal is ON:

| Cadence | Example |
|---------|---------|
| ~ every **8–12 hours** | morning + evening |
| Or **2–3 / day** while live | still-live bank |

Use bank **Still-live (day 2–3)**. Stop when deal turns OFF or user Accepts.

---

## After Accept (Order ID / order steps)

| When | Open |
|------|------|
| No Order ID · left | Place order · abandon + timers |
| Tracking / OTP / invoice | Order detail |
| ₹ paid to bank | Wallet |

Order steps stay clear (not funny). Active placement → **no** other-deal spam optional; product may still allow still-live on *other* deals if you want max engagement — default: **suppress other-deal commercial while placement active**.

---

## Soft safety (not “2/day”)

| Guard | Value |
|-------|--------|
| Min gap between **any** two pushes | **20–30 min** for follow-ups / still-live (avoid triple-stack). **`deal.live` / `deal.relist` exempt** |
| Soft ceiling | ~**8–12** commercial pushes / user / day (raise if needed) |
| Deal alerts OFF | Respect Profile toggle |
| Force / emergency | Admin can always send |

**Removed:** old “max 1 deal-live/day” and “max 2 pushes/day” as product defaults.

---

## Banks to use

Live · Funny · **Relist** · **Viewed 30–60m** · **Viewed 1.5h** · **Still-live** · Order ID · OTP · Tracking · Invoice · Payout · Ticket · Timers  

---

**LOCKED** to this engagement plan. Tune timings in config; don’t silently go back to 1–2/day.
