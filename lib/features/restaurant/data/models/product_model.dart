import '../../../../core/entities/product.dart';

class ProductModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final String imageUrl;
  final double basePrice;
  final double? discountPrice;
  final bool isAvailable;
  final String categoryName;
  final List<String> tags;
  final double rating;
  final List<OptionGroup> variationGroups;
  final List<OptionGroup> extraGroups;

  const ProductModel({
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

  Product toEntity() => Product(
        id: id,
        restaurantId: restaurantId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        basePrice: basePrice,
        discountPrice: discountPrice,
        isAvailable: isAvailable,
        categoryName: categoryName,
        tags: tags,
        rating: rating,
        variationGroups: variationGroups,
        extraGroups: extraGroups,
      );

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final imageUrls = json['image_urls'] as List<dynamic>? ?? const [];
    return ProductModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first as String : '',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      isAvailable: json['is_available'] as bool? ?? true,
      categoryName: json['menu_category'] as String? ?? 'Menu',
      tags: (json['tags'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      variationGroups: (json['variation_groups'] as List<dynamic>? ?? const [])
          .map((e) => _groupFromJson(e as Map<String, dynamic>))
          .toList(),
      extraGroups: (json['extra_groups'] as List<dynamic>? ?? const [])
          .map((e) => _groupFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static OptionGroup _groupFromJson(Map<String, dynamic> json) {
    final isRequired = json['is_required'] as bool? ?? false;
    final isSingleSelect = (json['selection_type'] as String? ?? 'single') == 'single';
    return OptionGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      isRequired: isRequired,
      minSelect: isRequired ? 1 : 0,
      maxSelect: isSingleSelect ? 1 : (json['max_selectable'] as int? ?? 1),
      choices: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => _choiceFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static OptionChoice _choiceFromJson(Map<String, dynamic> json) => OptionChoice(
        id: json['id'] as String,
        label: json['label'] as String,
        priceDelta: (json['price_delta'] as num?)?.toDouble() ?? 0,
        isDefault: json['is_default'] as bool? ?? false,
      );
}
