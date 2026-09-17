import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';

/// StreamProvider exposing the reactive list of active agendas.
///
/// Follows the MVVM recommendation: View subscribes to data state without managing streams.
final StreamProvider<List<Agenda>> agendasStreamProvider =
    StreamProvider<List<Agenda>>((ref) {
      final repository = ref.watch(agendaRepositoryProvider);
      return repository.watchAgendas();
    });

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
  /// Constructs a [HomeController] with the required [AgendaRepository].
  const HomeController(this._repository);

  final AgendaRepository _repository;

  /// Creates a new agenda with title, cover style, and custom initial paper style.
  Future<Agenda> createAgenda({
    required String title,
    String coverStyle = 'honey',
    String paperStyle = 'dotted',
  }) async {
    final agenda = await _repository.createAgenda(
      title: title,
      coverStyle: coverStyle,
    );

    // If initial paper style differs from default 'dotted', configure first page
    if (paperStyle != 'dotted') {
      final pages = await _repository.watchPages(agenda.id).first;
      if (pages.isNotEmpty) {
        await _repository.updatePageBackground(pages.first.id, paperStyle);
      }
    }

    return agenda;
  }

  /// Deletes an agenda by soft-deleting it in persistence.
  Future<void> deleteAgenda(String id) {
    return _repository.deleteAgenda(id);
  }
}
