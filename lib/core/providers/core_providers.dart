import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/asset_seeder.dart';
import '../storage/json_storage_service.dart';

/// Overridden in `bootstrap.dart` with the real singleton instance.
final sharedPreferencesProvider = Provider<SharedPreferencesAsync>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in bootstrap.dart');
});

final jsonStorageServiceProvider = Provider<JsonStorageService>((ref) {
  return JsonStorageService();
});

final assetSeederProvider = Provider<AssetSeeder>((ref) {
  return AssetSeeder();
});
