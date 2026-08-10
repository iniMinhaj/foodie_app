# Migration Status

Tracks progress migrating `foodie_app` from setState to Clean Architecture + Riverpod (manual) + go_router, module by module. See [BUILD_SPEC.md](BUILD_SPEC.md) for the full spec and [../CLAUDE.md](../CLAUDE.md) for working conventions.

## Directory layout

- `lib/features/<module>/{data,domain,presentation}/` — modules already migrated to Clean Architecture (currently: `auth`, `home`, `restaurant`, `cart`). Shared domain entities used across multiple modules live in `lib/core/entities/`, not inside any one feature. `CatalogRepository` (categories + paginated restaurant list) is `home`'s own repository, reused as-is by Search once it's built — extend it there rather than duplicating it. Restaurant Detail owns its own `RestaurantRepository` (single-restaurant + menu lookups) instead, since that's a distinct read shape from the paginated list and doesn't belong on `home`'s contract. Cart owns its own `CartRepository`, backed by `cart_sample.json`, and exposes `cartNotifierProvider` (an `AsyncNotifier`) as the single source of cart state for every screen that adds to or reads the cart.
- `lib/legacy/` — everything not yet migrated: old setState screens (mirrors the original `lib/features/<module>/` layout) plus `lib/legacy/models/` and the `CartService`/`MockDataLoader` scaffolding they depend on. To migrate a module, build its Clean Architecture version under `lib/features/<module>/`, wire it into `lib/router/app_router.dart` (or, for tabs reached only via `HomeScreen`'s bottom nav — Orders/Cart/Profile — swap the legacy widget for the migrated one directly in `home_screen.dart`), then delete the corresponding `lib/legacy/<module>/` folder.

- [x] **Global Core** — config, `Result`/`Failure`, simulated latency, `LocalApiClient`/`JsonLocalApiClient`/`AssetSeeder`, `CacheBox`, `Debouncer`, `PaginatedState`, `core_providers`, shared domain entities, `bootstrap.dart`/`main.dart` cutover.
- [x] **Auth** — register/login/logout/restore-session, `go_router` redirect guard, demo-grade hashed local persistence.
- [x] **Home** — categories + paginated restaurant list. Bottom nav still bridges into legacy Orders/Cart/Profile screens until those are migrated.
- [x] **Restaurant Detail** — restaurant header (rendered instantly from the tapped `Restaurant`, no refetch) + menu list, cached per-restaurant-id with TTL (`CacheBox`, `.family.autoDispose` `FutureProvider`).
- [ ] **Product Detail** — variation/extras selection, live pricing.
- [x] **Cart** — central cart state, single-restaurant rule.
- [ ] **Checkout** — address/payment selection, order placement.
- [ ] **Orders** — order history + status timeline.
- [ ] **Search** — debounced, race-safe product search.
- [ ] **Profile** — edit profile, manage addresses, reset demo data.
- [ ] **Full go_router table** — all routes wired (currently only `/login`, `/register`, `/home`; Search/Orders/Cart/Profile are still reached only via `HomeScreen`'s local bottom nav, not go_router routes).
- [ ] **Old code retired** — `lib/legacy/*` setState screens and `lib/legacy/models/*` deleted once their replacements land.

Each module is built per its section in `BUILD_SPEC.md`, gated on `flutter analyze && flutter test` passing, and committed as its own checkpoint.
