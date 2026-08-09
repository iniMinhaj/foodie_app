import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/core/entities/address.dart';
import 'package:foodie_app/core/entities/user_profile.dart';
import 'package:foodie_app/features/auth/domain/repositories/auth_repository.dart';

const fakeUser = UserProfile(
  id: 'user_1',
  name: 'Test User',
  email: 'test@foodie.com',
  phone: '',
  avatarUrl: '',
  addresses: <Address>[],
);

/// Pure-Dart fake for domain usecase tests — no Riverpod, no Flutter,
/// no real storage. Each call is scripted via the `next*` fields.
class FakeAuthRepository implements AuthRepository {
  Result<Failure, UserProfile>? nextRegisterResult;
  Result<Failure, SessionInfo>? nextLoginResult;
  Result<Failure, SessionInfo?>? nextRestoreSessionResult;
  Result<Failure, UserProfile>? nextGetUserByIdResult;

  bool registerCalled = false;
  bool loginCalled = false;
  bool logoutCalled = false;

  @override
  Future<Result<Failure, UserProfile>> register(
      String name, String email, String password) async {
    registerCalled = true;
    return nextRegisterResult ?? const Result.ok(fakeUser);
  }

  @override
  Future<Result<Failure, SessionInfo>> login(
      String email, String password) async {
    loginCalled = true;
    return nextLoginResult ??
        const Result.ok(SessionInfo(token: 'token', userId: 'user_1'));
  }

  @override
  Future<Result<Failure, void>> logout() async {
    logoutCalled = true;
    return const Result.ok(null);
  }

  @override
  Future<Result<Failure, SessionInfo?>> restoreSession() async {
    return nextRestoreSessionResult ?? const Result.ok(null);
  }

  @override
  Future<Result<Failure, UserProfile>> getUserById(String id) async {
    return nextGetUserByIdResult ?? const Result.ok(fakeUser);
  }
}
