import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/state_views.dart';
import '../checkout/checkout_screen.dart';
import '../utils/cart_service.dart';

/// TODO: Riverpod - `AnimatedBuilder(animation: CartService.instance, ...)`
/// becomes `ref.watch(cartProvider)`. No other structural change needed;
/// this screen is already "dumb" (reads cart state, renders it).
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const _deliveryFee = 1.99;
  static const _platformFee = 0.5;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final items = CartService.instance.items;
        final subtotal = CartService.instance.subtotal;
        final total = items.isEmpty ? 0.0 : subtotal + _deliveryFee + _platformFee;

        return Scaffold(
          appBar: AppBar(title: const Text('Your Cart')),
          body: items.isEmpty
              ? EmptyStateView(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your cart is empty',
                  message: 'Add items from a restaurant to get started.',
                  actionLabel: 'Browse Restaurants',
                  onAction: () => Navigator.of(context).maybePop(),
                )
              : ListView(
                  padding: EdgeInsets.all(AppSpacing.md),
                  children: [
                    for (final item in items) _CartItemTile(item: item),
                    SizedBox(height: AppSpacing.sm),
                    _PricingSummary(subtotal: subtotal, deliveryFee: _deliveryFee, platformFee: _platformFee, total: total),
                  ],
                ),
          bottomNavigationBar: items.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                      child: Text('Proceed to Checkout • \$${total.toStringAsFixed(2)}'),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item; // CartItemModel

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
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
          AppImage(url: item.product.primaryImage as String, width: 64.w, height: 64.w),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name as String, style: Theme.of(context).textTheme.titleMedium),
                if ((item.variationSummary as String).isNotEmpty)
                  Text(item.variationSummary as String, style: Theme.of(context).textTheme.bodyMedium),
                if ((item.extrasSummary as String).isNotEmpty)
                  Text('+ ${item.extrasSummary}', style: Theme.of(context).textTheme.bodySmall),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${(item.lineTotal as double).toStringAsFixed(2)}',
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

class _QtyControl extends StatelessWidget {
  final dynamic item;
  const _QtyControl({required this.item});

  @override
  Widget build(BuildContext context) {
    final quantity = item.quantity as int;
    final cartItemId = item.cartItemId as String;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBtn(Icons.remove_rounded, () => CartService.instance.updateQuantity(cartItemId, quantity - 1)),
        SizedBox(width: 20.w, child: Text('$quantity', textAlign: TextAlign.center)),
        _iconBtn(Icons.add_rounded, () => CartService.instance.updateQuantity(cartItemId, quantity + 1)),
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
    final style = isBold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
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
