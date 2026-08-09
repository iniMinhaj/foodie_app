import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/user_profile.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/network/simulated_latency.dart';
import '../../../../core/storage/local_api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../models/user_model.dart';

const _tokenKey = 'session_token';
const _userIdKey = 'session_user_id';
const _uuid = Uuid();

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource local;
  final SharedPreferencesAsync prefs;

  const AuthRepositoryImpl({required this.local, required this.prefs});

  @override
  Future<Result<Failure, UserProfile>> register(
      String name, String email, String password) async {
    try {
      await simulateDelay();
      final users = await local.getAllUsers();
      final normalizedEmail = email.toLowerCase();
      final alreadyExists =
          users.any((u) => u.email.toLowerCase() == normalizedEmail);
      if (alreadyExists) {
        return const Result.err(
            ConflictFailure('An account with this email already exists.'));
      }

      final newUser = UserModel(
        id: _uuid.v4(),
        email: normalizedEmail,
        passwordHash: local.hashPassword(password),
        fullName: name,
      );
      await local.saveAllUsers([...users, newUser]);
      return Result.ok(newUser.toEntity());
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Failure, SessionInfo>> login(
      String email, String password) async {
    try {
      await simulateDelay();
      final users = await local.getAllUsers();
      final normalizedEmail = email.toLowerCase();

      UserModel? user;
      for (final candidate in users) {
        if (candidate.email.toLowerCase() == normalizedEmail) {
          user = candidate;
          break;
        }
      }
      if (user == null) {
        return const Result.err(
            NotFoundFailure('No account found for this email.'));
      }
      if (local.hashPassword(password) != user.passwordHash) {
        return const Result.err(
            ValidationFailure('password', 'Incorrect password.'));
      }

      final token = _uuid.v4();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userIdKey, user.id);
      return Result.ok(SessionInfo(token: token, userId: user.id));
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Failure, void>> logout() async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    return const Result.ok(null);
  }

  @override
  Future<Result<Failure, SessionInfo?>> restoreSession() async {
    final token = await prefs.getString(_tokenKey);
    final userId = await prefs.getString(_userIdKey);
    if (token == null || userId == null) {
      return const Result.ok(null);
    }
    return Result.ok(SessionInfo(token: token, userId: userId));
  }

  @override
  Future<Result<Failure, UserProfile>> getUserById(String id) async {
    try {
      final users = await local.getAllUsers();
      for (final user in users) {
        if (user.id == id) {
          return Result.ok(user.toEntity());
        }
      }
      return const Result.err(NotFoundFailure('User not found.'));
    } on JsonStorageException catch (e) {
      return Result.err(UnknownFailure(e.message));
    }
  }
}
