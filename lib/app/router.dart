import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/app/app_shell.dart';
import 'package:honeyday/features/agendas/presentation/pages/agenda_trash_page.dart';
import 'package:honeyday/features/agendas/presentation/pages/agenda_viewer_page.dart';
import 'package:honeyday/features/agendas/presentation/pages/home_page.dart';
import 'package:honeyday/features/settings/presentation/pages/settings_page.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const _NotFoundPage(),
    routes: [
      // Older versions exposed the onboarding-only router's location.
      GoRoute(path: '/onboarding', redirect: (context, state) => '/'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomePage()),
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
      GoRoute(
        path: AgendaTrashPage.routePath,
        builder: (context, state) => const AgendaTrashPage(),
      ),
      GoRoute(
        path: '/agenda/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final mode = state.uri.queryParameters['mode'] ?? 'writing';
          return AgendaViewerPage(
            key: ValueKey(id),
            agendaId: id,
            initialMode: mode,
          );
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.explore_off_rounded,
                    size: 56,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.routerNotFoundTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.routerNotFoundMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_rounded),
                    label: Text(l10n.routerGoHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
