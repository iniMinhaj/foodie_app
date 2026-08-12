import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/entities/address.dart';
import 'package:foodie_app/core/entities/payment_method.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/auth/domain/entities/user_profile.dart';
import 'package:foodie_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:foodie_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:foodie_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:foodie_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:foodie_app/features/checkout/presentation/providers/checkout_notifier.dart';
import 'package:foodie_app/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:foodie_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:foodie_app/features/restaurant/presentation/providers/restaurant_providers.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_cart_repository.dart';
import '../../../../helpers/fake_checkout_repository.dart';
import '../../../../helpers/fake_profile_repository.dart';
import '../../../../helpers/fake_restaurant_repository.dart';

const _addrHome = Address(id: 'addr_1', label: 'Home', line1: 'House 1', city: 'Dhaka', isDefault: true);
const _addrOffice = Address(id: 'addr_2', label: 'Office', line1: 'Level 6', city: 'Dhaka', isDefault: false);
const _paymentCod =
    PaymentMethod(id: 'pm_1', type: PaymentMethodType.cod, label: 'Cash on Delivery', isDefault: true);
const _paymentCard =
    PaymentMethod(id: 'pm_2', type: PaymentMethodType.card, label: 'Card', isDefault: false);

const _profileWithData = UserProfile(
  id: 'user_1',
  name: 'Test User',
  email: 'test@foodie.com',
  phone: '',
  avatarUrl: '',
  addresses: [_addrHome, _addrOffice],
  paymentMethods: [_paymentCod, _paymentCard],
);

void main() {
  late FakeAuthRepository authRepository;
  late FakeProfileRepository profileRepository;
  late FakeCartRepository cartRepository;
  late FakeRestaurantRepository restaurantRepository;
  late FakeCheckoutRepository checkoutRepository;
  late ProviderContainer container;

  setUp(() async {
    authRepository = FakeAuthRepository();
    authRepository.nextRestoreSessionResult = const Result.ok(SessionInfo(token: 't', userId: 'user_1'));
    authRepository.nextGetUserByIdResult = const Result.ok(fakeUser);

    profileRepository = FakeProfileRepository();
    cartRepository = FakeCartRepository();
    restaurantRepository = FakeRestaurantRepository();
    checkoutRepository = FakeCheckoutRepository();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        profileRepositoryProvider.overrideWithValue(profileRepository),
        cartRepositoryProvider.overrideWithValue(cartRepository),
        restaurantRepositoryProvider.overrideWithValue(restaurantRepository),
        checkoutRepositoryProvider.overrideWithValue(checkoutRepository),
      ],
    );
    addTearDown(container.dispose);

    // Resolve auth first so ProfileNotifier.build() sees AuthAuthenticated.
    await container.read(authNotifierProvider.future);
    profileRepository.nextGetProfileResult = const Result.ok(_profileWithData);
  });

  group('CheckoutNotifier.build()', () {
    test('picks the default address and payment method', () async {
      final state = await container.read(checkoutNotifierProvider.future);

      expect(state.selectedAddressId, 'addr_1');
      expect(state.selectedPaymentMethodId, 'pm_1');
    });

    test('falls back to the first entry when nothing is marked default', () async {
      profileRepository.nextGetProfileResult = Result.ok(_profileWithData.copyWith(
        addresses: const [_addrOffice, _addrHome].map((a) => a.copyWith(isDefault: false)).toList(),
      ));

      final state = await container.read(checkoutNotifierProvider.future);

      expect(state.selectedAddressId, 'addr_2');
    });

    test('leaves selections null when Profile has no addresses/payment methods', () async {
      profileRepository.nextGetProfileResult = const Result.ok(fakeProfile);

      final state = await container.read(checkoutNotifierProvider.future);

      expect(state.selectedAddressId, isNull);
      expect(state.selectedPaymentMethodId, isNull);
    });
  });

  group('CheckoutNotifier selection', () {
    test('selectAddress()/selectPaymentMethod() update the selected ids', () async {
      await container.read(checkoutNotifierProvider.future);

      await container.read(checkoutNotifierProvider.notifier).selectAddress('addr_2');
      await container.read(checkoutNotifierProvider.notifier).selectPaymentMethod('pm_2');

      final state = container.read(checkoutNotifierProvider).value!;
      expect(state.selectedAddressId, 'addr_2');
      expect(state.selectedPaymentMethodId, 'pm_2');
    });
  });

  group('CheckoutNotifier.placeOrder()', () {
    test('guards against an empty cart without calling the repository', () async {
      cartRepository.nextGetCartResult = const Result.ok([]);
      await container.read(checkoutNotifierProvider.future);

      await container.read(checkoutNotifierProvider.notifier).placeOrder();

      final state = container.read(checkoutNotifierProvider).value!;
      expect(state.errorMessage, 'Your cart is empty.');
      expect(checkoutRepository.placeOrderCallCount, 0);
    });

    test('guards against no selected address without calling the repository', () async {
      profileRepository.nextGetProfileResult = const Result.ok(fakeProfile); // no addresses
      cartRepository.nextGetCartResult = Result.ok([buildFakeCartItem()]);
      await container.read(checkoutNotifierProvider.future);

      await container.read(checkoutNotifierProvider.notifier).placeOrder();

      final state = container.read(checkoutNotifierProvider).value!;
      expect(state.errorMessage, 'Please select a delivery address.');
      expect(checkoutRepository.placeOrderCallCount, 0);
    });

    test('happy path places the order, clears the cart, and records placedOrder', () async {
      cartRepository.nextGetCartResult = Result.ok([buildFakeCartItem(restaurantId: 'rest_1')]);
      await container.read(checkoutNotifierProvider.future);
      await container.read(cartNotifierProvider.future);

      await container.read(checkoutNotifierProvider.notifier).placeOrder();

      final state = container.read(checkoutNotifierProvider).value!;
      expect(checkoutRepository.placeOrderCallCount, 1);
      expect(state.isPlacingOrder, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.placedOrder, isNotNull);
      expect(state.placedOrder!.restaurantId, 'rest_1');
      expect(state.placedOrder!.addressLabel, 'Home');
      expect(state.placedOrder!.paymentMethodLabel, 'Cash on Delivery');
      expect(container.read(cartNotifierProvider).value!.items, isEmpty);
    });

    test('a repository failure surfaces as errorMessage and resets isPlacingOrder', () async {
      cartRepository.nextGetCartResult = Result.ok([buildFakeCartItem(restaurantId: 'rest_1')]);
      checkoutRepository.nextPlaceOrderResult = const Result.err(UnknownFailure('disk full'));
      await container.read(checkoutNotifierProvider.future);

      await container.read(checkoutNotifierProvider.notifier).placeOrder();

      final state = container.read(checkoutNotifierProvider).value!;
      expect(state.errorMessage, 'disk full');
      expect(state.isPlacingOrder, isFalse);
      expect(state.placedOrder, isNull);
    });
  });
}
