import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/core/constants/app_constants.dart';
import 'package:honeyday/features/agendas/presentation/controllers/home_controller.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_agenda_dialog.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Floating action button that creates a new agenda.
///
/// On tap, opens [NewAgendaDialog] and, on confirmation, creates the agenda
/// via [HomeController] then navigates to the edit route.
class HomeFab extends ConsumerWidget {
  /// Constructs a [HomeFab].
  const HomeFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showCreateAgendaDialog(context, ref),
      child: const Icon(Icons.add_rounded),
    );
  }

  Future<void> _showCreateAgendaDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const NewAgendaDialog(),
    );

    if (result == null || !context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final title = result['title'] ?? l10n.agendaNewDefaultTitle;
    final coverStyle = result['coverStyle'] ?? kDefaultCoverStyle;
    final paperStyle = result['paperStyle'] ?? kDefaultPaperStyle;

    final controller = ref.read(homeControllerProvider);
    final createdAgenda = await controller.createAgenda(
      title: title,
      coverStyle: coverStyle,
      paperStyle: paperStyle,
    );

    if (context.mounted) {
      context.go('/agenda/${createdAgenda.id}?mode=edit');
    }
  }
}
