enum SelectionType { single, multiple }

SelectionType _parseSelectionType(String? raw) {
  return raw == 'multiple' ? SelectionType.multiple : SelectionType.single;
}

class OptionItem {
  final String id;
  final String label;
  final double priceDelta;
  final bool isDefault;

  const OptionItem({
    required this.id,
    required this.label,
    required this.priceDelta,
    this.isDefault = false,
  });

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    return OptionItem(
      id: json['id'] as String,
      label: json['label'] as String,
      priceDelta: (json['price_delta'] as num?)?.toDouble() ?? 0.0,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

/// Shared shape for both "variation_groups" (e.g. Size, Spice Level) and
/// "extra_groups" (e.g. Add-ons) - the JSON schema is identical, so one
/// model covers both. `isRequired` + `selectionType` drive the UI rules
/// (radio vs checkbox, must-pick-one validation before "Add to cart").
class OptionGroup {
  final String id;
  final String name;
  final SelectionType selectionType;
  final bool isRequired;
  final int? maxSelectable;
  final List<OptionItem> options;

  const OptionGroup({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.isRequired,
    required this.options,
    this.maxSelectable,
  });

  factory OptionGroup.fromJson(Map<String, dynamic> json) {
    return OptionGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      selectionType: _parseSelectionType(json['selection_type'] as String?),
      isRequired: json['is_required'] as bool? ?? false,
      maxSelectable: json['max_selectable'] as int?,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => OptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final List<String> imageUrls;
  final double basePrice;
  final double? discountPrice;
  final bool isAvailable;
  final bool isFeatured;
  final double rating;
  final int totalReviews;
  final int preparationTimeMinutes;
  final List<String> tags;
  final List<OptionGroup> variationGroups;
  final List<OptionGroup> extraGroups;

  const ProductModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.basePrice,
    required this.discountPrice,
    required this.isAvailable,
    required this.isFeatured,
    required this.rating,
    required this.totalReviews,
    required this.preparationTimeMinutes,
    required this.tags,
    required this.variationGroups,
    required this.extraGroups,
  });

  /// Effective starting price shown on cards (discount takes priority).
  double get displayPrice => discountPrice ?? basePrice;

  bool get hasDiscount => discountPrice != null && discountPrice! < basePrice;

  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrls: (json['image_urls'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      isAvailable: json['is_available'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      preparationTimeMinutes: json['preparation_time_minutes'] as int? ?? 15,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      variationGroups: (json['variation_groups'] as List<dynamic>? ?? [])
          .map((e) => OptionGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      extraGroups: (json['extra_groups'] as List<dynamic>? ?? [])
          .map((e) => OptionGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
