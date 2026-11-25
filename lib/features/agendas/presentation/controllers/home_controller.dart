import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/core/database/persistent_storage_unavailable.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';

/// StreamProvider exposing the reactive list of active agendas.
///
/// Follows the MVVM recommendation: View subscribes to data state without managing streams.
final agendasStreamProvider = StreamProvider<List<Agenda>>(
  (ref) {
    final repository = ref.watch(agendaRepositoryProvider);
    return repository.watchAgendas();
  },
  retry: (count, error) => error is PersistentStorageUnavailable
      ? null
      : ProviderContainer.defaultRetry(count, error),
);

/// Controller providing actions for the home page.
final Provider<HomeController> homeControllerProvider =
    Provider<HomeController>((ref) {
      final repository = ref.watch(agendaRepositoryProvider);
      return HomeController(repository);
    });

/// ViewModel/Controller managing business logic and user actions for the home dashboard.
///
/// Encapsulates agenda creation, initialization of first page background, and deletions.
class HomeController {
  /// Constructs a [HomeController] with the required [FullAgendaRepository].
  const HomeController(this._repository);

  final FullAgendaRepository _repository;

  /// Creates a new agenda with title, cover style, and custom initial paper style.
  Future<Agenda> createAgenda({
    required String title,
    String coverStyle = 'honey',
    String paperStyle = 'dotted',
  }) => _repository.createAgenda(
    title: title,
    coverStyle: coverStyle,
    paperStyle: paperStyle,
  );

  /// Renames an agenda without allowing an empty or whitespace-only title.
  Future<void> renameAgenda(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', 'An agenda needs a title.');
    }
    await _repository.updateAgendaTitle(id, trimmed);
  }

  /// Deletes an agenda by soft-deleting it in persistence.
  Future<void> deleteAgenda(String id) {
    return _repository.deleteAgenda(id);
  }
}
