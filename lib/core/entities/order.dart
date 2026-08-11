import 'package:equatable/equatable.dart';

enum OrderStatus { placed, confirmed, preparing, outForDelivery, delivered, cancelled }

class OrderStatusEvent extends Equatable {
  final OrderStatus status;
  final DateTime timestamp;

  const OrderStatusEvent({required this.status, required this.timestamp});

  @override
  List<Object?> get props => [status, timestamp];
}

class OrderItem extends Equatable {
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String selectedOptionsSummary;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.selectedOptionsSummary,
  });

  @override
  List<Object?> get props => [productId, name, quantity, unitPrice, lineTotal, selectedOptionsSummary];
}

class Order extends Equatable {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String restaurantLogoUrl;
  final String orderNumber;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final DateTime placedAt;
  final List<OrderStatusEvent> statusTimeline;
  final String addressLabel;
  final String paymentMethodLabel;

  const Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantLogoUrl,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.placedAt,
    required this.statusTimeline,
    required this.addressLabel,
    required this.paymentMethodLabel,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        restaurantId,
        restaurantName,
        restaurantLogoUrl,
        orderNumber,
        items,
        subtotal,
        deliveryFee,
        total,
        status,
        placedAt,
        statusTimeline,
        addressLabel,
        paymentMethodLabel,
      ];
}
