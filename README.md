<p align="center">
  <img src="https://raw.githubusercontent.com/lamonega/honeyday/HEAD/assets/images/honeyday_logo.png" alt="Honeyday Logo" width="120">
</p>

<h1 align="center">Honeyday</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Linux%20%7C%20macOS%20%7C%20Windows-blue?style=for-the-badge" alt="Platforms">
  <img src="https://img.shields.io/badge/License-GPL--3.0-green?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/github/actions/workflow/status/lamonega/honeyday/ci.yml?branch=develop&style=for-the-badge&label=CI" alt="CI">
  <img src="https://img.shields.io/github/v/tag/lamonega/honeyday?style=for-the-badge&color=orange&label=version&sort=semver" alt="Version">
</p>

<p align="center">
  <strong>Digital agenda & journal app with freehand ink, modular widgets, and a warm paper aesthetic.</strong>
</p>

<p align="center">
  Built with Flutter — Multiplatform (Android, iOS, Web, Linux, macOS, Windows)
</p>

---

## Features

- **Multi-agenda management** — Create, rename, and switch between multiple agendas with custom covers and paper styles. Rename directly from a cover's action button; failed saves keep your new title available for retry.
- **Freehand ink engine** — Write, draw, and highlight with pressure-sensitive vector strokes (pen, highlighter, eraser).
- **Modular canvas widgets** — Drop shapes, planner templates, stickers, calendars, budget trackers, and more onto your pages.
- **Three interaction modes** — Reading (flip pages), Writing (ink drawing), Edit (drag, resize, rotate widgets).
- **Resume where you left off** — Each agenda remembers the last visited page on this device, even after reordering pages. Missing/deleted bookmarks fall back to the first page.
- **Duplicate pages** — Copy a page from the page manager, including its paper style, editable elements and handwriting. The independent copy is inserted immediately after the original; pending field edits are saved before copying.
- **Customizable themes** — System / light / dark mode, 8 accent color presets, warm paper-and-honey aesthetic.
- **Onboarding flow** — Clean 3-step onboarding carousel.
- **Local storage** — SQLite persistence via Drift. No account or cloud synchronization is required or currently implemented.
- **Editable backups** — Export/import all active agendas, page elements and handwriting as a portable `.honeyday` file. Imports create independent copies without overwriting existing agendas. See [backup scope, privacy and limitations](docs/backups.md).
- **PDF templates** — Export covers and page elements to PDF; handwritten ink is not currently included in PDF export (use editable backups to preserve it).
- **Responsive layout** — Adaptive navigation (bottom bar on mobile, rail on desktop).

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Flutter](https://flutter.dev) 3.x |
| State Management | [Riverpod](https://riverpod.dev) |
| Routing | [GoRouter](https://pub.dev/packages/go_router) |
| Local Database | [Drift](https://drift.simonbinder.eu) (SQLite) |
| Fonts | [Google Fonts](https://fonts.google.com) (Fraunces + Plus Jakarta Sans) |
| Animations | [flutter_animate](https://pub.dev/packages/flutter_animate) |
| Ink Engine | [perfect_freehand](https://pub.dev/packages/perfect_freehand) |
| Linting | [Very Good Analysis](https://pub.dev/packages/very_good_analysis) |

## Project Structure

```
lib/
├── app/                    # App shell, router, theme
│   ├── app.dart            # Root widget, providers
│   ├── app_shell.dart      # Navigation scaffold
│   ├── router.dart         # GoRouter config
│   └── theme.dart          # Material 3 themes
├── core/                   # Shared infrastructure
│   ├── accessibility/      # Semantic widgets
│   ├── constants/          # Shared UI constants
│   ├── database/           # Drift schema & providers
│   ├── l10n/               # Localization extensions
│   ├── providers/          # Riverpod providers (prefs, app version)
│   ├── theme/              # Colors, paper styles, design tokens
│   ├── utils/              # Color & haptic helpers
│   └── widgets/            # Reusable widgets (category filter)
├── features/               # Feature modules (domain / data / presentation)
│   ├── agendas/            # Agenda CRUD & viewer
│   ├── backup/             # Portable editable backups, validation & restore
│   ├── canvas/             # Ink canvas, transform engine, snapping
│   ├── catalog/            # Widget registry & modular elements
│   ├── export/             # PDF capture, compression workers & output
│   ├── onboarding/         # First-launch flow
│   └── settings/           # Preferences & appearance
└── main.dart               # Entry point
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install), stable channel. CI is pinned to **Flutter 3.47.5**; use the same version for reproducible checks.
- Dart SDK (bundled with Flutter), compatible with `pubspec.yaml` (`^3.13.3`).

Platform folders exist for Android, iOS, Web, Linux, macOS and Windows. CI runs
analysis and tests on Windows and builds the JavaScript Web target on Linux.
A platform listing is not a guarantee that its native file dialogs, pen input
or release packaging have been verified.

### Installation

```bash
# Clone the repository
git clone https://github.com/lamonega/honeyday.git
cd honeyday

# Install dependencies
flutter pub get

# Run code generation (Drift)
dart run build_runner build --delete-conflicting-outputs

# Launch the app
flutter run
```

### Verification

```bash
dart analyze
flutter test
flutter build web
```

`flutter build web` checks the browser target; it is separate from Drift code
generation. Native release builds require the corresponding platform toolchain.
Golden baselines have Windows and CI variants. Format only the files you change
with `dart format <paths>` rather than rewriting unrelated files.

The export benchmarks are excluded from that run. They are slow and their
numbers are machine-specific, so run them explicitly:

```bash
dart run test/benchmark/export_page_cost.dart          # per-page cost, old vs new
flutter test test/benchmark --run-skipped              # full pipeline, end to end
```

## License

This project is licensed under the **GNU General Public License v3.0** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with care by <a href="https://github.com/lamonega">lamonega</a>
</p>
