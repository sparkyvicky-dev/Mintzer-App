# Colors & design tokens (Figma → any platform)

**Status:** LOCKED for v1 design  
**Dark mode:** [THEME-LIGHT-DARK-MODE.md](./THEME-LIGHT-DARK-MODE.md)

Use these **hex tokens in Figma variables** — not hard-coded per screen. When you build the app (Flutter, React Native, or native), map the same tokens to code.

---

## Platform note (design first, build later)

| Step | What to do |
|------|------------|
| **Now (Figma)** | Layout, spacing (8dp grid), typography, **color tokens**, components |
| **Later (dev)** | Pick stack — docs assume **Flutter** first, but design is **not locked to Flutter** |
| **Rule** | Same structure in light + dark; no platform-specific UI (no iOS-only chrome unless you decide later) |

Design for **fluid, standard mobile patterns** (Material-style). Any modern framework can implement the same tokens.

---

## Mintzer logo (temporary)

| Until logo file arrives | Use in Figma |
|-------------------------|--------------|
| Header / Login | Text **“Mintzer”** in `#1A73E8` (light) or `#8AB4F8` (dark) |
| Or | Grey rounded rect `#E8EAED` + “M” in `#5F6368` |

**Important:** App **primary blue stays `#1A73E8`** — do **not** change buttons/links when logo colors arrive. Only **replace the logo asset**. If logo clashes, adjust **logo**, not the whole app palette.

---

## Store & bank logos (temporary)

| Until PNGs arrive | Use |
|-------------------|-----|
| Flipkart, Amazon, Axis, etc. | Fixed box 40×40 (store) / 32×32 (bank) · fill `#E8EAED` · letter **F**, **A**, **AX** in `#5F6368` |
| When PNG ready | Drop in box · **contain** · never stretch · never recolor official logos |

Dark mode: logo tile background `#3C4043`, letter `#9AA0A6`.

---

## Core tokens — Light

| Token | Hex | Use |
|-------|-----|-----|
| `background` | `#F8F9FA` | Screen background |
| `surface` | `#FFFFFF` | Cards, sheets, inputs |
| `primary` | `#1A73E8` | Buttons, links, active tab, key CTAs |
| `primary-pressed` | `#1557B0` | Button pressed |
| `primary-container` | `#E8F0FE` | Chips, Copy buttons, active strip bg |
| `text-primary` | `#202124` | Headings, amounts |
| `text-secondary` | `#5F6368` | Captions, hints, labels |
| `divider` | `#E8EAED` | Borders, row separators |
| `success` | `#188038` | Earn, paid, success check, dock accent |
| `success-container` | `#E6F4EA` | Success banners |
| `warning` | `#E37400` | Timer text |
| `warning-container` | `#FEF7E0` | Timer pill, timer row bg |
| `error` | `#D93025` | Errors, logout, destructive text |
| `error-container` | `#FCE8E6` | Error banners, suspended hint |

---

## Core tokens — Dark

| Token | Hex | Use |
|-------|-----|-----|
| `background` | `#121212` | Screen background |
| `surface` | `#1E1E1E` | Cards, sheets |
| `primary` | `#8AB4F8` | Buttons, links |
| `primary-container` | `#394457` | Chips, strips |
| `text-primary` | `#E8EAED` | Headings |
| `text-secondary` | `#9AA0A6` | Captions |
| `divider` | `#3C4043` | Borders |
| `success` | `#81C995` | Earn, success |
| `warning` | `#FDD663` | Timer |
| `warning-container` | `#3c2f1e` | Timer bg (adjust for contrast) |
| `error` | `#F28B82` | Errors, destructive |

---

## Component tokens (all screens)

| Component | Light | Notes |
|-----------|-------|--------|
| Primary button | bg `#1A73E8`, text `#FFFFFF` | Radius ~24dp, min height 48dp |
| Secondary / outline | border `#1A73E8`, text `#1A73E8` | |
| Text field | bg `#FFFFFF`, border `#E8EAED`, focus border `#1A73E8` | |
| Disabled button | bg `#E8EAED`, text `#9AA0A6` | |
| Bottom nav | bg `#FFFFFF`, active `#1A73E8`, inactive `#5F6368` | |
| FAB (support) | bg `#1A73E8`, icon `#FFFFFF` | |
| Copy button | bg `#E8F0FE`, text `#1A73E8` | Address rows |
| Destructive | text `#D93025` | Delete account, Cancel order |
| Snackbar (error/success) | bg `#323232`, text `#FFFFFF` | Bottom-right · *Copied* · API errors |

---

## Place order only (LOCKED v3)

| Element | Light |
|---------|-------|
| Checkout amount box border | `#1A73E8` |
| Open Flipkart zone | bg `#E8F0FE`, dashed `#1A73E8` |
| Bottom dock top border | `#188038` |
| Timer | bg `#FEF7E0`, text `#E37400`, countdown `#D93025` |
| Tap-to-paste field | border `#1A73E8`, hint `#5F6368` |

---

## What NOT to use

- Purple AI gradients  
- PerkPay dark/gold full-screen look  
- Random logo colors driving app primary  
- Stretched or recolored Flipkart/bank logos  

---

## Figma checklist

1. Create **variables** for tokens above (light collection + dark collection)  
2. Logo placeholder component — swap later  
3. LogoRow component — store 40 + bank 32  
4. Export specs as tokens — dev maps to Flutter `ThemeData` or equivalent  
