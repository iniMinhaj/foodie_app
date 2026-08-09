# Migration Status

Tracks progress migrating `foodie_app` from setState to Clean Architecture + Riverpod (manual) + go_router, module by module. See [BUILD_SPEC.md](BUILD_SPEC.md) for the full spec and [../CLAUDE.md](../CLAUDE.md) for working conventions.

## Directory layout

- `lib/features/<module>/{data,domain,presentation}/` — modules already migrated to Clean Architecture (currently: `auth`; `home` has only a router placeholder). Shared domain entities used across multiple modules live in `lib/core/entities/`, not inside any one feature.
- `lib/legacy/` — everything not yet migrated: old setState screens (mirrors the original `lib/features/<module>/` layout) plus `lib/legacy/models/` and the `CartService`/`MockDataLoader` scaffolding they depend on. To migrate a module, build its Clean Architecture version under `lib/features/<module>/`, wire it into `lib/router/app_router.dart`, then delete the corresponding `lib/legacy/<module>/` folder.

- [ ] **Global Core** — config, `Result`/`Failure`, simulated latency, `JsonStorageService`/`AssetSeeder`, `CacheBox`, `Debouncer`, `PaginatedState`, `core_providers`, shared domain entities, `bootstrap.dart`/`main.dart` cutover.
- [ ] **Auth** — register/login/logout/restore-session, `go_router` redirect guard, demo-grade hashed local persistence.
- [ ] **Home** — categories + paginated restaurant list.
- [ ] **Restaurant Detail** — cached-by-id restaurant + menu.
- [ ] **Product Detail** — variation/extras selection, live pricing.
- [ ] **Cart** — central cart state, single-restaurant rule.
- [ ] **Checkout** — address/payment selection, order placement.
- [ ] **Orders** — order history + status timeline.
- [ ] **Search** — debounced, race-safe product search.
- [ ] **Profile** — edit profile, manage addresses, reset demo data.
- [ ] **Full go_router table** — all routes wired (currently only `/login`, `/register`, placeholder `/home`).
- [ ] **Old code retired** — `lib/legacy/*` setState screens and `lib/legacy/models/*` deleted once their replacements land.

Each module is built per its section in `BUILD_SPEC.md`, gated on `flutter analyze && flutter test` passing, and committed as its own checkpoint.
