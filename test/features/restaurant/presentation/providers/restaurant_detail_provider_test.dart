import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/restaurant/presentation/providers/restaurant_detail_provider.dart';
import 'package:foodie_app/features/restaurant/presentation/providers/restaurant_providers.dart';

import '../../../../helpers/fake_restaurant_repository.dart';

void main() {
  late FakeRestaurantRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeRestaurantRepository();
    container = ProviderContainer(
      overrides: [restaurantRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  /// Subscribes and waits for the provider to leave its loading state,
  /// keeping it alive (via the returned subscription) for the duration —
  /// reading `.future` directly on an `.autoDispose` provider with no
  /// other listener races with disposal on the error path.
  Future<void> settle(String restaurantId) async {
    final completer = Completer<void>();
    final sub = container.listen(
      productsByRestaurantProvider(restaurantId),
      (_, next) {
        if (!next.isLoading) completer.complete();
      },
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await completer.future;
  }

  group('productsByRestaurantProvider', () {
    test('fetches from the repository on first read', () async {
      repository.nextProductsByRestaurantResult = const Result.ok([]);

      await settle('rest_1');

      expect(repository.getProductsByRestaurantCallCount, 1);
      expect(container.read(productsByRestaurantProvider('rest_1')).hasError, isFalse);
    });

    test('propagates a repository failure as an AsyncError', () async {
      repository.nextProductsByRestaurantResult = const Result.err(UnknownFailure('boom'));

      await settle('rest_1');

      final asyncValue = container.read(productsByRestaurantProvider('rest_1'));
      expect(asyncValue.hasError, isTrue);
      expect(asyncValue.error, isA<UnknownFailure>());
    });
  });
}
