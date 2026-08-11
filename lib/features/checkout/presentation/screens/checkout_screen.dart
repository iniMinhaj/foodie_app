import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/entities/payment_method.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/providers/cart_notifier.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';
import '../providers/checkout_notifier.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutAsync = ref.watch(checkoutNotifierProvider);
    final cartAsync = ref.watch(cartNotifierProvider);
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: checkoutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (error, stackTrace) => ErrorStateView(
          message: error is Failure ? error.userMessage : 'Something went wrong. Please try again.',
          onRetry: () => ref.invalidate(checkoutNotifierProvider),
        ),
        data: (checkoutState) {
          final cartItems = cartAsync.value?.items ?? const [];
          if (cartItems.isEmpty) {
            return EmptyStateView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Add items from a restaurant to get started.',
              actionLabel: 'Browse Restaurants',
              onAction: () => Navigator.of(context).maybePop(),
            );
          }

          final addresses = profileAsync.value?.profile.addresses ?? const [];
          final paymentMethods = profileAsync.value?.profile.paymentMethods ?? const [];

          return ListView(
            padding: EdgeInsets.all(AppSpacing.md),
            children: [
              if (checkoutState.errorMessage != null) ...[
                _ErrorBanner(message: checkoutState.errorMessage!),
                SizedBox(height: AppSpacing.md),
              ],
              Text('Delivery Address', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              if (addresses.isEmpty)
                const _EmptyRow(message: 'No saved addresses yet. Add one from Profile.')
              else
                for (final address in addresses)
                  _SelectableTile(
                    icon: Icons.location_on_outlined,
                    title: address.label,
                    subtitle: '${address.line1}, ${address.city}',
                    isSelected: address.id == checkoutState.selectedAddressId,
                    onTap: () => ref.read(checkoutNotifierProvider.notifier).selectAddress(address.id),
                  ),
              SizedBox(height: AppSpacing.lg),
              Text('Payment Method', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              if (paymentMethods.isEmpty)
                const _EmptyRow(message: 'No payment methods on file. Add one from Profile.')
              else
                for (final method in paymentMethods)
                  _SelectableTile(
                    icon: _paymentIcon(method.type),
                    title: method.label,
                    isSelected: method.id == checkoutState.selectedPaymentMethodId,
                    onTap: () => ref.read(checkoutNotifierProvider.notifier).selectPaymentMethod(method.id),
                  ),
            ],
          );
        },
      ),
      bottomNavigationBar: checkoutAsync.value == null || (cartAsync.value?.items.isEmpty ?? true)
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: ElevatedButton(
                  onPressed:
                      checkoutAsync.value!.isPlacingOrder ? null : () => _handlePlaceOrder(context, ref),
                  child: checkoutAsync.value!.isPlacingOrder
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          'Place Order • \$${((cartAsync.value?.subtotal ?? 0) + checkoutDeliveryFee + checkoutPlatformFee).toStringAsFixed(2)}',
                        ),
                ),
              ),
            ),
    );
  }
}

IconData _paymentIcon(PaymentMethodType type) => switch (type) {
      PaymentMethodType.card => Icons.credit_card_rounded,
      PaymentMethodType.wallet => Icons.account_balance_wallet_rounded,
      PaymentMethodType.cod => Icons.money_rounded,
    };

Future<void> _handlePlaceOrder(BuildContext context, WidgetRef ref) async {
  await ref.read(checkoutNotifierProvider.notifier).placeOrder();
  if (!context.mounted) return;

  final placed = ref.read(checkoutNotifierProvider).value?.placedOrder;
  if (placed == null) return; // errorMessage is already in state; the rebuild shows it inline

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
          SizedBox(height: AppSpacing.md),
          Text('Order Placed!', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Your order has been confirmed and is being prepared.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            child: const Text('Back to Home'),
          ),
        ),
      ],
    ),
  );
}

class _SelectableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
