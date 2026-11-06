> **Ejemplo ilustrativo:** `tasks`, `my_app` y sus rutas son hipotéticos; este ejemplo no se ha compilado ni ejecutado.

> Alchemist está declarado en `pubspec.yaml`; consulta CI y los golden existentes para las variantes de plataforma.

## Golden testing with Alchemist

Verifies widget layouts across theme variations:

```dart
// test/golden/features/tasks/task_card_golden_test.dart

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/tasks/domain/models/task_item.dart';
import 'package:my_app/features/tasks/presentation/widgets/task_card.dart';

void main() {
  group('TaskCard golden tests', () {
    final tItem = TaskItem(
      id: '1',
      title: 'Review pull request',
      dateTime: DateTime(2026, 1, 15, 10, 0),
      isCompleted: false,
    );

    goldenTest(
      'renders correctly in light and dark themes',
      fileName: 'task_card',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default state',
            child: TaskCard(
              item: tItem,
              onToggle: (_) {},
              onDelete: () {},
            ),
          ),
          GoldenTestScenario(
            name: 'Completed state',
            child: TaskCard(
              item: tItem.copyWith(isCompleted: true),
              onToggle: (_) {},
              onDelete: () {},
            ),
          ),
        ],
      ),
    );
  });
}
```

---

