# Mintzer App — Project README

**Last updated:** June 2026  
**Your status:** All page **content/specs are ready**. Next step is **UI design in Figma**.

---

## Welcome back — read this first

You paused before a trip. Nothing is broken. The hard part (deciding **what** each screen shows) is done. What’s left is **making it look good in Figma** — either yourself or with a designer.

---

## What is already done

| Done | Where |
|------|--------|
| All 14 screens + 11 pop-ups documented | `docs/screens/` |
| Home layout **locked** (deal card, nav, chips) | `docs/screens/02-home.md` |
| Place order, Wallet, Profile rules locked | `docs/design/` |
| Backend field names for deals | `docs/backend/` |
| HTML mockups you can open in Chrome | `assets/mockups/` |
| Full designer handoff package | `docs/design/FOR-DESIGNER.md` |

**Bottom nav (fixed):** Home · Orders · Wallet · Profile — no Offers tab.

**Style (fixed):** Google Material light · blue `#1A73E8` · not purple / not dark orange clone.

---

## What to do next — pick one path

### Path A — Hire a designer (recommended)

You tried DIY Figma; layout was OK but felt empty. A designer adds polish (real product photos, spacing, shadows).

1. Send them the folder **`docs/`** and **`assets/mockups/`**
2. Tell them to start with **`docs/design/FOR-DESIGNER.md`**
3. Ask them to open **`assets/mockups/home-samples.html`** in Chrome first
4. First deliverables: **design system** + **Home (List + Grid)** + **Login**
5. Then: Deal detail → Place order → Orders → Wallet → Profile → dark mode

**Optional PDF for designer:**  
In project folder run `node scripts/md-to-print-html.js designer` → open `docs/design/DESIGNER-HANDOFF.html` in Chrome → Print → Save as PDF.

---

### Path B — Continue design yourself (ChatGPT → Figma)

Only if you want to try again after the trip.

1. Open **`docs/design/FIGMA-CHATGPT-PROMPT-RULES.md`** — copy **BLOCK A**
2. Open **`docs/design/HOME-FIGMA-PROMPT.md`** — copy **BLOCK B**
3. Paste both into ChatGPT → ask for one Figma prompt for **"Home — List"**
4. After Figma generates, **manually polish** (this is what was missing before):
   - Replace placeholder images with **real product photos**
   - Make spend box a **filled blue block** `#E8F0FE` (not just a label line)
   - Tighten padding to **12dp** inside cards
   - Add **light shadow** on cards
   - Show **3 deals** in the frame
5. Side-by-side compare with **`assets/mockups/home-samples.html`** in Chrome
6. When Home looks good → repeat for next screen using that screen’s `.md` in `docs/screens/`

**Do not redesign Home layout** — only polish. Spec is locked in `02-home.md`.

---

### Path C — Skip Figma for now, plan dev later

Design can wait. When you’re ready to build the app, developers use the same `docs/` folder — no Figma required to start backend, but UI needs either Figma or the HTML mockups as reference.

---

## Suggested order after you return

Do these in order. Check off as you go.

- [ ] **Day 1 — Catch up**  
  Open `assets/mockups/home-samples.html` in Chrome. Skim `docs/design/FOR-DESIGNER.md` (15 min).

- [ ] **Day 1 — Decide path**  
  Designer (A) or DIY (B). If designer: find someone and send `FOR-DESIGNER.md`.

- [ ] **Week 1 — Home + Login in Figma**  
  List view, Grid view, Login phone + OTP. Match locked Home card.

- [ ] **Week 2 — Core flow**  
  Deal detail → Accept → Place order (use `place-order-locked.html`).

- [ ] **Week 3 — Rest of app**  
  My Orders, Order detail, Wallet, Profile, overlays (KYC, etc.).

- [ ] **Week 4 — Dark mode + states**  
  Same screens in dark theme. Loading, empty, error states per screen specs.

- [ ] **Then — Development**  
  Hand Figma + `docs/` to Flutter/dev team. Checklist: `docs/frontend/01-implementation-checklist.md`.

---

## Key files — quick links

| I want to… | Open this |
|------------|-----------|
| See locked Home in browser | `assets/mockups/home-samples.html` |
| Full app flow mockup | `assets/mockups/mintzer-full-flow.html` |
| Place order screen | `assets/mockups/place-order-locked.html` |
| Give everything to a designer | `docs/design/FOR-DESIGNER.md` |
| List of all screens | `docs/screens/SCREEN-INVENTORY.md` |
| One screen’s detail (copy, colors) | `docs/screens/01-login.md` … `11-account-deleted.md` |
| ChatGPT prompt for Home | `docs/design/HOME-FIGMA-PROMPT.md` |
| Colors (hex codes) | `docs/design/COLORS-AND-TOKENS.md` |

---

## Locked decisions — don’t re-debate these

- Home deal card: store logo on image · GST on color row · spend box · blue **Earn** button
- No **Offers** tab in bottom nav
- Wallet: **no withdraw** button
- Login: **phone + OTP only** — no name/KYC at login
- KYC (Name + PAN): only on **first Accept**
- Primary color: **`#1A73E8`** — stays even when new Mintzer logo arrives

Full list: `docs/design/FOR-DESIGNER.md` §21.

---

## Folder map

```
Mintzer-App/
├── README.md                 ← you are here
├── assets/
│   ├── mockups/              ← open .html files in Chrome
│   └── mintzer-*.png         ← reference images
└── docs/
    ├── screens/              ← each app screen (content ready)
    ├── design/               ← designer handoff + colors + rules
    ├── backend/              ← API / data fields
    └── frontend/             ← dev checklist (after design)
```

---

## If you forget everything

1. Open **`assets/mockups/home-samples.html`** in Chrome — that’s the target for Home.  
2. Open **`docs/design/FOR-DESIGNER.md`** — that’s everything for a designer.  
3. Next job: **Figma design**, not more spec writing.

---

## Questions while you’re away

Nothing in this repo needs daily attention during your trip. When you’re back, start with **Path A** or **Path B** above.

Good trip — pick up from **“Suggested order after you return”** when you’re ready.
