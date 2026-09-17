import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/presentation/widgets/element_history.dart';

CanvasWidgetData _el(String id, {double x = 0}) => CanvasWidgetData(
      id: id,
      pageId: 'page-1',
      widgetType: 'text_box',
      position: Offset(x, 0),
      size: const Size(100, 50),
    );

void main() {
  group('ElementHistory', () {
    test('starts with canUndo=false and canRedo=false', () {
      final history = ElementHistory();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('push + undo restores previous state', () {
      final history = ElementHistory();
      final before = [_el('a'), _el('b')];
      final after = [_el('a'), _el('b'), _el('c')];

      history.push(before);
      expect(history.canUndo, isTrue);

      final restored = history.undo(after);
      expect(restored, isNotNull);
      expect(restored!.map((e) => e.id), ['a', 'b']);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);
    });

    test('undo on empty stack returns null', () {
      final history = ElementHistory();
      expect(history.undo([_el('a')]), isNull);
    });

    test('redo restores next state after undo', () {
      final history = ElementHistory();
      final s0 = [_el('a')];
      final s1 = [_el('a'), _el('b')];

      history.push(s0);
      final undone = history.undo(s1);
      expect(undone!.map((e) => e.id), ['a']);

      final redone = history.redo([_el('a')]);
      expect(redone!.map((e) => e.id), ['a', 'b']);
      expect(history.canRedo, isFalse);
    });

    test('redo on empty redo stack returns null', () {
      final history = ElementHistory();
      expect(history.redo([_el('a')]), isNull);
    });

    test('new push clears redo stack', () {
      final history = ElementHistory();
      final s0 = [_el('a')];
      final s1 = [_el('a'), _el('b')];

      history
        ..push(s0)
        ..undo(s1) // redo stack now has s1
        ..push(s0); // should clear redo stack

      expect(history.canRedo, isFalse);
      expect(history.redo(s0), isNull);
    });

    test('undo/redo chain with multiple states', () {
      final history = ElementHistory();
      final s0 = [_el('a')];
      final s1 = [_el('a'), _el('b')];
      final s2 = [_el('a'), _el('b'), _el('c')];

      history
        ..push(s0)
        ..push(s1);

      expect(history.undo(s2)!.map((e) => e.id), ['a', 'b']);
      expect(history.undo([_el('a'), _el('b')])!.map((e) => e.id), ['a']);

      expect(history.redo([_el('a')])!.map((e) => e.id), ['a', 'b']);
      expect(history.redo([_el('a'), _el('b')])!.map((e) => e.id), [
        'a',
        'b',
        'c',
      ]);
    });

    test('push does not exceed max size (50)', () {
      final history = ElementHistory();
      for (var i = 0; i < 55; i++) {
        history.push([_el('$i')]);
      }
      // Only last 50 should be undoable
      var count = 0;
      var state = [_el('55')];
      while (history.canUndo) {
        state = history.undo(state)!;
        count++;
      }
      expect(count, 50);
    });

    test('clear resets both stacks', () {
      final h = ElementHistory()
        ..push([_el('a')])
        ..push([_el('a'), _el('b')])
        ..undo([_el('a'), _el('b'), _el('c')]);

      expect(h.canUndo, isTrue);
      expect(h.canRedo, isTrue);

      h.clear();

      expect(h.canUndo, isFalse);
      expect(h.canRedo, isFalse);
    });

    test('stores snapshots, not references', () {
      final history = ElementHistory();
      final original = [_el('a')];
      history.push(original);

      original.add(_el('b')); // mutate original after push
      final restored = history.undo([_el('a'), _el('b')]);
      expect(restored!.map((e) => e.id), ['a']); // snapshot was independent
    });
  });
}
