import '../../../../core/entities/product.dart';
import '../../../../core/entities/restaurant.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/network/simulated_latency.dart';
import '../../../../core/storage/local_api_client.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../datasources/local/restaurant_local_datasource.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantLocalDataSource local;

  const RestaurantRepositoryImpl(this.local);

  @override
  Future<Result<Failure, Restaurant>> getRestaurantById(String id) async {
    try {
      await simulateDelay();
      final restaurant = await local.getRestaurantById(id);
      if (restaurant == null) {
        return const Result.err(NotFoundFailure('Restaurant not found.'));
      }
      return Result.ok(restaurant.toEntity());
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Failure, List<Product>>> getProductsByRestaurant(String restaurantId) async {
    try {
      await simulateDelay();
      final products = await local.getProductsByRestaurant(restaurantId);
      return Result.ok(products.map((p) => p.toEntity()).toList());
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }
}
