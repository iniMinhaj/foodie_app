import '../../../../../core/storage/local_api_client.dart';
import '../../models/cart_item_model.dart';

/// Reads/writes `cart_sample.json`, whose `data` is a single cart object
/// (not a list) — [LocalApiClient.readCollection] already normalizes a
/// `Map` `data` into a 1-element list, and writing back a 1-element list
/// round-trips the same way, so this only ever deals with that one entry.
class CartLocalDataSource {
  final LocalApiClient storage;
  static const _fileName = 'cart_sample.json';

  const CartLocalDataSource(this.storage);

  Future<List<CartItemModel>> getItems() async {
    final raw = await storage.readCollection(_fileName);
    if (raw.isEmpty) return [];
    final items = raw.first['items'] as List<dynamic>? ?? const [];
    return items.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Rewrites only the `items` key on the cart object, leaving
  /// `cart_id`/`pricing_summary`/`updated_at` untouched so this module
  /// doesn't silently drop fields it doesn't itself model.
  Future<void> saveItems(List<CartItemModel> items) async {
    final raw = await storage.readCollection(_fileName);
    final cart = raw.isNotEmpty ? Map<String, dynamic>.from(raw.first) : <String, dynamic>{};
    cart['items'] = items.map((e) => e.toJson()).toList();
    await storage.writeCollection(_fileName, [cart]);
  }
}
