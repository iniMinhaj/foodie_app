import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/asset_seeder.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AssetSeeder().seed();
  final prefs = SharedPreferencesAsync();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FoodieApp(),
    ),
  );
}
