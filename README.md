# Foodie — Multi-Vendor Food Ordering App (Clean Architecture + Riverpod)

A portfolio-grade Flutter app that simulates a real multi-vendor food
ordering product — browsing, search, cart, checkout, order tracking — built
on **Clean Architecture** and **Riverpod (no codegen)**, with a mock JSON
"backend" that behaves like a real one: registration *writes* to disk, login
*reads* from that same write.

This README doubles as the **implementation spec**. Every module below is
written so it can be handed to an AI coding agent one at a time — "implement
the Auth module" — and built without needing the rest of the app to already
exist, as long as `0. Global Core` is done first.

---

## Table of Contents

0. [Global core (build this first)](#0-global-core-build-this-first)
1. [Shared data contracts](#1-shared-data-contracts)
2. [Module: Auth](#module-auth)
3. [Module: Home](#module-home)
4. [Module: Search](#module-search)
5. [Module: Restaurant Detail](#module-restaurant-detail)
6. [Module: Product Detail](#module-product-detail)
7. [Module: Cart](#module-cart)
8. [Module: Checkout](#module-checkout)
9. [Module: Orders](#module-orders)
10. [Module: Profile](#module-profile)
11. [Navigation wiring (go_router)](#11-navigation-wiring-go_router)
12. [Testing conventions](#12-testing-conventions)
13. [Engineering decision notes](#13-engineering-decision-notes)
14. [Suggested build order](#14-suggested-build-order)
15. [Out of scope, on purpose](#15-out-of-scope-on-purpose)

---

## 0. Global core (build this first)

Nothing else can be built until this exists — every module below depends on
it. This is infra, not a "feature."

**Files to create:**

```
core/config/app_config.dart          # pageSize=10, debounceMs=400, cacheTtl=Duration(minutes:5)
core/network/result.dart             # sealed Result<F extends Failure, T> { Ok(T), Err(F) } + .fold()/.map()
core/network/failures.dart           # Failure (base), NetworkFailure, ValidationFailure(String field,String msg), NotFoundFailure, ConflictFailure, UnknownFailure
core/network/simulated_latency.dart  # Future<void> simulateDelay({int minMs=300,int maxMs=900})
core/storage/asset_seeder.dart       # copies assets/mock/*.json -> getApplicationDocumentsDirectory()/mock/*.json, only if not already present
core/storage/json_storage_service.dart
   # Future<List<Map<String,dynamic>>> readCollection(String fileName)
   # Future<void> writeCollection(String fileName, List<Map<String,dynamic>> data)
   # must throw a typed exception (not generic Exception) on read/write failure
core/cache/cache_box.dart
   # class CacheEntry<T> { T value; DateTime storedAt; bool isExpired(Duration ttl) }
   # class CacheBox<T> { T? read(String key, Duration ttl); void write(String key, T value); void invalidate(String key); }
core/utils/debouncer.dart            # class Debouncer { Debouncer(Duration delay); void run(void Function() action); void dispose(); }
core/utils/pagination_state.dart
   # class PaginatedState<T> { List<T> items; int page; bool hasMore; bool isLoadingMore; bool isFirstLoad;
   #   PaginatedState<T> copyWith(...); factory PaginatedState.initial(); }
core/providers/core_providers.dart
   # sharedPreferencesProvider (Provider<SharedPreferences>, overridden in bootstrap.dart with the real instance)
   # jsonStorageServiceProvider
   # assetSeederProvider
core/theme/app_theme.dart            # colors, text styles, spacing/radius tokens (carry over from setState version)
core/widgets/                        # AppImage, ShimmerBox, EmptyState, ErrorState(failure, onRetry), AppButton, AppTextField
bootstrap.dart                        # runs AssetSeeder.seed(), reads SharedPreferences.getInstance(), builds ProviderScope with overrides, then runApp
main.dart                             # calls bootstrap()
```

**Acceptance checklist for this module:**
- [ ] `Result<F,T>` has `.fold(onErr, onOk)`, `.isOk`, `.map()` — no layer above `data/` ever uses `try/catch` for expected failures.
- [ ] `JsonStorageService` never touches `assets/mock/` directly — only the documents-directory copy.
- [ ] `AssetSeeder` is idempotent — running it twice does not overwrite existing user-modified data.
- [ ] `CacheBox.read()` returns `null` on miss *or* expiry (caller decides whether to refetch) — it never throws.
- [ ] `Debouncer.run()` cancels any pending timer before scheduling a new one.
- [ ] `PaginatedState.initial()` has `isFirstLoad = true`, empty `items`, `hasMore = true`.

---

## 1. Shared data contracts

Define these entities/models before any feature module — every module below
assumes they exist. Each entity lives in `domain/entities/`, each model
(`fromJson`/`toJson`, extends or maps to the entity) lives in `data/models/`.

```
Category      { id, name, iconUrl }

Restaurant    { id, name, coverImageUrl, logoUrl, cuisineTags[], rating,
                etaMinutes, deliveryFee, isOpen, categoryIds[] }

OptionChoice  { id, label, priceDelta }                      // e.g. "Large", +50
OptionGroup   { id, name, isRequired, minSelect, maxSelect,   // maxSelect=1 => radio, >1 => checkbox
                choices: List<OptionChoice> }
Product       { id, restaurantId, name, description, imageUrl,
                basePrice, isAvailable, optionGroups: List<OptionGroup> }

CartItemOption { groupId, choiceIds: List<String> }
CartItem       { id, productId, restaurantId, quantity,
                 selectedOptions: List<CartItemOption>, unitPrice, lineTotal }

Address        { id, label, line1, city, isDefault }
PaymentMethod  { id, type (cod|card|wallet), label }

OrderStatus    { placed, preparing, onTheWay, delivered, cancelled }
OrderItem      { productId, name, quantity, unitPrice, lineTotal, selectedOptionsSummary: String }
Order          { id, userId, restaurantId, restaurantName, items: List<OrderItem>,
                 subtotal, deliveryFee, total, status: OrderStatus,
                 placedAt, addressLabel, paymentMethodLabel }

UserProfile    { id, name, email, phone, avatarUrl, addresses: List<Address> }
```

**Pricing rule (used by both Product and Cart modules):**
`unitPrice = basePrice + sum(selected choices' priceDelta)`,
`lineTotal = unitPrice * quantity`.

---

## Module: Auth

**Goal:** registration writes a new user into the mutable `users.json`
copy; login validates against that same file; session persists across app
restarts; `go_router` redirects based on session state.

**Files:**
```
domain/repositories/auth_repository.dart
domain/usecases/auth/register_use_case.dart
domain/usecases/auth/login_use_case.dart
domain/usecases/auth/logout_use_case.dart
domain/usecases/auth/restore_session_use_case.dart
data/models/user_model.dart
data/datasources/local/auth_local_datasource.dart
data/repositories/auth_repository_impl.dart
presentation/features/auth/providers/auth_notifier.dart
presentation/features/auth/providers/session_provider.dart
presentation/features/auth/screens/login_screen.dart
presentation/features/auth/screens/register_screen.dart
```

**Repository contract:**
```dart
abstract class AuthRepository {
  Future<Result<Failure, UserProfile>> register(String name, String email, String password);
  Future<Result<Failure, SessionInfo>> login(String email, String password);
  Future<Result<Failure, void>> logout();
  Future<Result<Failure, SessionInfo?>> restoreSession(); // null Ok = no active session
}
```

**Business rules:**
- `RegisterUseCase`: trims/validates email format and non-empty name client-side (ValidationFailure per field) *before* touching the repository; repository additionally checks for a duplicate email in `users.json` and returns `ConflictFailure` if found.
- Password stored via a simple deterministic hash (e.g. salted SHA-256) — never store plaintext, but comment clearly that this is demo-grade, not production security.
- New user gets a generated `id` (uuid), empty `addresses`, and is appended to the existing list in `users.json`, then the whole file is rewritten via `JsonStorageService.writeCollection`.
- `LoginUseCase`: looks up by email, compares hash, returns `NotFoundFailure` if email doesn't exist and a distinct `ValidationFailure` if password is wrong (don't leak which one to the UI copy — show one generic "invalid credentials" message, but keep the failures typed differently internally so it's testable).
- On successful login, generate a session token (uuid) and persist `{token, userId}` via `SharedPreferences` (through `sessionProvider`'s repository call, not directly from the UI).
- `RestoreSessionUseCase` runs once at app start (inside `AuthNotifier.build()`): reads the persisted token, and if present, resolves it back into a `UserProfile` by re-reading `users.json`.

**Provider/state:**
```dart
sealed class AuthState { }
class AuthUnauthenticated extends AuthState {}
class AuthAuthenticated extends AuthState { final UserProfile user; }

class AuthNotifier extends AsyncNotifier<AuthState> {
  Future<AuthState> build() // calls RestoreSessionUseCase
  Future<void> login(String email, String password)
  Future<void> register(String name, String email, String password)
  Future<void> logout()
}
```
`sessionProvider` is a thin `Provider<bool>` derived from `authNotifierProvider` (`watch` + pattern match) — this is what `go_router`'s redirect listens to.

**UI states to handle on both screens:** idle → submitting (disable button,
show spinner) → field-level validation errors shown inline → top-level
failure (duplicate email / invalid credentials) shown as a banner, not a
dialog.

**Acceptance checklist:**
- [ ] Register a new account, then kill and reopen the app, then log in with those exact credentials — succeeds.
- [ ] Registering the same email twice returns a duplicate-email error, doesn't touch the file.
- [ ] Wrong password shows a generic error, not "wrong password" specifically.
- [ ] Logout clears the `SharedPreferences` token and `go_router` redirects to `/login`.
- [ ] Unit tests: `RegisterUseCase` duplicate-email path, `LoginUseCase` both failure paths, `AuthNotifier` state transitions via `ProviderContainer` with a fake `AuthRepository`.

---

## Module: Home

**Goal:** category chips/grid + paginated restaurant list, pull-to-refresh,
open-state disabled UI.

**Files:**
```
domain/repositories/catalog_repository.dart   # shared with Search/Restaurant modules — define once here
domain/usecases/catalog/get_categories_use_case.dart
domain/usecases/catalog/get_restaurants_page_use_case.dart
data/datasources/local/catalog_local_datasource.dart
data/repositories/catalog_repository_impl.dart
presentation/features/home/providers/categories_provider.dart
presentation/features/home/providers/restaurant_list_notifier.dart
presentation/features/home/screens/home_screen.dart
presentation/features/home/widgets/restaurant_card.dart
```

**Repository contract (catalog, shared):**
```dart
abstract class CatalogRepository {
  Future<Result<Failure, List<Category>>> getCategories();
  Future<Result<Failure, PaginatedResult<Restaurant>>> getRestaurants({required int page, int? categoryId});
  Future<Result<Failure, Restaurant>> getRestaurantById(String id);
  Future<Result<Failure, List<Product>>> getProductsByRestaurant(String restaurantId);
  Future<Result<Failure, PaginatedResult<Product>>> searchProducts({required String query, required int page});
}
class PaginatedResult<T> { List<T> items; bool hasMore; }
```

**Business rules:**
- `GetRestaurantsPageUseCase` slices `restaurants.json` by `AppConfig.pageSize`, optionally filtered by `categoryId` first, then sliced — `hasMore = (page * pageSize) < filteredList.length`.
- `restaurantListNotifierProvider` (a `NotifierProvider` wrapping `PaginatedState<Restaurant>`): `loadFirstPage()`, `loadNextPage()` (no-op if `isLoadingMore` or `!hasMore`), `refresh()` (resets to page 1, invalidates the `CacheBox` entry keyed by current `categoryId`), `selectCategory(int? id)` (resets pagination and refetches).
- Category selection and list are two separate providers that the screen composes — don't merge them into one giant Notifier.
- `is_open: false` restaurants render with a dimmed overlay + "Closed" badge and are not tappable into detail (or tappable into a read-only detail — pick one and be consistent, recommend: still viewable, just can't add to cart, matching Product module's `is_available` behavior).

**Acceptance checklist:**
- [ ] Scrolling near the end of the list triggers `loadNextPage()` exactly once per threshold crossing (no duplicate calls on fast scroll).
- [ ] Pull-to-refresh resets the list and re-hits the (simulated) network, ignoring any warm cache.
- [ ] Switching categories resets pagination to page 1.
- [ ] Unit tests: `GetRestaurantsPageUseCase` pagination math (exact page boundary, last-page-partial, empty category), `restaurantListNotifierProvider` `loadNextPage` no-op guard.

---

## Module: Search

**Goal:** debounced product search with race-condition-safe result
application, its own pagination.

**Files:**
```
presentation/features/search/providers/search_notifier.dart
presentation/features/search/screens/search_screen.dart
```
(Reuses `CatalogRepository.searchProducts` from the Home module's contract —
no new repository needed.)

**Provider/state:**
```dart
class SearchState { String query; PaginatedState<Product> results; bool isSearching; }

class SearchNotifier extends Notifier<SearchState> {
  final _debouncer = Debouncer(AppConfig.debounceDuration);
  int _requestId = 0;

  void onQueryChanged(String query) {
    // update state.query immediately for the text field's own display
    _debouncer.run(() => _search(query));
  }

  Future<void> _search(String query) async {
    final myRequestId = ++_requestId;
    // set isSearching = true
    final result = await ref.read(searchProductsUseCaseProvider).call(query, page: 1);
    if (myRequestId != _requestId) return; // stale — a newer search superseded this one, drop silently
    // apply result to state
  }

  Future<void> loadNextPage() { /* same requestId guard applies */ }
}
```

**Business rules:**
- Empty query → clear results, don't call the repository at all.
- Whitespace-only query treated as empty.
- `_requestId` guard is the actual correctness mechanism — the debounce timer alone only reduces call *frequency*, it doesn't prevent a slow earlier request from resolving after a faster later one (see [Engineering Decision Notes](#13-engineering-decision-notes)).

**Acceptance checklist:**
- [ ] Typing quickly triggers exactly one network call after the user stops, not one per keystroke.
- [ ] `fake_async` test: fire a "slow" search then a "fast" search, verify the final state matches the fast (later) query's results, not the slow (earlier) one's.
- [ ] Clearing the search field clears results without a network call.

---

## Module: Restaurant Detail

**Goal:** restaurant header + menu list, cached per-id with TTL so
navigating back and forth doesn't refetch within the cache window.

**Files:**
```
presentation/features/restaurant/providers/restaurant_detail_provider.dart
presentation/features/restaurant/screens/restaurant_detail_screen.dart
presentation/features/restaurant/widgets/menu_item_tile.dart
```

**Provider:**
```dart
final restaurantDetailProvider = FutureProvider.family
    .autoDispose<RestaurantDetailData, String>((ref, restaurantId) async {
  ref.keepAlive(); // survives navigating away and back within the widget's lifetime
  final cache = ref.read(cacheBoxProvider<RestaurantDetailData>());
  final cached = cache.read(restaurantId, AppConfig.cacheTtl);
  if (cached != null) return cached;

  final restaurant = await ref.read(getRestaurantByIdUseCaseProvider).call(restaurantId);
  final products = await ref.read(getProductsByRestaurantUseCaseProvider).call(restaurantId);
  final data = RestaurantDetailData(restaurant: restaurant, products: products);
  cache.write(restaurantId, data);
  return data;
});
```

**Business rules:**
- Passed the `Restaurant` object as `extra` from Home's list (see [Navigation wiring](#11-navigation-wiring-go_router)) so the header can render instantly while the menu list is still loading — don't block the whole screen on one combined future.
- Menu items with `is_available: false` render disabled (dimmed, "Unavailable" tag) and are not tappable into Product Detail.

**Acceptance checklist:**
- [ ] Opening the same restaurant twice within the cache TTL does not trigger a second simulated-network call (verify via a call-count spy on the fake datasource in a widget/provider test).
- [ ] After TTL expiry, reopening triggers a fresh fetch.
- [ ] Unavailable products are visibly disabled and not navigable.

---

## Module: Product Detail

**Goal:** the centerpiece screen — variation/extras selection with
required-group validation and live price recalculation.

**Files:**
```
domain/usecases/product/validate_product_selection_use_case.dart
presentation/features/product/providers/product_config_notifier.dart
presentation/features/product/screens/product_detail_screen.dart
presentation/features/product/widgets/option_group_selector.dart
```

**Provider:**
```dart
class ProductConfigState {
  Product product;
  Map<String, Set<String>> selectedChoiceIdsByGroup; // groupId -> chosen choiceIds
  int quantity;
  int get unitPrice; // computed
  int get totalPrice => unitPrice * quantity;
  Map<String, String> validationErrorsByGroup; // groupId -> message, empty if valid
  bool get canAddToCart => validationErrorsByGroup.isEmpty;
}

class ProductConfigNotifier extends Notifier<ProductConfigState> {
  // family(productId), seeded with the Product passed via go_router extra
  void toggleChoice(String groupId, String choiceId) {
    // single-select group (maxSelect==1): replace the set with {choiceId}
    // multi-select group: add/remove, but refuse to add past maxSelect (no-op, don't silently drop others)
    // after every toggle: recompute price + re-run validation for that group only
  }
  void setQuantity(int qty); // clamp to >= 1
  bool validateAll(); // called on "Add to Cart" tap — validates every required group, populates validationErrorsByGroup, returns overall validity
}
```

**Business rules (this is the "walk an interviewer through it" screen —
be precise):**
- A group is invalid if `isRequired && selectedChoiceIdsByGroup[group.id].isEmpty`.
- `minSelect`/`maxSelect` bound the *count* even for optional groups (e.g. "pick up to 3 toppings" — selecting a 4th is a no-op, not an error banner, since it's prevented rather than corrected after the fact).
- Price recalculates on every toggle, not just on submit — this is the "live pricing" behavior the original setState screen was built around; don't regress it to submit-time-only calculation.
- Tapping "Add to Cart" while invalid: run `validateAll()`, scroll to (or visually highlight) the first invalid required group, don't add to cart, don't navigate away.

**Acceptance checklist:**
- [ ] Selecting a choice in a single-select group deselects any previous choice in that same group.
- [ ] Attempting to over-select a multi-select group beyond `maxSelect` is a no-op with no error shown (it was prevented, not corrected).
- [ ] Price updates immediately on every toggle and on quantity change.
- [ ] Submitting with a required group unfilled blocks add-to-cart and surfaces which group is missing.
- [ ] Unit tests directly on `ProductConfigNotifier` (via `ProviderContainer`) covering: single-select replace, multi-select cap, required-group validation pass/fail, price math with multiple groups selected simultaneously.

---

## Module: Cart

**Goal:** central cart state, quantity controls, pricing summary — the one
piece of state that needs to survive navigating through Restaurant →
Product → back → Checkout.

**Files:**
```
domain/repositories/cart_repository.dart
domain/usecases/cart/add_to_cart_use_case.dart
domain/usecases/cart/update_cart_item_quantity_use_case.dart
domain/usecases/cart/remove_cart_item_use_case.dart
data/repositories/cart_repository_impl.dart   # in-memory only, no JSON persistence needed for cart
presentation/features/cart/providers/cart_notifier.dart
presentation/features/cart/screens/cart_screen.dart
```

**Provider:**
```dart
class CartState { List<CartItem> items; String? restaurantId; // single-restaurant-cart rule
  int get subtotal; }

class CartNotifier extends Notifier<CartState> {
  void add(Product product, ProductConfigState config); // from Product Detail's "Add to Cart"
  void updateQuantity(String cartItemId, int quantity); // quantity 0 => remove
  void remove(String cartItemId);
  void clear();
}
```
`cartNotifierProvider` must **not** be `autoDispose` — it's one of very few
providers in the app that should stay alive for the whole session (declared
without `.autoDispose`, or `keepAlive()`'d at root via `bootstrap.dart`
reading it once).

**Business rules:**
- **Single-restaurant cart:** adding a product from a different restaurant than what's already in the cart should prompt "Clear cart and start a new order?" rather than silently mixing restaurants — implement as a `Result`-style check the UI reacts to (`CartConflictException`-style typed result, not a thrown exception across the Notifier boundary).
- Identical product + identical selected options + same restaurant → increment quantity on the existing `CartItem` instead of adding a duplicate line.
- `lineTotal` recalculated whenever quantity changes.

**Acceptance checklist:**
- [ ] Adding the same product+options twice merges into one line with quantity 2, not two lines.
- [ ] Adding a product from a different restaurant while the cart is non-empty triggers the conflict flow, doesn't silently merge.
- [ ] Quantity set to 0 removes the line item.
- [ ] Unit tests: merge-on-identical-config, conflict detection, subtotal math.

---

## Module: Checkout

**Goal:** address + payment selection, simulated order placement that
writes into `orders.json` and clears the cart.

**Files:**
```
domain/usecases/checkout/place_order_use_case.dart
data/datasources/local/orders_local_datasource.dart
data/repositories/orders_repository_impl.dart   # shared with Orders module
presentation/features/checkout/providers/checkout_notifier.dart
presentation/features/checkout/screens/checkout_screen.dart
```

**Provider/state:**
```dart
class CheckoutState { Address? selectedAddress; PaymentMethod? selectedPayment; bool isPlacingOrder; }

class CheckoutNotifier extends Notifier<CheckoutState> {
  void selectAddress(Address a);
  void selectPayment(PaymentMethod p);
  Future<Result<Failure, Order>> placeOrder(); // reads cartNotifierProvider's current items
}
```

**Business rules:**
- `PlaceOrderUseCase` requires both an address and a payment method selected — returns `ValidationFailure` otherwise, checked before the simulated network call, not after.
- On success: build an `Order` from the current `CartState` (snapshotting item names/prices at time of order, not live references to `Product`), append to `orders.json` via `JsonStorageService`, then call `cartNotifierProvider.notifier.clear()`.
- `_isPlacingOrder` (bool guard) prevents a double-tap on "Place Order" from creating two orders — disable the button the instant it's tapped.

**Acceptance checklist:**
- [ ] Placing an order with no address selected shows a validation error, makes no network/write call.
- [ ] A successful order appears in `orders.json` with the exact items/prices that were in the cart at submit time.
- [ ] Cart is empty immediately after a successful order.
- [ ] Double-tapping "Place Order" produces exactly one order.

---

## Module: Orders

**Goal:** order history list + status timeline for a single order.

**Files:**
```
domain/usecases/orders/get_orders_for_user_use_case.dart
presentation/features/orders/providers/orders_notifier.dart
presentation/features/orders/screens/orders_list_screen.dart
presentation/features/orders/screens/order_detail_screen.dart
presentation/features/orders/widgets/order_status_timeline.dart
```

**Business rules:**
- Orders list is filtered by the current session's `userId` — reads `sessionProvider` to know which id to filter `orders.json` by.
- Newest-first sort by `placedAt`.
- Status timeline renders `OrderStatus` as an ordered sequence
  (`placed → preparing → onTheWay → delivered`) with the current status
  highlighted; `cancelled` is a distinct terminal state rendered separately,
  not inserted into the middle of the happy-path sequence.

**Acceptance checklist:**
- [ ] Only the logged-in user's own orders appear (verify with two seeded users in `users.json`/`orders.json`).
- [ ] Orders sorted newest first.
- [ ] Unit test: `GetOrdersForUserUseCase` filtering + sorting.

---

## Module: Profile

**Goal:** view/edit profile, manage saved addresses, logout, "reset demo
data" action.

**Files:**
```
domain/usecases/profile/update_profile_use_case.dart
domain/usecases/profile/add_address_use_case.dart
presentation/features/profile/providers/profile_notifier.dart
presentation/features/profile/screens/profile_screen.dart
presentation/features/profile/screens/edit_profile_screen.dart
```

**Business rules:**
- Editing profile writes back to `users.json` through the same
  `AuthLocalDataSource`/`AuthRepository` used by registration — don't create
  a second, parallel writer for the same file.
- "Reset demo data" button re-runs `AssetSeeder` in force mode (overwrite),
  then logs the current session out, since the user record it referenced
  may no longer exist post-reset.

**Acceptance checklist:**
- [ ] Editing name/phone persists across app restart.
- [ ] Adding an address makes it selectable in Checkout without needing to reopen the app.
- [ ] "Reset demo data" restores `users.json`/`restaurants.json`/etc. to the bundled seed and logs out.

---

## 11. Navigation wiring (go_router)

```
/login                         (public)
/register                      (public)
/  (ShellRoute — bottom nav)
  /home                        (protected)
  /search                      (protected)
  /orders                      (protected)
  /profile                     (protected)
/restaurant/:id                (protected, extra: Restaurant)
/product/:id                   (protected, extra: {Product, restaurantId})
/cart                          (protected)
/checkout                      (protected)
/orders/:id                    (protected, extra: Order)
```

- `redirect:` reads a `Listenable` wrapper around `sessionProvider` (a
  `GoRouterRefreshStream` fed by `ref.listen`), redirects unauthenticated
  users to `/login` from any protected route and redirects an authenticated
  user away from `/login`/`/register` to `/home`.
- Detail screens receive their seed object via `extra` (see Restaurant
  Detail and Product Detail modules above) — the `:id` in the path is for
  deep-linkability/`.family(id)` provider keys, the `extra` is for
  instant-render without waiting on a refetch.

---

## 12. Testing conventions

- **Domain usecases:** pure unit tests against a fake repository
  implementing the abstract contract — no Riverpod, no Flutter imports.
- **Data repositories:** tested against a fake datasource, asserting
  correct mapping and `Failure` translation.
- **Presentation notifiers:** `ProviderContainer` + provider overrides
  (fake repository/usecase injected), asserting `AsyncValue`/state
  transitions.
- **Timers:** anything using `Debouncer` is tested with `fake_async`, never
  a real `Future.delayed` wait.
- Shared test helpers live in `test/helpers/` — `fake_datasources.dart` and
  a `buildContainer({overrides})` helper so every notifier test doesn't
  re-declare the same boilerplate.
- Golden/widget-tree integration tests are explicitly **not** required for
  any module — see [Out of scope](#15-out-of-scope-on-purpose).

---

## 13. Engineering decision notes

**Why no Riverpod codegen.** Hand-written providers keep the dependency
graph fully readable without running `build_runner` first. A commented-out
`@riverpod` equivalent sits above each manual Notifier so the trade-off is
explicit rather than implied.

**Why usecases only where they earn their keep.** Not every field read
gets a `GetXUseCase` — that's over-engineering. Usecases exist where
there's real logic to isolate (validation, coordination, business rules
like required-option-group enforcement); a plain pass-through goes straight
from repository to Notifier.

**Why a JSON file on disk instead of an in-memory list for auth.** An
in-memory list resets on hot restart and doesn't survive relaunch, which
undersells the "register, then log back in" story. A real file write means
the persistence is checkable, not simulated.

**Why request-id guarding in Search, not just the debounce timer.** The
debounce timer only reduces call *frequency*; it doesn't stop an earlier,
slower request from resolving after a later, faster one and overwriting
its results. Those are two different race conditions.

**Why the cart is single-restaurant.** Mirrors how every real food-delivery
app actually works (one kitchen fulfills one order) — modeling a
multi-restaurant cart would be solving a problem the domain doesn't have,
just to look more "flexible."

---

## 14. Suggested build order

1. **Global Core** (Section 0) + **Shared data contracts** (Section 1)
2. **Auth** — nothing else needs to be behind a login wall to be *built*, but doing this first makes `go_router`'s guard meaningful from day one
3. **Home** (establishes the catalog repository the rest of the app reuses)
4. **Restaurant Detail** → **Product Detail** (the centerpiece)
5. **Cart** → **Checkout** → **Orders**
6. **Search** (fully independent, safe to build any time after Home)
7. **Profile** (touches Auth's writer, do last so the contract is stable)
8. **go_router wiring** (Section 11) — can be stubbed early with placeholder screens and filled in as each module lands

---

## 15. Out of scope, on purpose

- **Golden tests / full widget integration tests** — the UI itself isn't
  what's being evaluated here.
- **Real encryption/hashing for mock auth** — demo-grade by design, clearly
  commented; real auth security is a backend/infra concern.
- **A BLoC version of this app** — if it exists, it's a separate app in a
  different domain (delivery/driver tracking), not a port of this one.
- **`flutter analyze` warnings on first run** — run
  `flutter pub get && flutter analyze` right after cloning; anything
  flagged is first-pass cleanup, not unfinished architecture.