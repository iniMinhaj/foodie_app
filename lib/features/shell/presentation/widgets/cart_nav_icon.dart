import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cart/presentation/providers/cart_notifier.dart';

/// Bottom-nav cart icon with an item-count badge — the one visible payoff
/// of centralizing cart state app-wide instead of leaving it screen-local.
class CartNavIcon extends ConsumerWidget {
  final IconData icon;
  const CartNavIcon({required this.icon, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(cartNotifierProvider).value?.itemCount ?? 0;
    if (itemCount == 0) return Icon(icon);
    return Badge(
      label: Text('$itemCount'),
      backgroundColor: AppColors.primary,
      child: Icon(icon),
    );
  }
}
