import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/agendas/presentation/widgets/home/create_agenda_flow.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Floating action button that creates a new agenda.
///
/// The single "create agenda" entry point on the home screen; it delegates to
/// [showCreateAgendaAndNavigate] so the dialog, repository call and destination
/// route only exist in one place.
class HomeFab extends ConsumerWidget {
  /// Constructs a [HomeFab].
  const HomeFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      tooltip: AppLocalizations.of(context).agendaNewTitle,
      onPressed: () => showCreateAgendaAndNavigate(context, ref),
      child: const Icon(Icons.add_rounded),
    );
  }
}
