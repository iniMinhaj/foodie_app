import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// Copies the bundled `assets/mock/*.json` files into the app's
/// documents directory on first run, so [JsonStorageService] has a
/// mutable, per-install copy to read/write — the bundled assets
/// themselves are never touched.
class AssetSeeder {
  static const mockFileNames = [
    'categories.json',
    'restaurants.json',
    'products.json',
    'users.json',
    'orders.json',
    'cart_sample.json',
    'search_response.json',
    'error_responses.json',
  ];

  /// Idempotent by default — an existing file is left untouched so a
  /// user's writes (registration, placed orders, ...) survive across
  /// runs. Pass [force] to overwrite everything back to the bundled
  /// seed (used by Profile's "reset demo data").
  Future<void> seed({bool force = false}) async {
    final docs = await getApplicationDocumentsDirectory();
    final mockDir = Directory('${docs.path}/mock');
    if (!await mockDir.exists()) {
      await mockDir.create(recursive: true);
    }

    for (final fileName in mockFileNames) {
      final targetFile = File('${mockDir.path}/$fileName');
      if (!force && await targetFile.exists()) continue;
      final raw = await rootBundle.loadString('assets/mock/$fileName');
      await targetFile.writeAsString(raw);
    }
  }
}
