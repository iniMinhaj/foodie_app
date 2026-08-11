import '../../../../../core/storage/local_api_client.dart';
import '../../models/order_model.dart';

/// Appends a newly placed order to `orders.json`'s `data` list — the only
/// write this module performs; nothing here ever reads existing rows back.
class CheckoutLocalDataSource {
  final LocalApiClient storage;
  static const _fileName = 'orders.json';

  const CheckoutLocalDataSource(this.storage);

  Future<void> placeOrder(OrderModel order) async {
    final rows = await storage.readCollection(_fileName);
    await storage.writeCollection(_fileName, [...rows, order.toJson()]);
  }
}
