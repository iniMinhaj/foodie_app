import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String label;
  final String line1;
  final String city;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [id, label, line1, city, isDefault];
}
