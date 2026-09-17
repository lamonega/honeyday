import 'package:flutter/material.dart';

class ViewerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ViewerAppBar({
    required this.onBack,
    required this.actions,
    super.key,
  });

  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: onBack,
      ),
      actions: actions,
    );
  }
}
