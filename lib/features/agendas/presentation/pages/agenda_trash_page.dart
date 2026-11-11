import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/presentation/controllers/agenda_trash_controller.dart';
import 'package:honeyday/features/agendas/presentation/widgets/agenda_action_dialog.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

class AgendaTrashPage extends ConsumerWidget {
  const AgendaTrashPage({super.key});

  static const routePath = '/trash';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final agendas = ref.watch(trashedAgendasStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agendaTrashTitle),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.agendaTrashPolicy),
            ),
          ),
          agendas.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.agendaTrashError),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(trashedAgendasStreamProvider),
                      child: Text(l10n.agendaTrashRetry),
                    ),
                  ],
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(l10n.agendaTrashEmpty)),
                );
              }
              return SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => _TrashedAgendaTile(
                  agenda: items[index],
                  onRestore: () =>
                      _confirm(context, ref, items[index], permanent: false),
                  onDelete: () =>
                      _confirm(context, ref, items[index], permanent: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    Agenda agenda, {
    required bool permanent,
  }) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(agendaTrashControllerProvider);
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AgendaActionDialog(
        title: permanent
            ? l10n.agendaDeleteForeverTitle
            : l10n.agendaRestoreTitle,
        description: permanent
            ? l10n.agendaDeleteForeverContent(agenda.title)
            : l10n.agendaRestoreContent(agenda.title),
        confirmLabel: permanent ? l10n.agendaDeleteForever : l10n.agendaRestore,
        destructive: permanent,
        onConfirm: () => permanent
            ? controller.deletePermanently(agenda.id)
            : controller.restore(agenda.id),
      ),
    );
  }
}

class _TrashedAgendaTile extends StatelessWidget {
  const _TrashedAgendaTile({
    required this.agenda,
    required this.onRestore,
    required this.onDelete,
  });

  final Agenda agenda;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(agenda.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(l10n.agendaPageCount(agenda.pageCount)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.agendaRestore,
            onPressed: onRestore,
            icon: const Icon(Icons.restore_rounded),
          ),
          IconButton(
            tooltip: l10n.agendaDeleteForever,
            onPressed: onDelete,
            color: Theme.of(context).colorScheme.error,
            icon: const Icon(Icons.delete_forever_outlined),
          ),
        ],
      ),
    );
  }
}
