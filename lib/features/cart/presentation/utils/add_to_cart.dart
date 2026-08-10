import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entities/cart_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/cart_notifier.dart';

/// Single entry point every "add to cart" action should go through —
/// enforces the single-restaurant rule (a cart can only hold items from
/// one restaurant at a time) by confirming with the user before clearing
/// an existing cart from a different restaurant.
Future<void> addToCart(BuildContext context, WidgetRef ref, CartItem item) async {
  final notifier = ref.read(cartNotifierProvider.notifier);
  final existingRestaurantId = ref.read(cartNotifierProvider).value?.restaurantId;

  if (existingRestaurantId != null && existingRestaurantId != item.restaurantId) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Start a new cart?'),
        content: const Text(
          'Your cart has items from another restaurant. Adding this item will clear them.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Start New Cart')),
        ],
      ),
    );
    if (confirmed != true) return;
    await notifier.clear();
  }

  await notifier.addItem(item);
}
