enum OrderStatus { placed, confirmed, preparing, outForDelivery, delivered, cancelled }

OrderStatus _parseStatus(String raw) {
  switch (raw) {
    case 'placed':
      return OrderStatus.placed;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
      return OrderStatus.preparing;
    case 'out_for_delivery':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.placed;
  }
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderStatusEvent {
  final OrderStatus status;
  final DateTime timestamp;

  const OrderStatusEvent({required this.status, required this.timestamp});

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      status: _parseStatus(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class OrderItemSummary {
  final String productName;
  final int quantity;
  final double lineTotal;
  final String variationSummary;
  final String extrasSummary;

  const OrderItemSummary({
    required this.productName,
    required this.quantity,
    required this.lineTotal,
    required this.variationSummary,
    required this.extrasSummary,
  });

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    return OrderItemSummary(
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      lineTotal: (json['line_total'] as num).toDouble(),
      variationSummary: json['variation_summary'] as String? ?? '',
      extrasSummary: json['extras_summary'] as String? ?? '',
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String restaurantName;
  final String restaurantLogoUrl;
  final List<OrderItemSummary> items;
  final double grandTotal;
  final OrderStatus currentStatus;
  final List<OrderStatusEvent> statusTimeline;
  final DateTime placedAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.restaurantName,
    required this.restaurantLogoUrl,
    required this.items,
    required this.grandTotal,
    required this.currentStatus,
    required this.statusTimeline,
    required this.placedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurant'] as Map<String, dynamic>;
    final pricing = json['pricing_summary'] as Map<String, dynamic>;
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      restaurantName: restaurant['name'] as String,
      restaurantLogoUrl: restaurant['logo_url'] as String? ?? '',
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItemSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      grandTotal: (pricing['grand_total'] as num).toDouble(),
      currentStatus: _parseStatus(json['current_status'] as String),
      statusTimeline: (json['status_timeline'] as List<dynamic>)
          .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      placedAt: DateTime.parse(json['placed_at'] as String),
    );
  }
}
