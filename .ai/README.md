# Flutter clean architecture skills

This directory contains modular engineering standards, architecture patterns, and coding guidelines for Flutter projects.

---

## Skills index

### 1. clean-architecture
* [clean-architecture-principles.md](clean-architecture/clean-architecture-principles.md): Three-layer separation (domain, data, presentation), inward dependency rule, and feature-first modularity.
* [repository-pattern.md](clean-architecture/repository-pattern.md): Abstract interface contracts, data sources, DTOs, mappers, and error wrapping.

### 2. riverpod-state-management
* [riverpod-clean-guidelines.md](riverpod-state-management/riverpod-clean-guidelines.md): Notifiers, async state handling, immutable state transitions, and provider scoping rules.
* [async-safety-lifecycle.md](riverpod-state-management/async-safety-lifecycle.md): Guards against unmounted widget gaps, safe cleanup, and memory leak prevention.

### 3. presentation-widgets
* [atomic-widgets-rules.md](presentation-widgets/atomic-widgets-rules.md): Dumb widgets, const constructors, eliminating helper methods, and typed callbacks.
* [adaptive-navigation-gorouter.md](presentation-widgets/adaptive-navigation-gorouter.md): Declarative routing with GoRouter, persistent app shell, and responsive breakpoints.

### 4. code-craftsmanship
* [dart-clean-code-standards.md](code-craftsmanship/dart-clean-code-standards.md): SOLID principles in Dart, function length limits, flat control flow, and pattern matching.
* [very-good-analysis-lints.md](code-craftsmanship/very-good-analysis-lints.md): Zero-warning policy, strict linter compliance, and class member ordering.

### 5. testing
* [clean-testing-patterns.md](testing/clean-testing-patterns.md): Testing pyramid, unit tests with Mocktail (AAA pattern), widget tests, and golden tests with Alchemist.

---

## Architecture overview

```text
+-------------------------------------------------------------+
|                     Presentation layer                      |
|          (Widgets, Controllers, AsyncNotifiers)             |
+------------------------------+------------------------------+
                               |
                               | (watches state, dispatches)
                               v
+-------------------------------------------------------------+
|                        Domain layer                         |
|   (Pure Dart: Entities, Value Objects, Repository contracts)|
+------------------------------^------------------------------+
                               |
                               | (implements interfaces)
                               |
+------------------------------+------------------------------+
|                         Data layer                          |
|    (Repository implementations, Data sources, DTOs, APIs)   |
+-------------------------------------------------------------+
```

---

## References

- Flutter architecture recommendations: https://docs.flutter.dev/app-architecture/recommendations
- Flutter design patterns (Result): https://docs.flutter.dev/app-architecture/design-patterns/result
- Effective Dart: https://dart.dev/effective-dart
- Riverpod documentation: https://riverpod.dev
- GoRouter documentation: https://pub.dev/packages/go_router
- Material 3 layout breakpoints: https://m3.material.io/foundations/layout/applying-layout/window-size-classes
- Very Good Analysis: https://pub.dev/packages/very_good_analysis
- Mocktail: https://pub.dev/packages/mocktail
- Alchemist: https://pub.dev/packages/alchemist
- DeveloperYatin flutter-arch-skills: https://github.com/DeveloperYatin/flutter-arch-skills
- sgaabdu4 building-flutter-apps: https://github.com/sgaabdu4/building-flutter-apps
- KhalidWar flutter_cursor_rules: https://github.com/KhalidWar/flutter_cursor_rules
