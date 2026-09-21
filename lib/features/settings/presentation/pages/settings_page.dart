import 'dart:async';

import 'package:flutter/material.dart';
import 'package:honeyday/core/constants/app_constants.dart';
import 'package:honeyday/core/theme/app_colors.dart';

// Application version (used only for settings display).
const String kAppVersion = '0.1.4';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/app.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context).settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(label: AppLocalizations.of(context).settingsGeneral, colorScheme: colorScheme),
          SwitchListTile(
            title: Text(AppLocalizations.of(context).settingsDarkMode),
            subtitle: Text(
              themeMode == ThemeMode.system
                  ? AppLocalizations.of(context).settingsThemeSystem
                  : themeMode == ThemeMode.dark
                      ? AppLocalizations.of(context).settingsThemeOn
                      : AppLocalizations.of(context).settingsThemeOff,
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
            title: Text(AppLocalizations.of(context).settingsAccentColor),
            subtitle: Text(
              accentName ?? AppLocalizations.of(context).settingsAccentCustom,
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
          _SectionHeader(label: AppLocalizations.of(context).settingsAbout, colorScheme: colorScheme),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.of(context).settingsVersion),
            subtitle: Text(
              kAppVersion,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(AppLocalizations.of(context).settingsLicenses),
            subtitle: Text(
              AppLocalizations.of(context).settingsLicensesSubtitle,
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
        title: Text(AppLocalizations.of(context).settingsAccentColor),
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
                duration: kAnimationDurationNormal,
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
