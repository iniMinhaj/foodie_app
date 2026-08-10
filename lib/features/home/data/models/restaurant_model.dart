import '../../../../core/entities/restaurant.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String coverImageUrl;
  final String logoUrl;
  final List<String> cuisineTags;
  final double rating;
  final int etaMinMinutes;
  final int etaMaxMinutes;
  final double deliveryFee;
  final bool isOpen;
  final List<String> categoryIds;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.coverImageUrl,
    required this.logoUrl,
    required this.cuisineTags,
    required this.rating,
    required this.etaMinMinutes,
    required this.etaMaxMinutes,
    required this.deliveryFee,
    required this.isOpen,
    required this.categoryIds,
  });

  Restaurant toEntity() => Restaurant(
        id: id,
        name: name,
        coverImageUrl: coverImageUrl,
        logoUrl: logoUrl,
        cuisineTags: cuisineTags,
        rating: rating,
        etaMinMinutes: etaMinMinutes,
        etaMaxMinutes: etaMaxMinutes,
        deliveryFee: deliveryFee,
        isOpen: isOpen,
        categoryIds: categoryIds,
      );

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    final deliveryTime =
        json['delivery_time_minutes'] as Map<String, dynamic>? ?? const {};
    return RestaurantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      coverImageUrl: json['cover_url'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
      cuisineTags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      etaMinMinutes: deliveryTime['min'] as int? ?? 0,
      etaMaxMinutes: deliveryTime['max'] as int? ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      isOpen: json['is_open'] as bool? ?? true,
      categoryIds: (json['category_ids'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
