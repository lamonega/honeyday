import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/app/theme.dart';

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

class _NewAgendaDialogState extends State<NewAgendaDialog> {
  final _titleController = TextEditingController(text: 'Mi Agenda 2026');
  String _selectedCover = 'honey';
  String _selectedPaper = 'dotted';

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
    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeGradient = _coverGradients[_selectedCover] ?? _coverGradients['honey']!;
    final previewTitle = _titleController.text.trim().isEmpty
        ? 'Nueva Agenda'
        : _titleController.text.trim();

    return AlertDialog(
      title: Text(
        'Nueva Agenda',
        style: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: HoneydayTheme.inkPrimary,
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
                child: Container(
                  width: 170,
                  height: 110,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: activeGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Spine shadow
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
                      // Stitches
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
                      // Ribbon
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
                      // Stacked pages edge
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: 4,
                        child: Container(
                          color: const Color(0xFFFBF8EE),
                        ),
                      ),
                      // Title
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

              // Title input field
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Título de la agenda',
                  hintText: 'Ej. Finanzas y Metas 2026',
                  prefixIcon: Icon(Icons.book_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Cover color picker
              const Text(
                'Color de portada:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HoneydayTheme.inkPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _coverColors.entries.map((entry) {
                  final isSelected = _selectedCover == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCover = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? HoneydayTheme.inkPrimary
                              : Colors.transparent,
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
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Paper style selector
              const Text(
                'Estilo de hoja inicial:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HoneydayTheme.inkPrimary,
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
            backgroundColor: HoneydayTheme.honeyAmber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) return;
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
    );
  }
}
