import 'product_model.dart';

/// A single selected option, kept lightweight (no back-reference to the
/// full OptionGroup) so it's cheap to store per cart line.
class SelectedOption {
  final String groupId;
  final String groupName;
  final String optionId;
  final String optionLabel;
  final double priceDelta;

  const SelectedOption({
    required this.groupId,
    required this.groupName,
    required this.optionId,
    required this.optionLabel,
    required this.priceDelta,
  });
}

/// Represents one configured cart line: a product + its chosen
/// variations/extras + quantity. Two cart entries of the same product with
/// different options are intentionally different CartItems (e.g. one
/// "Large/Hot" biryani and one "Regular/Mild" biryani are separate lines).
class CartItemModel {
  final String cartItemId;
  final ProductModel product;
  int quantity;
  final List<SelectedOption> selectedVariations;
  final List<SelectedOption> selectedExtras;
  final String? specialInstructions;

  CartItemModel({
    required this.cartItemId,
    required this.product,
    required this.quantity,
    required this.selectedVariations,
    required this.selectedExtras,
    this.specialInstructions,
  });

  /// Price of one unit including all selected variation/extra deltas.
  double get unitPrice {
    final variationTotal = selectedVariations.fold<double>(0, (sum, o) => sum + o.priceDelta);
    final extrasTotal = selectedExtras.fold<double>(0, (sum, o) => sum + o.priceDelta);
    return product.displayPrice + variationTotal + extrasTotal;
  }

  double get lineTotal => unitPrice * quantity;

  String get variationSummary =>
      selectedVariations.map((e) => e.optionLabel).join(', ');

  String get extrasSummary =>
      selectedExtras.isEmpty ? '' : selectedExtras.map((e) => e.optionLabel).join(', ');
}
