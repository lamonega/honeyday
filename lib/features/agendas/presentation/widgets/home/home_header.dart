import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// AppBar for the home dashboard displaying the "Tus agendas" title.
///
/// The trailing action slot is left open so callers can inject an
/// [actions] list via the [HomeHeader] constructor. This keeps the
/// header focused on layout and styling while remaining composable.
class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Constructs a [HomeHeader].
  const HomeHeader({this.actions, super.key});

  /// Optional widgets displayed at the end of the AppBar (e.g. a create button).
  final List<Widget>? actions;

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
      actions: actions,
    );
  }
}
