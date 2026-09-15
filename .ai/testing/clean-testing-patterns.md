# Clean testing patterns in Flutter

Conventions for unit, repository, widget, and visual regression (golden) tests in Flutter.

---

## The testing pyramid

```text
       /\
      /  \       Golden tests (alchemist / visual verification)
     /----\
    /      \     Widget tests (component UI and interaction)
   /--------\
  /          \   Unit tests (domain models, mappers, repositories, notifiers)
 /------------\
```

```text
+---------------+-----------------------------+-----------------------------------+
| Test level    | Target                      | Tooling                           |
+---------------+-----------------------------+-----------------------------------+
| Unit          | Business logic, mappers, IO | flutter_test, mocktail            |
| Widget        | Stateless UI, event emission| flutter_test                      |
| Golden        | Multi-theme visual layout   | alchemist                         |
+---------------+-----------------------------+-----------------------------------+
```

---

## Unit testing with Mocktail (AAA pattern)

Arrange, act, assert pattern for repository tests:

```dart
// test/unit/features/tasks/data/repositories/task_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:my_app/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:my_app/features/tasks/data/models/task_dto.dart';
import 'package:my_app/features/tasks/data/repositories/task_repository_impl.dart';

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}
class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

void main() {
  late MockTaskLocalDataSource mockLocal;
  late MockTaskRemoteDataSource mockRemote;
  late TaskRepositoryImpl repository;

  setUp(() {
    mockLocal = MockTaskLocalDataSource();
    mockRemote = MockTaskRemoteDataSource();
    repository = TaskRepositoryImpl(
      localDataSource: mockLocal,
      remoteDataSource: mockRemote,
    );
  });

  group('TaskRepositoryImpl.getTasks', () {
    const tDto = TaskDto(
      id: '1',
      title: 'Complete documentation',
      dateMillis: 1700000000,
      isCompleted: false,
    );

    test('fetches from remote, persists locally, and returns domain items', () async {
      // 1. Arrange
      when(() => mockRemote.fetchTasks()).thenAnswer((_) async => [tDto]);
      when(() => mockLocal.persist(any())).thenAnswer((_) async {});

      // 2. Act
      final result = await repository.getTasks();

      // 3. Assert
      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(result.first.title, 'Complete documentation');
      verify(() => mockRemote.fetchTasks()).called(1);
      verify(() => mockLocal.persist(tDto)).called(1);
    });
  });
}
```

---

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

## References

- Flutter testing fundamentals: https://docs.flutter.dev/testing/overview
- Testing skills reference: https://github.com/DeveloperYatin/flutter-arch-skills/blob/main/testing/flutter-testing.md
- Mocktail library: https://pub.dev/packages/mocktail
- Alchemist golden test library: https://pub.dev/packages/alchemist
