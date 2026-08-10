import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/network/simulated_latency.dart';
import '../../../../core/storage/asset_seeder.dart';
import '../../../../core/storage/local_api_client.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/local/profile_local_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource local;
  final AssetSeeder seeder;

  const ProfileRepositoryImpl({required this.local, required this.seeder});

  @override
  Future<Result<Failure, UserProfile>> getProfile(String userId) async {
    try {
      await simulateDelay();
      final profile = await local.getProfile(userId);
      if (profile == null) {
        return const Result.err(NotFoundFailure('User not found.'));
      }
      return Result.ok(profile);
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Failure, UserProfile>> saveProfile(UserProfile profile) async {
    try {
      await simulateDelay();
      await local.saveProfile(profile);
      return Result.ok(profile);
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Failure, void>> resetDemoData() async {
    try {
      await simulateDelay();
      await seeder.seed(force: true);
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(UnknownFailure('Could not reset demo data. Please try again.'));
    }
  }
}
