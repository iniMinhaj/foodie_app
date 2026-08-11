import '../../../../core/entities/order.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/network/simulated_latency.dart';
import '../../../../core/storage/local_api_client.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/local/checkout_local_datasource.dart';
import '../models/order_model.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutLocalDataSource local;

  const CheckoutRepositoryImpl(this.local);

  @override
  Future<Result<Failure, Order>> placeOrder(Order order) async {
    try {
      await simulateDelay();
      await local.placeOrder(OrderModel.fromEntity(order));
      return Result.ok(order);
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }
}
