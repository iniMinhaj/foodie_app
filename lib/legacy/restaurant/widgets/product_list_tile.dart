import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image.dart';
import '../../models/product_model.dart';

class ProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductListTile({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.isAvailable ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: product.isAvailable ? onTap : null,
        child: Container(
          margin: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.sm),
          padding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(product.name, style: Theme.of(context).textTheme.titleMedium)),
                        if (product.isFeatured)
                          const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.warning),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        if (product.hasDiscount) ...[
                          Text(
                            '\$${product.basePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                        Text(
                          '\$${product.displayPrice.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        if (!product.isAvailable) ...[
                          const Spacer(),
                          Text('Unavailable', style: TextStyle(fontSize: 11.sp, color: AppColors.error, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              AppImage(url: product.primaryImage, width: 80.w, height: 80.w),
            ],
          ),
        ),
      ),
    );
  }
}
