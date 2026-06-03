# Mintzer — Frontend (build first)

Build the mobile app UI with **mock data** before connecting real APIs. Screen specs live in [../screens/](../screens/README.md).

## Stack (pick one before scaffold)

| Option | Good for |
|--------|----------|
| **Flutter** | Smooth UI, Material 3, Google colors out of the box |
| **React Native (Expo)** | If you prefer web/React ecosystem |

Default recommendation: **Flutter + Material 3** for RedBus-like fluid lists and `#1A73E8` theme.

## Build order

| Phase | Screens | Goal |
|-------|---------|------|
| **1** | App shell + theme | Colors, fonts, bottom nav, routing |
| **2** | Login (OTP UI) | Fake OTP — any code works |
| **3** | Home | Deal list + active placement strip (mock) |
| **4** | Deal detail | Product, logos, **money card** (fees + earn) |
| **5** | Accept | Timer, copy buttons, Order ID, Cancel |
| **6** | Order success | Celebration → My Orders |
| **7** | My Orders | Card steps: tracking → OFD → invoice lock → 48h timer |
| **8** | Wallet, Offers, Profile | Static / mock |

Backend later — swap mock services for API calls per [../backend/](../backend/README.md).

## Mock data rules

- One JSON file (or Dart/TS constants) with 2–3 sample deals including **platformFee**, **cardFee**, full money block.
- Mock **active placement** toggle for Home strip testing.
- Timer: local countdown from 15 min until API exists.
- Invoice step: mock `parcelReceived: true/false` flag on order.

## Shared UI components (build once)

| Component | Used on |
|-----------|---------|
| `DealCard` | Home list |
| `LogoRow` | Fixed 40×40 store/bank, `BoxFit.contain` |
| `MoneySummaryCard` | Deal detail (+ short form on Accept) |
| `PrimaryButton` / `OutlineButton` | Everywhere |
| `PasteTextField` | Accept, My Orders |
| `OrderProgressBar` | My Orders collapsed |
| `CountdownTimer` | Accept, payment 48h |
| `ActivePlacementBanner` | Home |

## Design tokens

```
primary       #1A73E8
surface       #FFFFFF
background    #F8F9FA
earnGreen     #188038
warning       #F9AB00
error         #D93025
textPrimary   #202124
textSecondary #5F6368
```

No purple gradients. Light theme only for v1.

## Navigation map

```
/login
/main (bottom nav)
  /home
  /orders
  /offers
  /profile
/deal/:id          → Deal detail
/accept/:id        → Accept (placement)
/order-success/:id
```

Deep links can mirror backend later.

## Phase 1 deliverable

User can tap: **Login → Home → Deal detail → Accept (timer) → fake submit → Success → My Orders (mock steps)** without any server.

## Next file

Screen-by-screen checklist: [01-implementation-checklist.md](./01-implementation-checklist.md)
