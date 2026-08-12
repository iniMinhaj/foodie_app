import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/session_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/orders/presentation/screens/order_history_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/shell/presentation/screens/main_shell_screen.dart';

/// Bridges Riverpod state changes into a `Listenable` go_router can use
/// as `refreshListenable` — `ref.listen` (not `ref.watch`) so the router
/// itself doesn't get rebuilt, just re-evaluates its redirect.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authNotifierProvider, (previous, next) => notifyListeners());
  }
}

const _authRoutes = {'/login', '/register'};

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isGoingToAuthRoute = _authRoutes.contains(state.matchedLocation);

      // Still resolving the initial restore-session check — don't
      // redirect anywhere yet, or an authenticated user would flash
      // through /login before landing on /home.
      if (authState.isLoading && !authState.hasValue) {
        return null;
      }

      final isLoggedIn = ref.read(sessionProvider);
      if (!isLoggedIn && !isGoingToAuthRoute) return '/login';
      if (isLoggedIn && isGoingToAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/orders', builder: (context, state) => const OrderHistoryScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
