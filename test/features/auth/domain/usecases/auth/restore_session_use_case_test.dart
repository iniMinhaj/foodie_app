import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:foodie_app/features/auth/domain/usecases/auth/restore_session_use_case.dart';

import '../../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late RestoreSessionUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = RestoreSessionUseCase(repository);
  });

  group('RestoreSessionUseCase', () {
    test('returns Ok(null) when there is no persisted session', () async {
      repository.nextRestoreSessionResult = const Result.ok(null);

      final result = await useCase.call();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('resolves a persisted session token back into a UserProfile',
        () async {
      repository.nextRestoreSessionResult =
          const Result.ok(SessionInfo(token: 't', userId: 'user_1'));
      repository.nextGetUserByIdResult = const Result.ok(fakeUser);

      final result = await useCase.call();

      expect(result.valueOrNull, fakeUser);
    });

    test('propagates a failure from restoreSession() itself', () async {
      repository.nextRestoreSessionResult =
          const Result.err(UnknownFailure('disk error'));

      final result = await useCase.call();

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
    });

    test('propagates a failure from resolving the user by id', () async {
      repository.nextRestoreSessionResult =
          const Result.ok(SessionInfo(token: 't', userId: 'ghost'));
      repository.nextGetUserByIdResult =
          const Result.err(NotFoundFailure('gone'));

      final result = await useCase.call();

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
