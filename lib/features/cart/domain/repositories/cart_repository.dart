import '../../../../core/entities/cart_item.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';

abstract class CartRepository {
  Future<Result<Failure, List<CartItem>>> getCart();

  Future<Result<Failure, void>> saveCart(List<CartItem> items);
}
