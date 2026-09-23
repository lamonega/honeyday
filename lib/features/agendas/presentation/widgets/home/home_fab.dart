import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/agendas/presentation/widgets/home/create_agenda_flow.dart';

/// Floating action button that creates a new agenda.
///
/// Delegates to [showCreateAgendaAndNavigate], shared with the home AppBar
/// action, so both entry points run the exact same create flow.
class HomeFab extends ConsumerWidget {
  /// Constructs a [HomeFab].
  const HomeFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => showCreateAgendaAndNavigate(context, ref),
      child: const Icon(Icons.add_rounded),
    );
  }
}
