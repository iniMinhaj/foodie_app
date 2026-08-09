import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers/auth_notifier.dart';

/// Stands in for the real Home module (not built yet — see
/// docs/MIGRATION_STATUS.md) so the router's auth guard has somewhere to
/// land an authenticated user.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final name = switch (authState.value) {
      AuthAuthenticated(:final user) => user.name,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Foodie')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_rounded,
                size: 48, color: AppColors.primary),
            SizedBox(height: AppSpacing.md),
            Text(
              name == null ? 'Signed in' : 'Signed in as $name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Home, Search, Restaurant/Product Detail, Cart, Checkout,\nOrders and Profile modules land here next.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
