import '../entities/user_profile.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

/// Runs once at app start: resolves a persisted session token back into
/// the `UserProfile` it belongs to, re-reading `users.json` so the
/// profile is never stale relative to the last write.
class RestoreSessionUseCase {
  final AuthRepository repository;

  const RestoreSessionUseCase(this.repository);

  /// `Ok(null)` means "no active session" — not an error.
  Future<Result<Failure, UserProfile?>> call() async {
    final sessionResult = await repository.restoreSession();
    if (sessionResult.isErr) {
      return Result.err(sessionResult.failureOrNull!);
    }

    final session = sessionResult.valueOrNull;
    if (session == null) {
      return const Result.ok(null);
    }

    final userResult = await repository.getUserById(session.userId);
    return userResult.map<UserProfile?>((user) => user);
  }
}
