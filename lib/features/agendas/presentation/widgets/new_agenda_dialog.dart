import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modal dialog for creating a new agenda notebook.
///
/// What: Collects title, cover theme color, and initial paper texture with a live cover preview.
/// Why: Provides a delightful and tactile creation flow before opening the canvas editor.
class NewAgendaDialog extends StatefulWidget {
  /// Constructs a [NewAgendaDialog].
  const NewAgendaDialog({super.key});

  @override
  State<NewAgendaDialog> createState() => _NewAgendaDialogState();
}

class _NewAgendaDialogState extends State<NewAgendaDialog>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController(text: 'Mi Agenda 2026');
  String _selectedCover = 'honey';
  String _selectedPaper = 'dotted';
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  static const _coverColors = <String, Color>{
    'honey': Color(0xFFD97706),
    'lavender': Color(0xFF8B5CF6),
    'sage': Color(0xFF10B981),
    'rose': Color(0xFFF43F5E),
    'slate': Color(0xFF475569),
  };

  static const _coverGradients = <String, LinearGradient>{
    'honey': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    'lavender': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    ),
    'sage': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10B981), Color(0xFF047857)],
    ),
    'rose': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
    ),
    'slate': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF475569), Color(0xFF1E293B)],
    ),
  };

  static const _paperStyles = <String, String>{
    'dotted': 'Puntos',
    'lined': 'Rayas',
    'grid': 'Cuadrícula',
    'blank': 'Blanca',
  };

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeGradient = _coverGradients[_selectedCover] ?? _coverGradients['honey']!;
    final previewTitle = _titleController.text.trim().isEmpty
        ? 'Nueva Agenda'
        : _titleController.text.trim();
    final colorScheme = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _scaleAnim,
      child: AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Nueva Agenda',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live notebook cover preview
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 170,
                    height: 110,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: activeGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _coverColors[_selectedCover]!.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 6,
                          top: 0,
                          bottom: 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              4,
                              (i) => Container(
                                width: 3,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 28,
                          child: Container(
                            width: 8,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          width: 4,
                          child: Container(color: const Color(0xFFFBF8EE)),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              previewTitle,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.fraunces(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Title input
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título de la agenda',
                    hintText: 'Ej. Finanzas y Metas 2026',
                    prefixIcon: Icon(Icons.book_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Cover color picker
                Text(
                  'Color de portada:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _coverColors.entries.map((entry) {
                    final isSelected = _selectedCover == entry.key;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCover = entry.key);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colorScheme.onSurface : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: entry.value.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Paper style selector
                Text(
                  'Estilo de hoja inicial:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: _paperStyles.entries.map((entry) {
                    return ButtonSegment(
                      value: entry.key,
                      label: Text(entry.value),
                    );
                  }).toList(),
                  selected: {_selectedPaper},
                  onSelectionChanged: (newSelection) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedPaper = newSelection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) return;
              HapticFeedback.lightImpact();
              Navigator.of(context).pop({
                'title': title,
                'coverStyle': _selectedCover,
                'paperStyle': _selectedPaper,
              });
            },
            child: const Text(
              'Crear Agenda',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
