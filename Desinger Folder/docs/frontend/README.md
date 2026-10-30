# Mintzer — Frontend (build first)

Build the mobile app UI with **mock data** before connecting real APIs. Screen specs live in [../screens/](../screens/README.md).

**Screen count:** [../screens/SCREEN-INVENTORY.md](../screens/SCREEN-INVENTORY.md) — **12 routes + ~10 overlays ≈ 22 UI surfaces**. Mockups in `assets/` are reference only; follow markdown specs.

## Stack (pick one before scaffold)

| Option | Good for |
|--------|----------|
| **Flutter** | Smooth UI, Material 3, Google colors out of the box |
| **React Native (Expo)** | If you prefer web/React ecosystem |

Default recommendation: **Flutter + Material 3** for RedBus-like fluid lists and `#1A73E8` theme.

## Build order

| Phase | Screens | Goal |
|-------|---------|------|
| **1** | App shell + theme (light + dark tokens) | Colors, fonts, bottom nav, routing |
| **2** | Login (phone + OTP) | Fake OTP — any code works |
| **3** | Home | Deal list + active placement strip (mock) |
| **4** | Deal detail | Product, logos, **money card** (fees + earn) |
| **5** | Place order | Mode choice, external + in-app layouts, KYC/bank gates |
| **6** | Order success | Celebration → My Orders |
| **7** | My Orders + Order detail | Placement card, steps, add note, tickets |
| **8** | Wallet, Profile | Wallet LOCKED (export + filters); Offers deferred |

Backend later — swap mock services for API calls per [../backend/](../backend/README.md).

## Mock data rules

- One JSON file (or Dart/TS constants) with 2–3 sample deals including **platformFee**, **cardFee**, full money block.
- Mock **active placement** toggle for Home strip + My Orders placement card.
- Timer: local countdown from config until API exists.
- Invoice step: mock `parcelReceived: true/false` flag on order.

## Shared UI components (build once)

| Component | Used on |
|-----------|---------|
| `DealCard` | Home list |
| `LogoRow` | Fixed 40×40 store/bank, `BoxFit.contain` |
| `MoneySummaryCard` | Deal detail (+ short form on Place order) |
| `PrimaryButton` / `OutlineButton` | Everywhere |
| `PasteTextField` | Place order, My Orders |
| `OrderProgressBar` | My Orders collapsed |
| `CountdownTimer` | Place order, placement card, payment 48h |
| `ActivePlacementBanner` | Home |
| `BottomSheetTabs` | Place order (Deal / Delivery / Submit) |

## Design tokens

**Light:** see checklist. **Dark:** [../design/THEME-LIGHT-DARK-MODE.md](../design/THEME-LIGHT-DARK-MODE.md).

```
primary       #1A73E8  (dark: #8AB4F8)
surface       #FFFFFF  (dark: #1E1E1E)
background    #F8F9FA  (dark: #121212)
earnGreen     #188038  (dark: #81C995)
```

No purple gradients.

## Navigation map

Full list: [../screens/SCREEN-INVENTORY.md](../screens/SCREEN-INVENTORY.md).

```
/login → /login/otp → /main (tabs)
/deal/:id
/place-order/:placementId
/order-success/:orderId
/orders/:id
/profile/tickets …
```

## Phase 1 deliverable

User can tap: **Login → Home → Deal detail → Place order (timer) → submit → Success → My Orders (steps)** without any server.

## Next file

Screen-by-screen checklist: [01-implementation-checklist.md](./01-implementation-checklist.md)
