import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';

void main() {
  group('Result', () {
    test('Ok reports isOk/isErr correctly and folds to the ok branch', () {
      const Result<Failure, int> result = Result.ok(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
      expect(
        result.fold((f) => 'err', (v) => 'ok:$v'),
        'ok:42',
      );
    });

    test('Err reports isOk/isErr correctly and folds to the err branch', () {
      const failure = NotFoundFailure('missing');
      const Result<Failure, int> result = Result.err(failure);

      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
      expect(
        result.fold((f) => 'err:${f.message}', (v) => 'ok'),
        'err:missing',
      );
    });

    test('map transforms an Ok value', () {
      const Result<Failure, int> result = Result.ok(2);
      final mapped = result.map((v) => v * 10);

      expect(mapped.valueOrNull, 20);
    });

    test('map passes an Err through unchanged', () {
      const failure = UnknownFailure('boom');
      const Result<Failure, int> result = Result.err(failure);
      final mapped = result.map((v) => v * 10);

      expect(mapped.isErr, isTrue);
      expect(mapped.failureOrNull, failure);
    });
  });
}
