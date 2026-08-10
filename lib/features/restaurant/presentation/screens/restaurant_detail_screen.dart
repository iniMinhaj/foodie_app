import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsByRestaurantProvider(widget.restaurant.id));

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
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
                  AppImage(url: widget.restaurant.coverImageUrl, fit: BoxFit.cover, borderRadius: BorderRadius.zero),
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
                  if (!widget.restaurant.isOpen)
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
          SliverToBoxAdapter(child: _RestaurantMeta(restaurant: widget.restaurant)),
          ...productsAsync.when(
            loading: () => [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ProductCardSkeleton(),
                  childCount: 3,
                ),
              ),
            ],
            error: (error, stackTrace) => [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240.h,
                  child: ErrorStateView(
                    message: error is Failure ? error.userMessage : 'Something went wrong. Please try again.',
                    onRetry: () => ref.invalidate(productsByRestaurantProvider(widget.restaurant.id)),
                  ),
                ),
              ),
            ],
            data: (products) => products.isEmpty
                ? [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 200.h,
                        child: const EmptyStateView(
                          icon: Icons.restaurant_menu_rounded,
                          title: 'No menu items yet',
                          message: 'Check back later for this restaurant\'s menu.',
                        ),
                      ),
                    ),
                  ]
                : [_MenuSection(products: products, scrollController: _scrollController)],
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}

/// Zomato-style menu browser: a horizontal scrollable row of the
/// restaurant's [Product.categoryName]s, with every category's items
/// listed below in sequence (not filtered). Scrolling the item list drives
/// which tab is highlighted — a "scrollspy" — and tapping a tab jumps the
/// list to that category's section. Selection is local UI state — it isn't
/// worth a Riverpod provider since nothing outside this screen needs to
/// observe it.
///
/// The category tab row is a pinned [SliverPersistentHeader] (not a plain
/// box) so it sticks under the collapsed cover-photo app bar while
/// scrolling, foodpanda/Zomato-style — this is why the whole section is a
/// [SliverMainAxisGroup] rather than a single [SliverToBoxAdapter].
class _MenuSection extends StatefulWidget {
  final List<Product> products;
  final ScrollController scrollController;
  const _MenuSection({required this.products, required this.scrollController});

  @override
  State<_MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<_MenuSection> {
  late String _activeCategory = widget.products.first.categoryName;

  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _tabKeys = {};
  Map<String, double> _sectionOffsets = {};
  final _tabScrollController = ScrollController();

  /// Suppresses [_onScroll] while a tap-triggered [ScrollController.animateTo]
  /// is in flight, so the listener doesn't flicker the highlight through
  /// whichever sections the animated jump scrolls past on its way to the target.
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeSectionOffsets());
  }

  @override
  void didUpdateWidget(_MenuSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products != oldWidget.products) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeSectionOffsets());
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _tabScrollController.dispose();
    super.dispose();
  }

  static List<String> _categoriesOf(List<Product> products) {
    final seen = <String>{};
    final ordered = <String>[];
    for (final product in products) {
      if (seen.add(product.categoryName)) ordered.add(product.categoryName);
    }
    return ordered;
  }

  GlobalKey _sectionKeyFor(String category) => _sectionKeys.putIfAbsent(category, () => GlobalKey());
  GlobalKey _tabKeyFor(String category) => _tabKeys.putIfAbsent(category, () => GlobalKey());

  /// Caches each section header's scroll offset via the same primitive
  /// [Scrollable.ensureVisible] uses under the hood — it accounts for the
  /// pinned cover-photo app bar and pinned tab row above the content for
  /// free, so landing a jump just below both needs no manual height math.
  void _recomputeSectionOffsets() {
    if (!mounted) return;
    final offsets = <String, double>{};
    for (final entry in _sectionKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      // maybeOf (not of) — a box mid-attach/detach during lazy sliver layout
      // may transiently have no viewport ancestor; `of` would throw for that.
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null) continue;
      offsets[entry.key] = viewport.getOffsetToReveal(box, 0.0).offset;
    }
    _sectionOffsets = offsets;
  }

  void _onScroll() {
    if (_isProgrammaticScroll) return;
    // Sliver layout is lazy — sections below the fold + cache extent aren't
    // built/laid out yet on the first frame, so this has to keep re-measuring
    // as more of them come into range while the user scrolls, not just once.
    _recomputeSectionOffsets();
    if (_sectionOffsets.isEmpty) return;
    final offset = widget.scrollController.offset;
    final categories = _categoriesOf(widget.products);

    var next = categories.first;
    for (final category in categories) {
      final sectionOffset = _sectionOffsets[category];
      if (sectionOffset != null && sectionOffset <= offset) {
        next = category;
      } else {
        break; // categories are ordered, so offsets are monotonically increasing
      }
    }

    if (next == _activeCategory) return;
    setState(() => _activeCategory = next);
    _revealTab(next);
  }

  void _selectCategory(String category) {
    if (category != _activeCategory) setState(() => _activeCategory = category);
    _revealTab(category);

    final target = _sectionOffsets[category];
    if (target == null) return; // offsets not measured yet — negligible startup race
    final clamped = target.clamp(0.0, widget.scrollController.position.maxScrollExtent);

    _isProgrammaticScroll = true;
    widget.scrollController
        .animateTo(clamped, duration: const Duration(milliseconds: 300), curve: Curves.easeOut)
        .whenComplete(() => _isProgrammaticScroll = false);
  }

  /// Scoped to [_tabScrollController]'s own viewport only — deliberately not
  /// [Scrollable.ensureVisible], which walks *every* ancestor Scrollable and
  /// would also nudge the outer vertical list (the pill row sits inside the
  /// same CustomScrollView the vertical scrollspy is driven by), fighting the
  /// user's own scroll and re-triggering [_onScroll] mid-gesture.
  void _revealTab(String category) {
    final box = _tabKeys[category]?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final target = viewport.getOffsetToReveal(box, 0.5).offset;
    final clamped = target.clamp(0.0, _tabScrollController.position.maxScrollExtent);
    _tabScrollController.animateTo(clamped, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoriesOf(widget.products);
    // Guards against a stale selection if the product list changes shape
    // underneath this widget (e.g. a retry after an error) without a category
    // matching what was previously selected.
    if (!categories.contains(_activeCategory)) _activeCategory = categories.first;

    final grouped = <String, List<Product>>{};
    for (final product in widget.products) {
      grouped.putIfAbsent(product.categoryName, () => []).add(product);
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryTabBarDelegate(
            categories: categories,
            selectedCategory: _activeCategory,
            onSelect: _selectCategory,
            tabScrollController: _tabScrollController,
            tabKeyFor: _tabKeyFor,
          ),
        ),
        for (final category in categories) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              key: _sectionKeyFor(category),
              title: category,
              actionLabel: '${grouped[category]!.length} item${grouped[category]!.length == 1 ? '' : 's'}',
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => MenuItemTile(product: grouped[category]![index]),
              childCount: grouped[category]!.length,
            ),
          ),
        ],
      ],
    );
  }
}

/// Pinned header wrapping the horizontal category-pill row so it sticks
/// under the app bar once scrolled to, instead of scrolling away with the
/// rest of the menu content.
class _CategoryTabBarDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelect;
  final ScrollController tabScrollController;
  final GlobalKey Function(String category) tabKeyFor;

  _CategoryTabBarDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
    required this.tabScrollController,
    required this.tabKeyFor,
  });

  double get _height => 44.h + AppSpacing.sm * 2;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: _height,
        child: Center(
          child: SizedBox(
            height: 44.h,
            child: SingleChildScrollView(
              controller: tabScrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  for (final name in categories)
                    _MenuCategoryTab(
                      key: tabKeyFor(name),
                      label: name,
                      isSelected: name == selectedCategory,
                      onTap: () => onSelect(name),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryTabBarDelegate oldDelegate) {
    return categories != oldDelegate.categories ||
        selectedCategory != oldDelegate.selectedCategory;
  }
}

class _MenuCategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuCategoryTab({super.key, required this.label, required this.isSelected, required this.onTap});

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
