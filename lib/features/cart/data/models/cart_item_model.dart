import '../../../../core/entities/cart_item.dart';

class CartOptionModel {
  final String groupId;
  final String groupName;
  final String choiceId;
  final String choiceLabel;
  final double priceDelta;

  const CartOptionModel({
    required this.groupId,
    required this.groupName,
    required this.choiceId,
    required this.choiceLabel,
    required this.priceDelta,
  });

  CartItemOption toEntity() => CartItemOption(
        groupId: groupId,
        groupName: groupName,
        choiceId: choiceId,
        choiceLabel: choiceLabel,
        priceDelta: priceDelta,
      );

  factory CartOptionModel.fromEntity(CartItemOption option) => CartOptionModel(
        groupId: option.groupId,
        groupName: option.groupName,
        choiceId: option.choiceId,
        choiceLabel: option.choiceLabel,
        priceDelta: option.priceDelta,
      );

  factory CartOptionModel.fromJson(Map<String, dynamic> json) => CartOptionModel(
        groupId: json['group_id'] as String,
        groupName: json['group_name'] as String? ?? '',
        choiceId: json['option_id'] as String,
        choiceLabel: json['option_label'] as String? ?? '',
        priceDelta: (json['price_delta'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'group_id': groupId,
        'group_name': groupName,
        'option_id': choiceId,
        'option_label': choiceLabel,
        'price_delta': priceDelta,
      };
}

class CartItemModel {
  final String id;
  final String productId;
  final String restaurantId;
  final String productName;
  final String productImageUrl;
  final double unitBasePrice;
  final int quantity;
  final List<CartOptionModel> selectedVariations;
  final List<CartOptionModel> selectedExtras;
  final String? specialInstructions;

  const CartItemModel({
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

  CartItem toEntity() => CartItem(
        id: id,
        productId: productId,
        restaurantId: restaurantId,
        productName: productName,
        productImageUrl: productImageUrl,
        unitBasePrice: unitBasePrice,
        quantity: quantity,
        selectedVariations: selectedVariations.map((o) => o.toEntity()).toList(),
        selectedExtras: selectedExtras.map((o) => o.toEntity()).toList(),
        specialInstructions: specialInstructions,
      );

  factory CartItemModel.fromEntity(CartItem item) => CartItemModel(
        id: item.id,
        productId: item.productId,
        restaurantId: item.restaurantId,
        productName: item.productName,
        productImageUrl: item.productImageUrl,
        unitBasePrice: item.unitBasePrice,
        quantity: item.quantity,
        selectedVariations: item.selectedVariations.map(CartOptionModel.fromEntity).toList(),
        selectedExtras: item.selectedExtras.map(CartOptionModel.fromEntity).toList(),
        specialInstructions: item.specialInstructions,
      );

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        id: json['cart_item_id'] as String,
        productId: json['product_id'] as String,
        restaurantId: json['restaurant_id'] as String? ?? '',
        productName: json['product_name'] as String? ?? '',
        productImageUrl: json['product_image'] as String? ?? '',
        unitBasePrice: (json['unit_base_price'] as num?)?.toDouble() ?? 0,
        quantity: json['quantity'] as int? ?? 1,
        selectedVariations: (json['selected_variations'] as List<dynamic>? ?? const [])
            .map((e) => CartOptionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        selectedExtras: (json['selected_extras'] as List<dynamic>? ?? const [])
            .map((e) => CartOptionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        specialInstructions: json['special_instructions'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'cart_item_id': id,
        'product_id': productId,
        'restaurant_id': restaurantId,
        'product_name': productName,
        'product_image': productImageUrl,
        'quantity': quantity,
        'unit_base_price': unitBasePrice,
        'selected_variations': selectedVariations.map((o) => o.toJson()).toList(),
        'selected_extras': selectedExtras.map((o) => o.toJson()).toList(),
        'special_instructions': specialInstructions,
        'unit_final_price': toEntity().unitPrice,
        'line_total': toEntity().lineTotal,
      };
}
