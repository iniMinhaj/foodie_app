import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/entities/cart_item.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../cart/presentation/providers/cart_notifier.dart';
import '../../../cart/presentation/utils/add_to_cart.dart';
import 'product_options_sheet.dart';

const _uuid = Uuid();

/// Read-only menu row (tapping into Product Detail isn't wired up yet, that
/// module doesn't exist) except for the [_AddToCartControl]: for a plain
/// product it adds a single unconfigured unit straight to [cartNotifierProvider];
/// for one with variations/extras it opens [ProductOptionsSheet] instead, since a
/// flat quantity add can't capture which options were chosen.
class MenuItemTile extends StatelessWidget {
  final Product product;

  const MenuItemTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.isAvailable ? 1.0 : 0.5,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.md, right: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppImage(
                  url: product.imageUrl,
                  width: 88.w,
                  height: 88.w,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                if (product.tags.contains('Bestseller'))
                  Positioned(
                    top: 4.h,
                    left: 4.w,
                    child: const _BestsellerBadge(),
                  ),
              ],
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VegIndicator(isVegetarian: product.isVegetarian),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (!product.isAvailable) ...[
                        SizedBox(width: AppSpacing.xs),
                        const _UnavailableBadge(),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        '\$${product.effectivePrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                      ),
                      if (product.hasDiscount) ...[
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          '\$${product.basePrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                        ),
                      ],
                      if (product.rating > 0) ...[
                        SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        SizedBox(width: 2.w),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (product.isAvailable) ...[
              SizedBox(width: AppSpacing.sm),
              _AddToCartControl(product: product),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnavailableBadge extends StatelessWidget {
  const _UnavailableBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        'Unavailable',
        style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _BestsellerBadge extends StatelessWidget {
  const _BestsellerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'Bestseller',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

/// Zomato's veg/non-veg marker: a green square+dot for [Product.isVegetarian],
/// a brown one otherwise (menu data doesn't distinguish non-veg any further).
class _VegIndicator extends StatelessWidget {
  final bool isVegetarian;
  const _VegIndicator({required this.isVegetarian});

  @override
  Widget build(BuildContext context) {
    final color = isVegetarian ? AppColors.success : const Color(0xFF8B4A2B);
    return Container(
      width: 14.w,
      height: 14.w,
      margin: EdgeInsets.only(top: 3.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(2.r),
      ),
      child: Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Drives [cartNotifierProvider] directly. A plain product renders "ADD"
/// (adding a single unconfigured unit directly) then a +/- stepper once it
/// has a matching cart line; a product with variations/extras always shows
/// "ADD" and opens [ProductOptionsSheet] instead, since there's no single
/// "the" cart line for it to step through at this list-tile level.
class _AddToCartControl extends ConsumerWidget {
  final Product product;
  const _AddToCartControl({required this.product});

  bool get _hasOptions => product.variationGroups.isNotEmpty || product.extraGroups.isNotEmpty;

  static bool _isPlainLine(CartItem item, String productId) =>
      item.productId == productId && item.selectedVariations.isEmpty && item.selectedExtras.isEmpty;

  Future<void> _addOne(BuildContext context, WidgetRef ref, List<CartItem> currentItems) async {
    final existing = currentItems.where((item) => _isPlainLine(item, product.id));
    if (existing.isNotEmpty) {
      final item = existing.first;
      await ref.read(cartNotifierProvider.notifier).updateQuantity(item.id, item.quantity + 1);
      return;
    }
    await addToCart(
      context,
      ref,
      CartItem(
        id: _uuid.v4(),
        productId: product.id,
        restaurantId: product.restaurantId,
        productName: product.name,
        productImageUrl: product.imageUrl,
        unitBasePrice: product.effectivePrice,
        quantity: 1,
        selectedVariations: const [],
        selectedExtras: const [],
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(seconds: 2)),
    );
  }

  void _removeOne(WidgetRef ref, List<CartItem> currentItems) {
    final existing = currentItems.where((item) => _isPlainLine(item, product.id));
    if (existing.isEmpty) return;
    final item = existing.first;
    ref.read(cartNotifierProvider.notifier).updateQuantity(item.id, item.quantity - 1);
  }

  Widget _addButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.w,
        height: 28.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primary, width: 1.4),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          'ADD',
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A configurable product has no single cart line to step through here —
    // every tap opens the sheet, which owns its own quantity picker.
    if (_hasOptions) {
      return _addButton(() => showProductOptionsSheet(context, product));
    }

    final items = ref.watch(cartNotifierProvider).value?.items ?? const <CartItem>[];
    final existing = items.where((item) => _isPlainLine(item, product.id));
    final quantity = existing.isEmpty ? 0 : existing.first.quantity;

    if (quantity == 0) {
      return _addButton(() => _addOne(context, ref, items));
    }

    return Container(
      width: 72.w,
      height: 28.h,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepIcon(icon: Icons.remove_rounded, onTap: () => _removeOne(ref, items)),
          Text('$quantity', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.white)),
          _StepIcon(icon: Icons.add_rounded, onTap: () => _addOne(context, ref, items)),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 20.w, height: 28.h, child: Icon(icon, size: 14, color: Colors.white)),
    );
  }
}
