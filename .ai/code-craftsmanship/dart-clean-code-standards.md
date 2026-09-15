# Dart clean code and craftsmanship standards

Standards for writing idiomatic, robust, and maintainable Dart code.

---

## SOLID principles in Dart

```text
+--------+----------------------------+-----------------------------------------------------+
| Letter | Principle                  | Application in Dart / Flutter                       |
+--------+----------------------------+-----------------------------------------------------+
| S      | Single responsibility      | Classes and functions have one reason to change.    |
| O      | Open / closed              | Extend behavior through abstractions/mixins.        |
| L      | Liskov substitution        | Subtypes honor interface contracts without quirks.  |
| I      | Interface segregation      | Prefer small focused interfaces over fat contracts. |
| D      | Dependency inversion       | High-level code depends on abstract interfaces.     |
+--------+----------------------------+-----------------------------------------------------+
```

---

## Nomenclature rules

```text
+-------------------+-------------+---------------------------------------------------------+
| Category          | Style       | Example                                                 |
+-------------------+-------------+---------------------------------------------------------+
| Classes / Enums   | PascalCase  | TaskItem, UserRole, AuthState                           |
| Variables / Methods| camelCase  | fetchTaskItems(), isLoading                             |
| Files / Folders   | snake_case  | task_repository.dart, app_colors.dart                   |
| Boolean properties| is/has/can  | isCompleted, hasError, canEdit                          |
+-------------------+-------------+---------------------------------------------------------+
```

---

## Function design and flat control flow

1. **Keep functions small:** Under 20 lines of code.
2. **Early returns:** Exit early when preconditions fail instead of deeply nesting code blocks:

```dart
// Bad: Nested control flow
void processTask(TaskItem? item) {
  if (item != null) {
    if (item.isValid) {
      save(item);
    } else {
      logError();
    }
  }
}

// Good: Flat control flow with early guard checks
void processTask(TaskItem? item) {
  if (item == null) return;
  if (!item.isValid) {
    logError();
    return;
  }
  save(item);
}
```

3. **Pattern matching with switch expressions:**

```dart
String getStatusLabel(Status status) => switch (status) {
  Status.initial => 'Ready',
  Status.loading => 'In progress',
  Status.success => 'Completed',
  Status.error => 'Failed',
};
```

---

## References

- Effective Dart style guide: https://dart.dev/effective-dart
- Effective Dart design guidelines: https://dart.dev/effective-dart/design
- Dart pattern matching documentation: https://dart.dev/language/patterns
- Flutter clean code rules: https://github.com/KhalidWar/flutter_cursor_rules
