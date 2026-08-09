import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/local/catalog_local_datasource.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/repositories/catalog_repository.dart';

final catalogLocalDataSourceProvider = Provider<CatalogLocalDataSource>((ref) {
  return CatalogLocalDataSource(ref.watch(localApiClientProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(ref.watch(catalogLocalDataSourceProvider));
});
