import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/core/database/app_database.dart';

/// Interactive card previewing a saved agenda notebook on the home dashboard.
///
/// What: Renders a notebook-styled cover with title, page count, and quick mode shortcuts.
/// Why: Directly reflects the SVG prototype ("Tus agendas"), providing separate entry points
/// for reading/writing and edit mode (accessed via the pencil icon).
class AgendaCard extends StatelessWidget {
  /// Constructs an [AgendaCard].
  const AgendaCard({
    required this.agenda,
    required this.onOpenWriting,
    required this.onOpenReading,
    required this.onOpenEdit,
    required this.onDelete,
    super.key,
  });

  /// The agenda database entity.
  final Agenda agenda;

  /// Triggered when tapping the card or writing button to open note-taking mode.
  final VoidCallback onOpenWriting;

  /// Triggered when tapping the book icon to enter horizontal reading mode.
  final VoidCallback onOpenReading;

  /// Triggered when tapping the pencil icon to enter layout edit mode.
  final VoidCallback onOpenEdit;

  /// Triggered when requesting deletion of this agenda.
  final VoidCallback onDelete;

  /// Maps coverStyle string to a pleasing gradient.
  LinearGradient _getCoverGradient(String style) {
    switch (style.toLowerCase()) {
      case 'lavender':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        );
      case 'sage':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF047857)],
        );
      case 'rose':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
        );
      case 'slate':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF475569), Color(0xFF1E293B)],
        );
      case 'honey':
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getCoverGradient(agenda.coverStyle);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HoneydayTheme.paperBorder),
      ),
      child: InkWell(
        onTap: onOpenWriting,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notebook cover top visual
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(gradient: gradient),
                child: Stack(
                  children: [
                    // Simulated spine stitches on left
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (index) => Container(
                            width: 6,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Centered title text
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 36,
                        right: 16,
                        top: 16,
                        bottom: 16,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          agenda.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    // Delete button in top right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        tooltip: 'Eliminar agenda',
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom details and actions bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Page count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: HoneydayTheme.honeyContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${agenda.pageCount} ${agenda.pageCount == 1 ? 'pág' : 'págs'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Reading mode shortcut (Eye icon from prototype)
                  IconButton(
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 22,
                      color: HoneydayTheme.inkSlate,
                    ),
                    tooltip: 'Modo lectura (ojo)',
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpenReading,
                  ),
                  const SizedBox(width: 4),
                  // Edit mode pencil shortcut (Pencil icon from prototype)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: HoneydayTheme.honeyAmber,
                      size: 22,
                    ),
                    tooltip: 'Modo edición (lápiz)',
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpenEdit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
