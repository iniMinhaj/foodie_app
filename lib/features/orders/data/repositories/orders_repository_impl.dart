import '../../../../core/entities/order.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/network/simulated_latency.dart';
import '../../../../core/storage/local_api_client.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/local/orders_local_datasource.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersLocalDataSource local;

  const OrdersRepositoryImpl(this.local);

  @override
  Future<Result<Failure, List<Order>>> getOrders() async {
    try {
      await simulateDelay();
      final orders = (await local.getOrders()).map((m) => m.order).toList()
        ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
      return Result.ok(orders);
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }
}
