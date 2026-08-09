import 'package:equatable/equatable.dart';

class OptionChoice extends Equatable {
  final String id;
  final String label;
  final double priceDelta;

  const OptionChoice({required this.id, required this.label, required this.priceDelta});

  @override
  List<Object?> get props => [id, label, priceDelta];
}

/// `maxSelect == 1` renders as a radio group, `> 1` as a checkbox group.
class OptionGroup extends Equatable {
  final String id;
  final String name;
  final bool isRequired;
  final int minSelect;
  final int maxSelect;
  final List<OptionChoice> choices;

  const OptionGroup({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.minSelect,
    required this.maxSelect,
    required this.choices,
  });

  @override
  List<Object?> get props => [id, name, isRequired, minSelect, maxSelect, choices];
}

class Product extends Equatable {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final String imageUrl;
  final double basePrice;
  final double? discountPrice;
  final bool isAvailable;

  /// Kept as two separate lists (not one merged `optionGroups`) because
  /// the real menu data — and the UI — treats "Size" and "Add-ons" as
  /// distinct sections with different copy, not one undifferentiated list.
  final List<OptionGroup> variationGroups;
  final List<OptionGroup> extraGroups;

  const Product({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
    required this.discountPrice,
    required this.isAvailable,
    required this.variationGroups,
    required this.extraGroups,
  });

  double get effectivePrice => discountPrice ?? basePrice;

  bool get hasDiscount => discountPrice != null && discountPrice! < basePrice;

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        name,
        description,
        imageUrl,
        basePrice,
        discountPrice,
        isAvailable,
        variationGroups,
        extraGroups,
      ];
}
