# Mintzer toasts (LOCKED 20 Sep 2026)

**Code:** `app/lib/widgets/mintzer_toast.dart`  
**Rule:** Short · relevant · dismissible. No black Material snackbars for product feedback.

## Families

| Kind | Look | Use for |
|------|------|---------|
| `info` | Lilac | Copies, soft opens, ticket opened |
| `success` | Mint | Saved, invoice uploaded, wallet/Excel |
| `warn` | Amber | 5 min left, missing field, soft alerts |
| `danger` | Soft red | 1 min, expired, network, errors, upload fail |
| `brand` | Solid purple | Rare system pings (orders/deals refreshed) |
| `celebrate` | Dark | Order submitted only |

## Durations

- Soft (`info` / `success` / `warn` / `brand`): **2s**
- Hard (`celebrate` / `danger`): **3s**

## Must

- Icon + title + optional one-line subtitle + **X**
- One toast at a time (`hideCurrentSnackBar`)
- After popping a sheet: capture `ScaffoldMessenger` first → `showMintzerToastOn`
- Timer thresholds fire **once** (5 min, 1 min) — not every tick

## Must not

- Saved / Removed-from-Saved until Saved exists
- Solid purple for every success
- Stacking timer spam
- Plain `SnackBar(content: Text(…))` in product flows
