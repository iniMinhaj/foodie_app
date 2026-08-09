import '../entities/user_profile.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Validates client-side *before* touching the repository — the
/// repository is only reached once name/email/password already pass
/// basic shape checks, so a `ConflictFailure` always means a genuine
/// duplicate, not a malformed request.
class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<Result<Failure, UserProfile>> call({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Result.err(ValidationFailure('name', 'Name is required.'));
    }

    final trimmedEmail = email.trim();
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return const Result.err(
          ValidationFailure('email', 'Enter a valid email address.'));
    }

    if (password.length < 6) {
      return const Result.err(ValidationFailure(
          'password', 'Password must be at least 6 characters.'));
    }

    return repository.register(trimmedName, trimmedEmail, password);
  }
}
