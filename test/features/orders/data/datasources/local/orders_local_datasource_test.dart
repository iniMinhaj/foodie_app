import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/entities/order.dart';
import 'package:foodie_app/features/orders/data/datasources/local/orders_local_datasource.dart';

import '../../../../../helpers/fake_local_api_client.dart';

Map<String, dynamic> _orderJson({
  String id = 'order_9001',
  String currentStatus = 'delivered',
}) =>
    {
      'id': id,
      'order_number': 'ORD-20260722-9001',
      'restaurant': {'id': 'rest_001', 'name': 'Spice Garden', 'logo_url': 'logo.jpg'},
      'items': [
        {
          'product_name': 'Chicken Biryani',
          'quantity': 2,
          'unit_final_price': 9.25,
          'line_total': 18.5,
          'variation_summary': 'Large, Hot',
          'extras_summary': 'Boiled Egg',
        },
      ],
      'pricing_summary': {
        'subtotal': 18.5,
        'delivery_fee': 1.99,
        'discount_amount': 0.0,
        'tax': 0.92,
        'grand_total': 21.41,
        'currency': 'USD',
      },
      'payment_method': 'cash_on_delivery',
      'current_status': currentStatus,
      'status_timeline': [
        {'status': 'placed', 'timestamp': '2026-07-22T18:02:00Z'},
        {'status': 'confirmed', 'timestamp': '2026-07-22T18:04:12Z'},
      ],
      'delivery_address': {'label': 'Home', 'line1': 'House 22', 'city': 'Dhaka'},
      'placed_at': '2026-07-22T18:02:00Z',
    };

void main() {
  group('OrdersLocalDataSource', () {
    test('getOrders() parses every row into an OrderModel', () async {
      final storage = FakeLocalApiClient({
        'orders.json': [_orderJson()],
      });
      final datasource = OrdersLocalDataSource(storage);

      final orders = await datasource.getOrders();

      expect(orders, hasLength(1));
      final order = orders.single.order;
      expect(order.id, 'order_9001');
      expect(order.orderNumber, 'ORD-20260722-9001');
      expect(order.restaurantName, 'Spice Garden');
      expect(order.status, OrderStatus.delivered);
      expect(order.items.single.name, 'Chicken Biryani');
      expect(order.items.single.selectedOptionsSummary, 'Large, Hot, Boiled Egg');
      expect(order.statusTimeline, hasLength(2));
      expect(order.statusTimeline.first.status, OrderStatus.placed);
      expect(order.addressLabel, 'Home');
    });

    test('parses the out_for_delivery and confirmed statuses correctly', () async {
      final storage = FakeLocalApiClient({
        'orders.json': [_orderJson(id: 'order_9002', currentStatus: 'out_for_delivery')],
      });
      final datasource = OrdersLocalDataSource(storage);

      final orders = await datasource.getOrders();

      expect(orders.single.order.status, OrderStatus.outForDelivery);
    });
  });
}
