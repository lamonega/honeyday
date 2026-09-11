import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/core/database/app_database.dart';

/// Application-wide provider for the singleton [AppDatabase] instance.
///
/// What: Exposes the initialized Drift SQLite database instance.
/// Why: Allows widgets and repositories to query reactive database streams.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
