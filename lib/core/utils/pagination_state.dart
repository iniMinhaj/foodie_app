/// Generic paginated-list state shared by every module that pages
/// through a collection (Home's restaurant list, Search's results, ...).
class PaginatedState<T> {
  final List<T> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isFirstLoad;

  const PaginatedState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.isLoadingMore,
    required this.isFirstLoad,
  });

  factory PaginatedState.initial() => PaginatedState<T>(
        items: const [],
        page: 0,
        hasMore: true,
        isLoadingMore: false,
        isFirstLoad: true,
      );

  PaginatedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isFirstLoad,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFirstLoad: isFirstLoad ?? this.isFirstLoad,
    );
  }
}
