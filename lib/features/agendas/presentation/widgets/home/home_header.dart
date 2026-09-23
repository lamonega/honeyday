import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// AppBar for the home dashboard displaying the "Tus agendas" title.
///
/// The header is layout-only: the single "create agenda" entry point lives in
/// the home FAB, so this bar carries no trailing actions of its own.
class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Constructs a [HomeHeader].
  const HomeHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
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
