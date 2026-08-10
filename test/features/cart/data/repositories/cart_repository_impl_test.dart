import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/features/cart/data/datasources/local/cart_local_datasource.dart';
import 'package:foodie_app/features/cart/data/repositories/cart_repository_impl.dart';

import '../../../../helpers/fake_local_api_client.dart';

Map<String, dynamic> _cartItemJson(String cartItemId) => {
      'cart_item_id': cartItemId,
      'product_id': 'prod_1',
      'restaurant_id': 'rest_1',
      'product_name': 'Chicken Biryani',
      'product_image': '',
      'quantity': 1,
      'unit_base_price': 5.75,
      'selected_variations': <Map<String, dynamic>>[],
      'selected_extras': <Map<String, dynamic>>[],
      'special_instructions': null,
    };

void main() {
  late CartRepositoryImpl repository;
  late FakeLocalApiClient storage;

  setUp(() {
    storage = FakeLocalApiClient({
      'cart_sample.json': [
        {
          'cart_id': 'cart_1',
          'items': [_cartItemJson('citem_1')],
        },
      ],
    });
    repository = CartRepositoryImpl(CartLocalDataSource(storage));
  });

  group('CartRepositoryImpl.getCart', () {
    test('returns the persisted cart items', () async {
      final result = await repository.getCart();

      final items = result.valueOrNull!;
      expect(items, hasLength(1));
      expect(items.first.id, 'citem_1');
    });
  });

  group('CartRepositoryImpl.saveCart', () {
    test('persists the given items and returns Ok', () async {
      final items = (await repository.getCart()).valueOrNull!;
      final updated = [items.first.copyWith(quantity: 5)];

      final result = await repository.saveCart(updated);

      expect(result.isOk, isTrue);
      final written = storage.peek('cart_sample.json')!.single;
      expect((written['items'] as List).single['quantity'], 5);
    });
  });
}
