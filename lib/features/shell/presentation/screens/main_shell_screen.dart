import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/cart_nav_icon.dart';

/// Persistent bottom-nav chrome around the app's 4 main tabs. Each tab is a
/// `StatefulShellBranch` with its own `Navigator`, so switching tabs keeps
/// every branch's scroll position and pushed sub-routes intact instead of
/// rebuilding it from scratch.
class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShellScreen({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: CartNavIcon(icon: Icons.shopping_bag_outlined),
            selectedIcon: CartNavIcon(icon: Icons.shopping_bag_rounded),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
