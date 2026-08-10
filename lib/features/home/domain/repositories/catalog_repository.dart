import '../../../../core/entities/category.dart';
import '../../../../core/entities/restaurant.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';

/// A single page of a larger collection — shared by every module that
/// pages through data (Home's restaurant list, Search's results, ...).
class PaginatedResult<T> {
  final List<T> items;
  final bool hasMore;

  const PaginatedResult({required this.items, required this.hasMore});
}

/// Read-only catalog access. Defined once here (Home is the first module
/// to need it) and reused as-is by Search, Restaurant Detail, and Product
/// Detail once those modules are built — see docs/MIGRATION_STATUS.md.
abstract class CatalogRepository {
  Future<Result<Failure, List<Category>>> getCategories();

  Future<Result<Failure, PaginatedResult<Restaurant>>> getRestaurants({
    required int page,
    String? categoryId,
  });
}
