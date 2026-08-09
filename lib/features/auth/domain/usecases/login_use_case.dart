import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<Result<Failure, SessionInfo>> call(
      {required String email, required String password}) {
    return repository.login(email, password);
  }
}
