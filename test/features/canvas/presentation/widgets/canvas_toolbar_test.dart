import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_toolbar.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('ink toolbar scrolls to its last control on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = InkCanvasController();
    addTearDown(controller.dispose);
    var closed = false;
    await tester.pumpWidget(
      ProviderScope(
        child: testMaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CanvasFloatingToolbar(
                  inkController: controller,
                  onCloseWriting: () => closed = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // Start over a tool button, not the slider that owns horizontal drags.
    await tester.dragFrom(const Offset(24, 27), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_rounded));
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
