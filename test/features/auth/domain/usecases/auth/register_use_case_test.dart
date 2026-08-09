import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/auth/domain/usecases/auth/register_use_case.dart';

import '../../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late RegisterUseCase useCase;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = RegisterUseCase(repository);
  });

  group('RegisterUseCase', () {
    test('rejects an empty name without calling the repository', () async {
      final result = await useCase.call(
          name: '  ', email: 'a@b.com', password: 'password123');

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).field, 'name');
      expect(repository.registerCalled, isFalse);
    });

    test('rejects a malformed email without calling the repository', () async {
      final result = await useCase.call(
          name: 'Tanvir', email: 'not-an-email', password: 'password123');

      expect(result.isErr, isTrue);
      expect((result.failureOrNull as ValidationFailure).field, 'email');
      expect(repository.registerCalled, isFalse);
    });

    test('rejects a too-short password without calling the repository',
        () async {
      final result =
          await useCase.call(name: 'Tanvir', email: 'a@b.com', password: '123');

      expect(result.isErr, isTrue);
      expect((result.failureOrNull as ValidationFailure).field, 'password');
      expect(repository.registerCalled, isFalse);
    });

    test('delegates to the repository once client-side validation passes',
        () async {
      final result = await useCase.call(
          name: 'Tanvir', email: 'a@b.com', password: 'password123');

      expect(repository.registerCalled, isTrue);
      expect(result.isOk, isTrue);
    });

    test(
        'surfaces a ConflictFailure from the repository (duplicate email) unchanged',
        () async {
      repository.nextRegisterResult =
          const Result.err(ConflictFailure('duplicate'));

      final result = await useCase.call(
          name: 'Tanvir', email: 'a@b.com', password: 'password123');

      expect(result.failureOrNull, isA<ConflictFailure>());
    });
  });
}
