import 'package:equatable/equatable.dart';

/// Base failure class — for all type of Error
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const Failure({required this.message, this.code, this.stackTrace});

  String get userMessage => message;

  bool get isRetryable => false;

  @override
  List<Object?> get props => [message, code];
}

// ─────────────────────────────────────────────
// Network
// ─────────────────────────────────────────────

/// No internet / timeout / DNS failure
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;
}

// ─────────────────────────────────────────────
// Server (5xx)
// ─────────────────────────────────────────────

/// 500 / 502 / 503 / 504
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    super.message = 'Something went wrong on our end. Please try again later.',
    this.statusCode,
    super.code,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

// ─────────────────────────────────────────────
// Client (4xx — auth এর বাইরে)
// ─────────────────────────────────────────────

/// 400 / 404 / 422 etc.
class ClientFailure extends Failure {
  final int? statusCode;

  const ClientFailure({
    required super.message,
    this.statusCode,
    super.code,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

// ─────────────────────────────────────────────
// Auth (401 / 403)
// ─────────────────────────────────────────────

class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Your session has expired. Please log in again.',
    super.code,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;
}

// ─────────────────────────────────────────────
// Cache / Local storage
// ─────────────────────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to load cached data.',
    super.code,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;
}

// ─────────────────────────────────────────────
// Unknown / Unexpected
// ─────────────────────────────────────────────

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;
}
