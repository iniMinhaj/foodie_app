import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/mock_data_loader.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/state_views.dart';

/// TODO: Riverpod - the `Timer` + `setState` debounce pattern here becomes
/// a `debounce` inside a `SearchNotifier`, typically using `Future.delayed`
/// inside `ref.debounce` or a Stream-based `.debounceTime` if using
/// rxdart. The 400ms constant and the "cancel previous timer" logic is
/// exactly what moves into the notifier - the TextField widget itself
/// barely changes.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;

  bool _isSearching = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _restaurantResults = [];
  List<Map<String, dynamic>> _productResults = [];
  List<String> _recentSearches = ['biryani', 'pizza', 'burger deals'];
  List<String> _trendingSearches = [];

  static const _debounceDuration = Duration(milliseconds: 400);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _isSearching = false;
        _restaurantResults = [];
        _productResults = [];
      });
      return;
    }

    // Show "typing" state immediately, but delay the actual "search" call
    // until the user pauses - this is the core debounce behavior.
    setState(() => _isSearching = true);

    _debounceTimer = Timer(_debounceDuration, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final result = await MockDataLoader.instance.search(query);
    if (!mounted) return;
    final data = result['data'] as Map<String, dynamic>;
    setState(() {
      _restaurantResults = List<Map<String, dynamic>>.from(data['restaurants'] as List);
      _productResults = List<Map<String, dynamic>>.from(data['products'] as List);
      _trendingSearches = List<String>.from(data['trending_searches'] as List);
      _isSearching = false;
      _hasSearched = true;
    });
  }

  void _selectSuggestion(String term) {
    _controller.text = term;
    _onQueryChanged(term);
    // Skip the debounce wait for an explicit tap - search immediately.
    _debounceTimer?.cancel();
    _runSearch(term);
    setState(() {
      if (!_recentSearches.contains(term)) {
        _recentSearches = [term, ..._recentSearches].take(5).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search restaurants or dishes',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _isSearching
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
                          _onQueryChanged('');
                        },
                      )
                    : null),
            isDense: true,
          ),
        ),
      ),
      body: _hasSearched ? _buildResults() : _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Recent Searches', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _recentSearches.map((term) => _SuggestionChip(label: term, icon: Icons.history_rounded, onTap: () => _selectSuggestion(term))).toList(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_restaurantResults.isEmpty && _productResults.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        message: 'Try searching with different keywords.',
      );
    }
    return ListView(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (_restaurantResults.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Restaurants', style: Theme.of(context).textTheme.titleMedium),
          ),
          ..._restaurantResults.map((r) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: AppImage(url: r['logo_url'] as String, width: 44, height: 44),
                ),
                title: Text(r['name'] as String),
                subtitle: Text('★ ${r['rating']}'),
              )),
          const Divider(height: 24),
        ],
        if (_productResults.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Dishes', style: Theme.of(context).textTheme.titleMedium),
          ),
          ..._productResults.map((p) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: AppImage(url: p['image_url'] as String, width: 44, height: 44),
                ),
                title: Text(p['name'] as String),
                subtitle: Text(p['restaurant_name'] as String),
                trailing: Text('\$${p['discount_price'] ?? p['base_price']}'),
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
