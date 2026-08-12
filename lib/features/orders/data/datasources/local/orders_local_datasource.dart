import '../../../../../core/storage/local_api_client.dart';
import '../../models/order_model.dart';

/// Reads `orders.json` via [LocalApiClient] — the same seeded, writable
/// file `CheckoutLocalDataSource` appends new orders to, unlike the legacy
/// `MockDataLoader.getOrders()` which read the read-only bundled asset
/// directly and never saw Checkout-placed orders.
class OrdersLocalDataSource {
  final LocalApiClient storage;
  static const _fileName = 'orders.json';

  const OrdersLocalDataSource(this.storage);

  Future<List<OrderModel>> getOrders() async {
    final raw = await storage.readCollection(_fileName);
    return raw.map(OrderModel.fromJson).toList();
  }
}
