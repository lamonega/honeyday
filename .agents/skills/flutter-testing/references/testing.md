> **Ejemplos ilustrativos:** `tasks`, `my_app` y sus rutas no existen aquí; Mocktail no figura en `pubspec.yaml` y su ejemplo requiere añadir esa dependencia. Alchemist sí está declarado y existen golden tests. Los ejemplos se conservan completos, pero no se han compilado ni ejecutado. Consulta CI para las variantes de plataforma.

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

## References

- Flutter testing fundamentals: https://docs.flutter.dev/testing/overview
- Testing skills reference: https://github.com/DeveloperYatin/flutter-arch-skills/blob/main/testing/flutter-testing.md
- Mocktail library: https://pub.dev/packages/mocktail
- Alchemist golden test library: https://pub.dev/packages/alchemist
