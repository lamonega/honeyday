import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the local SQLite database on native platforms.
DatabaseConnection openDatabaseConnection(String name) =>
    driftDatabase(name: name);
