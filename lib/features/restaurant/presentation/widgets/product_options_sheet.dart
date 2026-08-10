import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/entities/cart_item.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cart/presentation/utils/add_to_cart.dart';

const _uuid = Uuid();

/// Entry point for the "has variations/extras" add path — a product detail
/// picker shown as a modal sheet (not a full screen push) so choosing
/// options and adding to cart stays a single motion from the menu list.
void showProductOptionsSheet(BuildContext context, Product product) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProductOptionsSheet(product: product),
  );
}

class ProductOptionsSheet extends ConsumerStatefulWidget {
  final Product product;
  const ProductOptionsSheet({super.key, required this.product});

  @override
  ConsumerState<ProductOptionsSheet> createState() => _ProductOptionsSheetState();
}

class _ProductOptionsSheetState extends ConsumerState<ProductOptionsSheet> {
  // groupId -> selected choice ids. Single-select groups (maxSelect <= 1)
  // are just represented as a set that never grows past size 1 — one map
  // covers both radio- and checkbox-style groups without extra bookkeeping.
  final Map<String, Set<String>> _selections = {};
  int _quantity = 1;
  bool _showValidationErrors = false;

  List<OptionGroup> get _allGroups => [...widget.product.variationGroups, ...widget.product.extraGroups];

  @override
  void initState() {
    super.initState();
    // Pre-select defaults so the price shown on entry already matches what
    // a real menu would show, mirroring the legacy Product Detail screen.
    for (final group in _allGroups) {
      final defaults = group.choices.where((c) => c.isDefault).map((c) => c.id).toSet();
      if (defaults.isNotEmpty) {
        _selections[group.id] = defaults;
      } else if (group.isRequired && group.maxSelect <= 1 && group.choices.isNotEmpty) {
        _selections[group.id] = {group.choices.first.id};
      }
    }
  }

  double get _unitPrice {
    double price = widget.product.effectivePrice;
    for (final group in _allGroups) {
      final selectedIds = _selections[group.id] ?? const {};
      for (final choice in group.choices.where((c) => selectedIds.contains(c.id))) {
        price += choice.priceDelta;
      }
    }
    return price;
  }

  double get _totalPrice => _unitPrice * _quantity;

  int _selectedCount(OptionGroup group) => (_selections[group.id] ?? const {}).length;

  List<String> get _missingRequiredGroups =>
      _allGroups.where((g) => g.minSelect > 0 && _selectedCount(g) < g.minSelect).map((g) => g.name).toList();

  void _onOptionToggle(OptionGroup group, String optionId) {
    setState(() {
      final current = Set<String>.from(_selections[group.id] ?? const {});
      if (group.maxSelect <= 1) {
        _selections[group.id] = {optionId};
        return;
      }
      if (current.contains(optionId)) {
        current.remove(optionId);
      } else {
        if (current.length >= group.maxSelect) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You can select up to ${group.maxSelect} options for ${group.name}')),
          );
          return;
        }
        current.add(optionId);
      }
      _selections[group.id] = current;
    });
  }

  List<CartItemOption> _selectedOptionsFor(OptionGroup group) {
    final selectedIds = _selections[group.id] ?? const {};
    return group.choices
        .where((c) => selectedIds.contains(c.id))
        .map((c) => CartItemOption(
              groupId: group.id,
              groupName: group.name,
              choiceId: c.id,
              choiceLabel: c.label,
              priceDelta: c.priceDelta,
            ))
        .toList();
  }

  Future<void> _addToCart() async {
    if (_missingRequiredGroups.isNotEmpty) {
      setState(() => _showValidationErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select: ${_missingRequiredGroups.join(', ')}')),
      );
      return;
    }

    final product = widget.product;
    final item = CartItem(
      id: _uuid.v4(),
      productId: product.id,
      restaurantId: product.restaurantId,
      productName: product.name,
      productImageUrl: product.imageUrl,
      unitBasePrice: product.effectivePrice,
      quantity: _quantity,
      selectedVariations: product.variationGroups.expand(_selectedOptionsFor).toList(),
      selectedExtras: product.extraGroups.expand(_selectedOptionsFor).toList(),
    );

    await addToCart(context, ref, item);
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.sm),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppSpacing.md),
                  children: [
                    Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                    if (product.description.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.xs),
                      Text(product.description, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    for (final group in product.variationGroups)
                      _OptionGroupSection(
                        group: group,
                        selectedIds: _selections[group.id] ?? const {},
                        onToggle: (optionId) => _onOptionToggle(group, optionId),
                        showError: _showValidationErrors && group.minSelect > 0 && _selectedCount(group) < group.minSelect,
                      ),
                    for (final group in product.extraGroups)
                      _OptionGroupSection(
                        group: group,
                        selectedIds: _selections[group.id] ?? const {},
                        onToggle: (optionId) => _onOptionToggle(group, optionId),
                        showError: _showValidationErrors && group.minSelect > 0 && _selectedCount(group) < group.minSelect,
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      _QuantityStepper(quantity: _quantity, onChanged: (q) => setState(() => _quantity = q)),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addToCart,
                          child: Text('Add to cart • \$${_totalPrice.toStringAsFixed(2)}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OptionGroupSection extends StatelessWidget {
  final OptionGroup group;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final bool showError;

  const _OptionGroupSection({
    required this.group,
    required this.selectedIds,
    required this.onToggle,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    final isSingleSelect = group.maxSelect <= 1;
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
                Text(
                  '• Required',
                  style: TextStyle(fontSize: 11.sp, color: showError ? AppColors.error : AppColors.textMuted),
                )
              else if (!isSingleSelect)
                Text('• up to ${group.maxSelect}', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
            ],
          ),
          SizedBox(height: 4.h),
          for (final choice in group.choices)
            isSingleSelect
                ? RadioListTile<String>(
                    value: choice.id,
                    groupValue: selectedIds.isEmpty ? null : selectedIds.first,
                    onChanged: (value) => onToggle(value!),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    title: Text(choice.label, style: Theme.of(context).textTheme.bodyLarge),
                    secondary: choice.priceDelta > 0
                        ? Text('+\$${choice.priceDelta.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium)
                        : null,
                  )
                : CheckboxListTile(
                    value: selectedIds.contains(choice.id),
                    onChanged: (_) => onToggle(choice.id),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                    title: Text(choice.label, style: Theme.of(context).textTheme.bodyLarge),
                    secondary: choice.priceDelta > 0
                        ? Text('+\$${choice.priceDelta.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium)
                        : null,
                  ),
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
