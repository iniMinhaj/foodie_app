import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/home/domain/repositories/catalog_repository.dart';
import 'package:foodie_app/features/home/presentation/providers/catalog_providers.dart';
import 'package:foodie_app/features/home/presentation/providers/restaurant_list_notifier.dart';

import '../../../helpers/fake_catalog_repository.dart';

void main() {
  late FakeCatalogRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeCatalogRepository();
    container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('RestaurantListNotifier', () {
    test('starts at PaginatedState.initial() without calling the repository', () {
      final state = container.read(restaurantListNotifierProvider);

      expect(state.isFirstLoad, isTrue);
      expect(state.items, isEmpty);
      expect(repository.getRestaurantsCallCount, 0);
    });

    test('loadFirstPage populates items and hasMore from the repository', () async {
      repository.nextRestaurantsResult = Result.ok(PaginatedResult(
        items: [buildFakeRestaurant('r1'), buildFakeRestaurant('r2')],
        hasMore: true,
      ));

      final notifier = container.read(restaurantListNotifierProvider.notifier);
      await notifier.loadFirstPage();

      final state = container.read(restaurantListNotifierProvider);
      expect(state.items.map((r) => r.id), ['r1', 'r2']);
      expect(state.page, 1);
      expect(state.hasMore, isTrue);
      expect(state.isFirstLoad, isFalse);
    });

    test('loadNextPage appends items and advances the page', () async {
      final notifier = container.read(restaurantListNotifierProvider.notifier);
      repository.nextRestaurantsResult = Result.ok(PaginatedResult(
        items: [buildFakeRestaurant('r1')],
        hasMore: true,
      ));
      await notifier.loadFirstPage();

      repository.nextRestaurantsResult = Result.ok(PaginatedResult(
        items: [buildFakeRestaurant('r2')],
        hasMore: false,
      ));
      await notifier.loadNextPage();

      final state = container.read(restaurantListNotifierProvider);
      expect(state.items.map((r) => r.id), ['r1', 'r2']);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
    });

    test('loadNextPage is a no-op once hasMore is false', () async {
      final notifier = container.read(restaurantListNotifierProvider.notifier);
      repository.nextRestaurantsResult =
          const Result.ok(PaginatedResult(items: [], hasMore: false));
      await notifier.loadFirstPage();

      final callCountAfterFirstLoad = repository.getRestaurantsCallCount;
      await notifier.loadNextPage();

      expect(repository.getRestaurantsCallCount, callCountAfterFirstLoad);
    });

    test('loadNextPage is a no-op before the first page has loaded', () async {
      final notifier = container.read(restaurantListNotifierProvider.notifier);

      await notifier.loadNextPage();

      expect(repository.getRestaurantsCallCount, 0);
    });

    test('selectCategory resets pagination to page 1, refetches, and updates the selection', () async {
      final notifier = container.read(restaurantListNotifierProvider.notifier);
      repository.nextRestaurantsResult = Result.ok(PaginatedResult(
        items: [buildFakeRestaurant('r1', categoryIds: const ['cat_a'])],
        hasMore: true,
      ));
      await notifier.loadFirstPage();
      await notifier.loadNextPage(); // now on page 2

      repository.nextRestaurantsResult = Result.ok(PaginatedResult(
        items: [buildFakeRestaurant('r2', categoryIds: const ['cat_b'])],
        hasMore: false,
      ));
      notifier.selectCategory('cat_b');
      await Future<void>.delayed(Duration.zero);

      final state = container.read(restaurantListNotifierProvider);
      expect(state.page, 1);
      expect(state.items.map((r) => r.id), ['r2']);
      expect(container.read(selectedCategoryIdProvider), 'cat_b');
      expect(repository.lastRequestedCategoryId, 'cat_b');
    });

    test('a failed first load surfaces the failure message and clears it on a successful retry', () async {
      final notifier = container.read(restaurantListNotifierProvider.notifier);
      repository.nextRestaurantsResult = const Result.err(UnknownFailure('boom'));

      await notifier.loadFirstPage();

      expect(container.read(restaurantListErrorProvider), 'boom');
      expect(container.read(restaurantListNotifierProvider).isFirstLoad, isFalse);

      repository.nextRestaurantsResult = Result.ok(
        PaginatedResult(items: [buildFakeRestaurant('r1')], hasMore: false),
      );
      await notifier.loadFirstPage();

      expect(container.read(restaurantListErrorProvider), isNull);
      expect(container.read(restaurantListNotifierProvider).items, hasLength(1));
    });
  });
}
