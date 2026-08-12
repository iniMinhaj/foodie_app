import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/entities/address.dart';
import '../../../../core/entities/order.dart';
import '../../../../core/entities/payment_method.dart';
import '../../../../core/network/failures.dart';
import '../../../cart/presentation/providers/cart_notifier.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';
import '../../../restaurant/presentation/providers/restaurant_providers.dart';
import 'checkout_providers.dart';

const _uuid = Uuid();
const checkoutDeliveryFee = 1.99;
const checkoutPlatformFee = 0.5;

T? _defaultOrFirst<T>(List<T> items, bool Function(T) isDefault) {
  for (final item in items) {
    if (isDefault(item)) return item;
  }
  return items.isEmpty ? null : items.first;
}

String _orderNumber(String id) {
  final cleaned = id.replaceAll('-', '').toUpperCase();
  return 'ORD-${cleaned.length <= 8 ? cleaned : cleaned.substring(0, 8)}';
}

T? _byId<T>(List<T> items, String id, String Function(T) idOf) {
  for (final item in items) {
    if (idOf(item) == id) return item;
  }
  return null;
}

class CheckoutState extends Equatable {
  final String? selectedAddressId;
  final String? selectedPaymentMethodId;
  final bool isPlacingOrder;
  final String? errorMessage;
  final Order? placedOrder;

  const CheckoutState({
    this.selectedAddressId,
    this.selectedPaymentMethodId,
    this.isPlacingOrder = false,
    this.errorMessage,
    this.placedOrder,
  });

  CheckoutState copyWith({
    String? selectedAddressId,
    String? selectedPaymentMethodId,
    bool? isPlacingOrder,
    String? errorMessage,
    Order? placedOrder,
  }) =>
      CheckoutState(
        selectedAddressId: selectedAddressId ?? this.selectedAddressId,
        selectedPaymentMethodId: selectedPaymentMethodId ?? this.selectedPaymentMethodId,
        isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
        errorMessage: errorMessage,
        placedOrder: placedOrder ?? this.placedOrder,
      );

  @override
  List<Object?> get props =>
      [selectedAddressId, selectedPaymentMethodId, isPlacingOrder, errorMessage, placedOrder];
}

/// Selection state only — the address/payment-method *lists* live on
/// [profileNotifierProvider] and are read directly by the screen, never
/// duplicated here, so there's only one source of truth for them.
class CheckoutNotifier extends AsyncNotifier<CheckoutState> {
  @override
  Future<CheckoutState> build() async {
    // Read, not watch: Checkout only needs Profile's data once, to seed its
    // own selection — watching would reset an in-progress selection if the
    // user edits their profile elsewhere while this notifier stays alive.
    final profile = await ref.read(profileNotifierProvider.future);
    final address = _defaultOrFirst(profile.profile.addresses, (a) => a.isDefault);
    final paymentMethod = _defaultOrFirst(profile.profile.paymentMethods, (p) => p.isDefault);
    return CheckoutState(
      selectedAddressId: address?.id,
      selectedPaymentMethodId: paymentMethod?.id,
    );
  }

  Future<void> selectAddress(String addressId) async {
    final current = await future;
    state = AsyncData(current.copyWith(selectedAddressId: addressId));
  }

  Future<void> selectPaymentMethod(String paymentMethodId) async {
    final current = await future;
    state = AsyncData(current.copyWith(selectedPaymentMethodId: paymentMethodId));
  }

  Future<void> placeOrder() async {
    final current = await future;
    if (current.isPlacingOrder) return;

    final cart = await ref.read(cartNotifierProvider.future);
    if (cart.items.isEmpty) {
      state = AsyncData(current.copyWith(errorMessage: 'Your cart is empty.'));
      return;
    }
    if (current.selectedAddressId == null) {
      state = AsyncData(current.copyWith(errorMessage: 'Please select a delivery address.'));
      return;
    }
    if (current.selectedPaymentMethodId == null) {
      state = AsyncData(current.copyWith(errorMessage: 'Please select a payment method.'));
      return;
    }

    final profile = await ref.read(profileNotifierProvider.future);
    final Address? address = _byId(profile.profile.addresses, current.selectedAddressId!, (a) => a.id);
    final PaymentMethod? paymentMethod =
        _byId(profile.profile.paymentMethods, current.selectedPaymentMethodId!, (p) => p.id);
    if (address == null || paymentMethod == null) {
      // Built directly (not via copyWith) because copyWith's `??` fallback
      // can't express "clear this id to null" — only "leave it unchanged".
      state = AsyncData(CheckoutState(
        selectedAddressId: address?.id,
        selectedPaymentMethodId: paymentMethod?.id,
        errorMessage: 'Your selection is no longer available. Please choose again.',
      ));
      return;
    }

    state = AsyncData(current.copyWith(isPlacingOrder: true, errorMessage: null));

    final restaurantResult = await ref.read(restaurantRepositoryProvider).getRestaurantById(cart.restaurantId!);
    if (restaurantResult.isErr) {
      final failure = restaurantResult.failureOrNull as Failure;
      state = AsyncData(current.copyWith(isPlacingOrder: false, errorMessage: failure.userMessage));
      return;
    }
    final restaurant = restaurantResult.valueOrNull!;

    final id = _uuid.v4();
    final now = DateTime.now();
    final order = Order(
      id: id,
      userId: profile.profile.id,
      restaurantId: cart.restaurantId!,
      restaurantName: restaurant.name,
      restaurantLogoUrl: '',
      orderNumber: _orderNumber(id),
      items: [
        for (final item in cart.items)
          OrderItem(
            productId: item.productId,
            name: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            lineTotal: item.lineTotal,
            selectedOptionsSummary:
                [item.variationSummary, item.extrasSummary].where((s) => s.isNotEmpty).join(', '),
          ),
      ],
      subtotal: cart.subtotal,
      deliveryFee: checkoutDeliveryFee + checkoutPlatformFee,
      total: cart.subtotal + checkoutDeliveryFee + checkoutPlatformFee,
      status: OrderStatus.placed,
      placedAt: now,
      statusTimeline: [OrderStatusEvent(status: OrderStatus.placed, timestamp: now)],
      addressLabel: address.label,
      paymentMethodLabel: paymentMethod.label,
    );

    final result = await ref.read(checkoutRepositoryProvider).placeOrder(order);
    if (result.isErr) {
      final failure = result.failureOrNull as Failure;
      state = AsyncData(current.copyWith(isPlacingOrder: false, errorMessage: failure.userMessage));
      return;
    }

    await ref.read(cartNotifierProvider.notifier).clear();
    state = AsyncData(current.copyWith(isPlacingOrder: false, placedOrder: result.valueOrNull));
  }
}

final checkoutNotifierProvider = AsyncNotifierProvider<CheckoutNotifier, CheckoutState>(
  CheckoutNotifier.new,
  retry: (retryCount, error) => null,
);
