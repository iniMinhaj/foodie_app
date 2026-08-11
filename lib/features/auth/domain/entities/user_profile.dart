import 'package:equatable/equatable.dart';

import '../../../../core/entities/address.dart';
import '../../../../core/entities/payment_method.dart';

/// Auth's own view of "the current user" — deliberately lean for
/// login/register/session-restore. [loyaltyPoints]/[memberSince]/
/// [paymentMethods] are populated too (Profile reuses this exact entity
/// rather than duplicating it — see `docs/MIGRATION_STATUS.md`), but Auth's
/// own logic never reads them, hence the defaults so existing Auth call
/// sites don't need to name them.
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final List<Address> addresses;
  final int loyaltyPoints;
  final DateTime? memberSince;
  final List<PaymentMethod> paymentMethods;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.addresses,
    this.loyaltyPoints = 0,
    this.memberSince,
    this.paymentMethods = const [],
  });

  UserProfile copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    List<Address>? addresses,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      addresses: addresses ?? this.addresses,
      loyaltyPoints: loyaltyPoints,
      memberSince: memberSince,
      paymentMethods: paymentMethods,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, email, phone, avatarUrl, addresses, loyaltyPoints, memberSince, paymentMethods];
}
