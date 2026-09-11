import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/features/agendas/presentation/pages/agenda_viewer_page.dart';
import 'package:honeyday/features/agendas/presentation/pages/home_page.dart';

/// Provider exposing the declarative [GoRouter] instance.
///
/// What: Configures deep-linkable URLs for cross-platform navigation (Web & Desktop).
/// Why: Directs `/` to [HomePage] and `/agenda/:id` to [AgendaViewerPage] with mode query parameters.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/agenda/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final mode = state.uri.queryParameters['mode'] ?? 'writing';
          return AgendaViewerPage(agendaId: id, initialMode: mode);
        },
      ),
    ],
  );
});
