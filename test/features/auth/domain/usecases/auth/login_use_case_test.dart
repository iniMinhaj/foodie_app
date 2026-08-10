import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:foodie_app/features/auth/domain/usecases/login_use_case.dart';

import '../../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = LoginUseCase(repository);
  });

  group('LoginUseCase', () {
    test('returns NotFoundFailure when the repository reports no such email',
        () async {
      repository.nextLoginResult =
          const Result.err(NotFoundFailure('No account found for this email.'));

      final result =
          await useCase.call(email: 'missing@foodie.com', password: 'whatever');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
        'returns a ValidationFailure when the repository reports a wrong password',
        () async {
      repository.nextLoginResult = const Result.err(
          ValidationFailure('password', 'Incorrect password.'));

      final result =
          await useCase.call(email: 'test@foodie.com', password: 'wrong');

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('returns the SessionInfo on success', () async {
      repository.nextLoginResult =
          const Result.ok(SessionInfo(token: 't', userId: 'u'));

      final result =
          await useCase.call(email: 'test@foodie.com', password: 'right');

      expect(result.valueOrNull?.userId, 'u');
    });
  });
}
