import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:foodie_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../helpers/fake_local_api_client.dart';

const _seededEmail = 'seed@foodie.com';
const _seededPasswordHash =
    '3edb4f4bd30723ad8cbb671a836684b11ce36c42aa8c4dfc06ac9414a1bf692e'; // "Password123"

void main() {
  late FakeLocalApiClient storage;
  late AuthRepositoryImpl repository;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    storage = FakeLocalApiClient({
      'users.json': [
        {
          'id': 'user_1',
          'email': _seededEmail,
          'password_hash': _seededPasswordHash,
          'full_name': 'Seed User',
        },
      ],
    });

    repository = AuthRepositoryImpl(
      local: AuthLocalDataSource(storage),
      prefs: SharedPreferencesAsync(),
    );
  });

  group('AuthRepositoryImpl.register', () {
    test('appends a new user and returns their profile', () async {
      final result = await repository.register(
          'New Person', 'new@foodie.com', 'password123');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.email, 'new@foodie.com');
      expect(storage.peek('users.json'), hasLength(2));
    });

    test(
        'returns ConflictFailure and does not touch the file for a duplicate email',
        () async {
      final before = storage.peek('users.json');

      final result = await repository.register(
          'Someone Else', _seededEmail, 'password123');

      expect(result.failureOrNull, isA<ConflictFailure>());
      expect(storage.peek('users.json'), before);
    });
  });

  group('AuthRepositoryImpl.login', () {
    test('returns NotFoundFailure for an unknown email', () async {
      final result = await repository.login('nobody@foodie.com', 'whatever');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
        'returns a generic ValidationFailure for a wrong password (not "email not found")',
        () async {
      final result = await repository.login(_seededEmail, 'wrong-password');

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('succeeds and persists a session for correct credentials', () async {
      final result = await repository.login(_seededEmail, 'Password123');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.userId, 'user_1');

      final restored = await repository.restoreSession();
      expect(restored.valueOrNull?.userId, 'user_1');
    });
  });

  group('AuthRepositoryImpl.restoreSession / logout', () {
    test('restoreSession returns Ok(null) when nothing was ever logged in',
        () async {
      final result = await repository.restoreSession();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('logout clears the persisted session', () async {
      await repository.login(_seededEmail, 'Password123');
      await repository.logout();

      final result = await repository.restoreSession();
      expect(result.valueOrNull, isNull);
    });
  });
}
