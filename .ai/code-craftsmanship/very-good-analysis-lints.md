# Very good analysis and linter discipline

Practices for maintaining zero-warning compliance with strict static analysis.

---

## Static analysis lifecycle

```text
[ Write code ] ---> [ Format: dart format . ] ---> [ Analyze: dart analyze ] ---> [ Zero issues: Commit ]
                                                           |
                                                           +---> If issues: Fix before proceeding
```

---

## Key enforced rules

```text
+------------------------------------+--------------------------------+--------------------------------------+
| Rule                               | Problem                        | Standard solution                    |
+------------------------------------+--------------------------------+--------------------------------------+
| avoid_print                        | Pollutes release console       | Use debugPrint() or logger service   |
| public_member_api_docs             | Undocumented public APIs       | Add /// documentation comments       |
| prefer_const_constructors          | Memory and GC pressure         | Add const keyword                    |
| always_specify_types               | Ambiguous public contracts     | Add explicit type annotations        |
| sort_constructors_first            | Inconsistent class layout      | Order members canonically            |
+------------------------------------+--------------------------------+--------------------------------------+
```

---

## Class member ordering standard

Follow this sequence for class definitions:

```dart
class TaskManager {
  // 1. Unnamed & named constructors
  const TaskManager({required this.name});

  // 2. Factory constructors
  factory TaskManager.initial() => const TaskManager(name: 'Default');

  // 3. Static fields & methods
  static const int maxTasks = 100;

  // 4. Instance final fields
  final String name;

  // 5. Getters & setters
  bool get hasName => name.isNotEmpty;

  // 6. Overridden methods
  @override
  String toString() => 'TaskManager(name: $name)';

  // 7. Public methods
  void execute() => _runInternal();

  // 8. Private methods
  void _runInternal() {}
}
```

---

## Pre-commit verification workflow

```bash
dart format .
dart analyze
flutter test
```

---

## References

- Very Good Analysis package: https://pub.dev/packages/very_good_analysis
- Very Good Ventures linter repository: https://github.com/VeryGoodOpenSource/very_good_analysis
- Dart static analysis configuration: https://dart.dev/tools/analysis
