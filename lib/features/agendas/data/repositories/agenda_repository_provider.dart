import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/core/database/database_provider.dart';
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';

/// Application-wide provider for [FullAgendaRepository].
///
/// What: Instantiates the Drift-backed implementation injected with the active database.
/// Why: Exposes the abstract [FullAgendaRepository] contract for clean dependency injection and testing.
final agendaRepositoryProvider = Provider<FullAgendaRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftAgendaRepository(db);
});
