import 'package:foodie_app/core/entities/category.dart';
import 'package:foodie_app/core/entities/restaurant.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/home/domain/repositories/catalog_repository.dart';

Restaurant buildFakeRestaurant(
  String id, {
  List<String> categoryIds = const [],
  bool isOpen = true,
}) {
  return Restaurant(
    id: id,
    name: 'Restaurant $id',
    coverImageUrl: '',
    logoUrl: '',
    cuisineTags: const [],
    rating: 4.5,
    etaMinMinutes: 20,
    etaMaxMinutes: 30,
    deliveryFee: 1.5,
    isOpen: isOpen,
    categoryIds: categoryIds,
  );
}

/// Pure-Dart fake for notifier tests — no Riverpod, no Flutter, no real
/// storage. Each call is scripted via the `next*` fields.
class FakeCatalogRepository implements CatalogRepository {
  Result<Failure, List<Category>>? nextCategoriesResult;
  Result<Failure, PaginatedResult<Restaurant>>? nextRestaurantsResult;

  int getRestaurantsCallCount = 0;
  int? lastRequestedPage;
  String? lastRequestedCategoryId;

  @override
  Future<Result<Failure, List<Category>>> getCategories() async {
    return nextCategoriesResult ?? const Result.ok(<Category>[]);
  }

  @override
  Future<Result<Failure, PaginatedResult<Restaurant>>> getRestaurants({
    required int page,
    String? categoryId,
  }) async {
    getRestaurantsCallCount++;
    lastRequestedPage = page;
    lastRequestedCategoryId = categoryId;
    return nextRestaurantsResult ??
        const Result.ok(PaginatedResult(items: [], hasMore: false));
  }
}
