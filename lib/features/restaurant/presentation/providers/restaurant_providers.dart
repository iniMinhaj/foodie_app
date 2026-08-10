import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/local/restaurant_local_datasource.dart';
import '../../data/repositories/restaurant_repository_impl.dart';
import '../../domain/repositories/restaurant_repository.dart';

final restaurantLocalDataSourceProvider = Provider<RestaurantLocalDataSource>((ref) {
  return RestaurantLocalDataSource(ref.watch(localApiClientProvider));
});

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepositoryImpl(ref.watch(restaurantLocalDataSourceProvider));
});
