import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';

/// Modal dialog for creating a new agenda notebook.
///
/// What: Collects title, cover theme color, and initial paper texture.
/// Why: Provides an easy creation flow before opening the canvas editor.
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

  static const _paperStyles = <String, String>{
    'dotted': 'Puntos',
    'lined': 'Rayas',
    'grid': 'Cuadrícula',
    'blank': 'Blanca',
  };

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Nueva Agenda',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? HoneydayTheme.inkSlate
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
          child: const Text('Crear Agenda'),
        ),
      ],
    );
  }
}
