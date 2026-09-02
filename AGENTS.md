# Mintzer — Agent instructions

**Project path:** `D:\dev\mintzer-app`  
**Read first:** [docs/AGENT-DEV-PROCESS.md](docs/AGENT-DEV-PROCESS.md)

---

## What this repo is

Mintzer — Android-first Indian fintech app. Users browse Flipkart/Amazon card deals, accept deals, place orders on stores, submit proof, get paid in an in-app Wallet.

**This repo is specs + mockups + docs.** There is no Flutter/app code yet.

---

## Current phase

| Phase | Status |
|-------|--------|
| Screen content & product rules | **Done** — `docs/screens/`, `docs/design/` |
| Backend API specs | **Done** — `docs/backend- for developer reference/` |
| HTML reference mockups | **Done** — `assets/mockups/` |
| Figma UI design | **Next** — designer or client |
| Mobile app code (Flutter) | **After design** — see `docs/frontend/` |
| Backend implementation | **After or parallel** — see backend docs |

---

## Before you change anything

1. Read [docs/AGENT-DEV-PROCESS.md](docs/AGENT-DEV-PROCESS.md) (full process).
2. Check if the screen is **LOCKED** in [docs/screens/SCREEN-INVENTORY.md](docs/screens/SCREEN-INVENTORY.md).
3. **Markdown specs beat PNG mockups.** HTML exploration files (`home-v2.html`, `home-v3.html`, `home-card-variants.html`) are **not** source of truth.
4. **Locked Home reference:** `assets/mockups/home-samples.html` + `docs/screens/02-home.md`.

---

## Do not

- Add Offers tab to bottom nav (deferred).
- Add Wallet withdraw button.
- Change Home deal card field layout without client approval.
- Use purple gradients or clone competitor dark/orange UI.
- Ask for KYC at login (KYC = Name + PAN on **first Accept** only).
- Commit unless the user explicitly asks.

---

## Quick file map

| Need | Path |
|------|------|
| Full dev process (agents) | `docs/AGENT-DEV-PROCESS.md` |
| **Everything we discussed (master log)** | `docs/COMPLETE-DECISIONS-LOG.md` |
| All screens list | `docs/screens/SCREEN-INVENTORY.md` |
| Per-screen spec | `docs/screens/01-login.md` … `11-account-deleted.md` |
| Designer handoff | `docs/design/FOR-DESIGNER.md` |
| **Affiliate marketing (LOCKED)** | `docs/design/AFFILIATE-MARKETING-REQUIREMENTS.md` |
| Interactive demo v2.4 | `assets/mockups/mintzer-app-demo.html` |
| Frontend build order | `docs/frontend/README.md` |
| Frontend checklist | `docs/frontend/01-implementation-checklist.md` |
| Backend modules | `docs/backend- for developer reference/README.md` |
| Colors / tokens | `docs/design/COLORS-AND-TOKENS.md` |
| Validation UX | `docs/design/VALIDATION-UX.md` |
| Client “what to do next” | `README.md` |

---

## Style (fixed)

- Material 3 Light default · Dark mode required later
- Primary: `#1A73E8` (dark: `#8AB4F8`)
- Bottom nav: **Home · Orders · Wallet · Profile**
