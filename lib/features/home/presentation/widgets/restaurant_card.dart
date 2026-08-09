import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/entities/restaurant.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantCard({super.key, required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: restaurant.isOpen ? onTap : null,
      child: Opacity(
        opacity: restaurant.isOpen ? 1.0 : 0.5,
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.md, left: AppSpacing.md, right: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AppImage(
                    url: restaurant.coverImageUrl,
                    width: double.infinity,
                    height: 120.h,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  ),
                  if (!restaurant.isOpen)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: const _Badge(label: 'Closed', color: AppColors.error),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name, style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 4.h),
                    if (restaurant.cuisineTags.isNotEmpty)
                      Text(
                        restaurant.cuisineTags.take(3).join(' • '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                        SizedBox(width: 2.w),
                        Text(restaurant.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.bodyMedium),
                        SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                        SizedBox(width: 4.w),
                        Text(restaurant.etaLabel, style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Text(
                          restaurant.deliveryFee == 0
                              ? 'Free delivery'
                              : '\$${restaurant.deliveryFee.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}
