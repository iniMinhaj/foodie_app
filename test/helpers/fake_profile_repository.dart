import 'package:foodie_app/core/entities/address.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/auth/domain/entities/user_profile.dart';
import 'package:foodie_app/features/profile/domain/repositories/profile_repository.dart';

const fakeProfile = UserProfile(
  id: 'user_1',
  name: 'Test User',
  email: 'test@foodie.com',
  phone: '+8801700000000',
  avatarUrl: '',
  addresses: <Address>[],
  loyaltyPoints: 100,
);

/// Pure-Dart fake for profile notifier tests — no Riverpod, no Flutter,
/// no real storage. Each call is scripted via the `next*` fields.
class FakeProfileRepository implements ProfileRepository {
  Result<Failure, UserProfile>? nextGetProfileResult;
  Result<Failure, UserProfile>? nextSaveProfileResult;
  Result<Failure, void>? nextResetDemoDataResult;

  int getProfileCallCount = 0;
  int saveProfileCallCount = 0;
  int resetDemoDataCallCount = 0;
  UserProfile? lastSavedProfile;

  @override
  Future<Result<Failure, UserProfile>> getProfile(String userId) async {
    getProfileCallCount++;
    return nextGetProfileResult ?? const Result.ok(fakeProfile);
  }

  @override
  Future<Result<Failure, UserProfile>> saveProfile(UserProfile profile) async {
    saveProfileCallCount++;
    lastSavedProfile = profile;
    return nextSaveProfileResult ?? Result.ok(profile);
  }

  @override
  Future<Result<Failure, void>> resetDemoData() async {
    resetDemoDataCallCount++;
    return nextResetDemoDataResult ?? const Result.ok(null);
  }
}
