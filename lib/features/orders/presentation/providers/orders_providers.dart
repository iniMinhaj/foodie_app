import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/local/orders_local_datasource.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/repositories/orders_repository.dart';

final ordersLocalDataSourceProvider = Provider<OrdersLocalDataSource>((ref) {
  return OrdersLocalDataSource(ref.watch(localApiClientProvider));
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(ref.watch(ordersLocalDataSourceProvider));
});

/// Not `.family` (no parameter needed) and not `.autoDispose` — Orders is
/// a persistent bottom-nav tab like Cart/Profile, not a pushed/popped
/// per-id screen like Restaurant Detail.
final ordersProvider = FutureProvider<List<Order>>(
  (ref) async {
    final result = await ref.read(ordersRepositoryProvider).getOrders();
    if (result.isErr) {
      throw result.failureOrNull as Failure;
    }
    return result.valueOrNull!;
  },
  // Deterministic on failure, same reasoning as productsByRestaurantProvider.
  retry: (retryCount, error) => null,
);
