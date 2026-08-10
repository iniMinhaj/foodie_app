import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/entities/product.dart';
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
                  // Bottom scrim so the (future) title/foreground controls stay
                  // legible over busy food photography, Zomato-style.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
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
                : SliverToBoxAdapter(child: _CategoryMenu(products: products)),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}

/// Zomato-style menu browser: a horizontal scrollable row of the
/// restaurant's [Product.categoryName]s (first one selected by default),
/// with only the selected category's items listed below. Selection is
/// local UI state — it isn't worth a Riverpod provider since nothing
/// outside this screen needs to observe it.
class _CategoryMenu extends StatefulWidget {
  final List<Product> products;
  const _CategoryMenu({required this.products});

  @override
  State<_CategoryMenu> createState() => _CategoryMenuState();
}

class _CategoryMenuState extends State<_CategoryMenu> {
  late String _selectedCategory = widget.products.first.categoryName;

  @override
  Widget build(BuildContext context) {
    final categories = <String>[];
    for (final product in widget.products) {
      if (!categories.contains(product.categoryName)) categories.add(product.categoryName);
    }
    // Guards against a stale selection if the product list changes shape
    // underneath this widget (e.g. a retry after an error) without a category
    // matching what was previously selected.
    if (!categories.contains(_selectedCategory)) _selectedCategory = categories.first;

    final items = widget.products.where((p) => p.categoryName == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final name = categories[index];
              return _MenuCategoryTab(
                label: name,
                isSelected: name == _selectedCategory,
                onTap: () => setState(() => _selectedCategory = name),
              );
            },
          ),
        ),
        SectionHeader(
          title: _selectedCategory,
          actionLabel: '${items.length} item${items.length == 1 ? '' : 's'}',
        ),
        for (final product in items) MenuItemTile(product: product),
      ],
    );
  }
}

class _MenuCategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuCategoryTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: AppSpacing.sm),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RestaurantMeta extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantMeta({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: AppImage(
                  url: restaurant.logoUrl,
                  width: 52.w,
                  height: 52.w,
                  borderRadius: BorderRadius.circular(26.r),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name, style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 2.h),
                    if (restaurant.cuisineTags.isNotEmpty)
                      Text(
                        restaurant.cuisineTags.join(' • '),
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          // Wrap (not Row) so narrow screens drop the trailing chip to a
          // second line instead of overflowing — this row has three
          // variable-width chunks (rating/eta/delivery fee) with no single
          // good place to truncate.
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 4.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 2.w),
                    Text(
                      restaurant.rating.toStringAsFixed(1),
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 4.w),
                  Text(restaurant.etaLabel, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
          SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                restaurant.isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 14,
                color: restaurant.isOpen ? AppColors.success : AppColors.error,
              ),
              SizedBox(width: 4.w),
              Text(
                restaurant.isOpen ? 'Open now' : 'Currently closed',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: restaurant.isOpen ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
