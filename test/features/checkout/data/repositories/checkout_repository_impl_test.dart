import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/entities/order.dart';
import 'package:foodie_app/features/checkout/data/datasources/local/checkout_local_datasource.dart';
import 'package:foodie_app/features/checkout/data/repositories/checkout_repository_impl.dart';

import '../../../../helpers/fake_local_api_client.dart';

Order _fakeOrder() => Order(
      id: 'order_1',
      userId: 'user_1',
      restaurantId: 'rest_1',
      restaurantName: 'Spice Garden',
      restaurantLogoUrl: '',
      orderNumber: 'ORD-ORDER_1',
      items: const [],
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
  late CheckoutRepositoryImpl repository;
  late FakeLocalApiClient storage;

  setUp(() {
    storage = FakeLocalApiClient({'orders.json': []});
    repository = CheckoutRepositoryImpl(CheckoutLocalDataSource(storage));
  });

  group('CheckoutRepositoryImpl.placeOrder', () {
    test('persists the order and returns it back on success', () async {
      final order = _fakeOrder();

      final result = await repository.placeOrder(order);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, order);
      expect(storage.peek('orders.json'), hasLength(1));
      expect(storage.peek('orders.json')!.single['id'], 'order_1');
    });
  });
}
