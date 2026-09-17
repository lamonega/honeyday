# Riverpod clean state management

Best practices and constraints for clean state management in Flutter using Riverpod.

---

## State and event flow

```text
[ UI Widget ] --( Dispatches event: ref.read )--> [ AsyncNotifier ]
      ^                                                  |
      |                                                  | (Updates state)
      +--------------( Watches state: ref.watch )--------+
```

---

## Provider types overview

```text
+----------------------+--------------------+---------------------------------------+
| Use case             | Provider type      | Typical state                         |
+----------------------+--------------------+---------------------------------------+
| UI toggles, filters  | Notifier           | T (Immutable object / primitive)      |
| Async queries, APIs  | AsyncNotifier      | AsyncValue<T> (loading, data, error)  |
| Computed data        | Functional ref     | Derived value                         |
| Real-time streams    | StreamNotifier     | AsyncValue<T>                         |
+----------------------+--------------------+---------------------------------------+
```

---

## Implementation example

```dart
// lib/features/tasks/presentation/controllers/task_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../providers/task_providers.dart';

class TaskController extends AutoDisposeAsyncNotifier<List<TaskItem>> {
  @override
  Future<List<TaskItem>> build() async {
    final repository = ref.watch(taskRepositoryProvider);
    return repository.getTasks();
  }

  Future<void> addTask(TaskItem item) async {
    if (!ref.mounted) return;

    state = const AsyncValue.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskRepositoryProvider);
      await repository.saveTask(item);
      return repository.getTasks();
    });
  }

  Future<void> deleteTask(String id) async {
    if (!ref.mounted) return;

    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskRepositoryProvider);
      await repository.deleteTask(id);
      return repository.getTasks();
    });
  }
}

final taskControllerProvider =
    AsyncNotifierProvider.autoDispose<TaskController, List<TaskItem>>(
  TaskController.new,
);
```

---

## Access rules: watch, read, and listen

- **ref.watch:**
  - Used in widget `build()` or inside provider definitions.
  - Subscribes to changes and triggers rebuilds.
  - Never call `ref.watch` inside button callbacks or lifecycle handlers.

- **ref.read:**
  - Used in user interaction callbacks (`onPressed`).
  - Reads a provider instance or notifier without subscribing to state updates.
  - Never call `ref.read` inside `build()` to render reactive data.

- **ref.listen:**
  - Used in `build()` to handle side-effects (toasts, dialogs, route transitions).

---

## Selective rebuilding with select

Avoid rebuilding an entire widget tree when only one field changes:

```dart
// Bad: Rebuilds on any user state update
final user = ref.watch(userProfileProvider);
return Text(user.name);

// Good: Rebuilds only when the name property changes
final userName = ref.watch(userProfileProvider.select((u) => u.name));
return Text(userName);
```

---

## References

- Riverpod official documentation: https://riverpod.dev/docs/introduction/getting_started
- Riverpod providers concept: https://riverpod.dev/docs/concepts/providers
- Riverpod codegen rules reference: https://github.com/sgaabdu4/building-flutter-apps/blob/master/skills/building-flutter-apps/references/riverpod-codegen.md
