import 'package:equatable/equatable.dart';

import '../../../../core/entities/address.dart';

class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final List<Address> addresses;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.addresses,
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
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, avatarUrl, addresses];
}
