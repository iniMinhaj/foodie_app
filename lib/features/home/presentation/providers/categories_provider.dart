import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entities/category.dart';
import 'catalog_providers.dart';

/// A plain repository read with no coordination/validation logic to
/// isolate — no usecase needed, per the project's usecase convention.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final result = await ref.read(catalogRepositoryProvider).getCategories();
  return result.fold((failure) => throw failure, (categories) => categories);
});
