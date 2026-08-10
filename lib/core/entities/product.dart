import 'package:equatable/equatable.dart';

class OptionChoice extends Equatable {
  final String id;
  final String label;
  final double priceDelta;

  /// Pre-selected when a product's options sheet first opens, so the shown
  /// price already reflects what a real menu would default to.
  final bool isDefault;

  const OptionChoice({
    required this.id,
    required this.label,
    required this.priceDelta,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, label, priceDelta, isDefault];
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

  /// The Zomato-style menu section this item is grouped under on the
  /// Restaurant Detail screen (e.g. "Recommended", "Main Course"). Distinct
  /// from `home`'s global cuisine categories (Pizza/Burger/...) — this is
  /// per-restaurant menu structure, not a cross-restaurant filter.
  final String categoryName;

  /// Small badges surfaced on the menu tile (e.g. "Bestseller", "Spicy",
  /// "Vegetarian") — "Vegetarian" also drives the veg/non-veg indicator dot.
  final List<String> tags;
  final double rating;

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
    required this.categoryName,
    required this.tags,
    required this.rating,
    required this.variationGroups,
    required this.extraGroups,
  });

  double get effectivePrice => discountPrice ?? basePrice;

  bool get hasDiscount => discountPrice != null && discountPrice! < basePrice;

  bool get isVegetarian => tags.contains('Vegetarian');

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
        categoryName,
        tags,
        rating,
        variationGroups,
        extraGroups,
      ];
}
