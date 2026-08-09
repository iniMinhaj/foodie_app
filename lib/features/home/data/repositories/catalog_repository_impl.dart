import '../../../../core/config/app_config.dart';
import '../../../../core/entities/category.dart';
import '../../../../core/entities/restaurant.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/network/simulated_latency.dart';
import '../../../../core/storage/local_api_client.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/local/catalog_local_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogLocalDataSource local;

  const CatalogRepositoryImpl(this.local);

  @override
  Future<Result<Failure, List<Category>>> getCategories() async {
    try {
      await simulateDelay();
      final categories = await local.getCategories();
      return Result.ok(categories.map((c) => c.toEntity()).toList());
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Failure, PaginatedResult<Restaurant>>> getRestaurants({
    required int page,
    String? categoryId,
  }) async {
    try {
      await simulateDelay();
      final all = (await local.getRestaurants()).map((r) => r.toEntity());
      final filtered = categoryId == null
          ? all.toList()
          : all.where((r) => r.categoryIds.contains(categoryId)).toList();

      final start = (page - 1) * AppConfig.pageSize;
      if (start >= filtered.length) {
        return const Result.ok(PaginatedResult(items: [], hasMore: false));
      }
      final end = (start + AppConfig.pageSize < filtered.length)
          ? start + AppConfig.pageSize
          : filtered.length;

      return Result.ok(PaginatedResult(
        items: filtered.sublist(start, end),
        hasMore: end < filtered.length,
      ));
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }
}
