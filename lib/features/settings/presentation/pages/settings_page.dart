import 'dart:async';

import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/app.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _accentPresets = <String, Color>{
    'Abeja miel': Color(0xFFF59E0B),
    'Lavanda': Color(0xFF8B5CF6),
    'Salvia': Color(0xFF10B981),
    'Rosa': Color(0xFFEC4899),
    'Océano': Color(0xFF3B82F6),
    'Ladrillo': Color(0xFFEF4444),
    'Gris': Color(0xFF64748B),
    'Teal': Color(0xFF14B8A6),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeModeValue = ref.watch(themeModeProvider);
    final themeMode = themeModeValue.hasValue ? themeModeValue.value! : ThemeMode.system;
    final accentColorValue = ref.watch(accentColorProvider);
    final accentColor = accentColorValue.hasValue ? accentColorValue.value! : AppColors.honeyAmber;

    final accentName = _accentPresets.entries
        .where((e) => e.value.toARGB32() == accentColor.toARGB32())
        .map((e) => e.key)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          _SectionHeader(label: 'General', colorScheme: colorScheme),
          SwitchListTile(
            title: const Text('Modo oscuro'),
            subtitle: Text(
              themeMode == ThemeMode.system
                  ? 'Automático (sistema)'
                  : themeMode == ThemeMode.dark
                      ? 'Activado'
                      : 'Desactivado',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              final mode = value ? ThemeMode.dark : ThemeMode.light;
              unawaited(ref.read(themeModeProvider.notifier).set(mode));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Color de acento'),
            subtitle: Text(
              accentName ?? 'Personalizado',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline),
              ),
            ),
            onTap: () => unawaited(
              _showAccentColorPicker(context, ref, accentColor),
            ),
          ),
          const Divider(height: 1),
          _SectionHeader(label: 'Acerca de', colorScheme: colorScheme),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versión'),
            subtitle: Text(
              '0.1.0',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licencias'),
            subtitle: Text(
              'Revisar licencias de código abierto',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            onTap: () =>
                showLicensePage(context: context, applicationName: 'Honeyday'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccentColorPicker(
    BuildContext context,
    WidgetRef ref,
    Color currentColor,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color de acento'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _accentPresets.entries.map((entry) {
            final isSelected = entry.value.toARGB32() == currentColor.toARGB32();
            return GestureDetector(
              onTap: () async {
                await HapticFeedback.selectionClick();
                await ref.read(accentColorProvider.notifier).set(entry.value);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.onSurface
                        : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
