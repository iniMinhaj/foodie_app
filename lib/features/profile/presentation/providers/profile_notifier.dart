import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entities/address.dart';
import '../../../../core/network/failures.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import 'profile_providers.dart';

class ProfileState extends Equatable {
  final UserProfile profile;
  final String? errorMessage;

  const ProfileState({required this.profile, this.errorMessage});

  ProfileState copyWith({UserProfile? profile, String? errorMessage}) => ProfileState(
        profile: profile ?? this.profile,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [profile, errorMessage];
}

/// Loads the signed-in user's full profile record. Reachable only once
/// [authNotifierProvider] has already resolved to [AuthAuthenticated] — the
/// Profile tab lives behind `go_router`'s auth redirect — so `build()`
/// reads the id straight off the already-resolved auth state instead of
/// re-awaiting it. Every mutation follows the same optimistic-update,
/// persist, roll-back-with-`errorMessage`-on-failure shape as `CartNotifier`.
class ProfileNotifier extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    final authState = ref.watch(authNotifierProvider).value;
    final user = authState is AuthAuthenticated ? authState.user : null;
    if (user == null) {
      throw const UnknownFailure('No authenticated user.');
    }

    final result = await ref.read(profileRepositoryProvider).getProfile(user.id);
    return result.fold(
      (failure) => throw failure,
      (profile) => ProfileState(profile: profile),
    );
  }

  Future<void> updateDetails({String? name, String? phone, String? avatarUrl}) async {
    final current = await future;
    final updated = current.profile.copyWith(name: name, phone: phone, avatarUrl: avatarUrl);
    await _applyAndPersist(current, current.copyWith(profile: updated));
  }

  /// Marking [address] (or adding the very first address) as default
  /// clears every other address's default flag first, so the invariant
  /// "at most one default address" always holds after a write.
  Future<void> addAddress(Address address) async {
    final current = await future;
    final makeDefault = address.isDefault || current.profile.addresses.isEmpty;
    final addresses = [
      for (final existing in current.profile.addresses)
        makeDefault ? existing.copyWith(isDefault: false) : existing,
      address.copyWith(isDefault: makeDefault),
    ];
    await _persistAddresses(current, addresses);
  }

  Future<void> updateAddress(Address address) async {
    final current = await future;
    final addresses = [
      for (final existing in current.profile.addresses)
        if (existing.id == address.id)
          address
        else
          address.isDefault ? existing.copyWith(isDefault: false) : existing,
    ];
    await _persistAddresses(current, addresses);
  }

  /// Removing the current default promotes the next remaining address so
  /// the list never ends up with addresses but no default.
  Future<void> removeAddress(String addressId) async {
    final current = await future;
    final removed = current.profile.addresses.firstWhere((a) => a.id == addressId);
    final remaining = current.profile.addresses.where((a) => a.id != addressId).toList();
    if (removed.isDefault && remaining.isNotEmpty) {
      remaining[0] = remaining[0].copyWith(isDefault: true);
    }
    await _persistAddresses(current, remaining);
  }

  Future<void> setDefaultAddress(String addressId) async {
    final current = await future;
    final addresses = [
      for (final existing in current.profile.addresses) existing.copyWith(isDefault: existing.id == addressId),
    ];
    await _persistAddresses(current, addresses);
  }

  /// Restores every bundled mock file to its shipped seed and returns
  /// whether it succeeded — returned directly (not read back off
  /// `state.errorMessage`) so the caller can't mistake an unrelated,
  /// still-lingering error from an earlier mutation for a reset failure.
  /// The caller is responsible for signing the user out afterwards (a
  /// custom-registered account may no longer exist post-reset).
  Future<bool> resetDemoData() async {
    final result = await ref.read(profileRepositoryProvider).resetDemoData();
    if (result.isOk) {
      ref.invalidateSelf();
      return true;
    }
    final current = await future;
    final failure = result.failureOrNull as Failure;
    state = AsyncData(current.copyWith(errorMessage: failure.userMessage));
    return false;
  }

  Future<void> _persistAddresses(ProfileState current, List<Address> addresses) async {
    final updated = current.profile.copyWith(addresses: addresses);
    await _applyAndPersist(current, current.copyWith(profile: updated));
  }

  Future<void> _applyAndPersist(ProfileState previous, ProfileState next) async {
    state = AsyncData(next);
    final result = await ref.read(profileRepositoryProvider).saveProfile(next.profile);
    if (result.isErr) {
      final failure = result.failureOrNull as Failure;
      state = AsyncData(previous.copyWith(errorMessage: failure.userMessage));
    }
  }
}

final profileNotifierProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
  // Deterministic on failure, same reasoning as cartNotifierProvider.
  retry: (retryCount, error) => null,
);
