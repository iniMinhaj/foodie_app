import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/mock_data_loader.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/shimmer_placeholders.dart';
import '../../core/widgets/state_views.dart';
import '../../models/product_model.dart';
import '../../models/restaurant_model.dart';
import '../product/product_detail_screen.dart';
import 'widgets/product_list_tile.dart';

/// TODO: Riverpod - `productsAsync` becomes
/// `ref.watch(productsByRestaurantProvider(restaurant.id))`, a
/// `FutureProvider.family`. The isLoading/hasError bools below collapse
/// into a single AsyncValue.
class RestaurantDetailScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final json = await MockDataLoader.instance.getProducts();
      final all = (json['data'] as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
      // In a real API this filtering happens server-side via
      // `/restaurants/{id}/products`; here we filter the shared mock list.
      final filtered = all.where((p) => p.restaurantId == widget.restaurant.id).toList();
      if (!mounted) return;
      setState(() {
        _products = filtered;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.h,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: AppImage(url: restaurant.coverUrl, width: double.infinity, height: 180.h, borderRadius: BorderRadius.zero),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name, style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                      SizedBox(width: 2.w),
                      Text('${restaurant.rating} (${restaurant.totalReviews} reviews)', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 4.w),
                      Text('${restaurant.deliveryTimeLabel} • ${restaurant.distanceKm} km away', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  if (!restaurant.isOpen) ...[
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                      child: Text('Currently closed - preview menu only', style: TextStyle(fontSize: 12.sp, color: AppColors.error, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  SizedBox(height: AppSpacing.sm),
                  const Divider(),
                ],
              ),
            ),
          ),
          if (_hasError)
            SliverFillRemaining(child: ErrorStateView(message: 'Could not load the menu.', onRetry: _loadProducts))
          else if (_isLoading)
            SliverList(delegate: SliverChildBuilderDelegate((_, __) => const ProductCardSkeleton(), childCount: 4))
          else if (_products.isEmpty)
            SliverFillRemaining(
              child: EmptyStateView(
                icon: Icons.restaurant_menu_rounded,
                title: 'Menu unavailable',
                message: 'This restaurant has not added any items yet.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductListTile(
                  product: _products[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: _products[index])),
                  ),
                ),
                childCount: _products.length,
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}
