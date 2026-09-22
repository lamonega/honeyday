import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/constants/app_constants.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/presentation/controllers/home_controller.dart';
import 'package:honeyday/features/agendas/presentation/widgets/home/agenda_grid_card.dart';
import 'package:honeyday/features/agendas/presentation/widgets/home/home_empty_state.dart';
import 'package:honeyday/features/agendas/presentation/widgets/home/home_fab.dart';
import 'package:honeyday/features/agendas/presentation/widgets/home/home_header.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_agenda_dialog.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

// ──────────────────────────────────────────────
// Home page layout constants
// ──────────────────────────────────────────────

/// Breakpoint for tablet layout in responsive grid.
const int kBreakpointTablet = 900;
/// Breakpoint for desktop layout in responsive grid.
const int kBreakpointDesktop = 1200;
/// Extra-large spacing for layout padding.
const double kSpacingExtraLarge = 24;
/// Grid spacing between home cards.
const double kHomeGridSpacing = 20;
/// Aspect ratio for home agenda cards.
const double kHomeCardAspectRatio = 0.85;

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
      appBar: HomeHeader(
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateAgendaDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: const HomeFab(),
      body: agendasAsync.when(
        loading: () => _buildSkeletonLoader(context),
        error: (error, _) => _buildErrorState(context, error),
        data: (agendas) {
          if (agendas.isEmpty) {
            return const HomeEmptyState();
          }

          return _AgendaGrid(agendas: agendas, onDelete: _confirmDeleteAgenda);
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

  Widget _buildErrorState(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.homeErrorLoading,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
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

    final title = result['title'] ?? AppLocalizations.of(context).agendaNewDefaultTitle;
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
          AppLocalizations.of(context).agendaDeleteTitle,
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context).agendaDeleteContent(agenda.title),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(homeControllerProvider).deleteAgenda(agenda.id);
    }
  }
}

/// Responsive grid of agenda cards.
class _AgendaGrid extends ConsumerWidget {
  const _AgendaGrid({
    required this.agendas,
    required this.onDelete,
  });

  final List<Agenda> agendas;

  /// Callback that receives a context, ref, and agenda for deletion confirmation.
  final Future<void> Function(BuildContext, WidgetRef, Agenda) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              return AgendaGridCard(
                agenda: agenda,
                index: index,
                onOpenWriting: () {
                  context.go('/agenda/${agenda.id}?mode=writing');
                },
                onOpenReading: () {
                  context.go('/agenda/${agenda.id}?mode=reading');
                },
                onOpenEdit: () {
                  context.go('/agenda/${agenda.id}?mode=edit');
                },
                onDelete: () => onDelete(context, ref, agenda),
              );
            },
          ),
        );
      },
    );
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
