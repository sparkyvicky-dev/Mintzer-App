# GST deals — LOCKED (20 Sep 2026)

**Status: LOCKED** · Flutter `deal_detail_screen.dart` · `mintzer_dialogs.dart` (`showGstAlertDialog`) · invoice step in `order_detail_screen.dart`

GST means the user must enter **Company + GST No. from the delivery address section** on the store at checkout, then upload a matching invoice after delivery.

---

## Never say

- “Mintzer GST” / “Mintzer GSTIN”
- “Your personal GST” / “not your personal GST”
- Dump Company name + GSTIN in the Accept modal (values live only in **Place order → delivery address**)

---

## Where it shows

| Place | UI | Copy rule |
|-------|-----|-----------|
| **Home deal card** | Small **GST** pill on photo (teal tokens) | Label only — no essay |
| **Deal detail** | Teal info strip under Payment summary | Soft: *GST invoice needed. At checkout, enter the Company and GST No. shown in the delivery address.* |
| **First Accept (GST deals)** | Centered modal · icon · **1 · 2 · 3** steps · **I understand** | General warning — point to **delivery address section in the app** |
| **Place order** | Address block already has Company + GST No. | Hint: use those fields at checkout (no brand speech) |
| **Order detail → Invoice** (GST only) | Checklist + **Upload GST invoice** · verifying / re-upload copy | Match address fields; allow re-upload if rejected |

Non-GST deals: keep **Upload invoice** (no GST checklist).

---

## Accept modal (LOCKED structure)

**Title:** GST invoice needed  
**Subtitle:** Enter the correct GST details on the store when you checkout.

| # | Title | Body |
|---|--------|------|
| 1 | Enter GST at checkout | On the store, enter the Company and GST No. exactly as shown in the **delivery address section** in the app. |
| 2 | Upload the invoice after delivery | Uploading the correct invoice in the app is mandatory for this order. |
| 3 | Wrong GST or invoice may delay payout | If details don’t match, you can re-upload a corrected invoice. |

CTA: **I understand**

Keep numbered purple circles + document icon. Do not restyle without approval.

---

## Order lifecycle

Do **not** add a separate “GST Invoice” node. Locked rail stays:

Confirmation → Tracking → … → **Invoice** → Payment → Paid

For GST deals, only **Invoice** step copy/checklist change.

---

## Tokens

Home / deal GST pill: fill `#E0F2F1` · text `#00796B` · border `#80CBC4` — [COLORS-AND-TOKENS.md](./COLORS-AND-TOKENS.md)
