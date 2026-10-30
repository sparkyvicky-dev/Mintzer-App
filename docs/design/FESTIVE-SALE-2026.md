# Festive sale 2026 — banner and drawer icon

**Written:** 24 Sep 2026 night  
**Status:** Icon code is in the Flutter app. It is **not** on Play yet. The Home banner image is **not** made yet.

The Mintzer mark does not change shape. No motion on the icon. The Play Store listing icon stays the plain purple mark.

---

## Sale dates (checked 24 Sep 2026)

| What | When |
|------|------|
| Flipkart Early Bird | **24 Sep 2026** — preview, wishlist, price watch. Not the Plus sale. |
| Flipkart Plus, Black, and Flipkart credit card | **8 Oct 2026** early access. Flipkart’s own post says early access starts this day. Plus does **not** start before 8 Oct. |
| Flipkart, everyone else | **9 Oct 2026** |
| Amazon Great Indian Festival | **8 Oct 2026**. No end date announced. |
| Diwali | **8 Nov 2026** |
| Icon returns to plain | **12 Nov 2026** (after 11 Nov, Bhai Dooj) |

Sources: Flipkart story “Luck Badal Sakta Hai” (16 Sep 2026) · India Today, Times Now, PCQuest, ABP on Plus vs public day · Times of India on Amazon’s 8 Oct start.

---

## Home banner — not uploaded yet

Carousel slot is **118dp** tall. On a normal phone that is **328 × 118**. Export **984 × 354** px (3×). The app crops with cover, rounds the corners, and paints the banner name on a dark fade at the bottom. Leave the bottom **110px** empty. Keep words **48px** inside the top and side edges. No Flipkart or Amazon logos.

**Admin banner name:** `Big sales from 8 October. Fewer Mintzer deals.`

Paste this into ChatGPT **with the Flipkart banner screenshot in the same message**:

```text
The Flipkart Big Billion Days banner screenshot is attached. Use that image as the design. Match its colours, background, decorative shapes, and type style. Do not invent a different layout.

Make one wide banner for the Mintzer app Home screen.

Exact size: 984 × 354 pixels (aspect 164:59, about 2.78:1). Full bleed. No phone frame, no mockup, no rounded-corner preview, no drop shadow, no extra border, no watermark. Square corners.

The attached screen is tall. Keep its look, and fit it into this short wide strip. Use only the top announcement area: sale name, dates, and the main background. Drop the product grid, bank logos, and long offer lists.

Write only these lines, in the same style as the screenshot:

Left:
FLIPKART
Big Billion Days
8 Oct · Early access
9 Oct · Open to all

Right:
AMAZON
Great Indian Festival
8 Oct · Sale starts

One smaller line under both: Live deals on Mintzer will be limited.

Do not add an end date. None has been announced. Do not add discount percentages, bank names, product names, or prices.

Keep every word at least 48 pixels inside the left, right, and top edges. Leave the bottom 110 pixels empty or in the same dark colour as the background. The app places its own title there.

Large, clear type. No paragraphs and no buttons.

Output a single PNG, 984 × 354.
```

---

## Drawer icon — in the app, not on Play yet

**Rule:** the white M stays. Decoration sits in the purple around the M, inside the icon. The word sits on a gold band at the bottom, in heavy plain capitals. Fancy script was rejected. **BBD** and **GIF** together do not fit.

**Kept (4):**

| Day in the cycle | Icon |
|------------------|------|
| 1 | **SALE** + four stars around the M |
| 2 | **SALE** + a crown of stars above the M |
| 3 | **FEST** + four stars |
| 4 | **FEST** + crown |

**Dropped:** ring, side lamps, gold corners, lamp-only band, gift, bow, marigolds, lights, rangoli, BBD, GIF, “8 OCT”, “BBD GIF”.

**When it shows**

- Plain icon until **7 Oct 2026, 12:00 noon IST**.
- First open at or after that time: SALE + stars.
- Next calendar day (when the app is opened): SALE + crown, then FEST + stars, then FEST + crown, then repeat.
- **12 Nov 2026** onward: plain icon again.
- The phone does not change the icon at noon by itself. Someone has to open Mintzer. Some launchers keep the old picture until they refresh.

**Code**

- `app/android/app/src/main/kotlin/com/mintzer/FestiveLauncher.kt`
- Called from `MainActivity.onCreate`
- Five launcher aliases in `AndroidManifest.xml`: plain (on), and the four festive ones (off until the date)
- Art: `res/drawable/ic_launcher_fg_sale_stars.png` (and crown / fest pairs) plus mipmap densities
- Previews (Brave): `assets/mockups/festive-drawer-icon-around-m.html`

Package stays **`com.mintzer`**. Notification icon stays the plain white glyph.

---

## Still to do

1. **Banner:** run the prompt in ChatGPT with the Flipkart screenshot. Upload the **984 × 354** PNG in admin. Set the banner name above. Do this before 8 Oct. Early Bird (24 Sep) is only a Flipkart preview, so the banner can go up now.
2. **Play build:** this icon code is only in the repo. Ship an update **before 7 Oct, 12:00 noon** or phones keep the plain icon through the sales.
3. **End date:** coded through **11 Nov 2026**. Say if it should stop sooner (when the sales end) or run through Diwali only (**8 Nov**).
