import '../../../../core/entities/order.dart';

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

OrderItem _itemFromJson(Map<String, dynamic> json) => OrderItem(
      productId: json['product_id'] as String? ?? '',
      name: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_final_price'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num).toDouble(),
      selectedOptionsSummary: [
        json['variation_summary'] as String? ?? '',
        json['extras_summary'] as String? ?? '',
      ].where((s) => s.isNotEmpty).join(', '),
    );

OrderStatusEvent _statusEventFromJson(Map<String, dynamic> json) => OrderStatusEvent(
      status: _parseStatus(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

/// Read-only — parses `orders.json` rows (both bundled seed data and rows
/// Checkout has appended) into the shared [Order] entity. Distinct from
/// Checkout's write-only `OrderModel` (a different file/class, never
/// imported together).
class OrderModel {
  final Order order;

  const OrderModel(this.order);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurant'] as Map<String, dynamic>;
    final pricing = json['pricing_summary'] as Map<String, dynamic>;
    return OrderModel(
      Order(
        id: json['id'] as String,
        userId: '',
        restaurantId: restaurant['id'] as String? ?? '',
        restaurantName: restaurant['name'] as String,
        restaurantLogoUrl: restaurant['logo_url'] as String? ?? '',
        orderNumber: json['order_number'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => _itemFromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (pricing['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (pricing['delivery_fee'] as num?)?.toDouble() ?? 0,
        total: (pricing['grand_total'] as num).toDouble(),
        status: _parseStatus(json['current_status'] as String),
        placedAt: DateTime.parse(json['placed_at'] as String),
        statusTimeline: (json['status_timeline'] as List<dynamic>? ?? const [])
            .map((e) => _statusEventFromJson(e as Map<String, dynamic>))
            .toList(),
        addressLabel: (json['delivery_address'] as Map<String, dynamic>?)?['label'] as String? ?? '',
        paymentMethodLabel: json['payment_method'] as String? ?? '',
      ),
    );
  }
}
