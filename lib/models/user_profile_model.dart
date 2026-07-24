class AddressModel {
  final String id;
  final String label;
  final String line1;
  final String city;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      label: json['label'] as String,
      line1: json['line1'] as String,
      city: json['city'] as String,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

class UserProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final int loyaltyPoints;
  final List<AddressModel> addresses;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.loyaltyPoints,
    required this.addresses,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      avatarUrl: json['avatar_url'] as String? ?? '',
      loyaltyPoints: json['loyalty_points'] as int? ?? 0,
      addresses: (json['addresses'] as List<dynamic>? ?? [])
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
