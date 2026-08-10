import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/entities/cart_item.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../legacy/checkout/checkout_screen.dart';
import '../providers/cart_notifier.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static const _deliveryFee = 1.99;
  static const _platformFee = 0.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (error, stackTrace) => ErrorStateView(
          message: error is Failure ? error.userMessage : 'Something went wrong. Please try again.',
          onRetry: () => ref.invalidate(cartNotifierProvider),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return EmptyStateView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Add items from a restaurant to get started.',
              actionLabel: 'Browse Restaurants',
              onAction: () => Navigator.of(context).maybePop(),
            );
          }

          final subtotal = state.subtotal;
          final total = subtotal + _deliveryFee + _platformFee;

          return ListView(
            padding: EdgeInsets.all(AppSpacing.md),
            children: [
              for (final item in state.items) _CartItemTile(item: item),
              SizedBox(height: AppSpacing.sm),
              _PricingSummary(subtotal: subtotal, deliveryFee: _deliveryFee, platformFee: _platformFee, total: total),
            ],
          );
        },
      ),
      bottomNavigationBar: cartAsync.value == null || cartAsync.value!.items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                  child: Text(
                    'Proceed to Checkout • \$${(cartAsync.value!.subtotal + _deliveryFee + _platformFee).toStringAsFixed(2)}',
                  ),
                ),
              ),
            ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(url: item.productImageUrl, width: 64.w, height: 64.w),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: Theme.of(context).textTheme.titleMedium),
                if (item.variationSummary.isNotEmpty)
                  Text(item.variationSummary, style: Theme.of(context).textTheme.bodyMedium),
                if (item.extrasSummary.isNotEmpty)
                  Text('+ ${item.extrasSummary}', style: Theme.of(context).textTheme.bodySmall),
                if ((item.specialInstructions ?? '').isNotEmpty)
                  Text(
                    '"${item.specialInstructions}"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.lineTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    _QtyControl(item: item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends ConsumerWidget {
  final CartItem item;
  const _QtyControl({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBtn(
          Icons.remove_rounded,
          () => ref.read(cartNotifierProvider.notifier).updateQuantity(item.id, item.quantity - 1),
        ),
        SizedBox(width: 20.w, child: Text('${item.quantity}', textAlign: TextAlign.center)),
        _iconBtn(
          Icons.add_rounded,
          () => ref.read(cartNotifierProvider.notifier).updateQuantity(item.id, item.quantity + 1),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}

class _PricingSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double platformFee;
  final double total;

  const _PricingSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal', subtotal),
          _row(context, 'Delivery Fee', deliveryFee),
          _row(context, 'Platform Fee', platformFee),
          const Divider(),
          _row(context, 'Total', total, isBold: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, double value, {bool isBold = false}) {
    final style = isBold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
