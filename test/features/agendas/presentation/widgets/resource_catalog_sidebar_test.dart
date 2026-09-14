import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/presentation/widgets/add_catalog_element_sheet.dart';
import 'package:honeyday/features/agendas/presentation/widgets/resource_catalog_sidebar.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

void main() {
  group('ResourceCatalogSidebar', () {
    testWidgets('renders expanded sidebar initially without tip footer and without element descriptions', (
      tester,
    ) async {
      AgendaWidgetDefinition? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceCatalogSidebar(
              onSelectDefinition: (def) => selected = def,
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('Elementos'), findsOneWidget);
      expect(find.text('Diseño y plantillas'), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      // Verify tip footer is removed
      expect(
        find.textContaining('Toca un elemento para agregarlo'),
        findsNothing,
      );

      // Verify elements are shown by title only
      expect(find.text('Caja / Rectángulo'), findsOneWidget);
      expect(find.text('Tarjeta o contenedor para estructurar secciones'), findsNothing);

      // Verify initial width is 260
      final initialBox = tester.renderObject<RenderBox>(
        find.byType(AnimatedContainer),
      );
      expect(initialBox.size.width, 260);

      // Tap on item
      await tester.tap(find.text('Caja / Rectángulo'));
      expect(selected?.id, 'shape_box');
    });

    testWidgets('collapses to 52 width rail and expands back', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceCatalogSidebar(
              onSelectDefinition: (_) {},
            ),
          ),
        ),
      );

      // Tap collapse button
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      // Check collapsed rail
      final collapsedBox = tester.renderObject<RenderBox>(
        find.byType(AnimatedContainer),
      );
      expect(collapsedBox.size.width, 52);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.text('Elementos'), findsNothing);

      // Tap expand button to expand back
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      final expandedBox = tester.renderObject<RenderBox>(
        find.byType(AnimatedContainer),
      );
      expect(expandedBox.size.width, 260);
      expect(find.text('Elementos'), findsOneWidget);
    });

    testWidgets('collapsed rail can be expanded via Interests icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceCatalogSidebar(
              onSelectDefinition: (_) {},
            ),
          ),
        ),
      );

      // Collapse
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      // Tap the interests icon in collapsed rail
      await tester.tap(find.byIcon(Icons.interests_rounded));
      await tester.pumpAndSettle();

      // Should be expanded again
      expect(find.text('Elementos'), findsOneWidget);
    });
  });

  group('AddCatalogElementSheet', () {
    testWidgets('renders items without element descriptions or subtitles', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddCatalogElementSheet(),
          ),
        ),
      );

      expect(find.text('Catálogo de Elementos'), findsOneWidget);
      expect(find.text('Caja / Rectángulo'), findsOneWidget);
      // Verify descriptions are not rendered
      expect(find.text('Tarjeta o contenedor para estructurar secciones'), findsNothing);
      expect(find.textContaining('Tamaño sugerido'), findsNothing);
    });
  });
}
