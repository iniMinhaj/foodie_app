import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/entities/address.dart';
import 'package:foodie_app/core/network/failures.dart';
import 'package:foodie_app/core/network/result.dart';
import 'package:foodie_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:foodie_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:foodie_app/features/profile/presentation/providers/profile_notifier.dart';
import 'package:foodie_app/features/profile/presentation/providers/profile_providers.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_profile_repository.dart';

const _addrHome = Address(id: 'addr_1', label: 'Home', line1: 'House 1', city: 'Dhaka', isDefault: true);
const _addrOffice = Address(id: 'addr_2', label: 'Office', line1: 'Level 6', city: 'Dhaka', isDefault: false);

void main() {
  late FakeAuthRepository authRepository;
  late FakeProfileRepository profileRepository;
  late ProviderContainer container;

  setUp(() async {
    authRepository = FakeAuthRepository();
    authRepository.nextRestoreSessionResult = const Result.ok(SessionInfo(token: 't', userId: 'user_1'));
    authRepository.nextGetUserByIdResult = const Result.ok(fakeUser);

    profileRepository = FakeProfileRepository();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        profileRepositoryProvider.overrideWithValue(profileRepository),
      ],
    );
    addTearDown(container.dispose);

    // Resolve auth first so ProfileNotifier.build() sees AuthAuthenticated.
    await container.read(authNotifierProvider.future);
  });

  group('ProfileNotifier', () {
    test('build() loads the signed-in user\'s profile', () async {
      profileRepository.nextGetProfileResult = const Result.ok(fakeProfile);

      final state = await container.read(profileNotifierProvider.future);

      expect(state.profile, fakeProfile);
      expect(profileRepository.getProfileCallCount, 1);
    });

    test('updateDetails() patches the profile and persists it', () async {
      profileRepository.nextGetProfileResult = const Result.ok(fakeProfile);
      await container.read(profileNotifierProvider.future);

      await container.read(profileNotifierProvider.notifier).updateDetails(name: 'New Name');

      final state = container.read(profileNotifierProvider).value!;
      expect(state.profile.name, 'New Name');
      expect(profileRepository.lastSavedProfile?.name, 'New Name');
    });

    test('addAddress() to an empty list makes the new address the default', () async {
      profileRepository.nextGetProfileResult = const Result.ok(fakeProfile);
      await container.read(profileNotifierProvider.future);

      await container.read(profileNotifierProvider.notifier).addAddress(_addrHome.copyWith(isDefault: false));

      final addresses = container.read(profileNotifierProvider).value!.profile.addresses;
      expect(addresses, hasLength(1));
      expect(addresses.single.isDefault, isTrue);
    });

    test('addAddress() marked default clears the previous default', () async {
      profileRepository.nextGetProfileResult = Result.ok(fakeProfile.copyWith(addresses: [_addrHome]));
      await container.read(profileNotifierProvider.future);

      await container.read(profileNotifierProvider.notifier).addAddress(_addrOffice.copyWith(isDefault: true));

      final addresses = container.read(profileNotifierProvider).value!.profile.addresses;
      expect(addresses.firstWhere((a) => a.id == 'addr_1').isDefault, isFalse);
      expect(addresses.firstWhere((a) => a.id == 'addr_2').isDefault, isTrue);
    });

    test('removeAddress() of the default promotes the next remaining address', () async {
      profileRepository.nextGetProfileResult =
          Result.ok(fakeProfile.copyWith(addresses: [_addrHome, _addrOffice]));
      await container.read(profileNotifierProvider.future);

      await container.read(profileNotifierProvider.notifier).removeAddress('addr_1');

      final addresses = container.read(profileNotifierProvider).value!.profile.addresses;
      expect(addresses, hasLength(1));
      expect(addresses.single.id, 'addr_2');
      expect(addresses.single.isDefault, isTrue);
    });

    test('setDefaultAddress() flips the default flag across the list', () async {
      profileRepository.nextGetProfileResult =
          Result.ok(fakeProfile.copyWith(addresses: [_addrHome, _addrOffice]));
      await container.read(profileNotifierProvider.future);

      await container.read(profileNotifierProvider.notifier).setDefaultAddress('addr_2');

      final addresses = container.read(profileNotifierProvider).value!.profile.addresses;
      expect(addresses.firstWhere((a) => a.id == 'addr_1').isDefault, isFalse);
      expect(addresses.firstWhere((a) => a.id == 'addr_2').isDefault, isTrue);
    });

    test('a failed persist rolls back to the previous state with an error message', () async {
      profileRepository.nextGetProfileResult = const Result.ok(fakeProfile);
      await container.read(profileNotifierProvider.future);
      profileRepository.nextSaveProfileResult = const Result.err(UnknownFailure('disk full'));

      await container.read(profileNotifierProvider.notifier).updateDetails(name: 'Should Roll Back');

      final state = container.read(profileNotifierProvider).value!;
      expect(state.profile.name, fakeProfile.name);
      expect(state.errorMessage, 'disk full');
    });

    test('resetDemoData() invalidates and reloads the profile on success', () async {
      profileRepository.nextGetProfileResult = const Result.ok(fakeProfile);
      await container.read(profileNotifierProvider.future);

      await container.read(profileNotifierProvider.notifier).resetDemoData();
      await container.read(profileNotifierProvider.future);

      expect(profileRepository.resetDemoDataCallCount, 1);
      expect(profileRepository.getProfileCallCount, 2);
    });

    test('resetDemoData() surfaces a failure as errorMessage without invalidating', () async {
      profileRepository.nextGetProfileResult = const Result.ok(fakeProfile);
      await container.read(profileNotifierProvider.future);
      profileRepository.nextResetDemoDataResult = const Result.err(UnknownFailure('nope'));

      await container.read(profileNotifierProvider.notifier).resetDemoData();

      final state = container.read(profileNotifierProvider).value!;
      expect(state.errorMessage, 'nope');
      expect(profileRepository.getProfileCallCount, 1);
    });
  });
}
