import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../home/domain/repositories/catalog_repository.dart';
import '../../../home/presentation/providers/catalog_providers.dart';

class SearchState extends Equatable {
  final String query;
  final bool isSearching;
  final bool hasSearched;
  final List<SearchRestaurantResult> restaurantResults;
  final List<SearchProductResult> productResults;
  final List<String> recentSearches;
  final String? errorMessage;

  const SearchState({
    required this.query,
    required this.isSearching,
    required this.hasSearched,
    required this.restaurantResults,
    required this.productResults,
    required this.recentSearches,
    this.errorMessage,
  });

  factory SearchState.initial() => const SearchState(
        query: '',
        isSearching: false,
        hasSearched: false,
        restaurantResults: [],
        productResults: [],
        recentSearches: ['biryani', 'pizza', 'burger deals'],
      );

  SearchState copyWith({
    String? query,
    bool? isSearching,
    bool? hasSearched,
    List<SearchRestaurantResult>? restaurantResults,
    List<SearchProductResult>? productResults,
    List<String>? recentSearches,
    String? errorMessage,
  }) =>
      SearchState(
        query: query ?? this.query,
        isSearching: isSearching ?? this.isSearching,
        hasSearched: hasSearched ?? this.hasSearched,
        restaurantResults: restaurantResults ?? this.restaurantResults,
        productResults: productResults ?? this.productResults,
        recentSearches: recentSearches ?? this.recentSearches,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [query, isSearching, hasSearched, restaurantResults, productResults, recentSearches, errorMessage];
}

/// No initial load — state starts synchronously empty, driven entirely by
/// [onQueryChanged]/[selectSuggestion], mirroring `RestaurantListNotifier`'s
/// shape rather than `CartNotifier`'s "await an initial future" one.
class SearchNotifier extends Notifier<SearchState> {
  final _debouncer = Debouncer(AppConfig.debounceDuration);
  int _searchToken = 0;

  @override
  SearchState build() {
    ref.onDispose(_debouncer.dispose);
    return SearchState.initial();
  }

  void onQueryChanged(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: query,
        hasSearched: false,
        isSearching: false,
        restaurantResults: const [],
        productResults: const [],
      );
      return;
    }

    state = state.copyWith(query: query, isSearching: true);
    _debouncer.run(() => _runSearch(query));
  }

  /// Bypasses the debounce for an explicit tap — search immediately.
  void selectSuggestion(String term) {
    final recents =
        state.recentSearches.contains(term) ? state.recentSearches : [term, ...state.recentSearches].take(5).toList();
    state = state.copyWith(query: term, recentSearches: recents);
    _runSearch(term);
  }

  Future<void> _runSearch(String query) async {
    // Debouncer only reduces call frequency — this guards against an
    // earlier, slower response landing after a newer, faster one.
    final token = ++_searchToken;
    state = state.copyWith(isSearching: true);

    final result = await ref.read(catalogRepositoryProvider).search(query);
    if (token != _searchToken) return;

    state = result.fold(
      (failure) => state.copyWith(
        isSearching: false,
        hasSearched: true,
        errorMessage: failure.userMessage,
        restaurantResults: const [],
        productResults: const [],
      ),
      (results) => state.copyWith(
        isSearching: false,
        hasSearched: true,
        errorMessage: null,
        restaurantResults: results.restaurants,
        productResults: results.products,
      ),
    );
  }
}

final searchNotifierProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
