# Mintzer — Screen Specifications

Product flow documentation for the Mintzer mobile app rebuild. Use these files as the source of truth before implementation.

## Design principles

- **Colors:** Google Material (primary `#1A73E8`, white surfaces, green for earnings). No purple gradients or generic “AI” palettes.
- **Login:** Phone + OTP only at app entry. No profile forms at login.
- **Deal flow:** Option B — Home → Deal detail → Accept → Success → My Orders.
- **One active placement:** User cannot accept a new deal while a timer is running without Order ID or screenshot submitted.
- **No auto courier tracking:** User enters tracking and delivery details manually.
- **Timer duration:** Configurable in backend (not hardcoded in app).

## Screen index

| # | Screen | File |
|---|--------|------|
| 1 | Login (OTP) | [01-login.md](./01-login.md) |
| 2 | Home | [02-home.md](./02-home.md) |
| 3 | Deal detail | [03-deal-detail.md](./03-deal-detail.md) |
| 4 | Accept / place order | [04-accept-place-order.md](./04-accept-place-order.md) |
| 5 | Order placed success | [05-order-placed-success.md](./05-order-placed-success.md) |
| 6 | My Orders | [06-my-orders.md](./06-my-orders.md) |
| 7 | Wallet | [07-wallet.md](./07-wallet.md) |
| 8 | Offers | [08-offers.md](./08-offers.md) |
| 9 | Profile | [09-profile.md](./09-profile.md) |

## End-to-end flow

```
Login → Home → Deal detail → Accept → Order placed success → My Orders
                                                      ↓
                              Tracking → Out for delivery → (admin marks received)
                                                      ↓
                              Upload invoice → 48h payment timer → Wallet
```

## Related documentation

- **Backend API & admin:** [../backend/README.md](../backend/README.md)
- **Frontend build plan:** [../frontend/README.md](../frontend/README.md)

## Shared components

- **Bottom navigation:** Home | Orders | Offers | Profile
- **Support FAB:** Chat / WhatsApp (visible on main tabs)
- **Notifications:** Deep-link to Accept screen (active timer), My Orders (next action), or Deal detail (re-engage after expiry)
