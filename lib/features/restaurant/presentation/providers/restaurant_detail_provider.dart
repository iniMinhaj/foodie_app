import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cache_box.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/network/failures.dart';
import 'restaurant_providers.dart';

final _productsByRestaurantCacheProvider =
    Provider<CacheBox<List<Product>>>((ref) => CacheBox());

/// Menu for a single restaurant, kept separate from the restaurant header
/// data — the header renders instantly from the `Restaurant` object passed
/// via navigation `extra` (see `RestaurantDetailScreen`), so it shouldn't
/// block on this fetch. `.autoDispose` means leaving the screen and coming
/// back re-runs this provider, which is what lets the internal [CacheBox]
/// TTL check actually matter: within the TTL it returns the cached list
/// with no repository call, past it it fetches fresh.
final productsByRestaurantProvider = FutureProvider.family.autoDispose<List<Product>, String>(
  (ref, restaurantId) async {
    final cache = ref.read(_productsByRestaurantCacheProvider);
    final cached = cache.read(restaurantId, AppConfig.cacheTtl);
    if (cached != null) return cached;

    final result =
        await ref.read(restaurantRepositoryProvider).getProductsByRestaurant(restaurantId);
    if (result.isErr) {
      throw result.failureOrNull as Failure;
    }
    final products = result.valueOrNull!;
    cache.write(restaurantId, products);
    return products;
  },
  // Deterministic on failure: a repository error should surface as
  // AsyncError immediately, not silently retry — same reasoning as
  // authNotifierProvider's retry override.
  retry: (retryCount, error) => null,
);
