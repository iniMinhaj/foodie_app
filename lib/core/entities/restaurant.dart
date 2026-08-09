import 'package:equatable/equatable.dart';

class Restaurant extends Equatable {
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

  const Restaurant({
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

  /// e.g. "25-40 min" — the two-number range is real data, not a single
  /// average, so both bounds are kept up through the domain layer.
  String get etaLabel => '$etaMinMinutes-$etaMaxMinutes min';

  @override
  List<Object?> get props => [
        id,
        name,
        coverImageUrl,
        logoUrl,
        cuisineTags,
        rating,
        etaMinMinutes,
        etaMaxMinutes,
        deliveryFee,
        isOpen,
        categoryIds,
      ];
}
