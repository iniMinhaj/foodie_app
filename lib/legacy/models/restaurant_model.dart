class RestaurantModel {
  final String id;
  final String name;
  final String logoUrl;
  final String coverUrl;
  final double rating;
  final int totalReviews;
  final String priceRange;
  final int deliveryMinMinutes;
  final int deliveryMaxMinutes;
  final double deliveryFee;
  final bool isOpen;
  final bool isPromoted;
  final double distanceKm;
  final List<String> tags;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.coverUrl,
    required this.rating,
    required this.totalReviews,
    required this.priceRange,
    required this.deliveryMinMinutes,
    required this.deliveryMaxMinutes,
    required this.deliveryFee,
    required this.isOpen,
    required this.isPromoted,
    required this.distanceKm,
    required this.tags,
  });

  String get deliveryTimeLabel => '$deliveryMinMinutes-$deliveryMaxMinutes min';

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    final deliveryTime = json['delivery_time_minutes'] as Map<String, dynamic>? ?? {};
    return RestaurantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      priceRange: json['price_range'] as String? ?? '\$',
      deliveryMinMinutes: deliveryTime['min'] as int? ?? 20,
      deliveryMaxMinutes: deliveryTime['max'] as int? ?? 40,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['is_open'] as bool? ?? true,
      isPromoted: json['is_promoted'] as bool? ?? false,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    );
  }
}
