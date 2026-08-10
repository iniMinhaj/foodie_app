import 'package:foodie_app/core/entities/product.dart';
import 'package:foodie_app/core/entities/restaurant.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/restaurant/domain/repositories/restaurant_repository.dart';

import 'fake_catalog_repository.dart' show buildFakeRestaurant;

/// Pure-Dart fake for restaurant-detail provider/notifier tests — no
/// Riverpod, no Flutter, no real storage. Each call is scripted via the
/// `next*` fields.
class FakeRestaurantRepository implements RestaurantRepository {
  Result<Failure, Restaurant>? nextRestaurantByIdResult;
  Result<Failure, List<Product>>? nextProductsByRestaurantResult;

  int getRestaurantByIdCallCount = 0;
  int getProductsByRestaurantCallCount = 0;

  @override
  Future<Result<Failure, Restaurant>> getRestaurantById(String id) async {
    getRestaurantByIdCallCount++;
    return nextRestaurantByIdResult ?? Result.ok(buildFakeRestaurant(id));
  }

  @override
  Future<Result<Failure, List<Product>>> getProductsByRestaurant(String restaurantId) async {
    getProductsByRestaurantCallCount++;
    return nextProductsByRestaurantResult ?? const Result.ok(<Product>[]);
  }
}
