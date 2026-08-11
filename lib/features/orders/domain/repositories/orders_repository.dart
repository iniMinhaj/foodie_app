import '../../../../core/entities/order.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';

abstract class OrdersRepository {
  Future<Result<Failure, List<Order>>> getOrders();
}
