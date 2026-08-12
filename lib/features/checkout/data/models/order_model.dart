import '../../../../core/entities/order.dart';

/// Write-only — converts a placed [Order] into the `orders.json` row shape.
/// Nothing in this module reads orders back (that's the Orders module's
/// own separate `OrderModel`, in `lib/features/orders/data/models/`), so
/// there's no `fromJson`/`toEntity` here.
class OrderModel {
  final Order order;

  const OrderModel(this.order);

  factory OrderModel.fromEntity(Order order) => OrderModel(order);

  Map<String, dynamic> toJson() => {
        'id': order.id,
        'order_number': order.orderNumber,
        'restaurant': {
          'id': order.restaurantId,
          'name': order.restaurantName,
          'logo_url': order.restaurantLogoUrl,
        },
        'items': [
          for (final item in order.items)
            {
              'product_name': item.name,
              'quantity': item.quantity,
              'unit_final_price': item.unitPrice,
              'line_total': item.lineTotal,
              'variation_summary': item.selectedOptionsSummary,
              'extras_summary': '',
            },
        ],
        'pricing_summary': {
          'subtotal': order.subtotal,
          'delivery_fee': order.deliveryFee,
          'discount_amount': 0.0,
          'tax': 0.0,
          'grand_total': order.total,
          'currency': 'USD',
        },
        'payment_method': order.paymentMethodLabel,
        'current_status': order.status.name,
        'status_timeline': [
          for (final event in order.statusTimeline)
            {'status': event.status.name, 'timestamp': event.timestamp.toIso8601String()},
        ],
        'delivery_address': {'label': order.addressLabel},
        'placed_at': order.placedAt.toIso8601String(),
      };
}
