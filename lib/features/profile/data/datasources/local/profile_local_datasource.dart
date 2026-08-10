import '../../../../../core/entities/address.dart';
import '../../../../../core/storage/local_api_client.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../../auth/domain/entities/user_profile.dart';

/// Reuses Auth's [UserModel] to parse/serialize `users.json` rows — same
/// file, same full-fidelity shape — rather than duplicating that parsing
/// here (mirrors how `CatalogRepository` is reused as-is by Search; see
/// `docs/MIGRATION_STATUS.md`). Only `full_name`/`phone`/`avatar_url`/
/// `addresses` (and the `default_address_id` derived from them) are ever
/// rewritten — every other field (password hash, loyalty points, payment
/// methods, preferences) round-trips untouched, the same "preserve keys
/// this module doesn't own" discipline `CartLocalDataSource` uses.
class ProfileLocalDataSource {
  final LocalApiClient storage;
  static const _fileName = 'users.json';

  const ProfileLocalDataSource(this.storage);

  Future<UserProfile?> getProfile(String userId) async {
    final rows = await storage.readCollection(_fileName);
    for (final row in rows) {
      final user = UserModel.fromJson(row);
      if (user.id == userId) return user.toEntity();
    }
    return null;
  }

  Future<void> saveProfile(UserProfile profile) async {
    final rows = await storage.readCollection(_fileName);
    final index = rows.indexWhere((row) => row['id'] == profile.id);
    if (index == -1) {
      throw JsonStorageException('User ${profile.id} not found');
    }

    final existing = UserModel.fromJson(rows[index]);
    final updated = UserModel(
      id: existing.id,
      email: existing.email,
      passwordHash: existing.passwordHash,
      fullName: profile.name,
      phone: profile.phone,
      avatarUrl: profile.avatarUrl,
      memberSince: existing.memberSince,
      loyaltyPoints: existing.loyaltyPoints,
      defaultAddressId: _defaultAddressId(profile.addresses),
      addresses: profile.addresses,
      paymentMethods: existing.paymentMethods,
      preferences: existing.preferences,
    );

    final next = [...rows];
    next[index] = updated.toJson();
    await storage.writeCollection(_fileName, next);
  }

  String? _defaultAddressId(List<Address> addresses) {
    for (final address in addresses) {
      if (address.isDefault) return address.id;
    }
    return null;
  }
}
