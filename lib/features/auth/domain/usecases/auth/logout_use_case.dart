import '../../../../../core/network/failures.dart';
import '../../../../../core/network/result.dart';
import '../../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  Future<Result<Failure, void>> call() => repository.logout();
}
