import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../../../auth/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Result<Failure, UserProfile>> getProfile(String userId);

  Future<Result<Failure, UserProfile>> saveProfile(UserProfile profile);

  /// Restores every bundled mock file (not just `users.json`) back to its
  /// shipped seed — see `AssetSeeder.seed(force: true)`.
  Future<Result<Failure, void>> resetDemoData();
}
