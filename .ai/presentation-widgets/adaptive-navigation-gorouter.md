# Declarative navigation with GoRouter and responsive layout

Architectural guide for declarative routing with GoRouter, persistent application shells, and responsive layouts across platforms.

---

## Navigation and shell layout

```text
+-------------------------------------------------------------+
|                     StatefulShellRoute                      |
|                                                             |
|  [ NavigationRail / Drawer ]  +  [ IndexedStack Branch ]    |
|   - Dashboard (route /)       |   - Active Page content     |
|   - Explore   (route /explore)|                             |
|   - Settings  (route /settings)                             |
+-------------------------------------------------------------+
```

---

## App shell routing implementation

```dart
// lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/explore/presentation/pages/explore_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExplorePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
```

---

## Responsive layout breakpoints

```text
+----------------------+--------------------+---------------------------------------+
| Window class         | Breakpoint         | UI layout                             |
+----------------------+--------------------+---------------------------------------+
| Compact              | < 600 dp           | Phone (BottomNavigationBar)           |
| Medium               | 600 - 840 dp       | Tablet (NavigationRail)               |
| Expanded             | >= 840 dp          | Desktop/Web (NavigationRail / Drawer) |
+----------------------+--------------------+---------------------------------------+
```

```dart
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    required this.desktop,
    this.tablet,
    super.key,
  });

  final Widget mobile;
  final Widget desktop;
  final Widget? tablet;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 840) {
      return desktop;
    } else if (width >= 600) {
      return tablet ?? desktop;
    } else {
      return mobile;
    }
  }
}
```

---

## Invariant rules

1. **Use MediaQuery.sizeOf:** Prefer `MediaQuery.sizeOf(context)` over `MediaQuery.of(context)` to prevent rebuilds on unrelated media changes.
2. **Centralize route definitions:** Never hardcode route string literals across individual widgets.
3. **Keep business logic free of routing:** Dispatch navigation intents from UI handlers or declarative redirects.

---

## References

- Flutter official navigation overview: https://docs.flutter.dev/ui/navigation
- GoRouter package: https://pub.dev/packages/go_router
- Material 3 layout window size classes: https://m3.material.io/foundations/layout/applying-layout/window-size-classes
- Routing patterns reference: https://github.com/DeveloperYatin/flutter-arch-skills/blob/main/navigation/flutter-routing.md
