# Mintzer — Screen Specifications



Product flow documentation for the Mintzer mobile app rebuild. Use these files as the source of truth before implementation.



**How many screens?** See **[SCREEN-INVENTORY.md](./SCREEN-INVENTORY.md)** — **14 main routes**, **11 overlays**, **~25 UI surfaces** total.



**Mockups:** `assets/mintzer-*.png` are **reference only**. Specs in markdown win if anything conflicts.



## Design principles



- **Colors:** Google Material — full tokens in [../design/COLORS-AND-TOKENS.md](../design/COLORS-AND-TOKENS.md) · light + dark in [../design/THEME-LIGHT-DARK-MODE.md](../design/THEME-LIGHT-DARK-MODE.md). **Mintzer logo = placeholder** until brand file; app blue `#1A73E8` stays fixed.
- **Validation:** Field errors **inline** · API/action/copy → **snackbar bottom-right** — [../design/VALIDATION-UX.md](../design/VALIDATION-UX.md)
- **Platform:** Figma first · Flutter or other stack later.

- **Login:** Phone + OTP only at app entry. No profile forms at login.

- **Deal flow:** Home → Deal detail → Accept → Place order → Success → My Orders.

- **One active placement:** User cannot accept a new deal while a timer is running without Order ID or screenshot submitted.

- **No auto courier tracking:** User enters tracking and delivery details manually.

- **Timer duration:** Configurable in backend (not hardcoded in app).



## Screen index



| # | Screen | File | LOCKED |

|---|--------|------|--------|

| 1 | Login (OTP) | [01-login.md](./01-login.md) | — |

| 2 | Home | [02-home.md](./02-home.md) | **LOCKED** · `home-samples.html` |

| 3 | Deal detail | [03-deal-detail.md](./03-deal-detail.md) | — |

| 4 | Place order | [04-accept-place-order.md](./04-accept-place-order.md) | Yes |

| 5 | Order placed success | [05-order-placed-success.md](./05-order-placed-success.md) | — |

| 6 | My Orders + Order detail | [06-my-orders.md](./06-my-orders.md) | — |

| 7 | Wallet | [07-wallet.md](./07-wallet.md) | Yes |

| 8 | ~~Offers~~ | [08-offers.md](./08-offers.md) | Deferred — not in nav v1 |

| 9 | Profile (+ sub-flows) | [09-profile.md](./09-profile.md) | Yes |



## End-to-end flow



```

Login → Home → Deal detail → Accept → [KYC/bank if first] → Place order → Success → My Orders

                                                      ↓

                              Tracking → Out for delivery → (admin marks received)

                                                      ↓

                              Upload invoice → 48h payment timer → Wallet

```



## Related documentation



- **Screen count & routes:** [SCREEN-INVENTORY.md](./SCREEN-INVENTORY.md)

- **Backend API & admin:** [../backend/README.md](../backend/README.md)

- **Frontend build plan:** [../frontend/README.md](../frontend/README.md)

- **Design / LOCKED flows:** [../design/README.md](../design/README.md)



## Shared components



- **Bottom navigation:** Home | Orders | **Wallet** | Profile

- **Support FAB:** Chat / WhatsApp (visible on main tabs)

- **Notifications:** Push + bell inbox — deal viewed follow-up, accept abandon, timer warnings, order steps. Deep-link to Place order, Deal detail, My Orders, or Wallet. See [../backend- for developer reference/07-notifications.md](../backend-%20for%20developer%20reference/07-notifications.md). In-app Home strip + My Orders remain the primary resume path.

