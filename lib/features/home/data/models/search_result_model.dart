import '../../domain/repositories/catalog_repository.dart';

class SearchRestaurantModel {
  final String id;
  final String name;
  final String logoUrl;
  final double rating;

  const SearchRestaurantModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.rating,
  });

  factory SearchRestaurantModel.fromJson(Map<String, dynamic> json) => SearchRestaurantModel(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logo_url'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
      );

  SearchRestaurantResult toEntity() => SearchRestaurantResult(
        id: id,
        name: name,
        logoUrl: logoUrl,
        rating: rating,
      );
}

class SearchProductModel {
  final String id;
  final String name;
  final String restaurantId;
  final String restaurantName;
  final String imageUrl;
  final double basePrice;
  final double? discountPrice;

  const SearchProductModel({
    required this.id,
    required this.name,
    required this.restaurantId,
    required this.restaurantName,
    required this.imageUrl,
    required this.basePrice,
    required this.discountPrice,
  });

  factory SearchProductModel.fromJson(Map<String, dynamic> json) => SearchProductModel(
        id: json['id'] as String,
        name: json['name'] as String,
        restaurantId: json['restaurant_id'] as String? ?? '',
        restaurantName: json['restaurant_name'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
        discountPrice: (json['discount_price'] as num?)?.toDouble(),
      );

  SearchProductResult toEntity() => SearchProductResult(
        id: id,
        name: name,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        imageUrl: imageUrl,
        basePrice: basePrice,
        discountPrice: discountPrice,
      );
}
