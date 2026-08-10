import '../../../../core/entities/cart_item.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/network/simulated_latency.dart';
import '../../../../core/storage/local_api_client.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/local/cart_local_datasource.dart';
import '../models/cart_item_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartLocalDataSource local;

  const CartRepositoryImpl(this.local);

  @override
  Future<Result<Failure, List<CartItem>>> getCart() async {
    try {
      await simulateDelay();
      final items = await local.getItems();
      return Result.ok(items.map((m) => m.toEntity()).toList());
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Failure, void>> saveCart(List<CartItem> items) async {
    try {
      await simulateDelay();
      await local.saveItems(items.map(CartItemModel.fromEntity).toList());
      return const Result.ok(null);
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }
}
