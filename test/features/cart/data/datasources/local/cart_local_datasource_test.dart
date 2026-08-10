import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/features/cart/data/datasources/local/cart_local_datasource.dart';
import 'package:foodie_app/features/cart/data/models/cart_item_model.dart';

import '../../../../../helpers/fake_local_api_client.dart';

Map<String, dynamic> _cartItemJson({
  String cartItemId = 'citem_001',
  String productId = 'prod_1001',
  int quantity = 2,
}) =>
    {
      'cart_item_id': cartItemId,
      'product_id': productId,
      'restaurant_id': 'rest_001',
      'product_name': 'Chicken Biryani',
      'product_image': 'https://cdn.example.com/products/chicken_biryani_1.jpg',
      'quantity': quantity,
      'unit_base_price': 5.75,
      'selected_variations': <Map<String, dynamic>>[],
      'selected_extras': <Map<String, dynamic>>[],
      'special_instructions': null,
    };

void main() {
  group('CartLocalDataSource', () {
    test('getItems() parses the items array off the single cart object', () async {
      final storage = FakeLocalApiClient({
        'cart_sample.json': [
          {
            'cart_id': 'cart_5001',
            'restaurant_id': 'rest_001',
            'items': [_cartItemJson()],
            'pricing_summary': {'subtotal': 11.5},
          },
        ],
      });
      final datasource = CartLocalDataSource(storage);

      final items = await datasource.getItems();

      expect(items, hasLength(1));
      expect(items.first.id, 'citem_001');
      expect(items.first.quantity, 2);
    });

    test('getItems() returns an empty list when no cart object exists', () async {
      final storage = FakeLocalApiClient({'cart_sample.json': []});
      final datasource = CartLocalDataSource(storage);

      expect(await datasource.getItems(), isEmpty);
    });

    test('saveItems() replaces items while preserving other cart fields', () async {
      final storage = FakeLocalApiClient({
        'cart_sample.json': [
          {
            'cart_id': 'cart_5001',
            'items': [_cartItemJson()],
            'pricing_summary': {'subtotal': 11.5},
          },
        ],
      });
      final datasource = CartLocalDataSource(storage);

      await datasource.saveItems([
        CartItemModel.fromJson(_cartItemJson(cartItemId: 'citem_new', quantity: 3)),
      ]);

      final written = storage.peek('cart_sample.json')!.single;
      expect(written['cart_id'], 'cart_5001');
      expect(written['pricing_summary'], {'subtotal': 11.5});
      expect((written['items'] as List).single['cart_item_id'], 'citem_new');
      expect((written['items'] as List).single['quantity'], 3);
    });
  });
}
