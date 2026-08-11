import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/storage/asset_seeder.dart';
import 'package:foodie_app/features/auth/domain/entities/user_profile.dart';
import 'package:foodie_app/features/profile/data/datasources/local/profile_local_datasource.dart';
import 'package:foodie_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../../helpers/fake_local_api_client.dart';
import '../../../../helpers/fake_path_provider.dart';

Map<String, dynamic> _userJson(String id) => {
      'id': id,
      'email': '$id@foodie.com',
      'password_hash': 'hash',
      'full_name': 'User $id',
      'addresses': <Map<String, dynamic>>[],
      'payment_methods': <Map<String, dynamic>>[],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalApiClient storage;
  late ProfileRepositoryImpl repository;

  setUp(() {
    storage = FakeLocalApiClient({
      'users.json': [_userJson('user_1')],
    });
    repository = ProfileRepositoryImpl(
      local: ProfileLocalDataSource(storage),
      seeder: AssetSeeder(),
    );
  });

  group('ProfileRepositoryImpl.getProfile', () {
    test('returns the matching profile', () async {
      final result = await repository.getProfile('user_1');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.name, 'User user_1');
    });

    test('returns NotFoundFailure for an unknown id', () async {
      final result = await repository.getProfile('ghost');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('ProfileRepositoryImpl.saveProfile', () {
    test('persists the profile and returns it back', () async {
      const updated = UserProfile(
        id: 'user_1',
        name: 'Updated Name',
        email: 'user_1@foodie.com',
        phone: '',
        avatarUrl: '',
        addresses: [],
      );

      final result = await repository.saveProfile(updated);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.name, 'Updated Name');
      expect(storage.peek('users.json')!.single['full_name'], 'Updated Name');
    });
  });

  group('ProfileRepositoryImpl.resetDemoData', () {
    test('reseeds the mock files via AssetSeeder(force: true)', () async {
      final tempDir = await Directory.systemTemp.createTemp('profile_repo_test');
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);

      final result = await repository.resetDemoData();

      expect(result.isOk, isTrue);
      expect(await File('${tempDir.path}/mock/users.json').exists(), isTrue);
    });
  });
}
