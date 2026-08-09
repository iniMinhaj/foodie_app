import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entities/user_profile.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/login_use_case.dart';
import '../../domain/usecases/auth/logout_use_case.dart';
import '../../domain/usecases/auth/register_use_case.dart';
import '../../domain/usecases/auth/restore_session_use_case.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource(ref.watch(jsonStorageServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    local: ref.watch(authLocalDataSourceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final registerUseCaseProvider =
    Provider((ref) => RegisterUseCase(ref.watch(authRepositoryProvider)));
final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));
final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));
final restoreSessionUseCaseProvider = Provider(
  (ref) => RestoreSessionUseCase(ref.watch(authRepositoryProvider)),
);

sealed class AuthState {
  const AuthState();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  final UserProfile user;

  const AuthAuthenticated(this.user);
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
  // Deterministic in tests: a failed attempt (e.g. wrong password) should
  // not silently retry and overwrite the AsyncError state we're asserting.
  retry: (retryCount, error) => null,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final result = await ref.read(restoreSessionUseCaseProvider).call();
    return result.fold(
      (failure) => const AuthUnauthenticated(),
      (user) =>
          user == null ? const AuthUnauthenticated() : AuthAuthenticated(user),
    );
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading<AuthState>();
    final result = await ref
        .read(loginUseCaseProvider)
        .call(email: email, password: password);
    await result.fold(
      (failure) async {
        state = AsyncError<AuthState>(failure, StackTrace.current);
      },
      (session) async {
        final userResult =
            await ref.read(authRepositoryProvider).getUserById(session.userId);
        state = userResult.fold(
          (failure) => AsyncError<AuthState>(failure, StackTrace.current),
          (user) => AsyncData<AuthState>(AuthAuthenticated(user)),
        );
      },
    );
  }

  /// Registers the account only — does not log the user in. On success
  /// the state simply returns to [AuthUnauthenticated] (no error), and
  /// the screen navigates to `/login` for the user to sign in with their
  /// new credentials, per the module's acceptance criteria.
  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading<AuthState>();
    final result = await ref
        .read(registerUseCaseProvider)
        .call(name: name, email: email, password: password);
    state = result.fold(
      (failure) => AsyncError<AuthState>(failure, StackTrace.current),
      (user) => const AsyncData<AuthState>(AuthUnauthenticated()),
    );
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider).call();
    state = const AsyncData<AuthState>(AuthUnauthenticated());
  }
}
