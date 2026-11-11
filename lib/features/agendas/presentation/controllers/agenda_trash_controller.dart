import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/repositories/repository_interfaces.dart';

final StreamProvider<List<Agenda>> trashedAgendasStreamProvider =
    StreamProvider.autoDispose<List<Agenda>>((ref) {
      return ref.watch(agendaRepositoryProvider).watchTrashedAgendas();
    });

final Provider<AgendaTrashController> agendaTrashControllerProvider =
    Provider<AgendaTrashController>((ref) {
      return AgendaTrashController(ref.watch(agendaRepositoryProvider));
    });

class AgendaTrashController {
  const AgendaTrashController(this._repository);

  final AgendaTrashRepository _repository;

  Future<void> restore(String id) => _repository.restoreAgenda(id);

  Future<void> deletePermanently(String id) =>
      _repository.deleteAgendaPermanently(id);
}
