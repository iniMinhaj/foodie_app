import 'package:equatable/equatable.dart';

enum PaymentMethodType { cod, card, wallet }

class PaymentMethod extends Equatable {
  final String id;
  final PaymentMethodType type;

  /// Display label the data layer derives from the richer real fields
  /// (card brand/last4, wallet provider, ...) — the domain layer only
  /// needs the one string to render.
  final String label;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [id, type, label, isDefault];
}
