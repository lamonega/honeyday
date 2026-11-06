import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  for (final id in [
    'sticker_heart',
    'sticker_star',
    'sticker_coffee',
    'sticker_pin',
  ]) {
    testWidgets('$id scales its icon with the element bounds', (tester) async {
      Future<double> iconSize(double size) async {
        await tester.pumpWidget(
          testMaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Builder(
                    builder: (context) => CatalogRegistry.buildWidget(
                      context,
                      widgetType: id,
                      elementId: 'sticker',
                      configJson: '{}',
                      isInteractive: false,
                      onConfigChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        return tester
            .widget<Icon>(
              find.descendant(
                of: find.byType(ScalableStickerIcon),
                matching: find.byType(Icon),
              ),
            )
            .size!;
      }

      final small = await iconSize(80);
      final large = await iconSize(160);
      expect(small, 64);
      expect(large, small * 2);
      expect(tester.takeException(), isNull);
    });
  }
}
