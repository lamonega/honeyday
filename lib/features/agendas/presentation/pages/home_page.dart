import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Honeyday',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.5),
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
        loading: () => _buildSkeletonLoader(context),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Error al cargar agendas',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$error',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        data: (agendas) {
          if (agendas.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
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
                        )
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: Duration(milliseconds: 60 * index),
                        )
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 400.ms,
                          delay: Duration(milliseconds: 60 * index),
                          curve: Curves.easeOutCubic,
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

  Widget _buildSkeletonLoader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width < 600
              ? 1
              : width < 900
              ? 2
              : 3;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.85,
            ),
            itemCount: crossAxisCount * 2,
            itemBuilder: (context, index) {
              return _SkeletonCard(delay: Duration(milliseconds: 100 * index));
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
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
                  'Aún no tienes agendas',
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 150.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 500.ms,
                  delay: 150.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 8),
            Text(
                  'Crea tu primer cuaderno para organizar tus días,\ndibujar y planificar con estilo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 250.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 500.ms,
                  delay: 250.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 32),
            FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Crear Mi Primera Agenda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showCreateAgendaDialog(context, ref),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 400.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 500.ms,
                  delay: 400.ms,
                  curve: Curves.easeOutCubic,
                )
                .then()
                .shimmer(
                  duration: 1200.ms,
                  delay: 800.ms,
                  color: Colors.white.withValues(alpha: 0.3),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
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

/// Skeleton placeholder card shown during loading.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.delay});

  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(onComplete: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: 400.ms, delay: delay)
        .shimmer(
          duration: 1500.ms,
          delay: delay,
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
        );
  }
}
