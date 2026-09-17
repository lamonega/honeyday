# Flutter clean architecture principles

Guidelines for structuring Flutter applications with strict layer separation, dependency inversion, and feature-first modularity.

---

## Layer boundaries and dependency rule

Dependencies point strictly inward toward the domain layer.

```text
[ Presentation layer ]  --->  [ Domain layer ]  <---  [ Data layer ]
  Widgets, Controllers         Entities, Contracts       Repositories, DTOs
```

### Core responsibilities

```text
+-------------------+-------------------------------------------------------------+
| Layer             | Allowed dependencies and responsibilities                   |
+-------------------+-------------------------------------------------------------+
| Domain            | Pure Dart only. Zero Flutter or external package imports.   |
|                   | Contains immutable entities and abstract contracts.         |
+-------------------+-------------------------------------------------------------+
| Data              | Depends on Domain. Implements repository interfaces.        |
|                   | Handles network (HTTP/Dio), database storage, and DTOs.     |
+-------------------+-------------------------------------------------------------+
| Presentation      | Depends on Domain. Contains UI widgets and state notifiers. |
|                   | Renders state and forwards user actions to controllers.     |
+-------------------+-------------------------------------------------------------+
```

---

## Directory layout

Features are isolated into modular feature folders:

```text
lib/
├── app/                                 # Global bootstrap, theme, and router
├── core/                                # Shared utilities, extensions, and network clients
└── features/
    └── <feature_name>/
        ├── data/
        │   ├── datasources/             # Local and remote data sources
        │   ├── models/                  # DTOs with fromJson / toJson
        │   └── repositories/            # Repository implementations
        ├── domain/
        │   ├── models/                  # Pure immutable domain entities
        │   └── repositories/            # Abstract interface contracts
        └── presentation/
            ├── controllers/             # Riverpod Notifiers / state holders
            ├── pages/                   # Screen widgets
            └── widgets/                 # Reusable feature-level components
```

---

## Key rules

1. **Pure domain entities:**
   - Entities must use `final` fields and `const` constructors.
   - Do not include `fromJson` or `toJson` in domain entities. Serialization belongs to DTOs in the data layer.
   - Never import `flutter/widgets.dart` or platform libraries into the domain layer.

2. **Interface abstraction:**
   - Define repositories as `abstract interface class` inside `domain/repositories/`.
   - Contract methods must accept and return domain entities or primitives.

3. **Data layer isolation:**
   - External APIs and storage engines must stay inside `data/datasources/`.
   - DTOs map to domain entities via explicit conversion methods (`toEntity()` and `fromEntity()`).

4. **Presentation decoupling:**
   - Widgets render UI and capture user events. They must never perform I/O operations directly.

---

## Verification checklist

- [ ] Does the domain layer contain zero Flutter framework dependencies?
- [ ] Are all repositories defined as interfaces in the domain layer?
- [ ] Are DTOs mapped explicitly to domain entities before reaching domain or UI?
- [ ] Do dependencies point inward toward the domain?

---

## References

- Official Flutter architecture recommendations: https://docs.flutter.dev/app-architecture/recommendations
- Clean architecture skills reference: https://github.com/DeveloperYatin/flutter-arch-skills/blob/main/architecture/flutter-clean-architecture.md
- Building Flutter apps architecture specification: https://github.com/sgaabdu4/building-flutter-apps/blob/master/skills/building-flutter-apps/references/architecture.md
