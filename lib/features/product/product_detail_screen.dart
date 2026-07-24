import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cart_service.dart';
import '../../core/widgets/app_image.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../cart/cart_screen.dart';

/// TODO: Riverpod - this is the screen with the most "logic" in the whole
/// app, and also the cleanest Riverpod migration target: everything below
/// (`_selectedVariations`, `_selectedExtras`, `_quantity`, `_unitPrice`)
/// becomes one immutable `ProductConfigState`, mutated through a
/// `ProductConfigNotifier` scoped to this product via
/// `.family(product.id)`. The price getter becomes a `Provider` derived
/// from that notifier, so the price line rebuilds independently of the
/// option list. `_validateRequiredGroups` becomes a plain function the
/// notifier calls before emitting an "add to cart" side effect.
class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // groupId -> selected optionId (single-select variation groups)
  final Map<String, String> _selectedVariations = {};
  // groupId -> set of selected optionIds (multi-select extra groups)
  final Map<String, Set<String>> _selectedExtras = {};
  final _instructionsController = TextEditingController();

  int _quantity = 1;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    // Pre-select defaults so the price shown on entry is already correct,
    // matching what the user would see on a real menu.
    for (final group in widget.product.variationGroups) {
      final defaultOption = group.options.where((o) => o.isDefault).toList();
      if (defaultOption.isNotEmpty) {
        _selectedVariations[group.id] = defaultOption.first.id;
      } else if (group.isRequired && group.options.isNotEmpty) {
        _selectedVariations[group.id] = group.options.first.id;
      }
    }
    for (final group in widget.product.extraGroups) {
      _selectedExtras[group.id] = {};
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  double get _unitPrice {
    double price = widget.product.displayPrice;
    for (final group in widget.product.variationGroups) {
      final selectedId = _selectedVariations[group.id];
      if (selectedId == null) continue;
      final option = group.options.firstWhere((o) => o.id == selectedId);
      price += option.priceDelta;
    }
    for (final group in widget.product.extraGroups) {
      final selectedIds = _selectedExtras[group.id] ?? {};
      for (final option in group.options.where((o) => selectedIds.contains(o.id))) {
        price += option.priceDelta;
      }
    }
    return price;
  }

  double get _totalPrice => _unitPrice * _quantity;

  /// Every required variation group must have a selection before "Add to
  /// cart" is allowed - mirrors how a real backend would reject an
  /// incomplete order payload, but caught client-side first.
  List<String> get _missingRequiredGroups {
    return widget.product.variationGroups
        .where((g) => g.isRequired && _selectedVariations[g.id] == null)
        .map((g) => g.name)
        .toList();
  }

  void _onVariationSelected(String groupId, String optionId) {
    setState(() => _selectedVariations[groupId] = optionId);
  }

  void _onExtraToggled(OptionGroup group, String optionId) {
    setState(() {
      final current = _selectedExtras[group.id] ?? {};
      if (current.contains(optionId)) {
        current.remove(optionId);
      } else {
        final maxSelectable = group.maxSelectable;
        if (maxSelectable != null && current.length >= maxSelectable) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You can select up to $maxSelectable options for ${group.name}')),
          );
          return;
        }
        current.add(optionId);
      }
      _selectedExtras[group.id] = current;
    });
  }

  void _onAddToCart() {
    if (_missingRequiredGroups.isNotEmpty) {
      setState(() => _showValidationErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select: ${_missingRequiredGroups.join(', ')}')),
      );
      return;
    }

    final variations = <SelectedOption>[];
    for (final group in widget.product.variationGroups) {
      final selectedId = _selectedVariations[group.id];
      if (selectedId == null) continue;
      final option = group.options.firstWhere((o) => o.id == selectedId);
      variations.add(SelectedOption(
        groupId: group.id,
        groupName: group.name,
        optionId: option.id,
        optionLabel: option.label,
        priceDelta: option.priceDelta,
      ));
    }

    final extras = <SelectedOption>[];
    for (final group in widget.product.extraGroups) {
      final selectedIds = _selectedExtras[group.id] ?? {};
      for (final option in group.options.where((o) => selectedIds.contains(o.id))) {
        extras.add(SelectedOption(
          groupId: group.id,
          groupName: group.name,
          optionId: option.id,
          optionLabel: option.label,
          priceDelta: option.priceDelta,
        ));
      }
    }

    CartService.instance.addItem(CartItemModel(
      cartItemId: '${widget.product.id}_${DateTime.now().microsecondsSinceEpoch}',
      product: widget.product,
      quantity: _quantity,
      selectedVariations: variations,
      selectedExtras: extras,
      specialInstructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240.h,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: AppImage(url: product.primaryImage, width: double.infinity, height: 240.h, borderRadius: BorderRadius.zero),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                      SizedBox(width: 2.w),
                      Text('${product.rating} (${product.totalReviews})', style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 2.w),
                      Text('${product.preparationTimeMinutes} min', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(product.description, style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(height: AppSpacing.md),
                  const Divider(),

                  for (final group in product.variationGroups) ...[
                    _VariationGroupSection(
                      group: group,
                      selectedOptionId: _selectedVariations[group.id],
                      onSelected: (optionId) => _onVariationSelected(group.id, optionId),
                      showError: _showValidationErrors && group.isRequired && _selectedVariations[group.id] == null,
                    ),
                    const Divider(),
                  ],

                  for (final group in product.extraGroups) ...[
                    _ExtraGroupSection(
                      group: group,
                      selectedOptionIds: _selectedExtras[group.id] ?? {},
                      onToggled: (optionId) => _onExtraToggled(group, optionId),
                    ),
                    const Divider(),
                  ],

                  SizedBox(height: AppSpacing.sm),
                  Text('Special Instructions (optional)', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _instructionsController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'e.g. Less spicy, no onions'),
                  ),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            _QuantityStepper(
              quantity: _quantity,
              onChanged: (q) => setState(() => _quantity = q),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.product.isAvailable ? _onAddToCart : null,
                child: Text('Add to cart • \$${_totalPrice.toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariationGroupSection extends StatelessWidget {
  final OptionGroup group;
  final String? selectedOptionId;
  final ValueChanged<String> onSelected;
  final bool showError;

  const _VariationGroupSection({
    required this.group,
    required this.selectedOptionId,
    required this.onSelected,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(group.name, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(width: 6.w),
              if (group.isRequired)
                Text('• Required', style: TextStyle(fontSize: 11.sp, color: showError ? AppColors.error : AppColors.textMuted)),
            ],
          ),
          SizedBox(height: 4.h),
          ...group.options.map((option) {
            final isSelected = selectedOptionId == option.id;
            return RadioListTile<String>(
              value: option.id,
              groupValue: selectedOptionId,
              onChanged: (value) => onSelected(value!),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              title: Text(option.label, style: Theme.of(context).textTheme.bodyLarge),
              secondary: option.priceDelta > 0
                  ? Text('+\$${option.priceDelta.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium)
                  : null,
              selected: isSelected,
            );
          }),
        ],
      ),
    );
  }
}

class _ExtraGroupSection extends StatelessWidget {
  final OptionGroup group;
  final Set<String> selectedOptionIds;
  final ValueChanged<String> onToggled;

  const _ExtraGroupSection({
    required this.group,
    required this.selectedOptionIds,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(group.name, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(width: 6.w),
              if (group.maxSelectable != null)
                Text('• up to ${group.maxSelectable}', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
            ],
          ),
          SizedBox(height: 4.h),
          ...group.options.map((option) {
            final isSelected = selectedOptionIds.contains(option.id);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (_) => onToggled(option.id),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              title: Text(option.label, style: Theme.of(context).textTheme.bodyLarge),
              secondary: Text('+\$${option.priceDelta.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
            );
          }),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 24.w,
            child: Text('$quantity', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}
