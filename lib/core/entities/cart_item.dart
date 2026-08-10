import 'package:equatable/equatable.dart';

/// One selected choice within a product's variation/extra group, captured
/// at add-to-cart time — label and price are a snapshot, not a live
/// lookup, so a cart line still renders correctly even if the underlying
/// product/menu data changes or isn't loaded.
class CartItemOption extends Equatable {
  final String groupId;
  final String groupName;
  final String choiceId;
  final String choiceLabel;
  final double priceDelta;

  const CartItemOption({
    required this.groupId,
    required this.groupName,
    required this.choiceId,
    required this.choiceLabel,
    required this.priceDelta,
  });

  @override
  List<Object?> get props => [groupId, groupName, choiceId, choiceLabel, priceDelta];
}

/// One configured cart line: a product + its chosen variations/extras +
/// quantity, denormalized so the Cart screen never has to re-fetch product
/// data to render. Two lines for the same product with different options
/// are intentionally separate entries.
class CartItem extends Equatable {
  final String id;
  final String productId;
  final String restaurantId;
  final String productName;
  final String productImageUrl;
  final double unitBasePrice;
  final int quantity;
  final List<CartItemOption> selectedVariations;
  final List<CartItemOption> selectedExtras;
  final String? specialInstructions;

  const CartItem({
    required this.id,
    required this.productId,
    required this.restaurantId,
    required this.productName,
    required this.productImageUrl,
    required this.unitBasePrice,
    required this.quantity,
    required this.selectedVariations,
    required this.selectedExtras,
    this.specialInstructions,
  });

  /// Price of one unit including all selected variation/extra deltas.
  double get unitPrice {
    final variationTotal = selectedVariations.fold<double>(0, (sum, o) => sum + o.priceDelta);
    final extrasTotal = selectedExtras.fold<double>(0, (sum, o) => sum + o.priceDelta);
    return unitBasePrice + variationTotal + extrasTotal;
  }

  double get lineTotal => unitPrice * quantity;

  String get variationSummary => selectedVariations.map((o) => o.choiceLabel).join(', ');

  String get extrasSummary => selectedExtras.map((o) => o.choiceLabel).join(', ');

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        productId: productId,
        restaurantId: restaurantId,
        productName: productName,
        productImageUrl: productImageUrl,
        unitBasePrice: unitBasePrice,
        quantity: quantity ?? this.quantity,
        selectedVariations: selectedVariations,
        selectedExtras: selectedExtras,
        specialInstructions: specialInstructions,
      );

  @override
  List<Object?> get props => [
        id,
        productId,
        restaurantId,
        productName,
        productImageUrl,
        unitBasePrice,
        quantity,
        selectedVariations,
        selectedExtras,
        specialInstructions,
      ];
}
