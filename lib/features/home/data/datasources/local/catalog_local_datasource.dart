import '../../../../../core/storage/local_api_client.dart';
import '../../models/category_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/search_result_model.dart';

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

  /// `search_response.json`'s `data` is an object (not a list), so
  /// [LocalApiClient.readCollection] wraps it as a single-element list —
  /// `.first` is that whole `{restaurants,products,...}` object. [query]
  /// is accepted for interface honesty but unused: the mock backend
  /// returns the same static batch regardless of query.
  Future<({List<SearchRestaurantModel> restaurants, List<SearchProductModel> products})> search(
    String query,
  ) async {
    final raw = (await storage.readCollection('search_response.json')).first;
    final restaurants = (raw['restaurants'] as List<dynamic>? ?? const [])
        .map((e) => SearchRestaurantModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final products = (raw['products'] as List<dynamic>? ?? const [])
        .map((e) => SearchProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (restaurants: restaurants, products: products);
  }
}
