# Contributing to Honeyday

Thanks for your interest in contributing! This guide will help you get up and running.

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- [Dart SDK](https://dart.dev/get-dart) (bundled with Flutter)
- [Very Good CLI](https://cli.vgv.dev/) (optional, for scaffolding)

## Getting Started

```bash
# Fork and clone the repo
git clone https://github.com/<your-username>/honeyday.git
cd honeyday

# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Verify everything works
flutter analyze
flutter test
```

## Project Structure

This project follows [Clean Architecture](https://pub.dev/packages/flutter_clean_architecture) principles:

```
lib/features/<feature>/
├── domain/          # Models, repositories (abstract), use cases
├── data/            # Repository implementations, data sources
└── presentation/    # Pages, widgets, controllers (Riverpod)
```

When adding a new feature, create a new directory under `lib/features/` following this structure.

## Code Style

- This project uses **Very Good Analysis** for linting. Run `flutter analyze` before committing.
- Prefer `const` constructors where possible.
- Use `final` for immutable variables.
- Follow the existing naming conventions (camelCase for variables/functions, PascalCase for classes).
- Avoid `print()` statements — use logging or debug tools instead.

## Branching

- `main` — stable, production-ready code
- `feat/<name>` — new features
- `fix/<name>` — bug fixes
- `chore/<name>` — maintenance, refactoring, tooling

## Pull Requests

1. Create a feature branch from `main`
2. Make your changes
3. Run `flutter analyze` and `flutter test` — ensure no errors
4. Commit with a [conventional commit](https://www.conventionalcommits.org/) message:
   - `feat: add new widget type`
   - `fix: resolve page ordering bug`
   - `docs: update README`
   - `chore: upgrade dependencies`
5. Open a PR against `main` with a clear description

## Golden Tests

If you modify visual widgets, update golden files:

```bash
flutter test --update-goldens
```

Review the diffs in `test/golden/goldens/` before committing.

## Reporting Issues

- Use [GitHub Issues](https://github.com/lamonega/honeyday/issues)
- Include steps to reproduce, expected vs actual behavior
- Mention your Flutter version and target platform

## License

By contributing, you agree that your contributions will be licensed under the [GPL-3.0 License](LICENSE).
