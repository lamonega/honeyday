> **Ejemplo ilustrativo:** `tasks`, `my_app` y sus rutas son hipotéticos; este ejemplo no se ha compilado ni ejecutado.

> Mocktail no figura en `pubspec.yaml`; usarlo requeriría incorporar la dependencia.

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

