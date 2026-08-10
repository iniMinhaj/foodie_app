import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cache_box.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/entities/restaurant.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/utils/pagination_state.dart';
import 'catalog_providers.dart';

/// Kept separate from [restaurantListNotifierProvider] so the category
/// chip row only rebuilds on selection changes, not on every list-state
/// change (new page loaded, refresh in flight, ...).
class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? categoryId) => state = categoryId;
}

final selectedCategoryIdProvider =
    NotifierProvider<SelectedCategoryNotifier, String?>(SelectedCategoryNotifier.new);

/// Also kept separate from [PaginatedState] itself — that class is shared
/// by every paginated module (Search's results too) and stays a plain
/// success-shaped state; a failed first load is signalled here instead.
class RestaurantListErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? message) => state = message;
}

final restaurantListErrorProvider =
    NotifierProvider<RestaurantListErrorNotifier, String?>(RestaurantListErrorNotifier.new);

final _restaurantListCacheProvider =
    Provider<CacheBox<PaginatedState<Restaurant>>>((ref) => CacheBox());

class RestaurantListNotifier extends Notifier<PaginatedState<Restaurant>> {
  String? _categoryId;

  String get _cacheKey => _categoryId ?? '_all';

  /// Doesn't self-trigger a fetch — the widget kicks off [loadFirstPage]
  /// explicitly (see `HomeScreen.initState`). Keeping `build()` a pure
  /// sync return also keeps this notifier trivial to unit test: a fresh
  /// `ProviderContainer` always starts at `PaginatedState.initial()` with
  /// zero repository calls, no timing race to account for.
  @override
  PaginatedState<Restaurant> build() => PaginatedState<Restaurant>.initial();

  Future<void> loadFirstPage() async {
    final cached =
        ref.read(_restaurantListCacheProvider).read(_cacheKey, AppConfig.cacheTtl);
    if (cached != null) {
      ref.read(restaurantListErrorProvider.notifier).set(null);
      state = cached;
      return;
    }
    state = PaginatedState<Restaurant>.initial();
    await _fetchPage(1);
  }

  Future<void> loadNextPage() async {
    if (state.isFirstLoad || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetchPage(state.page + 1);
  }

  /// Resets to page 1 and re-hits the (simulated) network, ignoring any
  /// warm cache. Also clears the category filter so pull-to-refresh acts
  /// as a full reset back to the unfiltered list.
  Future<void> refresh() async {
    _categoryId = null;
    ref.read(selectedCategoryIdProvider.notifier).select(null);
    ref.read(_restaurantListCacheProvider).invalidate(_cacheKey);
    state = PaginatedState<Restaurant>.initial();
    await _fetchPage(1);
  }

  void selectCategory(String? categoryId) {
    if (categoryId == _categoryId) return;
    _categoryId = categoryId;
    ref.read(selectedCategoryIdProvider.notifier).select(categoryId);
    loadFirstPage();
  }

  Future<void> _fetchPage(int page) async {
    final result = await ref
        .read(catalogRepositoryProvider)
        .getRestaurants(page: page, categoryId: _categoryId);

    result.fold(
      (Failure failure) {
        ref.read(restaurantListErrorProvider.notifier).set(failure.userMessage);
        state = state.copyWith(isLoadingMore: false, isFirstLoad: false);
      },
      (paginated) {
        ref.read(restaurantListErrorProvider.notifier).set(null);
        final next = state.copyWith(
          items: page == 1 ? paginated.items : [...state.items, ...paginated.items],
          page: page,
          hasMore: paginated.hasMore,
          isLoadingMore: false,
          isFirstLoad: false,
        );
        ref.read(_restaurantListCacheProvider).write(_cacheKey, next);
        state = next;
      },
    );
  }
}

final restaurantListNotifierProvider =
    NotifierProvider<RestaurantListNotifier, PaginatedState<Restaurant>>(
  RestaurantListNotifier.new,
);
