import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';

void main() {
  group('CanvasMode and Providers Tests', () {
    test('CanvasMode enum values exist and default is writing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mode = container.read(canvasModeProvider);
      expect(mode, CanvasMode.writing);
    });

    test(
      'CanvasModeNotifier transitions between reading, writing, and edit',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(canvasModeProvider.notifier)
          ..setReading();
        expect(container.read(canvasModeProvider), CanvasMode.reading);

        notifier.setEdit();
        expect(container.read(canvasModeProvider), CanvasMode.edit);

        notifier.setWriting();
        expect(container.read(canvasModeProvider), CanvasMode.writing);

        notifier.setMode(CanvasMode.reading);
        expect(container.read(canvasModeProvider), CanvasMode.reading);
      },
    );

    test(
      'InkToolNotifier manages active tool, palette colors, and stroke widths',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        var state = container.read(inkToolProvider);
        expect(state.tool, InkToolType.pen);
        expect(state.color, const Color(0xFF1E293B));
        expect(state.strokeWidth, 3);

        final notifier = container.read(inkToolProvider.notifier)
          ..selectTool(InkToolType.highlighter);
        state = container.read(inkToolProvider);
        expect(state.tool, InkToolType.highlighter);
        expect(state.strokeWidth, 18);

        // Switch to eraser: strokeWidth should automatically update to 20.0
        notifier.selectTool(InkToolType.eraser);
        state = container.read(inkToolProvider);
        expect(state.tool, InkToolType.eraser);
        expect(state.strokeWidth, 20);

        // Change color
        const newColor = Color(0xFFD97706);
        notifier.setColor(newColor);
        state = container.read(inkToolProvider);
        expect(state.color, newColor);

        // Change custom stroke width
        notifier.setStrokeWidth(7.5);
        state = container.read(inkToolProvider);
        expect(state.strokeWidth, 7.5);
      },
    );
  });
}
