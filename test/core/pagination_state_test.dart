import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/utils/pagination_state.dart';

void main() {
  group('PaginatedState', () {
    test('initial() starts empty, first load, with more assumed available', () {
      final state = PaginatedState<int>.initial();

      expect(state.items, isEmpty);
      expect(state.page, 0);
      expect(state.hasMore, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.isFirstLoad, isTrue);
    });

    test('copyWith overrides only the given fields', () {
      final state = PaginatedState<int>.initial();
      final next = state.copyWith(items: [1, 2, 3], page: 1, isFirstLoad: false);

      expect(next.items, [1, 2, 3]);
      expect(next.page, 1);
      expect(next.isFirstLoad, isFalse);
      expect(next.hasMore, isTrue); // untouched field preserved
    });
  });
}
