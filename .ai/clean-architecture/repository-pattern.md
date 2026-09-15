# Flutter clean repository pattern

Implementation guide for the repository pattern in Flutter Clean Architecture, connecting data sources to the domain layer.

---

## Data flow diagram

```text
[ Data sources ] ---> [ DTOs ] ---> [ Repository implementation ] ---> [ Domain entities ]
(Remote API / DB)      (JSON)                 (Mapper)                    (Used by UI)
```

---

## Step-by-step implementation

### 1. Define the domain contract

Place repository interfaces in `domain/repositories/`:

```dart
// lib/features/tasks/domain/repositories/task_repository.dart

import '../models/task_item.dart';

abstract interface class TaskRepository {
  Future<List<TaskItem>> getTasks();
  Future<TaskItem> getTaskById(String id);
  Future<void> saveTask(TaskItem item);
  Future<void> deleteTask(String id);
  Stream<List<TaskItem>> watchTasks();
}
```

### 2. Define the data transfer object (DTO)

Place DTOs and serializations in `data/models/`:

```dart
// lib/features/tasks/data/models/task_dto.dart

import '../../domain/models/task_item.dart';

class TaskDto {
  const TaskDto({
    required this.id,
    required this.title,
    required this.dateMillis,
    required this.isCompleted,
  });

  factory TaskDto.fromJson(Map<String, dynamic> json) {
    return TaskDto(
      id: json['id'] as String,
      title: json['title'] as String,
      dateMillis: json['date_millis'] as int,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final int dateMillis;
  final bool isCompleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date_millis': dateMillis,
        'is_completed': isCompleted,
      };

  TaskItem toEntity() {
    return TaskItem(
      id: id,
      title: title,
      dateTime: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      isCompleted: isCompleted,
    );
  }

  factory TaskDto.fromEntity(TaskItem entity) {
    return TaskDto(
      id: entity.id,
      title: entity.title,
      dateMillis: entity.dateTime.millisecondsSinceEpoch,
      isCompleted: entity.isCompleted,
    );
  }
}
```

### 3. Implement the repository

Place repository implementations in `data/repositories/`:

```dart
// lib/features/tasks/data/repositories/task_repository_impl.dart

import '../../domain/models/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_dto.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl({
    required TaskLocalDataSource localDataSource,
    required TaskRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  final TaskLocalDataSource _localDataSource;
  final TaskRemoteDataSource _remoteDataSource;

  @override
  Future<List<TaskItem>> getTasks() async {
    try {
      final remoteDtos = await _remoteDataSource.fetchTasks();
      for (final dto in remoteDtos) {
        await _localDataSource.persist(dto);
      }
      return remoteDtos.map((dto) => dto.toEntity()).toList();
    } catch (_) {
      final cachedDtos = await _localDataSource.fetchAll();
      return cachedDtos.map((dto) => dto.toEntity()).toList();
    }
  }

  @override
  Future<void> saveTask(TaskItem item) async {
    final dto = TaskDto.fromEntity(item);
    await _localDataSource.persist(dto);
    await _remoteDataSource.uploadTask(dto);
  }

  @override
  Future<TaskItem> getTaskById(String id) async {
    final dto = await _remoteDataSource.fetchTaskById(id);
    return dto.toEntity();
  }

  @override
  Future<void> deleteTask(String id) async {
    await _localDataSource.remove(id);
    await _remoteDataSource.deleteTask(id);
  }

  @override
  Stream<List<TaskItem>> watchTasks() {
    return _localDataSource.watchAll().map(
          (dtos) => dtos.map((dto) => dto.toEntity()).toList(),
        );
  }
}
```

---

## Invariant rules

1. **Inject interfaces only:** Constructor dependencies must use abstract interfaces (`TaskLocalDataSource`), never concrete implementations.
2. **Explicit mappings:** Convert DTOs to entities using explicit mapping methods.
3. **Hide SDK details:** Prevent network clients or database drivers from leaking into domain contracts.

---

## References

- Flutter official design patterns (Result and Repositories): https://docs.flutter.dev/app-architecture/design-patterns/result
- Clean architecture repository pattern: https://github.com/DeveloperYatin/flutter-arch-skills/blob/main/architecture/flutter-repository-pattern.md
- Building Flutter apps persistence guidelines: https://github.com/sgaabdu4/building-flutter-apps/blob/master/skills/building-flutter-apps/references/architecture.md
