# Mintzer App — Project README

**Project folder:** `D:\dev\mintzer-app` (local dev copy)  
**Last updated:** 18 Sep 2026  
**Your status:** Specs + **live demo UI locked**. Live Play orders mapped. **Play update must not crash** — [docs/STATUS.md](docs/STATUS.md). **Next: Flutter in `app/`** (replace the counter).

**New Cursor agent?** Read **`AGENTS.md`** then **`docs/STATUS.md`** then **`docs/AGENT-DEV-PROCESS.md`**.  
**Everything we discussed:** open **`assets/mockups/mintzer-decisions-log.html`** in Chrome (or `docs/COMPLETE-DECISIONS-LOG.html`)

---

## Welcome back — read this first

Open **`docs/STATUS.md`**. UI is locked. The job is **Flutter that cannot crash on old Play orders** — not more Figma, not uploading the HTML demo.

---

## What is already done

| Done | Where |
|------|--------|
| All 14 screens + 11 pop-ups documented | `docs/screens/` |
| Home layout **locked** (deal card, nav, chips) | `docs/screens/02-home.md` |
| Place order, Wallet, Profile rules locked | `docs/design/` |
| Backend field names for deals | `docs/backend/` |
| **Live demo UI locked 2026-09-18** | `assets/mockups/mintzer-designer-taste-demo.html` |
| **Affiliate marketing spec + demo v2.4** | `docs/design/AFFILIATE-MARKETING-REQUIREMENTS.md` · `mintzer-app-demo.html` |
| Full designer handoff package | `docs/design/FOR-DESIGNER.md` |

**Bottom nav (fixed):** Home · Orders · Wallet · Profile — no Offers tab.

**Style (fixed):** Material 3 light · app purple `#7B61FF` (live demo) · mintzer.in may stay `#9C71E4`.

---

## What to do next — pick one path

### Path A — Start the real user app (recommended now)

UI is locked. Do **not** upload the HTML demo to Play.

1. Scaffold **Flutter** from `docs/frontend/01-implementation-checklist.md`
2. Match `assets/mockups/mintzer-designer-taste-demo.html`
3. When Orders work on mock data, map live rows with `docs/backend- for developer reference/11-live-order-migration.md`
4. Ship as **`com.mintzer`** (same key). Test an old paid order + an in-progress order first.

### Path B — Hire a designer (parallel, not a gate)

You tried DIY Figma; layout was OK but felt empty. A designer adds polish (real product photos, spacing, shadows).

1. Send them the folder **`docs/`** and **`assets/mockups/`**
2. Tell them to start with **`docs/design/FOR-DESIGNER.md`**
3. Ask them to open **`assets/mockups/home-samples.html`** in Chrome first
4. First deliverables: **design system** + **Home (List + Grid)** + **Login**
5. Then: Deal detail → Place order → Orders → Wallet → Profile → dark mode

**Optional PDF for designer:**  
In project folder run `node scripts/md-to-print-html.js designer` → open `docs/design/DESIGNER-HANDOFF.html` in Chrome → Print → Save as PDF.

---

### Path C — Continue design yourself (ChatGPT → Figma)

Only if you want visual polish without a designer. Not required to start Flutter.

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

## Suggested order after you return

Do these in order. Check off as you go.

- [ ] **Catch up** — `docs/STATUS.md` · live demo HTML · `11-live-order-migration.md` §10 (legacy users).
- [ ] **Do not** upload the demo to Play. **Do not** force PAN on update.
- [ ] **Start Flutter** — `app/` + `docs/frontend/01-implementation-checklist.md` (mock data first).
- [ ] **Wire live orders** — mapper. Test old paid + in-progress + **no crash on empty fields**.
- [ ] **Play update** as `com.mintzer` only after those cases work. Keep force-update **off** until then.

Designer/Figma can run **in parallel** (Path B / C). Not a gate.

---

## Key files — quick links

| I want to… | Open this |
|------------|-----------|
| See locked Home in browser | `assets/mockups/home-samples.html` |
| **Try full app (live demo)** | **`assets/mockups/mintzer-designer-taste-demo.html`** |
| **Old Play orders → new UI** | `docs/backend- for developer reference/11-live-order-migration.md` |
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
- Primary color: **`#7B61FF`** — live demo. Website purple `#9C71E4` is mintzer.in only.

Full list: `docs/design/FOR-DESIGNER.md` §21.

---

## Folder map

```
Mintzer-App/
├── AGENTS.md                 ← new agents: read first
├── README.md                 ← you are here
├── assets/
│   ├── mockups/              ← open .html files in Chrome
│   └── mintzer-*.png         ← reference images
└── docs/
    ├── AGENT-DEV-PROCESS.md  ← full app dev process for agents
    ├── screens/              ← each app screen (content ready)
    ├── design/               ← designer handoff + colors + rules
    ├── backend- for developer reference/
    └── frontend/             ← dev checklist (after design)
```

---

## If you forget everything

1. **`docs/STATUS.md`** — locked, crash rules, TODO.  
2. **`assets/mockups/mintzer-designer-taste-demo.html`** — the UI.  
3. Next job: **Flutter in `app/`**, then mapper on live rows. Not a Play upload.

---

## Questions while you’re away

Nothing in this repo needs daily attention during your trip. When you’re back, start with **Path A** or **Path B** above.

Good trip — pick up from **“Suggested order after you return”** when you’re ready.
