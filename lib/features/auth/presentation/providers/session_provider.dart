import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_notifier.dart';

/// Derived from [authNotifierProvider] — this is what `go_router`'s
/// redirect listens to. `true` only once restore/login has actually
/// resolved to an authenticated user; loading/error both read as "no
/// session yet" so the redirect never lets a half-resolved state through.
final sessionProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.maybeWhen(
    data: (state) => state is AuthAuthenticated,
    orElse: () => false,
  );
});
