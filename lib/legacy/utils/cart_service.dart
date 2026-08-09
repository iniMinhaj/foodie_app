import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';

/// A plain ChangeNotifier singleton standing in for a real state manager.
/// It's the one place in this UI-only build where a "global store" was
/// unavoidable - Product Detail adds items, Cart screen reads/mutates them,
/// Home's bottom nav badge reads the count.
///
/// TODO: Riverpod - delete this class. Replace with
/// `CartNotifier extends Notifier<List<CartItemModel>>` and a
/// `cartProvider`. Every `CartService.instance.xxx()` call below becomes
/// `ref.read(cartProvider.notifier).xxx()`, and every `AnimatedBuilder`
/// listening to this becomes `ref.watch(cartProvider)`. The method bodies
/// (price math, add/remove logic) can be copy-pasted almost as-is.
class CartService extends ChangeNotifier {
  CartService._();
  static final instance = CartService._();

  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  void addItem(CartItemModel item) {
    _items.add(item);
    notifyListeners();
  }

  void updateQuantity(String cartItemId, int quantity) {
    final item = _items.firstWhere((e) => e.cartItemId == cartItemId);
    if (quantity <= 0) {
      _items.removeWhere((e) => e.cartItemId == cartItemId);
    } else {
      item.quantity = quantity;
    }
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((e) => e.cartItemId == cartItemId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
