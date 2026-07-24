# Foodie — Multi-Vendor Food Ordering App (UI Layer)

This is the **presentation layer** of the app, built with plain `setState`
on purpose — it's the scaffolding to migrate onto **Riverpod** (and a second
pass onto **BLoC** for a separate showcase app). Every screen that holds
local state has a `TODO: Riverpod` comment at the top of the file explaining
exactly what becomes a Notifier/Provider and what stays as-is.

## Run it

```bash
flutter pub get
flutter run
```

No backend needed — all data comes from `assets/mock/*.json`, loaded through
`MockDataLoader` with an artificial network delay so loading/shimmer states
are visible.

## Structure

```
lib/
  core/
    theme/app_theme.dart          # colors, text styles, spacing/radius tokens
    utils/mock_data_loader.dart   # ★ swap this for Dio calls later — every
                                   #   screen goes through here, never rootBundle directly
    utils/cart_service.dart       # ★ temporary ChangeNotifier global store —
                                   #   delete once cartProvider exists
    widgets/                      # shared: AppImage, shimmer skeletons, empty/error states
  models/                         # plain fromJson models (Category, Restaurant,
                                   # Product w/ variation & extra groups, CartItem, Order, UserProfile)
  features/
    splash/
    auth/login_screen.dart        # UI-only — real auth (Firebase) wires in separately
    home/                         # categories + paginated restaurant list, pull-to-refresh
    search/                       # Timer-based debounce demo
    restaurant/                   # restaurant detail + menu list
    product/                      # ★ centerpiece: variation/extras selection + live pricing
    cart/                         # reads CartService, qty controls, pricing summary
    checkout/                     # address + payment selection, simulated order placement
    orders/                       # order history + status timeline tracking
    profile/
```

## Where the "senior" signals are

- **`product_detail_screen.dart`** — required-group validation, single vs
  multi-select option groups, `max_selectable` enforcement, live unit/total
  price recalculation. This is the one screen worth walking an interviewer
  through line by line.
- **`mock_data_loader.dart`** — every screen reads through one seam. Swapping
  JSON assets for a real Dio-based repository touches this file only.
- **Shimmer + empty + error states** are separate, reusable widgets, not
  copy-pasted per screen — intentional, and a good golden-test target.
- **`is_available: false` / `is_open: false`** products/restaurants exist in
  the mock data on purpose so the disabled/unavailable UI states are real,
  not hypothetical.

## Migrating to Riverpod (suggested order)

1. `cart_service.dart` → `CartNotifier` + `cartProvider` (touches Product
   Detail, Cart, Checkout)
2. `mock_data_loader.dart` calls → wrap each in a `Repository` interface,
   inject via `Provider`, call from `FutureProvider`/`FutureProvider.family`
   per screen (Home, Restaurant Detail, Orders, Profile)
3. `search_screen.dart`'s Timer debounce → `AsyncNotifier` with a debounced
   `search(query)` method
4. `product_detail_screen.dart`'s selection maps → `ProductConfigNotifier`
   scoped `.family(productId)`
5. `checkout_screen.dart`'s `_isPlacingOrder` → `AsyncNotifier.guard()`
   around the real order-placement call

## Not included (by design)

- No `flutter analyze` / test run happened here — this was written without
  a local Flutter SDK. Run `flutter pub get && flutter analyze` first thing
  after unzipping, and treat any warnings as expected first-pass cleanup.
- No BLoC version — per the plan, that's a separate app (delivery/driver
  tracking domain) built from scratch with `flutter_bloc` + `bloc_test`,
  not a port of this one.
- No unit/golden/integration tests yet — add those once the Riverpod
  migration lands, so tests target the final architecture instead of code
  you're about to throw away.
