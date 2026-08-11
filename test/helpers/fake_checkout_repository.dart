import 'package:foodie_app/core/entities/order.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/checkout/domain/repositories/checkout_repository.dart';

/// Pure-Dart fake for checkout notifier tests — no Riverpod, no Flutter,
/// no real storage. Each call is scripted via the `next*` fields.
class FakeCheckoutRepository implements CheckoutRepository {
  Result<Failure, Order>? nextPlaceOrderResult;

  int placeOrderCallCount = 0;
  Order? lastPlacedOrder;

  @override
  Future<Result<Failure, Order>> placeOrder(Order order) async {
    placeOrderCallCount++;
    lastPlacedOrder = order;
    return nextPlaceOrderResult ?? Result.ok(order);
  }
}
