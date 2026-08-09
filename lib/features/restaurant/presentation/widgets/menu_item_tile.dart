import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';

/// Read-only menu row — tapping into Product Detail isn't wired up yet
/// (that module doesn't exist), so unavailable items are just visibly
/// disabled and not tappable, per the module's acceptance criteria.
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppImage(
              url: product.imageUrl,
              width: 72.w,
              height: 72.w,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (product.hasDiscount) ...[
                        Text(
                          '\$${product.basePrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        '\$${product.effectivePrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
