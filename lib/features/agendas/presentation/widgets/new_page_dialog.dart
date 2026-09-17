import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';

/// Shows a dialog prompting the user to choose the layout/paper design for a new page.
Future<String?> showNewPageDesignDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const NewPageDesignDialog(),
  );
}

/// Modal dialog allowing users to pick a paper design when adding a new agenda page.
class NewPageDesignDialog extends StatefulWidget {
  const NewPageDesignDialog({super.key, this.initialStyle = PaperStyle.dotted});

  final PaperStyle initialStyle;

  @override
  State<NewPageDesignDialog> createState() => _NewPageDesignDialogState();
}

class _NewPageDesignDialogState extends State<NewPageDesignDialog> {
  late PaperStyle _selectedStyle;

  static const _designs = [
    _PageDesignOption(
      style: PaperStyle.lined,
      title: 'Líneas',
      icon: Icons.view_headline_rounded,
    ),
    _PageDesignOption(
      style: PaperStyle.dotted,
      title: 'Puntos',
      icon: Icons.grain_rounded,
    ),
    _PageDesignOption(
      style: PaperStyle.blank,
      title: 'En blanco',
      icon: Icons.crop_portrait_rounded,
    ),
    _PageDesignOption(
      style: PaperStyle.grid,
      title: 'Cuadrícula',
      icon: Icons.grid_4x4_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _buildOptionCard(_designs[0], colorScheme)),
                const SizedBox(width: 10),
                Expanded(child: _buildOptionCard(_designs[1], colorScheme)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildOptionCard(_designs[2], colorScheme)),
                const SizedBox(width: 10),
                Expanded(child: _buildOptionCard(_designs[3], colorScheme)),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(_selectedStyle.name),
          child: const Text('Crear'),
        ),
      ],
    );
  }

  Widget _buildOptionCard(_PageDesignOption option, ColorScheme colorScheme) {
    final isSelected = _selectedStyle == option.style;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedStyle = option.style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              option.icon,
              size: 20,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            Text(
              option.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDesignOption {
  const _PageDesignOption({
    required this.style,
    required this.title,
    required this.icon,
  });

  final PaperStyle style;
  final String title;
  final IconData icon;
}
