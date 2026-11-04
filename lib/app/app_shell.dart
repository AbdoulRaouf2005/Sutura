import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Coquille principale avec barre de navigation inférieure à quatre
/// destinations (guide §6).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<({IconData icon, IconData activeIcon, String label})>
      _destinations = <({IconData icon, IconData activeIcon, String label})>[
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Accueil',
    ),
    (
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Clients',
    ),
    (
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Commandes',
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Réglages',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final int index = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (int i) => navigationShell.goBranch(
            i,
            initialLocation: i == index,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _destinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon:
                      Icon(d.activeIcon, color: Theme.of(context).colorScheme.primary),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
