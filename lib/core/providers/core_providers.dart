import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/asset_seeder.dart';
import '../storage/json_local_api_client.dart';
import '../storage/local_api_client.dart';

/// Overridden in `bootstrap.dart` with the real singleton instance.
final sharedPreferencesProvider = Provider<SharedPreferencesAsync>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in bootstrap.dart');
});

final localApiClientProvider = Provider<LocalApiClient>((ref) {
  return JsonLocalApiClient();
});

final assetSeederProvider = Provider<AssetSeeder>((ref) {
  return AssetSeeder();
});
