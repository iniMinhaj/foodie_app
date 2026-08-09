import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:foodie_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:foodie_app/features/auth/presentation/providers/session_provider.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('AuthNotifier', () {
    test(
        'build() resolves to Unauthenticated when there is no persisted session',
        () async {
      final state = await container.read(authNotifierProvider.future);

      expect(state, isA<AuthUnauthenticated>());
      expect(container.read(sessionProvider), isFalse);
    });

    test('build() resolves to Authenticated when a session restores', () async {
      repository.nextRestoreSessionResult =
          const Result.ok(SessionInfo(token: 't', userId: 'user_1'));

      final state = await container.read(authNotifierProvider.future);

      expect(state, isA<AuthAuthenticated>());
      expect(container.read(sessionProvider), isTrue);
    });

    test(
        'login() success transitions to Authenticated and flips sessionProvider',
        () async {
      await container.read(authNotifierProvider.future);

      await container
          .read(authNotifierProvider.notifier)
          .login('test@foodie.com', 'password123');

      final state = container.read(authNotifierProvider);
      expect(state.value, isA<AuthAuthenticated>());
      expect(container.read(sessionProvider), isTrue);
    });

    test(
        'login() failure surfaces as AsyncError without flipping sessionProvider',
        () async {
      await container.read(authNotifierProvider.future);
      repository.nextLoginResult =
          const Result.err(NotFoundFailure('no such user'));

      await container
          .read(authNotifierProvider.notifier)
          .login('missing@foodie.com', 'x');

      final state = container.read(authNotifierProvider);
      expect(state.hasError, isTrue);
      expect(container.read(sessionProvider), isFalse);
    });

    test('logout() returns to Unauthenticated', () async {
      await container.read(authNotifierProvider.future);
      await container
          .read(authNotifierProvider.notifier)
          .login('test@foodie.com', 'password123');
      expect(container.read(sessionProvider), isTrue);

      await container.read(authNotifierProvider.notifier).logout();

      expect(container.read(sessionProvider), isFalse);
      expect(repository.logoutCalled, isTrue);
    });

    test(
        'register() success does not authenticate — state stays Unauthenticated',
        () async {
      await container.read(authNotifierProvider.future);

      await container
          .read(authNotifierProvider.notifier)
          .register('New', 'new@foodie.com', 'password123');

      final state = container.read(authNotifierProvider);
      expect(state.hasError, isFalse);
      expect(state.value, isA<AuthUnauthenticated>());
      expect(repository.registerCalled, isTrue);
    });

    test('register() failure (e.g. duplicate email) surfaces as AsyncError',
        () async {
      await container.read(authNotifierProvider.future);
      repository.nextRegisterResult =
          const Result.err(ConflictFailure('exists'));

      await container
          .read(authNotifierProvider.notifier)
          .register('New', 'dup@foodie.com', 'password123');

      final state = container.read(authNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<ConflictFailure>());
    });

    test('register() with an invalid email never reaches the repository',
        () async {
      await container.read(authNotifierProvider.future);

      await container
          .read(authNotifierProvider.notifier)
          .register('New', 'not-an-email', 'password123');

      expect(repository.registerCalled, isFalse);
      final state = container.read(authNotifierProvider);
      expect(state.error, isA<ValidationFailure>());
    });
  });
}
