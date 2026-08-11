import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../restaurant/presentation/providers/restaurant_providers.dart';
import '../../../restaurant/presentation/screens/restaurant_detail_screen.dart';
import '../providers/search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectSuggestion(String term) {
    _controller.text = term;
    ref.read(searchNotifierProvider.notifier).selectSuggestion(term);
  }

  Future<void> _openRestaurant(String restaurantId) async {
    final result = await ref.read(restaurantRepositoryProvider).getRestaurantById(restaurantId);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.userMessage))),
      (restaurant) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: restaurant)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (query) => ref.read(searchNotifierProvider.notifier).onQueryChanged(query),
          decoration: InputDecoration(
            hintText: 'Search restaurants or dishes',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: state.isSearching
                ? Padding(
                    padding: EdgeInsets.all(14.w),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchNotifierProvider.notifier).onQueryChanged('');
                        },
                      )
                    : null),
            isDense: true,
          ),
        ),
      ),
      body: state.hasSearched ? _buildResults(state) : _buildSuggestions(state),
    );
  }

  Widget _buildSuggestions(SearchState state) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Recent Searches', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: state.recentSearches
              .map((term) => _SuggestionChip(label: term, icon: Icons.history_rounded, onTap: () => _selectSuggestion(term)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResults(SearchState state) {
    if (state.restaurantResults.isEmpty && state.productResults.isEmpty) {
      return const EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        message: 'Try searching with different keywords.',
      );
    }
    return ListView(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (state.restaurantResults.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Restaurants', style: Theme.of(context).textTheme.titleMedium),
          ),
          ...state.restaurantResults.map((r) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: AppImage(url: r.logoUrl, width: 44, height: 44),
                ),
                title: Text(r.name),
                subtitle: Text('★ ${r.rating}'),
                onTap: () => _openRestaurant(r.id),
              )),
          const Divider(height: 24),
        ],
        if (state.productResults.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Dishes', style: Theme.of(context).textTheme.titleMedium),
          ),
          ...state.productResults.map((p) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: AppImage(url: p.imageUrl, width: 44, height: 44),
                ),
                title: Text(p.name),
                subtitle: Text(p.restaurantName),
                trailing: Text('\$${p.effectivePrice.toStringAsFixed(2)}'),
              )),
        ],
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            SizedBox(width: 6.w),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
