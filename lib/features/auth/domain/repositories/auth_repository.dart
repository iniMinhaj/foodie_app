import '../entities/user_profile.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';

class SessionInfo {
  final String token;
  final String userId;

  const SessionInfo({required this.token, required this.userId});
}

abstract class AuthRepository {
  Future<Result<Failure, UserProfile>> register(
      String name, String email, String password);
  Future<Result<Failure, SessionInfo>> login(String email, String password);
  Future<Result<Failure, void>> logout();

  /// `Ok(null)` means "no active session" — not an error.
  Future<Result<Failure, SessionInfo?>> restoreSession();

  Future<Result<Failure, UserProfile>> getUserById(String id);
}
