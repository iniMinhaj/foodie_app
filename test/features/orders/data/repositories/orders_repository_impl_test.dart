import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/features/orders/data/datasources/local/orders_local_datasource.dart';
import 'package:foodie_app/features/orders/data/repositories/orders_repository_impl.dart';

import '../../../../helpers/fake_local_api_client.dart';

Map<String, dynamic> _orderJson(String id, String placedAt) => {
      'id': id,
      'order_number': 'ORD-$id',
      'restaurant': {'id': 'rest_001', 'name': 'Spice Garden', 'logo_url': ''},
      'items': <Map<String, dynamic>>[],
      'pricing_summary': {'subtotal': 10.0, 'delivery_fee': 2.0, 'grand_total': 12.0},
      'payment_method': 'cash_on_delivery',
      'current_status': 'placed',
      'status_timeline': [
        {'status': 'placed', 'timestamp': placedAt},
      ],
      'delivery_address': {'label': 'Home'},
      'placed_at': placedAt,
    };

void main() {
  group('OrdersRepositoryImpl.getOrders', () {
    test('returns orders sorted by placedAt descending, newest first', () async {
      final storage = FakeLocalApiClient({
        'orders.json': [
          _orderJson('order_old', '2026-07-22T18:02:00Z'),
          _orderJson('order_new', '2026-07-24T09:00:00Z'),
          _orderJson('order_mid', '2026-07-23T20:10:00Z'),
        ],
      });
      final repository = OrdersRepositoryImpl(OrdersLocalDataSource(storage));

      final result = await repository.getOrders();

      final orders = result.valueOrNull!;
      expect(orders.map((o) => o.id), ['order_new', 'order_mid', 'order_old']);
    });
  });
}
