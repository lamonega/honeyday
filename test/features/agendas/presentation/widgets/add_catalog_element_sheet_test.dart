import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/presentation/widgets/add_catalog_element_sheet.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AddCatalogElementSheet', () {
    testWidgets('renders items without element descriptions or subtitles', (
      tester,
    ) async {
      await tester.pumpWidget(
        testMaterialApp(home: const Scaffold(body: AddCatalogElementSheet())),
      );

      expect(find.text('Elementos'), findsOneWidget);
      expect(find.text('Rectángulo'), findsOneWidget);
      expect(find.textContaining('Tamaño sugerido'), findsNothing);
    });
  });
}
