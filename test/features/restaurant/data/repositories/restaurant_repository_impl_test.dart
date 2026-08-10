import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/features/restaurant/data/datasources/local/restaurant_local_datasource.dart';
import 'package:foodie_app/features/restaurant/data/repositories/restaurant_repository_impl.dart';

import '../../../../helpers/fake_local_api_client.dart';

Map<String, dynamic> _restaurant(String id) => {
      'id': id,
      'name': 'Restaurant $id',
      'logo_url': '',
      'cover_url': '',
      'category_ids': <String>[],
      'rating': 4.2,
      'delivery_time_minutes': {'min': 20, 'max': 30},
      'delivery_fee': 1.5,
      'is_open': true,
      'tags': <String>[],
    };

Map<String, dynamic> _product(String id, {required String restaurantId}) => {
      'id': id,
      'restaurant_id': restaurantId,
      'name': 'Product $id',
      'description': '',
      'image_urls': <String>[],
      'base_price': 5.0,
      'discount_price': null,
      'is_available': true,
      'variation_groups': <Map<String, dynamic>>[],
      'extra_groups': <Map<String, dynamic>>[],
    };

void main() {
  late RestaurantRepositoryImpl repository;

  setUp(() {
    final storage = FakeLocalApiClient({
      'restaurants.json': [_restaurant('rest_1'), _restaurant('rest_2')],
      'products.json': [
        _product('prod_1', restaurantId: 'rest_1'),
        _product('prod_2', restaurantId: 'rest_1'),
        _product('prod_3', restaurantId: 'rest_2'),
      ],
    });

    repository = RestaurantRepositoryImpl(RestaurantLocalDataSource(storage));
  });

  group('RestaurantRepositoryImpl.getRestaurantById', () {
    test('returns the matching restaurant', () async {
      final result = await repository.getRestaurantById('rest_1');

      expect(result.valueOrNull?.id, 'rest_1');
    });

    test('returns NotFoundFailure for an unknown id', () async {
      final result = await repository.getRestaurantById('rest_none');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('RestaurantRepositoryImpl.getProductsByRestaurant', () {
    test('returns only products belonging to the given restaurant', () async {
      final result = await repository.getProductsByRestaurant('rest_1');

      final products = result.valueOrNull!;
      expect(products.map((p) => p.id), ['prod_1', 'prod_2']);
    });

    test('returns an empty list for a restaurant with no products', () async {
      final result = await repository.getProductsByRestaurant('rest_2_no_products');

      expect(result.valueOrNull, isEmpty);
    });
  });
}
