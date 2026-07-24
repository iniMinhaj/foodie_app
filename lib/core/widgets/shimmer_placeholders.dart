import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Shared shimmer wrapper so every skeleton in the app uses the same
/// base/highlight colors instead of each screen re-declaring them.
class AppShimmer extends StatelessWidget {
  final Widget child;
  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: child,
    );
  }
}

class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md, left: AppSpacing.md, right: AppSpacing.md),
        height: 220.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.md, right: AppSpacing.md),
        height: 100.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

class ChipSkeleton extends StatelessWidget {
  const ChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: 64.w,
        margin: EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
