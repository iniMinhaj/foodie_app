import '../../../../core/entities/address.dart';
import '../../../../core/entities/user_profile.dart';

/// Full-fidelity model for one row of `users.json`. Carries fields Auth
/// itself never reads (`loyaltyPoints`, `paymentMethods`, `preferences`,
/// ...) so that when the Auth repository rewrites the *whole* file via
/// `JsonStorageService.writeCollection`, every other user's profile data
/// round-trips unchanged instead of being silently dropped.
class UserModel {
  final String id;
  final String email;
  final String passwordHash;
  final String fullName;
  final String phone;
  final String avatarUrl;
  final String? memberSince;
  final int loyaltyPoints;
  final String? defaultAddressId;
  final List<Address> addresses;
  final List<Map<String, dynamic>> paymentMethods;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.fullName,
    this.phone = '',
    this.avatarUrl = '',
    this.memberSince,
    this.loyaltyPoints = 0,
    this.defaultAddressId,
    this.addresses = const [],
    this.paymentMethods = const [],
    this.preferences = const {},
  });

  UserProfile toEntity() => UserProfile(
        id: id,
        name: fullName,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
        addresses: addresses,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      passwordHash: json['password_hash'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      memberSince: json['member_since'] as String?,
      loyaltyPoints: json['loyalty_points'] as int? ?? 0,
      defaultAddressId: json['default_address_id'] as String?,
      addresses: (json['addresses'] as List<dynamic>? ?? [])
          .map((e) => _addressFromJson(e as Map<String, dynamic>))
          .toList(),
      paymentMethods: (json['payment_methods'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>(),
      preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password_hash': passwordHash,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'member_since': memberSince,
        'loyalty_points': loyaltyPoints,
        'default_address_id': defaultAddressId,
        'addresses': addresses.map(_addressToJson).toList(),
        'payment_methods': paymentMethods,
        'preferences': preferences,
      };

  static Address _addressFromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        line1: json['line1'] as String? ?? '',
        city: json['city'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
      );

  static Map<String, dynamic> _addressToJson(Address address) => {
        'id': address.id,
        'label': address.label,
        'line1': address.line1,
        'city': address.city,
        'is_default': address.isDefault,
      };
}
