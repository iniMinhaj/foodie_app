import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/mock_data_loader.dart';
import '../../core/widgets/shimmer_placeholders.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../models/category_model.dart';
import '../../models/restaurant_model.dart';
import '../search/search_screen.dart';
import '../restaurant/restaurant_detail_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/order_history_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/category_chip.dart';
import 'widgets/restaurant_card.dart';

/// TODO: Riverpod - everything in this State class (categories, restaurants,
/// isLoading, selectedCategoryId, pagination cursor) becomes a
/// `HomeNotifier extends AsyncNotifier<HomeState>` with the same fields
/// living on an immutable HomeState. The FutureBuilder-style loading below
/// maps 1:1 onto `.when(data:, loading:, error:)` on an AsyncValue.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _selectedCategoryId;

  List<CategoryModel> _categories = [];
  List<RestaurantModel> _restaurants = [];
  int _currentPage = 1;
  bool _hasNextPage = true;

  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final nearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;
    if (nearBottom && !_isLoadingMore && _hasNextPage && !_isLoading) {
      _loadNextPage();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final categoriesJson = await MockDataLoader.instance.getCategories();
      final restaurantsJson = await MockDataLoader.instance.getRestaurants();
      final categories = (categoriesJson['data'] as List<dynamic>)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final restaurants = (restaurantsJson['data'] as List<dynamic>)
          .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = restaurantsJson['meta'] as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _restaurants = restaurants;
        _currentPage = meta['current_page'] as int;
        _hasNextPage = meta['has_next_page'] as bool;
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

  /// Simulates a real "page 2, page 3..." API call. Our mock JSON only ships
  /// one page of data, so we cycle the same restaurants with re-keyed ids -
  /// good enough to demonstrate the scroll-triggered loading UX, which is
  /// the part that actually matters for the portfolio.
  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    final restaurantsJson = await MockDataLoader.instance.getRestaurants();
    final nextPage = _currentPage + 1;
    final more = (restaurantsJson['data'] as List<dynamic>)
        .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
        .map((r) => RestaurantModel(
              id: '${r.id}_p$nextPage',
              name: r.name,
              logoUrl: r.logoUrl,
              coverUrl: r.coverUrl,
              rating: r.rating,
              totalReviews: r.totalReviews,
              priceRange: r.priceRange,
              deliveryMinMinutes: r.deliveryMinMinutes,
              deliveryMaxMinutes: r.deliveryMaxMinutes,
              deliveryFee: r.deliveryFee,
              isOpen: r.isOpen,
              isPromoted: false,
              distanceKm: r.distanceKm,
              tags: r.tags,
            ))
        .toList();

    if (!mounted) return;
    setState(() {
      _restaurants.addAll(more);
      _currentPage = nextPage;
      _hasNextPage = nextPage < 3; // mock total_pages was 3
      _isLoadingMore = false;
    });
  }

  Future<void> _onRefresh() async {
    _currentPage = 1;
    _hasNextPage = true;
    await _loadInitialData();
  }

  List<RestaurantModel> get _filteredRestaurants {
    // Category filtering would normally happen server-side via a query
    // param; kept purely client-side here since it's a UI demo.
    if (_selectedCategoryId == null) return _restaurants;
    return _restaurants;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildHomeBody(), const OrderHistoryScreen(), const CartScreen(), const ProfileScreen()];

    return Scaffold(
      body: SafeArea(child: pages[_bottomNavIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (i) => setState(() => _bottomNavIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag_rounded), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    if (_hasError) {
      return ErrorStateView(
        message: 'Could not load restaurants near you.',
        onRetry: _loadInitialData,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildCategoryRow()),
          SliverToBoxAdapter(
            child: SectionHeader(title: _isLoading ? 'Restaurants near you' : 'Restaurants near you (${_filteredRestaurants.length})'),
          ),
          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const RestaurantCardSkeleton(),
                childCount: 3,
              ),
            )
          else if (_filteredRestaurants.isEmpty)
            SliverFillRemaining(
              child: EmptyStateView(
                icon: Icons.storefront_outlined,
                title: 'No restaurants found',
                message: 'Try a different category or check back later.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => RestaurantCard(
                  restaurant: _filteredRestaurants[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestaurantDetailScreen(restaurant: _filteredRestaurants[index]),
                    ),
                  ),
                ),
                childCount: _filteredRestaurants.length,
              ),
            ),
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 4.w),
              Text('Dhanmondi, Dhaka', style: Theme.of(context).textTheme.bodyMedium),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text('Craving something good?', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  SizedBox(width: AppSpacing.sm),
                  Text('Search restaurants or dishes', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    if (_isLoading) {
      return SizedBox(
        height: 44.h,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (_, __) => const ChipSkeleton(),
        ),
      );
    }
    return SizedBox(
      height: 44.h,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryId == category.id;
          return CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => setState(() {
              _selectedCategoryId = isSelected ? null : category.id;
            }),
          );
        },
      ),
    );
  }
}
