# Light mode + Dark mode (entire app)

**Requirement:** Full app supports **day (light)** and **night (dark)**. User can switch.

---

## Default

| | |
|--|--|
| **Default** | Light mode (first install) |
| **User choice** | Profile → **Appearance** → Light · Dark · **System** (optional) |

**System** = follow phone dark mode setting (recommended third option).

---

## Where user changes theme

| Location | Control |
|----------|---------|
| **Profile → Appearance** | Light / Dark / System |
| Persist | Saved on device + account (sync if logged in on two phones) |

---

## Design rules (both modes)

- **Same layout** — only colors change, not structure  
- **Same copy** — English / Hindi unchanged  
- **Logos** — Mintzer: **placeholder until brand file** (see [COLORS-AND-TOKENS.md](./COLORS-AND-TOKENS.md)). Store/bank: grey tile + letter, then PNG — never stretch or recolor  
- **Money / earn** — green must stay readable in dark mode (adjust shade)  
- **Status strips** (orders) — blue/amber/green with dark-mode variants  
- **No** purple AI gradients in either mode  

**Platform:** Design with tokens in Figma first. App can be built in **Flutter or another stack** later — same hex tokens map to any framework.

**Full palette + logo rules:** [COLORS-AND-TOKENS.md](./COLORS-AND-TOKENS.md)

---

## Color tokens — Light (day)

| Token | Hex |
|-------|-----|
| Background | `#F8F9FA` |
| Surface / card | `#FFFFFF` |
| Primary | `#1A73E8` |
| Primary pressed | `#1557B0` |
| Primary container | `#E8F0FE` |
| Text primary | `#202124` |
| Text secondary | `#5F6368` |
| Timer / warning bg | `#FEF7E0` |
| Timer text | `#E37400` |
| Earn / success | `#188038` |
| Success container | `#E6F4EA` |
| Error / logout | `#D93025` |
| Divider | `#E8EAED` |

---

## Color tokens — Dark (night)

| Token | Hex |
|-------|-----|
| Background | `#121212` |
| Surface / card | `#1E1E1E` |
| Primary | `#8AB4F8` |
| Text primary | `#E8EAED` |
| Text secondary | `#9AA0A6` |
| Earn / success | `#81C995` |
| Error / logout | `#F28B82` |
| Divider | `#3C4043` |

Designer: deliver **Figma variables** or two frames per key screen (Home, Deal detail, Accept, Orders, Wallet, Profile).

**Mockups:** Dark samples below are **visual reference only** — implement from tokens above. Light/dark share the same **12 routes** (not separate screen count).

**Dark mode reference mockups (v1):**
- `assets/mintzer-home-dark-mockup.png`
- `assets/mintzer-deal-detail-dark-mockup.png`
- `assets/mintzer-place-order-external-dark-mockup.png`
- `assets/mintzer-wallet-dark-mockup.png`
- `assets/mintzer-profile-dark-mockup.png`

(Light mockups: all other `assets/mintzer-*-mockup.png` without `-dark-` in the name.)

---

## Screens that must have dark mode (v1)

- Login + OTP  
- Home  
- Deal detail  
- Accept / timer  
- Order placed success  
- My Orders list + order detail  
- Wallet  
- Profile + KYC + Language + My tickets  
- Offers placeholder  
- All modals (KYC gate, cancel, tickets, dialogs)  

---

## Implementation note (for dev)

- **Design is platform-agnostic** — Figma tokens first; choose Flutter / React Native / native after design is locked  
- Flutter (recommended in repo docs): `ThemeMode` + `ThemeData` light/dark  
- Do not maintain two separate apps — one theme system  

---

## Profile row (add)

| Row | Options |
|-----|---------|
| **Appearance** | Light · Dark · System |
