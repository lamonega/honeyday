import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(label: 'General'),
          SwitchListTile(
            title: const Text('Modo oscuro'),
            subtitle: const Text(
              'Usar el tema oscuro de la aplicación',
              style: TextStyle(color: AppColors.inkSecondary),
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
            subtitle: const Text(
              'Abeja miel',
              style: TextStyle(color: AppColors.inkSecondary),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.honeyAmber,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paperBorder),
              ),
            ),
            onTap: () {},
          ),
          const Divider(height: 1),
          const _SectionHeader(label: 'Acerca de'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versión'),
            subtitle: const Text(
              '1.0.0',
              style: TextStyle(color: AppColors.inkSecondary),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licencias'),
            subtitle: const Text(
              'Revisar licencias de código abierto',
              style: TextStyle(color: AppColors.inkSecondary),
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
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.honeyAmber,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
