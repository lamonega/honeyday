/// UI layer constants for the Honeyday app.
///
/// Only constants referenced in 2+ files are kept here.
/// All single-use constants live at the top of the file that consumes them.

/// Responsive grid breakpoint for mobile layout.
/// Used by: app/app_shell.dart, features/agendas/presentation/pages/home_page.dart
const int kBreakpointMobile = 600;

/// Default paper style token for new agendas.
/// Used by: features/agendas/presentation/pages/home_page.dart,
/// features/agendas/presentation/widgets/new_agenda_dialog.dart
const String kDefaultPaperStyle = 'dotted';

/// Standard animation duration for consistent transitions.
/// Used by: features/agendas/presentation/widgets/new_agenda_dialog.dart,
/// features/agendas/presentation/widgets/resource_catalog_sidebar.dart,
/// features/settings/presentation/pages/settings_page.dart
const Duration kAnimationDurationNormal = Duration(milliseconds: 200);
