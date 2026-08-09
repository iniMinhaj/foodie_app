import '../../../../../core/storage/local_api_client.dart';
import '../../models/category_model.dart';
import '../../models/restaurant_model.dart';

class CatalogLocalDataSource {
  final LocalApiClient storage;

  const CatalogLocalDataSource(this.storage);

  Future<List<CategoryModel>> getCategories() async {
    final raw = await storage.readCollection('categories.json');
    return raw.map(CategoryModel.fromJson).toList();
  }

  Future<List<RestaurantModel>> getRestaurants() async {
    final raw = await storage.readCollection('restaurants.json');
    return raw.map(RestaurantModel.fromJson).toList();
  }
}
