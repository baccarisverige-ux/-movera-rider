# Movera Rider architecture

Source of truth: the **current approved Movera Rider UI**.
Backend is the source of truth for price, assignment, and ride state.
This app is presentation + user interaction only.

## Layers

```
Rider app  = presentation + interaction
Driver app = driver workflow (separate)
Backend    = source of truth
Realtime   = live ride state
Payments   = money
Maps       = geography / routing
```

Inside each feature:

- `presentation/` screens and widgets only
- `application/` controllers / notifiers / use-cases
- `domain/` entities, repository interfaces, ride/pricing rules
- `data/` DTOs, local storage, remote sources, repository impls

UI never calls HTTP, Maps SDKs, payment SDKs, or storage directly.

## Ride lifecycle

`idle → pickup_selected → destination_selected → quote_loading →
ride_options_ready → ride_selected → payment_selected → booking_requested →
finding_driver → driver_assigned → driver_arriving → driver_waiting →
trip_started → trip_in_progress → trip_completed → payment_finalized →
rating_pending → closed`

Scheduled rides branch from booking, they are not a second product.

## State and navigation

Keep **GetX** as the current navigator (`GetMaterialApp`) until a dedicated
Riverpod/Bloc migration. Do not mix a second state library in the same pass.
Ride data moves by **IDs and immutable models**, not raw widget state.

## Rules

1. One change, one purpose. Never rename, restyle, migrate state, and change
   map/API logic in the same commit.
2. Nothing critical lives only in the UI: pricing, ride status, payments, maps,
   auth, promotions, permissions each have a domain/service layer.
3. Every feature must recover from refresh, restart, slow network, GPS loss,
   API failure, denied permissions, and partial outage.

## Cleanup map (this pass)

### KEEP (approved current design — not moved, not restyled)

| Screen | File |
|---|---|
| Home | `lib/features/rider/home/home.dart` |
| Select ride | `lib/features/rider/select ride/select_ride.dart` |
| Finding driver | `lib/features/rider/Finding Drivers/finding_drivers.dart` |
| Waiting / active ride | `lib/features/rider/waiting for driver/waiting_for_driver.dart` |
| Ride completed | `lib/features/rider/ride completed/` |
| Payment methods | `lib/features/rider/my wallet/wallet.dart` (`WalletScreen`) |
| Wallet | `lib/features/rider/my wallet/wallet.dart` (`WalletHome`) |
| Ride history | `lib/features/rider/ride history/ride_history.dart` |
| Support | `lib/features/rider/support/support.dart` |
| Profile / menu | `lib/features/rider/profile/profile.dart`, `side menu/side_menu.dart` |
| Schedule ride | `lib/features/rider/schedule ride/` |
| Saved places | `lib/features/rider/saved places/` |
| Promotions | `lib/features/rider/promotions/promotions.dart` |
| Chat | `lib/shared/presentation/chat/chat.dart` |
| Notifications | `lib/shared/presentation/notification/notifiction.dart` |
| Refer & earn | `lib/shared/presentation/Refer and Earn/refer_and_earn.dart` |
| Auth (login chain) | `lib/features/rider/auth/sign in/`, `create acc/`, `phone verification/` |

Auth is unused from `main()` today (app opens on Home). It is **kept**, not deleted.

### REMOVE (proven unused — zero imports, zero routes)

| Old file | Why |
|---|---|
| `shared/presentation/splash/splash.dart` | Original splash. `main` opens Home. |
| `shared/presentation/onboarding/onboarding.dart` | Only used by unused Splash. Model `shared/models/onboarding.dart` is **kept**. |
| `features/rider/auth/starter/starter.dart` | Welcome/starter never referenced. |
| `shared/widgets/color_picker.dart` | Template widget, no callers. |
| `shared/widgets/dropdown.dart` | Template widget, no callers. |
| `shared/widgets/expantion_tile.dart` | Template widget, no callers. |
| `features/rider/my wallet/components/choose_bank.dart` | Old withdraw sheet, not wired to current Wallet. |
| `features/rider/my wallet/components/withdraw_sucess.dart` | Only used by unused choose_bank. |

Already removed in earlier work: old Help wrapper, old Trips list, old History app bar.

### NOT deleted (doubt)

- Auth screens (Sign in / Create account / Phone) — current login UI, not a duplicate of a new screen.
- Folder names with spaces (`select ride`, `Finding Drivers`) — rename is a later dedicated commit.

## Next architecture steps (later commits, one each)

1. Extract map geocoding/camera into `core/maps` without changing Home visuals.
2. Move voucher catalog into `features/wallet/domain` without changing Wallet UI.
3. Typed routes for Home → SelectRide → FindingDrivers.
4. Remote quotes replacing local fare math.
5. Snake_case folder rename pass.
