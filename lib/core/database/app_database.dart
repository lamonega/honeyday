import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Represents user-created agendas in Honeyday.
///
/// What: Stores agenda metadata such as title, visual cover theme, and page count.
/// Why: Provides offline-first storage and audit timestamps compatible with Supabase sync.
class Agendas extends Table {
  /// UUID v4 unique identifier.
  TextColumn get id => text()();

  /// User-facing title for the agenda.
  TextColumn get title => text()();

  /// Aesthetic cover design token (e.g., 'honey', 'lavender', 'sage', 'rose', 'slate').
  TextColumn get coverStyle => text().withDefault(const Constant('honey'))();

  /// Current number of pages in the agenda.
  IntColumn get pageCount => integer().withDefault(const Constant(1))();

  /// Creation timestamp in UTC.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Modification timestamp in UTC.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete indicator for synchronization conflict resolution.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Represents individual pages belonging to an agenda.
///
/// What: Stores the page sequence index and visual paper texture/grid type.
/// Why: Allows dynamic page reordering, insertion, and custom page backgrounds.
class Pages extends Table {
  /// UUID v4 unique identifier.
  TextColumn get id => text()();

  /// Foreign key linking the page to its parent agenda.
  TextColumn get agendaId => text().references(Agendas, #id)();

  /// 0-indexed or 1-indexed order sequence of this page within the agenda.
  IntColumn get pageNumber => integer()();

  /// Paper texture style (e.g., 'blank', 'dotted', 'lined', 'grid').
  TextColumn get backgroundStyle =>
      text().withDefault(const Constant('dotted'))();

  /// Creation timestamp in UTC.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Modification timestamp in UTC.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete indicator.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Represents modular canvas widgets placed on a page (Layer 1 & Layer 2).
///
/// What: Stores 2D positioning (X, Y), dimensions (width, height), rotation, and widget configuration.
/// Why: Decouples widget visual representations from the layout engine, allowing arbitrary transforms.
class CanvasElements extends Table {
  /// UUID v4 unique identifier.
  TextColumn get id => text()();

  /// Foreign key referencing the page this element is placed upon.
  TextColumn get pageId => text().references(Pages, #id)();

  /// Modular widget type discriminator (e.g. 'calendar_grid', 'budget_calculator', 'journal_block', 'text_box').
  TextColumn get widgetType => text()();

  /// X coordinate in the unscaled page coordinate system.
  RealColumn get posX => real().withDefault(const Constant(0))();

  /// Y coordinate in the unscaled page coordinate system.
  RealColumn get posY => real().withDefault(const Constant(0))();

  /// Rendered width of the widget container.
  RealColumn get width => real().withDefault(const Constant(220))();

  /// Rendered height of the widget container.
  RealColumn get height => real().withDefault(const Constant(180))();

  /// Rotation angle around center in radians.
  RealColumn get rotation => real().withDefault(const Constant(0))();

  /// JSON payload storing widget-specific contents (e.g., checklist items, budget entries, text body).
  TextColumn get configJson => text().withDefault(const Constant('{}'))();

  /// Creation timestamp in UTC.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Modification timestamp in UTC.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete indicator.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Represents freehand ink strokes drawn on a page (Layer 3).
///
/// What: Stores brush profile, hex color, stroke width, and vector points serialized as JSON.
/// Why: Allows vector stroke serialization, undo/redo reconstructability, and resolution-independent rendering.
class Strokes extends Table {
  /// UUID v4 unique identifier.
  TextColumn get id => text()();

  /// Foreign key referencing the page this stroke belongs to.
  TextColumn get pageId => text().references(Pages, #id)();

  /// Brush style profile (e.g. 'pen', 'highlighter', 'eraser').
  TextColumn get brushType => text().withDefault(const Constant('pen'))();

  /// 8-character or 6-character hex representation of the stroke color (e.g. '#1E293B', '#FFD97706').
  TextColumn get colorHex => text().withDefault(const Constant('#1E293B'))();

  /// Base thickness of the brush stroke in virtual points.
  RealColumn get strokeWidth => real().withDefault(const Constant(3))();

  /// Serialized JSON array of vector points with coordinates and pressure `[{"x":10,"y":20,"p":0.8}]`.
  TextColumn get pointsJson => text().withDefault(const Constant('[]'))();

  /// Creation timestamp in UTC.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Modification timestamp in UTC.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete indicator.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Main Drift SQLite database engine for Honeyday.
///
/// What: Manages connection, schema definition, and reactive queries.
/// Why: Uses `drift_flutter` for platform-agnostic persistence across Android, iOS, Desktop, and Web.
@DriftDatabase(tables: [Agendas, Pages, CanvasElements, Strokes])
class AppDatabase extends _$AppDatabase {
  /// Constructs an [AppDatabase].
  ///
  /// Can accept an explicit [QueryExecutor] for in-memory testing.
  AppDatabase([QueryExecutor? executor])
      : super(
          executor ??
              driftDatabase(
                name: 'honeyday_db',
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                ),
              ),
        );

  @override
  int get schemaVersion => 1;
}

/// Type alias for the Drift-generated [Page] data class to avoid naming conflicts with Flutter's `Page` widget.
typedef AgendaPage = Page;
