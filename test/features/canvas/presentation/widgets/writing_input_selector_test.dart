import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/theme/theme_data.dart';
import 'package:honeyday/features/canvas/domain/writing_input.dart';
import 'package:honeyday/features/canvas/presentation/widgets/writing_input_selector.dart';

import '../../../../helpers/pump_app.dart';

const Key _paperKey = ValueKey('paper');

Future<Color> _backgroundBelowLabel(WidgetTester tester, Finder label) async {
  final paper = find.byKey(_paperKey);
  final boundary = tester.renderObject<RenderRepaintBoundary>(paper);
  // Sample inside the segment, just below its text rather than on a glyph.
  final labelRect = tester.getRect(label);
  final point =
      Offset(labelRect.center.dx, labelRect.bottom + 1) -
      tester.getTopLeft(paper);
  final image = await boundary.toImage();
  try {
    final bytes = (await image.toByteData())!;
    final index = (point.dy.floor() * image.width + point.dx.floor()) * 4;
    return Color.fromARGB(
      bytes.getUint8(index + 3),
      bytes.getUint8(index),
      bytes.getUint8(index + 1),
      bytes.getUint8(index + 2),
    );
  } finally {
    image.dispose();
  }
}

double _contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    for (final selection in WritingInput.values) {
      testWidgets('$brightness: $selection stays legible on light paper', (
        tester,
      ) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(writingInputProvider.notifier).selected = selection;
        final theme = brightness == Brightness.dark
            ? HoneydayTheme.darkTheme()
            : HoneydayTheme.lightTheme();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: testMaterialApp(
              home: Theme(
                data: theme,
                child: const Center(
                  child: RepaintBoundary(
                    key: _paperKey,
                    child: SizedBox(
                      width: 360,
                      height: 80,
                      child: ColoredBox(
                        color: Colors.white,
                        child: Center(child: WritingInputSelector()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final text in ['Contenido', 'Tinta']) {
          final label = find.text(text);
          final foreground = DefaultTextStyle.of(tester.element(label))
              .style
              .color!;
          final background = (await tester.runAsync(
            () => _backgroundBelowLabel(tester, label),
          ))!;
          expect(
            _contrast(foreground, background),
            greaterThanOrEqualTo(4.5),
            reason: '$text must remain legible above paper in $brightness',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('switching input clears text focus and updates the selection', (
    tester,
  ) async {
    final container = ProviderContainer();
    final focus = FocusNode();
    addTearDown(container.dispose);
    addTearDown(focus.dispose);
    container.read(writingInputProvider.notifier).selected =
        WritingInput.content;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testMaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focus),
                const WritingInputSelector(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);

    await tester.tap(find.text('Tinta'));
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
    expect(container.read(writingInputProvider), WritingInput.ink);

    await tester.tap(find.text('Contenido'));
    await tester.pumpAndSettle();
    expect(container.read(writingInputProvider), WritingInput.content);
    expect(tester.takeException(), isNull);
  });
}
