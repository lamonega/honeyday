import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          _SectionHeader(label: 'General', colorScheme: colorScheme),
          SwitchListTile(
            title: const Text('Modo oscuro'),
            subtitle: Text(
              'Usar el tema oscuro de la aplicación',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (_) {
              // TODO(theme): implement theme toggle with riverpod provider
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Color de acento'),
            subtitle: Text(
              'Abeja miel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline),
              ),
            ),
            onTap: () {},
          ),
          const Divider(height: 1),
          _SectionHeader(label: 'Acerca de', colorScheme: colorScheme),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versión'),
            subtitle: Text(
              '1.0.0',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licencias'),
            subtitle: Text(
              'Revisar licencias de código abierto',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Honeyday',
            ),
          ),
        ],
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
