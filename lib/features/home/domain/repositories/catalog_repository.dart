import 'package:equatable/equatable.dart';

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

/// A restaurant search hit — deliberately not the full [Restaurant] entity,
/// which the mock search response can't fully populate (no cuisine tags,
/// delivery fee, open state, ...). Tapping a result refetches the real
/// [Restaurant] by id instead of rendering this partial data as if it were
/// complete.
class SearchRestaurantResult extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final double rating;

  const SearchRestaurantResult({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.rating,
  });

  @override
  List<Object?> get props => [id, name, logoUrl, rating];
}

/// A product search hit — carries [restaurantName] directly since the
/// shared [Product] entity has no such field and search results need it
/// for display without a second lookup.
class SearchProductResult extends Equatable {
  final String id;
  final String name;
  final String restaurantId;
  final String restaurantName;
  final String imageUrl;
  final double basePrice;
  final double? discountPrice;

  const SearchProductResult({
    required this.id,
    required this.name,
    required this.restaurantId,
    required this.restaurantName,
    required this.imageUrl,
    required this.basePrice,
    required this.discountPrice,
  });

  double get effectivePrice => discountPrice ?? basePrice;

  @override
  List<Object?> get props => [id, name, restaurantId, restaurantName, imageUrl, basePrice, discountPrice];
}

class SearchResults {
  final List<SearchRestaurantResult> restaurants;
  final List<SearchProductResult> products;

  const SearchResults({required this.restaurants, required this.products});
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

  /// The mock backend has no real query filtering (always returns the same
  /// static batch) and never paginates search results, so this is a single
  /// combined read rather than a [PaginatedResult] — matches both the mock's
  /// actual shape and what the UI does with it.
  Future<Result<Failure, SearchResults>> search(String query);
}
