import 'package:foodie_app/core/entities/order.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/orders/domain/repositories/orders_repository.dart';

/// Pure-Dart fake for Orders provider tests — no Riverpod, no Flutter, no
/// real storage. Each call is scripted via the `next*` fields.
class FakeOrdersRepository implements OrdersRepository {
  Result<Failure, List<Order>>? nextGetOrdersResult;

  int getOrdersCallCount = 0;

  @override
  Future<Result<Failure, List<Order>>> getOrders() async {
    getOrdersCallCount++;
    return nextGetOrdersResult ?? const Result.ok(<Order>[]);
  }
}

Order buildFakeOrder({
  String id = 'order_1',
  String userId = '',
  String restaurantId = 'rest_1',
  String restaurantName = 'Spice Garden',
  String restaurantLogoUrl = '',
  String orderNumber = 'ORD-00000001',
  List<OrderItem> items = const [],
  double subtotal = 18.5,
  double deliveryFee = 2.49,
  double total = 20.99,
  OrderStatus status = OrderStatus.placed,
  DateTime? placedAt,
  List<OrderStatusEvent> statusTimeline = const [],
  String addressLabel = 'Home',
  String paymentMethodLabel = 'Cash on Delivery',
}) =>
    Order(
      id: id,
      userId: userId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantLogoUrl: restaurantLogoUrl,
      orderNumber: orderNumber,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      status: status,
      placedAt: placedAt ?? DateTime.utc(2026, 7, 22, 18, 2),
      statusTimeline: statusTimeline,
      addressLabel: addressLabel,
      paymentMethodLabel: paymentMethodLabel,
    );
