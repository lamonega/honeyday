# Async safety and lifecycle management

Rules to prevent unmounted widget exceptions, memory leaks, and stale async callbacks in Flutter.

---

## The async gap problem

```text
Widget mounted ---> [ Start async work ] ---> (User navigates away / unmounts)
                           |
                           v
                   [ Async work finishes ]
                           |
                           +---> Without guard: Exception (context used after unmount)
                           +---> With guard: if (!context.mounted) return; (Safe exit)
```

---

## Core rules

### 1. Guard BuildContext with context.mounted

Always check `context.mounted` immediately after an `await` before accessing `context`:

```dart
// Bad: Can throw if the user navigated back during save()
Future<void> _onSave(BuildContext context, WidgetRef ref) async {
  await ref.read(taskControllerProvider.notifier).save();
  Navigator.of(context).pop();
}

// Good: Safely aborts if the widget unmounted
Future<void> _onSave(BuildContext context, WidgetRef ref) async {
  await ref.read(taskControllerProvider.notifier).save();
  if (!context.mounted) return;
  Navigator.of(context).pop();
}
```

### 2. Guard Notifier state mutations with ref.mounted

Inside `Notifier` or `AsyncNotifier` methods:

```dart
// Good: Discard mutation if the notifier was disposed during fetch
Future<void> loadData() async {
  state = const AsyncValue.loading();
  try {
    final data = await _service.fetch();
    if (!ref.mounted) return;
    state = AsyncValue.data(data);
  } catch (error, stackTrace) {
    if (!ref.mounted) return;
    state = AsyncValue.error(error, stackTrace);
  }
}
```

### 3. Cleanup controllers and subscriptions

Always dispose subscriptions, timers, and controllers:

```dart
// In Riverpod providers:
ref.onDispose(() {
  subscription.cancel();
  timer.cancel();
});

// In StatefulWidget:
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

---

## Common pitfalls summary

```text
+------------------------------------+--------------------------------+--------------------------------+
| Anti-pattern                       | Risk                           | Solution                       |
+------------------------------------+--------------------------------+--------------------------------+
| Calling context after await        | Runtime crash                  | if (!context.mounted) return;  |
| Mutating state after disposal      | Riverpod lifecycle error       | if (!ref.mounted) return;      |
| Unguarded timer or subscription    | Memory and battery leak        | Cancel in onDispose or dispose |
+------------------------------------+--------------------------------+--------------------------------+
```

---

## References

- Dart linter rule use_build_context_synchronously: https://dart.dev/tools/linter-rules/use_build_context_synchronously
- Flutter BuildContext.mounted documentation: https://api.flutter.dev/flutter/widgets/BuildContext/mounted.html
- Async mutations reference: https://github.com/sgaabdu4/building-flutter-apps/blob/master/skills/building-flutter-apps/references/state-management/async-mutations.md
