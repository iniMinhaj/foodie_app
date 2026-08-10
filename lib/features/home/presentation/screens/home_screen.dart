import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_placeholders.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../legacy/cart/cart_screen.dart';
import '../../../../legacy/orders/order_history_screen.dart';
import '../../../../legacy/profile/profile_screen.dart';
import '../../../../legacy/search/search_screen.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../restaurant/presentation/screens/restaurant_detail_screen.dart';
import '../providers/categories_provider.dart';
import '../providers/restaurant_list_notifier.dart';
import '../widgets/category_chip.dart';
import '../widgets/restaurant_card.dart';

/// Home tab plus a lightweight bottom-nav bridge into the still-legacy
/// Orders/Cart/Profile screens — those become their own Clean Architecture
/// modules later (see docs/MIGRATION_STATUS.md); until then this is the
/// only way to reach them from a fully-migrated screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Scheduled rather than called inline — Riverpod disallows mutating
    // provider state during a widget's build/initState phase.
    Future.microtask(
      () => ref.read(restaurantListNotifierProvider.notifier).loadFirstPage(),
    );
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
    if (nearBottom) {
      ref.read(restaurantListNotifierProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeBody(scrollController: _scrollController),
      const OrderHistoryScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_bottomNavIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (i) => setState(() => _bottomNavIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  final ScrollController scrollController;
  const _HomeBody({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(restaurantListNotifierProvider);
    final errorMessage = ref.watch(restaurantListErrorProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(restaurantListNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _Header()),
          const SliverToBoxAdapter(child: _CategoryRow()),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: listState.isFirstLoad
                  ? 'Restaurants near you'
                  : 'Restaurants near you (${listState.items.length})',
            ),
          ),
          if (listState.isFirstLoad)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const RestaurantCardSkeleton(),
                childCount: 3,
              ),
            )
          else if (errorMessage != null && listState.items.isEmpty)
            SliverFillRemaining(
              child: ErrorStateView(
                message: errorMessage,
                onRetry: () =>
                    ref.read(restaurantListNotifierProvider.notifier).loadFirstPage(),
              ),
            )
          else if (listState.items.isEmpty)
            const SliverFillRemaining(
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
                  restaurant: listState.items[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestaurantDetailScreen(restaurant: listState.items[index]),
                    ),
                  ),
                ),
                childCount: listState.items.length,
              ),
            ),
          if (listState.isLoadingMore)
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
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 4.w),
              Expanded(
                child: Text('Dhanmondi, Dhaka', style: Theme.of(context).textTheme.bodyMedium),
              ),
              Consumer(
                builder: (context, ref, _) => IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
                  tooltip: 'Log out',
                  onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text('Craving something good?', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
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
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedId = ref.watch(selectedCategoryIdProvider);

    return SizedBox(
      height: 44.h,
      child: categoriesAsync.when(
        loading: () => ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (_, __) => const ChipSkeleton(),
        ),
        error: (error, stackTrace) => const SizedBox.shrink(),
        data: (categories) => ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedId == category.id;
            return CategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () => ref
                  .read(restaurantListNotifierProvider.notifier)
                  .selectCategory(isSelected ? null : category.id),
            );
          },
        ),
      ),
    );
  }
}
