import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/local/checkout_local_datasource.dart';
import '../../data/repositories/checkout_repository_impl.dart';
import '../../domain/repositories/checkout_repository.dart';

final checkoutLocalDataSourceProvider = Provider<CheckoutLocalDataSource>((ref) {
  return CheckoutLocalDataSource(ref.watch(localApiClientProvider));
});

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepositoryImpl(ref.watch(checkoutLocalDataSourceProvider));
});
