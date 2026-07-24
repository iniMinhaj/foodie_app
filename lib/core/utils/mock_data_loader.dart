import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Simulates a remote datasource by reading local JSON assets with an
/// artificial delay, so loading/shimmer states are actually visible.
///
/// TODO: Riverpod - this is the exact seam to replace. Wrap each method
/// below in a Repository interface + Impl, inject via Provider, and swap
/// this class's body for a Dio call (`_dio.get('/products')`) later. Every
/// screen in this app calls through here, never `rootBundle` directly - so
/// only this file changes when a real API is ready.
class MockDataLoader {
  MockDataLoader._();
  static final instance = MockDataLoader._();

  Future<Map<String, dynamic>> _loadJson(String assetPath) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCategories() => _loadJson('assets/mock/categories.json');

  Future<Map<String, dynamic>> getRestaurants() => _loadJson('assets/mock/restaurants.json');

  Future<Map<String, dynamic>> getProducts() => _loadJson('assets/mock/products.json');

  Future<Map<String, dynamic>> getOrders() => _loadJson('assets/mock/orders.json');

  Future<Map<String, dynamic>> getUserProfile() => _loadJson('assets/mock/user_profile.json');

  Future<Map<String, dynamic>> search(String query) async {
    // Real backend would filter server-side; we simulate the same response
    // shape regardless of query so the UI has something to render.
    await Future.delayed(const Duration(milliseconds: 400));
    final raw = await rootBundle.loadString('assets/mock/search_response.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
