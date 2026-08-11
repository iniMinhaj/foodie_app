import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/entities/order.dart';
import 'package:foodie_app/features/checkout/data/datasources/local/checkout_local_datasource.dart';
import 'package:foodie_app/features/checkout/data/models/order_model.dart';

import '../../../../../helpers/fake_local_api_client.dart';

Order _fakeOrder() => Order(
      id: 'a1b2c3d4-0000-0000-0000-000000000000',
      userId: 'user_1',
      restaurantId: 'rest_1',
      restaurantName: 'Spice Garden',
      restaurantLogoUrl: '',
      orderNumber: 'ORD-A1B2C3D4',
      items: const [
        OrderItem(
          productId: 'prod_1',
          name: 'Chicken Biryani',
          quantity: 2,
          unitPrice: 9.25,
          lineTotal: 18.5,
          selectedOptionsSummary: 'Large',
        ),
      ],
      subtotal: 18.5,
      deliveryFee: 2.49,
      total: 20.99,
      status: OrderStatus.placed,
      placedAt: DateTime.utc(2026, 7, 22, 18, 2),
      statusTimeline: [
        OrderStatusEvent(status: OrderStatus.placed, timestamp: DateTime.utc(2026, 7, 22, 18, 2)),
      ],
      addressLabel: 'Home',
      paymentMethodLabel: 'Cash on Delivery',
    );

void main() {
  group('CheckoutLocalDataSource', () {
    test('placeOrder() appends the new order row, leaving existing rows untouched', () async {
      final storage = FakeLocalApiClient({
        'orders.json': [
          {'id': 'order_existing'},
        ],
      });
      final datasource = CheckoutLocalDataSource(storage);

      await datasource.placeOrder(OrderModel.fromEntity(_fakeOrder()));

      final rows = storage.peek('orders.json')!;
      expect(rows, hasLength(2));
      expect(rows.first['id'], 'order_existing');
      expect(rows.last['id'], 'a1b2c3d4-0000-0000-0000-000000000000');
      expect(rows.last['current_status'], 'placed');
    });
  });
}
