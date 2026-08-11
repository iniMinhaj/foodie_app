import '../../../../core/entities/order.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';

abstract class CheckoutRepository {
  Future<Result<Failure, Order>> placeOrder(Order order);
}
