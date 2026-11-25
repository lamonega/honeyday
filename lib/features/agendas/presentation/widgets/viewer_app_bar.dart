import 'package:flutter/material.dart';

class ViewerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ViewerAppBar({
    required this.onBack,
    required this.actions,
    this.title,
    super.key,
  });

  final VoidCallback onBack;
  final List<Widget> actions;
  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final agendaTitle = title;
    return AppBar(
      title: agendaTitle == null
          ? null
          : Text(agendaTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onBack,
      ),
      actions: actions,
    );
  }
}
