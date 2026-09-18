import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/constants/app_constants.dart';
import 'package:honeyday/l10n/app_localizations.dart';
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
        title: Text(
          'Honeyday',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateAgendaDialog(context, ref),
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
              final crossAxisCount = width < kBreakpointMobile
                  ? 1
                  : width < kBreakpointTablet
                  ? 2
                  : width < kBreakpointDesktop
                  ? 3
                  : 4;

              return Padding(
                padding: const EdgeInsets.all(kSpacingExtraLarge),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: kHomeGridSpacing,
                    mainAxisSpacing: kHomeGridSpacing,
                    childAspectRatio: kHomeCardAspectRatio,
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
                          begin: kOnboardingScaleBegin,
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
      padding: const EdgeInsets.all(kSpacingExtraLarge),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width < kBreakpointMobile
              ? 1
              : width < kBreakpointTablet
              ? 2
              : 3;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: kHomeGridSpacing,
              mainAxisSpacing: kHomeGridSpacing,
              childAspectRatio: kHomeCardAspectRatio,
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
            Icon(
              Icons.auto_stories_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Sin agendas',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca + para crear una.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
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

    final title = result['title'] ?? AppLocalizations.of(context).newAgenda;
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
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({required this.delay});
  final Duration delay;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
                            .withValues(alpha: 0.5 + _animation.value * 0.5),
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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5 + _animation.value * 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5 + _animation.value * 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
