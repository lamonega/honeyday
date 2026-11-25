import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/core/constants/app_constants.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int get _currentIndex => widget.navigationShell.currentIndex;

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showRail = MediaQuery.sizeOf(context).width >= kBreakpointMobile;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Row(
        children: [
          if (showRail) ...[
            SafeArea(
              right: false,
              child: NavigationRail(
                scrollable: true,
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTap,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: Text(l10n.navHome),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.settings_outlined),
                    selectedIcon: const Icon(Icons.settings),
                    label: Text(l10n.navSettings),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            key: const ValueKey('navigation-shell'),
            // A branch Navigator's modal barrier must not hide its sibling
            // rail from the accessibility tree.
            child: Semantics(container: true, child: widget.navigationShell),
          ),
        ],
      ),
      bottomNavigationBar: showRail
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTap,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: l10n.navSettings,
                ),
              ],
            ),
    );
  }
}
