import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/app/app_shell.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

void main() {
  for (final size in [const Size(1024, 600), const Size(1100, 800)]) {
    testWidgets('rail exposes both navigation destinations at $size', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => AppShell(navigationShell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => const Scaffold(body: Text('Home body')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/settings',
                    builder: (_, _) =>
                        const Scaffold(body: Text('Settings body')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      void expectDestination(String label, {required bool selected}) {
        final nodes = tester.semantics.simulatedAccessibilityTraversal().where(
          (node) => node.label.contains(label),
        );
        expect(nodes, hasLength(1), reason: 'Missing or duplicated $label');
        expect(
          nodes.single,
          isSemantics(hasTapAction: true, isSelected: selected),
        );
      }

      expect(find.byType(NavigationRail), findsOneWidget);
      expectDestination('Inicio', selected: true);
      expectDestination('Ajustes', selected: false);

      final settings = tester.semantics
          .simulatedAccessibilityTraversal()
          .singleWhere((node) => node.label.contains('Ajustes'));
      settings.owner!.performAction(settings.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(find.text('Settings body'), findsOneWidget);
      expectDestination('Inicio', selected: false);
      expectDestination('Ajustes', selected: true);

      final dialog = showDialog<void>(
        context: tester.element(find.text('Settings body')),
        builder: (context) => AlertDialog(
          title: const Text('Diálogo global'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final dialogLabels = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((node) => node.label);
      expect(dialogLabels, contains('Diálogo global'));
      for (final label in ['Inicio', 'Ajustes']) {
        expect(dialogLabels.any((value) => value.contains(label)), isFalse);
      }
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      await dialog;
      expectDestination('Inicio', selected: false);
      expectDestination('Ajustes', selected: true);
    });
  }
}
