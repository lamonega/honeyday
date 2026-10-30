import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/initial_element_position.dart';

void main() {
  test('weekly template starts entirely inside the page', () {
    final position = initialElementPosition(
      elementSize: const Size(720, 280),
      pageSize: const Size(800, 1100),
    );
    expect(position, const Offset(80, 100));
    expect(position.dx + 720, lessThanOrEqualTo(800));
  });

  test('smaller elements keep their preferred position', () {
    expect(
      initialElementPosition(
        elementSize: const Size(100, 100),
        pageSize: const Size(800, 1100),
      ),
      const Offset(120, 100),
    );
  });

  test(
    'oversized elements and negative positions are clamped to the origin',
    () {
      expect(
        initialElementPosition(
          elementSize: const Size(900, 1200),
          pageSize: const Size(800, 1100),
          preferred: const Offset(-20, -10),
        ),
        Offset.zero,
      );
    },
  );
}
