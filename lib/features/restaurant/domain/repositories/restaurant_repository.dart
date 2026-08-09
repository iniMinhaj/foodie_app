import '../../../../core/entities/product.dart';
import '../../../../core/entities/restaurant.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';

/// Read-only access to a single restaurant's detail data. Kept separate
/// from `home`'s `CatalogRepository` (which only ever needs the paginated
/// restaurant *list*) so the Restaurant Detail module owns its own
/// domain/data layers per Clean Architecture, instead of reaching into
/// another feature's repository.
abstract class RestaurantRepository {
  Future<Result<Failure, Restaurant>> getRestaurantById(String id);

  Future<Result<Failure, List<Product>>> getProductsByRestaurant(String restaurantId);
}
