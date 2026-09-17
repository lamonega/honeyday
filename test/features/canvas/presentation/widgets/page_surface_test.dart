import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';

void main() {
  group('PageSurface and PaperStyle Tests', () {
    test('PaperStyle.fromString parses styles correctly with fallback', () {
      expect(PaperStyle.fromString('dotted'), PaperStyle.dotted);
      expect(PaperStyle.fromString('lined'), PaperStyle.lined);
      expect(PaperStyle.fromString('grid'), PaperStyle.grid);
      expect(PaperStyle.fromString('blank'), PaperStyle.blank);
      expect(PaperStyle.fromString('unknown_pattern'), PaperStyle.dotted);
      expect(PaperStyle.fromString(null), PaperStyle.dotted);
    });

    testWidgets('PageSurface renders correctly with CustomPainter', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageSurface(
              paperStyle: PaperStyle.dotted,
              child: SizedBox(width: 300, height: 300),
            ),
          ),
        ),
      );

      expect(find.byType(PageSurface), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('PageSurface supports lined and grid paper textures', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PageSurface(paperStyle: PaperStyle.lined)),
        ),
      );
      expect(find.byType(PageSurface), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PageSurface(paperStyle: PaperStyle.grid)),
        ),
      );
      expect(find.byType(PageSurface), findsOneWidget);
    });
  });
}
