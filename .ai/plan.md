# Honeyday — Implementation Master Plan ("Canva for Agendas")

> **Target Audience:** Autonomous AI Implementing Agents and Subagents.  
> **Repository:** `honeyday` (Flutter Cross-Platform: Android, iOS, Windows, macOS, Linux, Web).  
> **Source Spec:** `prototipo honeyday.svg` and `rules.md`.

---

## 1. Directives for Implementing Agents & Subagents

Implementing agents must break down tasks and spawn specialized **subagents** for distinct modules (e.g., Database Subagent, Canvas Engine Subagent, Catalog Widgets Subagent). 

Every subagent **MUST** strictly adhere to the following four rules:

### Rule 1: Adhere Strictly to Framework & Codebase Conventions
* **Architecture:** Feature-First organization (`lib/app/`, `lib/core/`, `lib/features/<feature>/data|domain|presentation`).
* **State Management:** Riverpod (`flutter_riverpod`). Use `AsyncValue` (`when`, `whenData`), keep providers minimal (`autoDispose`), separate business logic from UI widgets.
* **Linter & Formatting:** Conform 100% to `very_good_analysis`. No `print()` calls (use `debugPrint()`), use `const` constructors wherever possible, enforce immutability (`final` fields on all models and states).
* **Cross-Platform Safety:** **NEVER** import `dart:io` in shared or UI layers. Use platform-agnostic packages (`path_provider`, `drift_flutter`, `dio`).
* **Responsiveness:** Support Material 3 standard breakpoints (Compact < 600dp, Medium 600–840dp, Expanded > 840dp) via `LayoutBuilder` and `MediaQuery.sizeOf(context)`.

### Rule 2: Consult Official Documentation & Up-To-Date Packages
* Before writing code for third-party libraries, subagents must query external documentation (web search or MCP tools like `context7`) to ensure compatibility with the installed package versions (e.g., `drift: ^2.35.0`, `drift_flutter: ^0.3.1`, `perfect_freehand: ^2.0.0`, `go_router: ^18.0.1`).
* Never invent deprecated APIs or obsolete syntax.

### Rule 3: Leverage MCP Tools, Debug Windows & Visual Verification
* Do not develop blind. Use available tooling to visually verify and interact with features:
  * **`chrome-devtools` MCP:** Navigate to running web instances, call `take_screenshot` to verify visual rendering, and simulate `click`, `drag`, or `type_text` to test interactions.
  * **`dart-flutter` MCP:** Utilize runtime error logs (`get_runtime_errors`), widget inspection, `hot_reload`, and driver actions.
  * **Golden Tests (`alchemist`):** Generate visual snapshot tests to ensure widgets render correctly across platforms without UI regressions.

### Rule 4: Mandatory Code Comments in English Explaining "What" and "Why"
* Every class, non-trivial method, custom painter, and architectural decision must include clear docstrings and inline comments written in **English**.
* Comments must explain **what** the code does and **why** a specific approach was chosen (e.g., matrix transformation formulas, coordinate mapping, gesture prioritization).

---

## 2. Product Architecture & Mental Model

Honeyday is a **layered visual planner ("Canva for Daily Planners")**. Each page inside an agenda/daily planner is composed of stacked layers rendered inside a shared coordinate space:

```
┌────────────────────────────────────────────────────────────────────────┐
│ Layer 3: Ink & Freehand Vector Layer (Handwriting / Drawing / Brushes)  │
│          Rendered via CustomPainter using `perfect_freehand`           │
├────────────────────────────────────────────────────────────────────────┤
│ Layer 2: Interactive Content Layer (Text fields, Checklists, Inputs)   │
│          Editable inputs mapped to underlying widget data               │
├────────────────────────────────────────────────────────────────────────┤
│ Layer 1: Modular Catalog Widgets (Calendars, Calculators, Habit logs)  │
│          Freeform position (X, Y), bounds (W, H), rotation, guides      │
├────────────────────────────────────────────────────────────────────────┤
│ Layer 0: Page Surface & Alignment System (Paper grid, Snap guides)      │
└────────────────────────────────────────────────────────────────────────┘
```

### The Three Operational Modes
1. **Edit Mode (`CanvasMode.edit`):**
   * Entered from Home by tapping the pencil icon on an agenda card.
   * Elements in Layer 1 can be dragged, resized, rotated, aligned, or deleted.
   * Alignment guidelines (magnetic snapping to center, page edges, and sibling widgets) are active.
   * Ink drawing and text input inside widgets are locked out to prevent accidental changes.
2. **Writing Mode (`CanvasMode.writing`):**
   * Default mode when opening an agenda to take notes.
   * Layer 1 widget positions are completely **locked**.
   * Layer 2 (inputs) and Layer 3 (freehand stylus/touch drawing with brushes) are active.
3. **Reading Mode (`CanvasMode.reading`):**
   * All editing and drawing interactions are disabled.
   * Touch/mouse gestures drive smooth horizontal page flips via `PageView`.

---

## 3. Data Schema & Persistence (Local Drift SQLite + Supabase Ready)

All entities use UUID v4 as primary keys and include audit/sync timestamps (`created_at`, `updated_at`, `is_deleted`) to ensure future bi-directional sync with Supabase.

### Entity Relationship Model

```text
AGENDA (1) ──< PAGE (N) ──┬──< CANVAS_ELEMENT (N)
                          └──< STROKE (N)
```

* **`Agendas`**: `id` (UUID), `title`, `cover_style`, `page_count`, timestamps.
* **`Pages`**: `id` (UUID), `agenda_id`, `page_number`, `background_style`, timestamps.
* **`CanvasElements`**: `id` (UUID), `page_id`, `widget_type`, `pos_x`, `pos_y`, `width`, `height`, `rotation`, `config_json`, timestamps.
* **`Strokes`**: `id` (UUID), `page_id`, `brush_type`, `color_hex`, `stroke_width`, `points_json`, timestamps.

---

## 4. Phased Implementation Roadmap

### Phase 1: Foundation, Infrastructure & Database Setup
* **Goal:** Configure dependencies, establish the *Feature-First* directory tree, build the Drift SQLite engine, and define base themes.
* **Tasks:**
  1. Add required packages to `pubspec.yaml`:
     * Core: `drift: ^2.35.0`, `drift_flutter: ^0.3.1`, `perfect_freehand: ^2.0.0`, `uuid: ^4.5.1`, `google_fonts: ^6.3.2`.
     * Dev: `drift_dev: ^2.35.0`, `build_runner: ^2.4.15`.
  2. Implement `lib/app/`:
     * `app.dart`: Base `MaterialApp.router` wrapped in `ProviderScope`.
     * `theme.dart`: Material 3 theme with warm honey/paper palette (`#FFFDF7` paper background, `#D97706` amber accents, `#1E293B` text).
     * `router.dart`: `go_router` declaration (`/` home, `/agenda/:id` planner viewer/editor).
  3. Implement `lib/core/database/`:
     * Drift tables: `Agendas`, `Pages`, `CanvasElements`, `Strokes`.
     * Type converters: JSON converters for `config_json` and `points_json`.
     * Local database initialization using `drift_flutter` (`driftDatabase(name: 'honeyday_db')`).
  4. Run `dart run build_runner build -d` to generate Drift code.
  5. Create repository classes in `lib/features/agendas/data/repositories/`.
* **Verification:** Run `dart analyze` (0 warnings) and execute unit tests for database CRUD operations.

---

### Phase 2: Canvas Engine & Mode State Machine
* **Goal:** Implement the multi-layer interactive canvas supporting freeform positioning, alignment snapping, vector strokes, and mode switching.
* **Tasks:**
  1. **Mode State Provider:**
     * `canvasModeProvider`: Manages `CanvasMode.reading`, `CanvasMode.writing`, and `CanvasMode.edit`.
  2. **Alignment & Snapping System (`lib/features/canvas/domain/snapping.dart`):**
     * Mathematical helper calculating horizontal/vertical alignment guide lines (page center, element-to-element edges, grid thresholds).
  3. **Transformable Element Wrapper (`lib/features/canvas/presentation/widgets/transformable_box.dart`):**
     * In `edit` mode: shows resize handles on corners, rotation anchor, and drag feedback.
     * In `writing`/`reading` mode: renders pure child without transform overlays.
  4. **Vector Ink Engine (`lib/features/canvas/presentation/widgets/ink_canvas.dart`):**
     * Custom painter utilizing `perfect_freehand`.
     * Captures `PointerDownEvent`, `PointerMoveEvent`, `PointerUpEvent`.
     * Records points with normalized pressure (`details.pressure`).
     * Supports brush styles: Pen, Marker/Highlighter (semi-transparent blend mode), and Eraser (stroke-level or point-level).
     * Undo/Redo stack in memory, debounced commit to Drift SQLite.
  5. **Page Container (`lib/features/canvas/presentation/pages/page_view_canvas.dart`):**
     * Combines background, widgets layer, text inputs, and ink layer inside a `Stack`.
* **Verification:** Run app on Chrome (`flutter run -d chrome`), inspect via `chrome-devtools` MCP, take screenshot, verify drawing and drag-and-drop.

---

### Phase 3: Catalog of Reusable Agenda Widgets
* **Goal:** Create the initial set of modular widgets identified in the SVG prototype.
* **Tasks:**
  1. **Widget Contract:**
     * `AgendaWidgetDefinition`: Abstract base class specifying widget metadata, default dimensions, configuration schema, and renderer.
  2. **Day / Week Grid Widget (`lib/features/catalog/presentation/widgets/calendar_grid_widget.dart`):**
     * Configurable rows/columns (1 day, 7 days weekly spread, 30/31 days monthly view).
     * Interactive checkmarks and day headers.
  3. **Simple Budget Calculator (`lib/features/catalog/presentation/widgets/budget_widget.dart`):**
     * Simple tabular list of entries (Description, Category, Amount).
     * Automatic live calculation of Total Income, Total Expenses, and Net Balance.
     * Clean non-Excel UI with Material 3 styling.
  4. **Daily / Weekly Entry Block (`lib/features/catalog/presentation/widgets/journal_block_widget.dart`):**
     * Lined or dotted note area with date header, mood picker, and priority bullets.
  5. **Free Text & Sticker Elements (`lib/features/catalog/presentation/widgets/text_box_widget.dart`):**
     * Formatted text box with customizable font size, color, and background fill.
* **Verification:** Golden snapshot tests using `alchemist` for each widget variant.

---

### Phase 4: Agenda & Page Navigation ("Tus Agendas")
* **Goal:** Build the home dashboard and page management system.
* **Tasks:**
  1. **Home Screen (`lib/features/agendas/presentation/pages/home_page.dart`):**
     * "Tus agendas" view with responsive grid/list.
     * Agenda card with visual preview, title, total pages, and last modified date.
     * Quick action buttons: Open (Writing/Reading) and Pencil icon (Edit layout mode).
     * New Agenda creation modal (choose title, cover style, initial page template).
  2. **Page Navigation (`lib/features/agendas/presentation/pages/agenda_viewer_page.dart`):**
     * Horizontal `PageView.builder` for seamless page flipping.
     * In `reading` mode: smooth swipe transitions.
     * In `edit` / `writing` mode: swipe disabled or restricted to top toolbar arrows to prevent gesture conflicts with stylus/canvas.
  3. **Page Management Drawer / Thumbnails:**
     * Reorder pages, duplicate page, add blank page, delete page.
  4. **Auto-Save & State Debouncing:**
     * Debounced writes (500ms) to SQLite when modifying ink strokes or widget properties.
* **Verification:** Test agenda creation, page switching, and data reload after app restart.

---

### Phase 5: Verification, Quality Assurance & Polishing
* **Goal:** Guarantee 100% adherence to quality rules, zero regressions, and smooth cross-platform execution.
* **Tasks:**
  1. **Strict Lint Audit:**
     * Run `dart analyze .` and eliminate every warning/hint.
     * Run `dart format --set-exit-if-changed .` across all files.
  2. **Automated Testing Suite:**
     * Unit tests for models, serialization, and budget calculation logic.
     * Golden tests with `alchemist` for responsive breakpoints (Compact, Medium, Expanded).
  3. **Visual & Interaction Walkthrough:**
     * Test on Web via `chrome-devtools` MCP: take screenshots of Home, Edit Mode, and Writing Mode.
     * Test on Windows Desktop (`flutter run -d windows`).

---

## 5. Definition of Done (DoD) Checklist

An implementing agent can consider a task complete only when:
- [ ] Code strictly complies with `very_good_analysis` (zero lints from `dart analyze`).
- [ ] Every new file and method contains English comments explaining *what* and *why*.
- [ ] No direct `dart:io` calls in UI or cross-platform domain logic.
- [ ] Unit tests pass via `flutter test`.
- [ ] Visual verification was performed and recorded using `alchemist` golden tests or `chrome-devtools` MCP screenshots.
- [ ] Changes are cleanly committed to version control with descriptive messages.
