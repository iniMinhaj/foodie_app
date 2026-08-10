import '../../../../../core/storage/local_api_client.dart';
import '../../../../home/data/models/restaurant_model.dart';
import '../../models/product_model.dart';

/// Reads the same `restaurants.json`/`products.json` files `home`'s
/// `CatalogLocalDataSource` reads, but for single-restaurant lookups
/// rather than the paginated list — kept as its own datasource so the
/// Restaurant Detail module owns its data layer instead of depending on
/// `home`'s. [RestaurantModel] is reused as-is (identical JSON shape,
/// no reason to re-declare the same mapping twice).
class RestaurantLocalDataSource {
  final LocalApiClient storage;

  const RestaurantLocalDataSource(this.storage);

  Future<RestaurantModel?> getRestaurantById(String id) async {
    final raw = await storage.readCollection('restaurants.json');
    for (final json in raw) {
      if (json['id'] == id) return RestaurantModel.fromJson(json);
    }
    return null;
  }

  Future<List<ProductModel>> getProductsByRestaurant(String restaurantId) async {
    final raw = await storage.readCollection('products.json');
    return raw
        .map(ProductModel.fromJson)
        .where((product) => product.restaurantId == restaurantId)
        .toList();
  }
}
