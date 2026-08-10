import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entities/cart_item.dart';
import '../../../../core/network/failures.dart';
import 'cart_providers.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final String? errorMessage;

  const CartState({required this.items, this.errorMessage});

  factory CartState.initial() => const CartState(items: []);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// The one restaurant every line currently belongs to, or `null` if the
  /// cart is empty — the single-restaurant rule is enforced against this.
  String? get restaurantId => items.isEmpty ? null : items.first.restaurantId;

  CartState copyWith({List<CartItem>? items, String? errorMessage}) => CartState(
        items: items ?? this.items,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [items, errorMessage];
}

/// Loads the persisted cart exactly once, then keeps every mutation
/// optimistic-then-persisted. `AsyncNotifier` (not the plain `Notifier`
/// `RestaurantListNotifier` uses) on purpose: an add-to-cart tap can land
/// before the user ever opens the Cart tab, so every mutation method
/// starts by awaiting [future] — this is the same "await the initial
/// async load before acting" shape `AuthNotifier` uses for session
/// restore, not `RestaurantListNotifier`'s "widget explicitly triggers
/// the fetch" shape.
class CartNotifier extends AsyncNotifier<CartState> {
  @override
  Future<CartState> build() async {
    final result = await ref.read(cartRepositoryProvider).getCart();
    return result.fold(
      (failure) => CartState(items: const [], errorMessage: failure.userMessage),
      (items) => CartState(items: items),
    );
  }

  Future<void> addItem(CartItem item) async {
    final current = await future;
    await _applyAndPersist(current, current.copyWith(items: [...current.items, item]));
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final current = await future;
    final next = quantity <= 0
        ? current.items.where((i) => i.id != cartItemId).toList()
        : [for (final i in current.items) if (i.id == cartItemId) i.copyWith(quantity: quantity) else i];
    await _applyAndPersist(current, current.copyWith(items: next));
  }

  Future<void> removeItem(String cartItemId) async {
    final current = await future;
    final next = current.items.where((i) => i.id != cartItemId).toList();
    await _applyAndPersist(current, current.copyWith(items: next));
  }

  Future<void> clear() async {
    final current = await future;
    await _applyAndPersist(current, current.copyWith(items: const []));
  }

  Future<void> _applyAndPersist(CartState previous, CartState next) async {
    state = AsyncData(next);
    final result = await ref.read(cartRepositoryProvider).saveCart(next.items);
    if (result.isErr) {
      final failure = result.failureOrNull as Failure;
      state = AsyncData(previous.copyWith(errorMessage: failure.userMessage));
    }
  }
}

final cartNotifierProvider = AsyncNotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
  // Deterministic on failure, same reasoning as authNotifierProvider.
  retry: (retryCount, error) => null,
);
