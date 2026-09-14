import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/features/agendas/presentation/controllers/home_controller.dart';
import 'package:honeyday/features/agendas/presentation/widgets/agenda_card.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_agenda_dialog.dart';

/// Home dashboard displaying "Tus agendas".
///
/// Implements the View in the MVVM architectural pattern recommended by the Flutter team:
/// Delegates all state streaming and business logic to [HomeController].
class HomePage extends ConsumerWidget {
  /// Constructs a [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendasAsync = ref.watch(agendasStreamProvider);

    return Scaffold(
      backgroundColor: HoneydayTheme.paperLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HoneydayTheme.honeyContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: HoneydayTheme.honeyAmber,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus agendas',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: HoneydayTheme.inkPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  'Honeyday',
                  style: TextStyle(
                    fontSize: 12,
                    color: HoneydayTheme.inkSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: HoneydayTheme.honeyAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Nueva Agenda',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showCreateAgendaDialog(context, ref),
            ),
          ),
        ],
      ),
      body: agendasAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: HoneydayTheme.honeyAmber),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error al cargar agendas: $error',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ),
        data: (agendas) {
          if (agendas.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Responsive crossAxisCount based on Material 3 standard breakpoints
              final width = constraints.maxWidth;
              final crossAxisCount = width < 600
                  ? 1
                  : width < 900
                  ? 2
                  : width < 1200
                  ? 3
                  : 4;

              return Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: agendas.length,
                  itemBuilder: (context, index) {
                    final agenda = agendas[index];
                    return AgendaCard(
                      agenda: agenda,
                      onOpenWriting: () {
                        context.go('/agenda/${agenda.id}?mode=writing');
                      },
                      onOpenReading: () {
                        context.go('/agenda/${agenda.id}?mode=reading');
                      },
                      onOpenEdit: () {
                        context.go('/agenda/${agenda.id}?mode=edit');
                      },
                      onDelete: () =>
                          _confirmDeleteAgenda(context, ref, agenda),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: HoneydayTheme.honeyContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: HoneydayTheme.honeyAmber,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes agendas creadas',
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HoneydayTheme.inkPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primer cuaderno para organizar tus días, dibujar\ny planificar tus semanas con estilo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: HoneydayTheme.inkSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: HoneydayTheme.honeyAmber,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Crear Mi Primera Agenda',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showCreateAgendaDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateAgendaDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const NewAgendaDialog(),
    );

    if (result == null || !context.mounted) return;

    final title = result['title'] ?? 'Nueva Agenda';
    final coverStyle = result['coverStyle'] ?? 'honey';
    final paperStyle = result['paperStyle'] ?? 'dotted';

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

  Future<void> _confirmDeleteAgenda(
    BuildContext context,
    WidgetRef ref,
    Agenda agenda,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Eliminar agenda?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Se eliminará "${agenda.title}" y todas sus páginas asociadas.',
          style: const TextStyle(color: HoneydayTheme.inkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: HoneydayTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(homeControllerProvider).deleteAgenda(agenda.id);
    }
  }
}
