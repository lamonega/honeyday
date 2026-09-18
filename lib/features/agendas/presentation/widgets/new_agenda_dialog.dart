import 'dart:async';

import 'package:flutter/material.dart';
import 'package:honeyday/core/constants/app_constants.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/utils/color_utils.dart';
import 'package:honeyday/core/theme/paper_style.dart';

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
  String _selectedCover = '#D97706';
  String _selectedPaper = kDefaultPaperStyle;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  static const _presetColors = <String>[
    '#D97706',
    '#8B5CF6',
    '#10B981',
    '#F43F5E',
    '#475569',
    '#2563EB',
    '#EA580C',
    '#7C3AED',
  ];

  static const _paperStyles = PaperStyle.labels;

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
    final activeColor = hexToColor(_selectedCover);
    final darkColor = darken(activeColor);
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
                Center(
                  child: _LiveCoverPreview(
                    title: previewTitle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [activeColor, darkColor],
                    ),
                    shadowColor: activeColor,
                  ),
                ),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Título',
                    prefixIcon: Icon(Icons.book_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                _CoverColorPicker(
                  colors: _presetColors,
                  selectedCover: _selectedCover,
                  onColorSelected: (hex) =>
                      setState(() => _selectedCover = hex),
                ),
                const SizedBox(height: 20),
                _PaperStyleSelector(
                  styles: _paperStyles,
                  selectedPaper: _selectedPaper,
                  onPaperSelected: (key) =>
                      setState(() => _selectedPaper = key),
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
              unawaited(HapticFeedback.lightImpact());
              Navigator.of(context).pop({
                'title': title,
                'coverStyle': _selectedCover,
                'paperStyle': _selectedPaper,
              });
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

}

class _LiveCoverPreview extends StatelessWidget {
  const _LiveCoverPreview({
    required this.title,
    required this.gradient,
    required this.shadowColor,
  });

  final String title;
  final LinearGradient gradient;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 170,
      height: 110,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.35),
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
            child: Container(color: const AppColors.paperEdge),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
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
    );
  }
}

class _CoverColorPicker extends StatelessWidget {
  const _CoverColorPicker({
    required this.colors,
    required this.selectedCover,
    required this.onColorSelected,
  });

  final List<String> colors;
  final String selectedCover;
  final ValueChanged<String> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((hex) {
        final isSelected = selectedCover == hex;
        final color = hexToColor(hex);
        return GestureDetector(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            onColorSelected(hex);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: isSelected ? 2.5 : 0,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

}

class _PaperStyleSelector extends StatelessWidget {
  const _PaperStyleSelector({
    required this.styles,
    required this.selectedPaper,
    required this.onPaperSelected,
  });

  final Map<String, String> styles;
  final String selectedPaper;
  final ValueChanged<String> onPaperSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: styles.entries.map((entry) {
        return ButtonSegment(value: entry.key, label: Text(entry.value));
      }).toList(),
      selected: {selectedPaper},
      onSelectionChanged: (newSelection) {
        unawaited(HapticFeedback.selectionClick());
        onPaperSelected(newSelection.first);
      },
    );
  }
}
