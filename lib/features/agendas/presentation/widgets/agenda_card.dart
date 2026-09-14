import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/core/database/app_database.dart';

/// Interactive card previewing a saved agenda notebook on the home dashboard.
///
/// What: Renders a tactile notebook-styled cover with spine stitch, page edges,
/// ribbon bookmark, Fraunces editorial title, and quick mode shortcuts.
/// Why: Directly reflects the physical agenda aesthetic of Honeyday, providing clear
/// entry points for reading/writing and edit mode.
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

  /// Maps coverStyle string to a rich physical notebook gradient.
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
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
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
                    // Subtle light curvature highlight across the notebook cover
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Spine shadow band on left
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Simulated spine stitches on left
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (index) => Container(
                            width: 5,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 1,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bookmark ribbon hanging from top
                    Positioned(
                      top: 0,
                      right: 44,
                      child: Container(
                        width: 12,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Stacked paper pages edge on the right
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF8EE),
                          border: Border(
                            left: BorderSide(
                              color: Colors.black.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            8,
                            (i) => Container(
                              height: 1,
                              color: const Color(0xFFE2D8C0),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Notebook title text (Fraunces editorial)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32,
                        right: 48,
                        top: 18,
                        bottom: 16,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          agenda.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fraunces(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Delete button in top right
                    Positioned(
                      top: 6,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white70,
                          size: 19,
                        ),
                        tooltip: 'Eliminar agenda',
                        visualDensity: VisualDensity.compact,
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
                        color: HoneydayTheme.honeyDark,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Reading mode shortcut (Eye icon from prototype)
                  IconButton(
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 20,
                      color: HoneydayTheme.inkSecondary,
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
                      size: 20,
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
