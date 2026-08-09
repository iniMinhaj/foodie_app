import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/features/home/data/datasources/local/catalog_local_datasource.dart';
import 'package:foodie_app/features/home/data/repositories/catalog_repository_impl.dart';

import '../../../../helpers/fake_local_api_client.dart';

/// 12 restaurants: 10 tagged `cat_a` (an exact page boundary when
/// filtered), 2 tagged `cat_b` (unfiltered spills into a partial page 2).
Map<String, dynamic> _restaurant(String id, {required String categoryId}) => {
      'id': id,
      'name': 'Restaurant $id',
      'logo_url': '',
      'cover_url': '',
      'category_ids': [categoryId],
      'rating': 4.2,
      'delivery_time_minutes': {'min': 20, 'max': 30},
      'delivery_fee': 1.5,
      'is_open': true,
      'tags': <String>[],
    };

void main() {
  late CatalogRepositoryImpl repository;

  setUp(() {
    final storage = FakeLocalApiClient({
      'categories.json': [
        {'id': 'cat_a', 'name': 'Pizza', 'icon_url': 'icon_a.png'},
        {'id': 'cat_b', 'name': 'Burger', 'icon_url': 'icon_b.png'},
      ],
      'restaurants.json': [
        for (var i = 1; i <= 10; i++) _restaurant('rest_$i', categoryId: 'cat_a'),
        for (var i = 11; i <= 12; i++) _restaurant('rest_$i', categoryId: 'cat_b'),
      ],
    });

    repository = CatalogRepositoryImpl(CatalogLocalDataSource(storage));
  });

  group('CatalogRepositoryImpl.getCategories', () {
    test('maps every category field', () async {
      final result = await repository.getCategories();

      final categories = result.valueOrNull!;
      expect(categories, hasLength(2));
      expect(categories.first.id, 'cat_a');
      expect(categories.first.name, 'Pizza');
      expect(categories.first.iconUrl, 'icon_a.png');
    });
  });

  group('CatalogRepositoryImpl.getRestaurants pagination', () {
    test('page 1 unfiltered returns the first pageSize (10) items with hasMore true', () async {
      final result = await repository.getRestaurants(page: 1);

      final page = result.valueOrNull!;
      expect(page.items, hasLength(10));
      expect(page.items.first.id, 'rest_1');
      expect(page.hasMore, isTrue);
    });

    test('page 2 unfiltered returns the trailing partial page with hasMore false', () async {
      final result = await repository.getRestaurants(page: 2);

      final page = result.valueOrNull!;
      expect(page.items.map((r) => r.id), ['rest_11', 'rest_12']);
      expect(page.hasMore, isFalse);
    });

    test('a category filter landing exactly on the page size reports hasMore false', () async {
      final result = await repository.getRestaurants(page: 1, categoryId: 'cat_a');

      final page = result.valueOrNull!;
      expect(page.items, hasLength(10));
      expect(page.hasMore, isFalse);
    });

    test('a page past the end of a filtered category returns no items', () async {
      final result = await repository.getRestaurants(page: 2, categoryId: 'cat_a');

      final page = result.valueOrNull!;
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('an unknown category returns an empty page, not an error', () async {
      final result = await repository.getRestaurants(page: 1, categoryId: 'cat_none');

      final page = result.valueOrNull!;
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
