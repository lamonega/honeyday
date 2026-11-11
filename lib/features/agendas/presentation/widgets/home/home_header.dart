import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// AppBar for the home dashboard displaying the "Tus agendas" title.
///
/// Creation lives in the home FAB; the trailing action opens recoverable trash.
class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Constructs a [HomeHeader].
  const HomeHeader({required this.onOpenTrash, super.key});

  final VoidCallback onOpenTrash;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      actions: [
        IconButton(
          tooltip: l10n.agendaTrashTitle,
          onPressed: onOpenTrash,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
      title: Text(
        l10n.homeTitle,
        style: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
