import 'error.dart';

class ErrorHandler {
  ErrorHandler._();

  static Failure handle(Object error, [StackTrace? stackTrace]) {
    final failure = _map(error, stackTrace);

    return failure;
  }

  // ── Mapping logic ────────────────────────────────────────────

  static Failure _map(Object error, StackTrace? st) {
    if (error is DioException) return _fromDio(error, st);
    if (error is SocketException) {
      return NetworkFailure(stackTrace: st);
    }
    if (error is FormatException) {
      return ClientFailure(
        message: 'Invalid data format received from server.',
        stackTrace: st,
      );
    }
    return UnknownFailure(message: error.toString(), stackTrace: st);
  }

  static Failure _fromDio(DioException e, StackTrace? st) {
    switch (e.type) {
      // ── No internet / timeout ───────────────────────────────
      case DioExceptionType.connectionError:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionTimeout:
        return NetworkFailure(stackTrace: st);

      // ── Server responded with error status ──────────────────
      case DioExceptionType.badResponse:
        return _fromResponse(e.response, st);

      // ── Request cancelled ────────────────────────────────────
      case DioExceptionType.cancel:
        return ClientFailure(
          message: 'Request was cancelled.',
          code: 'REQUEST_CANCELLED',
          stackTrace: st,
        );

      // ── Anything else ────────────────────────────────────────
      case DioExceptionType.unknown:
      default:
        if (e.error is SocketException) {
          return NetworkFailure(stackTrace: st);
        }
        return UnknownFailure(stackTrace: st);
    }
  }

  static Failure _fromResponse(Response? response, StackTrace? st) {
    final statusCode = response?.statusCode;
    final serverMessage = _extractServerMessage(response);

    return switch (statusCode) {
      // ── Auth ──────────────────────────────────────────────
      401 || 403 => AuthFailure(
          message:
              serverMessage ?? 'You are not authorized to perform this action.',
          code: statusCode.toString(),
          stackTrace: st,
        ),

      // ── Client errors ─────────────────────────────────────
      400 => ClientFailure(
          message: serverMessage ?? 'Invalid request. Please check your input.',
          statusCode: statusCode,
          code: 'BAD_REQUEST',
          stackTrace: st,
        ),
      404 => ClientFailure(
          message: serverMessage ?? 'The requested resource was not found.',
          statusCode: statusCode,
          code: 'NOT_FOUND',
          stackTrace: st,
        ),
      422 => ClientFailure(
          message:
              serverMessage ?? 'Validation failed. Please check your input.',
          statusCode: statusCode,
          code: 'UNPROCESSABLE',
          stackTrace: st,
        ),

      // ── Server errors ─────────────────────────────────────
      500 || 502 || 503 || 504 => ServerFailure(
          message: serverMessage ??
              'Something went wrong on our end. Please try again later.',
          statusCode: statusCode,
          code: statusCode.toString(),
          stackTrace: st,
        ),

      // ── Fallback ──────────────────────────────────────────
      _ => UnknownFailure(
          message: serverMessage ?? 'An unexpected error occurred.',
          code: statusCode?.toString(),
          stackTrace: st,
        ),
    };
  }

  static String? _extractServerMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        // Common API response patterns:
        return data['message'] as String? ??
            data['error'] as String? ??
            data['msg'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
