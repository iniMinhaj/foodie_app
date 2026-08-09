import 'failures.dart';

/// A success-or-typed-failure return type, used end-to-end from
/// datasource up through the Notifier — the app never uses `try/catch`
/// for an *expected* failure once a call returns a [Result].
sealed class Result<F extends Failure, T> {
  const Result();

  const factory Result.ok(T value) = Ok<F, T>;
  const factory Result.err(F failure) = Err<F, T>;

  bool get isOk => this is Ok<F, T>;
  bool get isErr => this is Err<F, T>;

  /// Collapse both branches into one value.
  R fold<R>(R Function(F failure) onErr, R Function(T value) onOk) {
    return switch (this) {
      Ok<F, T>(:final value) => onOk(value),
      Err<F, T>(:final failure) => onErr(failure),
    };
  }

  /// Transform the success value, passing a failure through unchanged.
  Result<F, R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Ok<F, T>(:final value) => Result.ok(transform(value)),
      Err<F, T>(:final failure) => Result.err(failure),
    };
  }

  /// The success value, or `null` if this is an [Err].
  T? get valueOrNull => switch (this) {
        Ok<F, T>(:final value) => value,
        Err<F, T>() => null,
      };

  /// The failure, or `null` if this is an [Ok].
  F? get failureOrNull => switch (this) {
        Ok<F, T>() => null,
        Err<F, T>(:final failure) => failure,
      };
}

final class Ok<F extends Failure, T> extends Result<F, T> {
  final T value;
  const Ok(this.value);
}

final class Err<F extends Failure, T> extends Result<F, T> {
  final F failure;
  const Err(this.failure);
}
