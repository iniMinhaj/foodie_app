import 'package:equatable/equatable.dart';

class CartItemOption extends Equatable {
  final String groupId;
  final List<String> choiceIds;

  const CartItemOption({required this.groupId, required this.choiceIds});

  @override
  List<Object?> get props => [groupId, choiceIds];
}

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String restaurantId;
  final int quantity;
  final List<CartItemOption> selectedOptions;
  final double unitPrice;

  const CartItem({
    required this.id,
    required this.productId,
    required this.restaurantId,
    required this.quantity,
    required this.selectedOptions,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  @override
  List<Object?> get props => [id, productId, restaurantId, quantity, selectedOptions, unitPrice];
}
