import 'package:foodie_app/core/entities/cart_item.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/cart/domain/repositories/cart_repository.dart';

/// Pure-Dart fake for cart notifier tests — no Riverpod, no Flutter, no
/// real storage. Each call is scripted via the `next*` fields.
class FakeCartRepository implements CartRepository {
  Result<Failure, List<CartItem>>? nextGetCartResult;
  Result<Failure, void>? nextSaveCartResult;

  int getCartCallCount = 0;
  int saveCartCallCount = 0;
  List<CartItem>? lastSavedItems;

  @override
  Future<Result<Failure, List<CartItem>>> getCart() async {
    getCartCallCount++;
    return nextGetCartResult ?? const Result.ok(<CartItem>[]);
  }

  @override
  Future<Result<Failure, void>> saveCart(List<CartItem> items) async {
    saveCartCallCount++;
    lastSavedItems = items;
    return nextSaveCartResult ?? const Result.ok(null);
  }
}

CartItem buildFakeCartItem({
  String id = 'citem_1',
  String productId = 'prod_1',
  String restaurantId = 'rest_1',
  String productName = 'Chicken Biryani',
  String productImageUrl = '',
  double unitBasePrice = 5.75,
  int quantity = 1,
  List<CartItemOption> selectedVariations = const [],
  List<CartItemOption> selectedExtras = const [],
  String? specialInstructions,
}) =>
    CartItem(
      id: id,
      productId: productId,
      restaurantId: restaurantId,
      productName: productName,
      productImageUrl: productImageUrl,
      unitBasePrice: unitBasePrice,
      quantity: quantity,
      selectedVariations: selectedVariations,
      selectedExtras: selectedExtras,
      specialInstructions: specialInstructions,
    );
