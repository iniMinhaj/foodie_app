import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/local/cart_local_datasource.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/repositories/cart_repository.dart';

final cartLocalDataSourceProvider = Provider<CartLocalDataSource>((ref) {
  return CartLocalDataSource(ref.watch(localApiClientProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(ref.watch(cartLocalDataSourceProvider));
});
