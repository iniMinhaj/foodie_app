import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/entities/address.dart';
import 'package:foodie_app/core/storage/local_api_client.dart';
import 'package:foodie_app/features/auth/domain/entities/user_profile.dart';
import 'package:foodie_app/features/profile/data/datasources/local/profile_local_datasource.dart';

import '../../../../../helpers/fake_local_api_client.dart';

Map<String, dynamic> _userJson({String id = 'user_1'}) => {
      'id': id,
      'email': 'seed@foodie.com',
      'password_hash': 'super-secret-hash',
      'full_name': 'Seed User',
      'phone': '+8801700000000',
      'avatar_url': 'https://cdn.example.com/avatars/user_1.jpg',
      'member_since': '2024-03-11T00:00:00Z',
      'loyalty_points': 480,
      'default_address_id': 'addr_001',
      'addresses': [
        {'id': 'addr_001', 'label': 'Home', 'line1': 'House 22', 'city': 'Dhaka', 'is_default': true},
      ],
      'payment_methods': [
        {'id': 'pm_001', 'type': 'card', 'brand': 'visa', 'last4': '4242', 'is_default': true},
      ],
      'preferences': {'notifications_enabled': true},
    };

void main() {
  group('ProfileLocalDataSource.getProfile', () {
    test('parses the matching row into a UserProfile', () async {
      final storage = FakeLocalApiClient({
        'users.json': [_userJson(id: 'user_1'), _userJson(id: 'user_2')],
      });
      final datasource = ProfileLocalDataSource(storage);

      final profile = await datasource.getProfile('user_2');

      expect(profile, isNotNull);
      expect(profile!.id, 'user_2');
      expect(profile.name, 'Seed User');
      expect(profile.loyaltyPoints, 480);
      expect(profile.paymentMethods, hasLength(1));
      expect(profile.paymentMethods.single.label, 'Visa •••• 4242');
    });

    test('returns null when no user matches the id', () async {
      final storage = FakeLocalApiClient({'users.json': [_userJson()]});
      final datasource = ProfileLocalDataSource(storage);

      expect(await datasource.getProfile('ghost'), isNull);
    });
  });

  group('ProfileLocalDataSource.saveProfile', () {
    test('rewrites owned fields while preserving password hash / loyalty / payment methods', () async {
      final storage = FakeLocalApiClient({
        'users.json': [_userJson(id: 'user_1'), _userJson(id: 'user_2')],
      });
      final datasource = ProfileLocalDataSource(storage);

      const updated = UserProfile(
        id: 'user_1',
        name: 'New Name',
        email: 'seed@foodie.com',
        phone: '+8801900000000',
        avatarUrl: 'https://cdn.example.com/avatars/new.jpg',
        addresses: [
          Address(id: 'addr_002', label: 'Office', line1: 'Level 6', city: 'Dhaka', isDefault: true),
        ],
      );

      await datasource.saveProfile(updated);

      final rows = storage.peek('users.json')!;
      final written = rows.firstWhere((r) => r['id'] == 'user_1');
      expect(written['full_name'], 'New Name');
      expect(written['phone'], '+8801900000000');
      expect(written['avatar_url'], 'https://cdn.example.com/avatars/new.jpg');
      expect(written['default_address_id'], 'addr_002');
      expect((written['addresses'] as List).single['id'], 'addr_002');
      // Untouched by this module — round-tripped from the existing row.
      expect(written['password_hash'], 'super-secret-hash');
      expect(written['loyalty_points'], 480);
      expect(written['payment_methods'], _userJson()['payment_methods']);

      final other = rows.firstWhere((r) => r['id'] == 'user_2');
      expect(other['full_name'], 'Seed User');
    });

    test('throws JsonStorageException when the user id does not exist', () async {
      final storage = FakeLocalApiClient({'users.json': [_userJson(id: 'user_1')]});
      final datasource = ProfileLocalDataSource(storage);

      const updated = UserProfile(
        id: 'ghost',
        name: 'Nobody',
        email: 'nobody@foodie.com',
        phone: '',
        avatarUrl: '',
        addresses: [],
      );

      expect(() => datasource.saveProfile(updated), throwsA(isA<JsonStorageException>()));
    });
  });
}
