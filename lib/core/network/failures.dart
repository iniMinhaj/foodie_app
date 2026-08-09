import 'package:equatable/equatable.dart';

/// Base type for every expected failure a repository can return.
///
/// Every layer above `data/` reacts to a typed [Failure] via [Result],
/// never a caught exception — `try/catch` only belongs inside a
/// datasource, at the actual I/O boundary.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  /// Copy shown to the user — some subclasses override this to avoid
  /// leaking internal detail (e.g. login failures never say *which*
  /// field was wrong).
  String get userMessage => message;

  @override
  List<Object?> get props => [message];
}

/// A single field failed client- or server-side validation.
class ValidationFailure extends Failure {
  final String field;

  const ValidationFailure(this.field, String message) : super(message);

  @override
  List<Object?> get props => [field, message];
}

/// The requested resource does not exist (e.g. no user with that email).
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

/// The requested write conflicts with existing state (e.g. duplicate email).
class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Already exists.']);
}

/// Simulated connectivity/timeout failure.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network.']);
}

/// Anything else — a caught exception at a datasource boundary that
/// doesn't map to a more specific failure above.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong. Please try again.']);
}
