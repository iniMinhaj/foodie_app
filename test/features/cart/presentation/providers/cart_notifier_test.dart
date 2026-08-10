import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/cart/presentation/providers/cart_notifier.dart';
import 'package:foodie_app/features/cart/presentation/providers/cart_providers.dart';

import '../../../../helpers/fake_cart_repository.dart';

void main() {
  late FakeCartRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeCartRepository();
    container = ProviderContainer(
      overrides: [cartRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('CartNotifier', () {
    test('build() loads the persisted cart', () async {
      repository.nextGetCartResult = Result.ok([buildFakeCartItem()]);

      final state = await container.read(cartNotifierProvider.future);

      expect(state.items, hasLength(1));
      expect(repository.getCartCallCount, 1);
    });

    test('addItem() appends a line and persists the new cart', () async {
      await container.read(cartNotifierProvider.future);

      await container.read(cartNotifierProvider.notifier).addItem(buildFakeCartItem());

      final state = container.read(cartNotifierProvider).value!;
      expect(state.items, hasLength(1));
      expect(repository.saveCartCallCount, 1);
      expect(repository.lastSavedItems, hasLength(1));
    });

    test('updateQuantity() bumps the matching line', () async {
      repository.nextGetCartResult = Result.ok([buildFakeCartItem(id: 'a', quantity: 1)]);
      await container.read(cartNotifierProvider.future);

      await container.read(cartNotifierProvider.notifier).updateQuantity('a', 3);

      expect(container.read(cartNotifierProvider).value!.items.single.quantity, 3);
    });

    test('updateQuantity() to zero removes the line', () async {
      repository.nextGetCartResult = Result.ok([buildFakeCartItem(id: 'a')]);
      await container.read(cartNotifierProvider.future);

      await container.read(cartNotifierProvider.notifier).updateQuantity('a', 0);

      expect(container.read(cartNotifierProvider).value!.items, isEmpty);
    });

    test('removeItem() drops the matching line', () async {
      repository.nextGetCartResult = Result.ok([buildFakeCartItem(id: 'a'), buildFakeCartItem(id: 'b')]);
      await container.read(cartNotifierProvider.future);

      await container.read(cartNotifierProvider.notifier).removeItem('a');

      expect(container.read(cartNotifierProvider).value!.items.map((i) => i.id), ['b']);
    });

    test('clear() empties the cart', () async {
      repository.nextGetCartResult = Result.ok([buildFakeCartItem()]);
      await container.read(cartNotifierProvider.future);

      await container.read(cartNotifierProvider.notifier).clear();

      expect(container.read(cartNotifierProvider).value!.items, isEmpty);
    });

    test('a failed persist rolls back to the previous state with an error message', () async {
      await container.read(cartNotifierProvider.future);
      repository.nextSaveCartResult = const Result.err(UnknownFailure('disk full'));

      await container.read(cartNotifierProvider.notifier).addItem(buildFakeCartItem());

      final state = container.read(cartNotifierProvider).value!;
      expect(state.items, isEmpty);
      expect(state.errorMessage, 'disk full');
    });

    test('CartState.restaurantId reflects the current cart, null when empty', () async {
      repository.nextGetCartResult = Result.ok([buildFakeCartItem(restaurantId: 'rest_9')]);
      final state = await container.read(cartNotifierProvider.future);

      expect(state.restaurantId, 'rest_9');

      await container.read(cartNotifierProvider.notifier).clear();
      expect(container.read(cartNotifierProvider).value!.restaurantId, isNull);
    });
  });
}
