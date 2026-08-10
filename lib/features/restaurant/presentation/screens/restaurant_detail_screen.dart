import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/entities/restaurant.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_placeholders.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/restaurant_detail_provider.dart';
import '../widgets/menu_item_tile.dart';

/// Receives [restaurant] directly (passed by the caller — see
/// `RestaurantCard.onTap` in `home_screen.dart`) so the header renders
/// instantly without waiting on a refetch; only the menu list depends on
/// [productsByRestaurantProvider].
class RestaurantDetailScreen extends ConsumerWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByRestaurantProvider(restaurant.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.h,
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(url: restaurant.coverImageUrl, fit: BoxFit.cover, borderRadius: BorderRadius.zero),
                  if (!restaurant.isOpen)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: Text(
                        'Closed',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _RestaurantMeta(restaurant: restaurant)),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Menu')),
          productsAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const ProductCardSkeleton(),
                childCount: 3,
              ),
            ),
            error: (error, stackTrace) => SliverToBoxAdapter(
              child: SizedBox(
                height: 240.h,
                child: ErrorStateView(
                  message: error is Failure ? error.userMessage : 'Something went wrong. Please try again.',
                  onRetry: () => ref.invalidate(productsByRestaurantProvider(restaurant.id)),
                ),
              ),
            ),
            data: (products) => products.isEmpty
                ? SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200.h,
                      child: const EmptyStateView(
                        icon: Icons.restaurant_menu_rounded,
                        title: 'No menu items yet',
                        message: 'Check back later for this restaurant\'s menu.',
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => MenuItemTile(product: products[index]),
                      childCount: products.length,
                    ),
                  ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}

class _RestaurantMeta extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantMeta({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(restaurant.name, style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: AppSpacing.xs),
          if (restaurant.cuisineTags.isNotEmpty)
            Text(
              restaurant.cuisineTags.join(' • '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
              SizedBox(width: 4.w),
              Text(restaurant.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(width: AppSpacing.md),
              const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
              SizedBox(width: 4.w),
              Text(restaurant.etaLabel, style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(width: AppSpacing.md),
              const Icon(Icons.delivery_dining_rounded, size: 18, color: AppColors.textMuted),
              SizedBox(width: 4.w),
              Text(
                restaurant.deliveryFee == 0
                    ? 'Free delivery'
                    : '\$${restaurant.deliveryFee.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
